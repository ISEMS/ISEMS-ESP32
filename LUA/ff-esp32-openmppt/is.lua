-- If config.lua doesn't contain this setting, set to "false".
encrypted_webkey = false

-- Load content from config.lua
dofile"config.lua"

adc.setwidth(adc.ADC1, 12)

adc.setup(adc.ADC1, 6, adc.ATTEN_0db)
adc.setup(adc.ADC1, 5, adc.ATTEN_0db)
adc.setup(adc.ADC1, 4, adc.ATTEN_11db)

gpio.config( { gpio={14}, dir=gpio.OUT, pull=gpio.PULL_UP })
dac.enable(dac.CHANNEL_1)


Vref = 1100 --mV

files = file.list()

if file.exists("VrefCal") then

    print("Vref already calibrated. Great!")
    file.open("VrefCal", "r")
    Vref = file.readline()
    print("VrefValue is set to:", Vref, "mV" )
    file.close()

else

    print("VrefCal not found. Vref of ESP chip *not* calibrated. Using default Vref value of 1100 mV")
    print("It is recommended to calibrate Vref using vrcal.lua and a laboratory power supply.")

end

pagestring = "mp2.lua not started yet."

require"mp2"

function cryptokey (webkey, randomstring, webkeyhash)

    randomstring = encoder.toHex(sodium.random.buf(16))
    randomstringforhash = randomstring .. webkey
    hashobj = crypto.new_hash("SHA256")
    hashobj:update(randomstringforhash)
    digest = hashobj:finalize()
    webkeyhash = encoder.toHex(digest)
    print("Randomstringforhash:", randomstringforhash)
    print("webkey:", webkey)
    print("Randomstring:", randomstring)
    print("Digest Hex:", webkeyhash)
    print("FreeMEM:", node.heap())

return randomstring, webkeyhash

end


autoreboot_disabled = 0

if nextreboot == nil then nextreboot = 99999 end
if nextreboot == 0 then autoreboot_disabled = 1 end

print("Autoreboot_disabled  =", autoreboot_disabled)

packetrev = "1"
counter_serial_loop = 0
health_estimate = 100
powersave = 0
timestamp = 123456789
firmware_type = "ESP_1A"
health_test_in_progress = 0
health_estimate = 100
charge_state = 100
if webkey == nil then webkey = "empty" end

if encrypted_webkey == true then  randomstring,  webkeyhash = cryptokey (webkey) end

if encrypted_webkey == false then webkeyhash = webkey end



