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

dofile"mp2.lua"

print(lat)
print(nodeid)

nextreboot = 99999
packetrev = "1"
counter_serial_loop = 0
health_estimate = 100
powersave = 0
timestamp = 123456789
firmware_type = "ESP_1A"
health_test_in_progress = 0
health_estimate = 100
charge_state = 100


print("WiFi Mode: ", wlanmode)


srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
	conn:on("receive", function(sck, payload)
		print(payload)
                 v  = string.match(payload, "csv")
                if v == nil then sck:send(pagestring) else sck:send(csvlog) end
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
wifi.sta.on("got_ip", function(event, info) print("got ip "..info.ip) end)

wifi.ap.on("start")
wifi.ap.on("sta_connected", function(event, info) print("Station connected:  "..info.mac ) end)

-- mandatory to start wifi after reset
wifi.start()

--wifi.sta.sethostname("ESP32ISEMS")
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

--wifi.sta.sethostname("ESP32ISEMS")
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

-- mandatory to start wifi after reset
wifi.start()

--wifi.sta.sethostname("ESP32ISEMS")


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
mppttimer:register(60000, tmr.ALARM_AUTO, function() dofile"mp2.lua" end)
mppttimer:start()

