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
	conn:on("receive", function(sck, payload)

                 csv  = string.match(payload, "csv")
                 ftp  = string.match(payload, "ftp+")
                 rst  = string.match(payload, "reboot+")
                 tel  = string.match(payload, "telnet+")
                 sh  = string.match(payload, "shell+")
                 m  = string.match(payload, "mpptstart+")
                 load_off = string.match(payload, "loadoff+")
                 load_on = string.match(payload, "loadon+")
                 rand = string.match(payload, "random.html")
                 h  = string.match(payload, "help")

                 key  = string.match(payload, webkeyhash)
                 rand = string.match(payload, "random")


                if csv == nil and rand == nil  and ftp == nil and rst == nil and tel == nil and sh == nil and m == nil and h == nil and load_off == nil and load_on == nil then sck:send(pagestring) print("INDEX") end

                if csv ~= nil then print("CSV") sck:send(csvlog)  end

                if rand ~= nil then print("RANDOM") sck:send(randomstring)  end

                if ftp ~= nil and key ~= nil and ftp_runs == nil then print("FTP") sck:send("FTP server enabled. MPPT timer stopped. Reboot device when you are finished.") require("ftpserver").createServer('admin', ftppass)  mppttimer:stop() ftp_runs = 1 pagestring = "<html>ISEMS is disabled while FTP is running. See <a href=\"help.html\">Howto</a><html>" if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end end

                if rst ~= nil and key ~= nil then print("RST") sck:send("Rebooting in 2 seconds. Will be back in 8 seconds.") reboottimer = tmr.create() reboottimer:register(2000, tmr.ALARM_SINGLE, function() node.restart() end) reboottimer:start() end

                if tel ~= nil and key ~= nil and telnet_runs == nil then print("TELNET") sck:send("Lua interface via telnet port 2323 enabled.") require"telnet" telnet_runs = 1 if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end  end

                if sh ~= nil and key ~= nil and shell_runs == nil then print("SHELL") sck:send("Command line shell via telnet port 2333 enabled.") require"telnet2" shell_runs = 1 if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end  end

                if m ~= nil and key ~= nil then print("MPPT") sck:send("Starting MPPT timer.") pagestring = "<html>ISEMS is enabled. Wait a minute unti the status is updated and reload the page. For general help information see <a href=\"help.html\">Howto</a><html>" mppttimer:start() if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end  end

                if load_off ~= nil and key ~= nil then print("LOAD_OFF") sck:send("Load disabled.") gpio.wakeup(14, gpio.INTR_LOW) gpio.write(14, 0) load_disabled = true if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end  end

                if load_on ~= nil and key ~= nil then print("LOAD_ON") sck:send("Load enabled.")  gpio.wakeup(14, gpio.INTR_HIGH) gpio.write(14, 1) load_disabled = false if encrypted_webkey == true then  randomstring, webkeyhash = cryptokey (webkey) end end

                if (ftp ~= nil or rst ~= nil or tel ~= nil or sh ~= nil or m ~= nil or load_off ~= nil or load_on ~= nil ) and key == nil then print("DENIED") sck:send("Will not execute the command. Reason: webkey for admin command is incorrect or missing.") end

                if h ~= nil then print("HELP") sck:send("<html>Commands on this device can be executed remotely by sending HTTP GET requests + secret-key. <br><br>Assuming your secret-key is secret123, if you open the URL <h3>http://IP-or-URL-of-FF-ESP32-device/ftp+secret123</h3> in a browser, the system will start a FTP server and stop the main program loop to free up CPU and RAM ressources. Now you can upload a customized version of <b>config.lua</b> via FTP with the default FTP user-password combination <b>admin / pass123</b>. All passwords are stored in <b>config.lua</b> and should be changed before deploying the system, of course. Reboot the device to apply the new config.<br><br>You have the option to use a unsafe (plain text key) and a (relatively) safe option to execute remote commands. If the option <b>encrypted_webkey=true</b> is set in <b>config.lua</b>, each action triggered via HTTP GET requires a encrypted one-time key. The one-time key is the sha256 checksum of the random string nonce+secret-key (without the <b>+</b> in between). The nonce is available <a href=\"random.html\">here</a>. For example, if the nonce is 123456789, the one-time key can be generated by executing <b>echo -n 123245689secret123 | sha256sum</b> <h3>Commands:</h3> <b>/ftp+key</b> (starts ftp server and pauses the main MPPT program)<br><b>/reboot+key</b><br><b>/telnet+key</b> (starts an open (!) telnet LUA command line interface at port 2323)<br><b>/shell+key</b> (starts an open (!) Unix-like minimal commandline interface at telnet port 2333)<br><b>/mpptstart+key</b> (restarts the main mppt program. It is automatically paused when FTP starts in order to save CPU and RAM.)<br><b>/loadoff+key</b> Turn load off.<br><b>/loadon+key</b> Turn load on.<h3>Use your passwords only over a encrypted WiFi and if you trust the network. FTP and HTTP keys can be sniffed easily, as they are sent unencrypted. Links are case sensitive. Remember that this is a tiny device with very limited resources. If all features are enabled, the device might occasionally run out of memory, crash and reboot. </h3>") end

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