srv = net.createServer(net.TCP)
srv:listen(80, function(conn)

    http_preamble = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n"

	conn:on("receive", function(sck, payload)

                -- Send the HTTP response.
                function send_response(response)
                    sck:send(http_preamble .. response)
                end

                -- HTTP method.
                method_post = string.match(payload, "POST")

                -- Authentication key.
                key  = string.match(payload, webkeyhash)

                -- Define resources.
                csv  = string.match(payload, "csv")
                help  = string.match(payload, "help")
                rand = string.match(payload, "random")

                -- Define actions.
                ftp  = string.match(payload, "ftp+")
                rst  = string.match(payload, "reboot+")
                tel  = string.match(payload, "telnet+")
                sh  = string.match(payload, "shell+")
                mppt_start  = string.match(payload, "mpptstart+")
                load_off = string.match(payload, "loadoff+")
                load_on = string.match(payload, "loadon+")

                -- Serve HTML index page.
                if csv == nil and rand == nil and ftp == nil and rst == nil and tel == nil and sh == nil and mppt_start == nil and help == nil and load_off == nil and load_on == nil then
                    print("INDEX")
                    -- "pagestring" contains the main splash screen generated within "mp2.lua".
                    send_response(pagestring)
                    return
                end

                -- Serve "random" page.
                if rand ~= nil then
                    print("RANDOM")
                    send_response(randomstring)
                    return
                end

                -- Serve help page.
                if help ~= nil then
                    print("HELP")
                    help_page = [[
                        <html>
                        Commands on this device can be executed remotely by sending HTTP POST requests + secret-key.
                        <br><br>

                        Assuming your secret-key is "secret123", if you invoke
                        <pre>curl http://IP-or-URL-of-FF-ESP32-device --request POST --data-raw 'ftp+secret123'</pre>,
                        the system will start a FTP server and stop the main program loop to free up CPU and RAM resources.
                        <br><br>

                        Now, you can upload a customized version of <b>config.lua</b> via FTP
                        with the default FTP user-password combination <b>admin / pass123</b> like
                        <pre>lftp -u admin,pass123 IP-or-URL-of-FF-ESP32-device -c 'put config.lua'</pre>
                        <br><br>

                        All passwords are stored in <b>config.lua</b> and should be changed before deploying the system, of course.
                        Just reboot the device to apply the new configuration.
                        <br><br>

                        <h3>Commands</h3>
                        <b>/ftp+key</b> (starts ftp server and pauses the main MPPT program)<br>
                        <b>/reboot+key</b><br><b>/telnet+key</b> (starts an open (!) telnet LUA command line interface at port 2323)<br>
                        <b>/shell+key</b> (starts an open (!) Unix-like minimal commandline interface at telnet port 2333)<br>
                        <b>/mpptstart+key</b> (restarts the main mppt program. It is automatically paused when FTP starts in order to save CPU and RAM.)<br>
                        <b>/loadoff+key</b> Turn load off.<br>
                        <b>/loadon+key</b> Turn load on.<br>

                        <h3>Caveats</h3>
                        Use your passwords only over a encrypted WiFi and if you trust the network.
                        FTP and HTTP keys can be sniffed easily, as they are sent unencrypted.
                        Links are case sensitive. Remember that this is a tiny device with very limited ressources.
                        If all features are enabled, the device might occasionally run out of memory, crash and reboot.

                        </html>
                        ]]
                    send_response(help_page)
                    return
                end

                -- Serve CSV log.
                if csv ~= nil then
                    print("CSV")
                    send_response(csvlog)
                    return
                end


                -- Invoke device commands.

                -- Protect against invalid HTTP method.
                if method_post == nil then
                    send_response("Will not execute the command. Reason: Invoking commands needs HTTP POST.")
                    return
                end

                -- Protect against unauthorized access.
                if key == nil then
                    print("DENIED")
                    send_response("Will not execute the command. Reason: webkey for admin command is incorrect or missing.")
                    return
                end

                if ftp ~= nil and ftp_runs == nil then
                    print("FTP")
                    sck:send("FTP server enabled. MPPT timer stopped. Reboot device when you are finished.")
                    require("ftpserver").createServer('admin', ftppass)
                    mppttimer:stop()
                    ftp_runs = 1
                    send_response("<html>ISEMS is disabled while FTP is running. See <a href=\"help.html\">Howto</a><html>")
                end

                if rst ~= nil then
                    print("RST")
                    send_response("Rebooting in 2 seconds. Will be back in 8 seconds.")
                    reboottimer = tmr.create()
                    reboottimer:register(2000, tmr.ALARM_SINGLE, function()
                        node.restart()
                    end)
                    reboottimer:start()
                end

                if tel ~= nil and telnet_runs == nil then
                    print("TELNET")
                    send_response("Lua interface via telnet port 2323 enabled.")
                    require"telnet"
                    telnet_runs = 1
                end

                if sh ~= nil and shell_runs == nil then
                    print("SHELL")
                    send_response("Command line shell via telnet port 2333 enabled.")
                    require"telnet2"
                    shell_runs = 1
                end

                if mppt_start ~= nil then
                    print("MPPT")
                    send_response([[
                        <html>
                        Starting MPPT timer.
                        <br/><br/>
                        ISEMS is enabled. Wait a minute until the status is updated and reload the page.
                        For general help information see <a href=\"help.html\">Howto</a>
                        <html>
                        ]])
                    mppttimer:start()
                end

                if load_off ~= nil then
                    print("LOAD_OFF")
                    send_response("Load disabled.")
                    gpio.wakeup(14, gpio.INTR_LOW)
                    gpio.write(14, 0)
                    load_disabled = true
                end

                if load_on ~= nil then
                    print("LOAD_ON")
                    send_response("Load enabled.")
                    gpio.wakeup(14, gpio.INTR_HIGH)
                    gpio.write(14, 1)
                    load_disabled = false
                end

                -- Crypto magic ;].
                if encrypted_webkey == true then
                    randomstring, webkeyhash = cryptokey(webkey)
                end

	end)
	conn:on("sent", function(sck) sck:close() end)


end)


-- WiFi mode
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE

print("WiFi Mode: ", wlanmode)

if wlanmode == 3 then

print("Starting WiFi in STATIONAP mode")

-- run WiFi AP and connect to WiFi access point

wifi.mode(wifi.STATIONAP, true)

wifi.sta.on("connected", function() print("connected") end)
wifi.sta.on("got_ip", function(event, info) print("got ip "..info.ip) localstaip = info.ip end)

wifi.ap.on("start")
wifi.ap.on("sta_connected", function(event, info) print("Station connected:  "..info.mac ) end)

-- mandatory to start wifi after reset
wifi.start()

wifi.sta.sethostname("FF-ESP32")
cfg={}

cfg.ssid=ap_ssid
cfg.pwd=ap_pwd
wifi.ap.config(cfg)
cfg={}
cfg.ip=ap_ip
cfg.netmask=ap_netmask
cfg.gateway=ap_gateway
-- Possible conflict, if station is on a different channel.
-- cfg.channel=ap_channel
cfg.dns=ap_dns

wifi.ap.setip(cfg)


wifi.sta.config({ssid=sta_ssid, pwd=sta_pwd, auto=true}, true)

end

if wlanmode == 2  then

-- Run as WiFi access point

wifi.mode(wifi.SOFTAP, true)

wifi.ap.on("start")
wifi.ap.on("sta_connected", function(event, info) print("Station connected:  "..info.mac ) end)

-- mandatory to start wifi after reset
wifi.start()
cfg={}

cfg.ssid=ap_ssid
cfg.pwd=ap_pwd
wifi.ap.config(cfg)
cfg={}
cfg.ip=ap_ip
cfg.netmask=ap_netmask
cfg.gateway=ap_gateway
cfg.channel=ap_channel
cfg.dns=ap_dns

wifi.ap.setip(cfg)

end

if wlanmode == 1 then

-- Run as WiFi client
wifi.mode(wifi.STATION, true)

wifi.sta.on("connected", function() print("connected") end)
wifi.sta.on("got_ip", function(event, info) print("got ip "..info.ip) end)

wifi.sta.sethostname("FF-ESP32")
-- mandatory to start wifi after reset
wifi.start()

wifi.sta.config({ssid=sta_ssid, pwd=sta_pwd, auto=true}, true)

end

uplinktimer = tmr.create()
uplinktimer:register(10000, tmr.ALARM_SINGLE, function() print("Starting NTP service") time.initntp("pool.ntp.org") end)
uplinktimer:start()

--[[
The logic of the local timezone setting in the SDK is reversed.
For example: To get UTC+2 you actually need to set UTC-2. Whatever...
The default shows central european standard time.]]

time.settimezone("CEST-2")


mppttimer = tmr.create()
mppttimer:register(60000, tmr.ALARM_AUTO, function() dofile"mp2.lua" if autoreboot_disabled ~= 1 then nextreboot = nextreboot - 1 end
if autoreboot ~= 1 and nextreboot <= -1 then node.restart() end end)
mppttimer:start()

if mqtt_enabled == true or mqtt_enabled == true then
mqtttimer = tmr.create()
mqtttimer:register(65000, tmr.ALARM_AUTO, function() dofile"telemetry.lua" end)
mqtttimer:start()
end
