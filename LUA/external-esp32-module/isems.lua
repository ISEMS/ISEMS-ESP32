-- Load content from config.lua

--conf = {} 
-- f, err = loadfile("config.lua", "t", conf)()

dofile"config.lua"


print(lat)
print(nodeid)

nextreboot = 99999

-- configure UART port 2 of ESP32 for 9600, 8N1, with echo,
-- to communicate with the Freifunk-Open-MPPT-Solarcontroller

-- configure for 9600, 8N1, with echo
uart.setup(2, 9600, 8, uart.PARITY_NONE, uart.STOPBITS_1, {tx = 17, rx = 16})
uart.start(2)
packetrev = "1"
counter_serial_loop = 0
health_estimate = 100
powersave = 0
timestamp = 123456789
firmware_type = "ESP_1A"
pagestring = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Independent Solar Energy Mesh</h1><br><h2>Status of " .. nodeid .. "(local node)</h2><br> No data yet. Come back in a minute."
csvlog = nodeid .. ";1;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0;0"
quickstart_threshold = 14
health_test_in_progress = 0
health_estimate = 100

charge_state = 0

Bit_0  = 0
Bit_1  = 0
Bit_2  = 0
Bit_3  = 0
Bit_4  = 0
Bit_5  = 0
Bit_6  = 0
Bit_7  = 0
Bit_8  = 0
Bit_9  = 0
Bit_10 = 0
Bit_11 = 0

srv = net.createServer(net.TCP)
srv:listen(80, function(conn)
	conn:on("receive", function(sck, payload)
		print(payload)
                 v  = string.match(payload, "csv")
                if v == nil then sck:send(pagestring) else sck:send(csvlog) end
	end)
	conn:on("sent", function(sck) sck:close() end)
end)


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
cfg.dns=ap_dns

wifi.ap.setip(cfg)


wifi.sta.config({ssid=sta_ssid, pwd=sta_pwd, auto=true}, true)

uplinktimer = tmr.create()
uplinktimer:register(10000, tmr.ALARM_SINGLE, function() print("Starting NTP service") time.initntp("pool.ntp.org") end)
uplinktimer:start()

--[[
The logic of the local timezone setting in the SDK is reversed. 
For example: To get UTC+2 you actually need to set UTC-2. Whatever... 
The default shows central european standard time.]]

time.settimezone("CEST-2")

-- uart 2

uart.on(2, "data", "\r",
    function(data)
       print(data)
       v = string.match(data, "Temperature.%d+.%d")
       if v ~= nil then battery_temperature = string.match(v, "%d+.%d") end
       
       v  = string.match(data, "Temperature adjusted charge end..%d+")
       if v ~= nil then  temp_corr_V_end = string.match(v, "%d+") 
       temp_corr_V_end = temp_corr_V_end/1000 end
       
       v  = string.match(data, "Firmware:.%w+_%a+_%d+")
       if v ~= nil then firmware_type =  string.match(v, "%w+_%a+_%d+") end
       
       v = string.match(data, "V_in_idle.%d+")
       if v ~= nil then V_oc = string.match(v, "%d+") 
       V_oc = V_oc/1000 end
       
       v = string.match(data, "V_in.%d+")
       if v ~= nil then V_in = string.match(v, "%d+")
       V_in = V_in/1000 end
       
       v = string.match(data, "V_out.%d+")
       if v ~= nil then V_out = string.match(v, "%d+")
       V_out = V_out/1000 end
       
       v = string.match(data, "Minutes until load off: %d+")
       if v ~= nil then nextreboot = string.match(v, "%d+") end
       
       v = string.match(data, "F=Load oFF.......%d+")
       if v ~= nil then low_voltage_disconnect = string.match(v, "%d+") end
       
       counter_serial_loop = (counter_serial_loop + 1) 
       
       print("we are before counter serial loop", counter_serial_loop)
        
        if counter_serial_loop >= quickstart_threshold then counter_serial_loop = 0
       
       quickstart_threshold = 28
       
       
       print("we are inside counter serial loop", counter_serial_loop)
       
        if (V_in >= V_out and V_out ~= 0) then charge_status = "Charging" Bit_0 = 1 end

        if (V_in < V_out) then charge_status = "Discharging" Bit_1 = 1 end

        if (V_out == 0.0 and V_in == 0.0) then charge_status = "No information" end

        if (V_oc == 0.0 and V_in < V_out) then V_in = 0.0 end

        if (V_oc == 0.0 and V_in > V_out) then V_oc = V_in end

        if (temp_corr_V_end == 0.0) then temp_corr_V_end = 14.2 end 

-- Charge state estimate
-- To estimate charge state when discharging is relatively simple, due to low and constant load.
       
       print("we are at charge state estimate", counter_serial_loop)
        
        if V_in < V_out and V_out > 12.60 then charge_state = (95 + ((V_out - 12.6) * 20)) end 

        if V_in < V_out and V_out < 12.60 then charge_state = (10 + ((V_out - 11.6) * 85)) end 

        -- Estimate while charging without measuring current – tricky!

        -- Detect and handle charge end
        -- At charge end, the battery can no longer take the full energy offered by the solar module. Once we are at 100% charge, the MPPT voltage almost reaches V_oc 

        if V_out >= (temp_corr_V_end - 0.05) then charge_state = (((V_out - 12.0) / ((temp_corr_V_end - 12.0) /100)) * (V_in / (V_oc - 0.5) )) end

                    
        -- Detect and handle very low charge current
        -- At very low charge current, the V_oc versus V_mpp ratio is smaller than the MPP controller calculates.

        if V_out < (temp_corr_V_end - 0.05) and V_in > V_out and 1.22 > (V_oc / V_in) and V_out > 12.6 then charge_state = (85 + ((V_out - 12.6) * 30)) end

                    
        -- Detect and handle considerable charge current
        -- At considerable charge current, the V_oc versus V_mpp ratio matches the ratio the MPP controller calculates. Unless the current doesn't go down close to zero, we haven't reached charge limit.

        if V_out < (temp_corr_V_end - 0.05) and 1.22 < (V_oc / V_in) then charge_state = (V_out - (temp_corr_V_end * 0.85)) / ((temp_corr_V_end - (temp_corr_V_end * 0.85)) / 90) end

       

print("we are at charge state float", counter_serial_loop)
       
if  charge_state_float == nil then charge_state_float = charge_state end
    
--[[ Handle the corner case when the router has spent time running without serial data from the controller.
-- Kickstart from charge state estimate, as soon as the controller is connected again.]]

if (charge_state_float < (charge_state - 30)) then charge_state_float = charge_state
print("Debug: Kickstart battery gauge from charge state estimate")
end 

-- Sanity check of battery level gauge: Move slowly

if charge_state > charge_state_float then charge_state = charge_state_float + 0.25 end

if charge_state < charge_state_float and V_out > 0 then charge_state = charge_state_float - 0.25 end

charge_state_float = charge_state 

charge_state_int = math.ceil(charge_state)


-- if V_out >= (temp_corr_V_end - 0.05) and V_in >= (V_oc * 0.95) and V_in > 16.00 then charge_status = "Fully charged" Bit_2 = 1 end

if charge_state_int > 100 then charge_state_int = 100 end

if charge_state_int == 100 then charge_status = "Fully charged" Bit_2 = 1 Bit_0 = 0 end 

if charge_state_int < 0 then charge_state_int = 0 end


       
       
-- Battery health estimate calculation
       
print("we are at battery health estimate", counter_serial_loop)
                    
-- Log discharge rate over 6 hours at night. Save battery gauge at 22 hours local time, then check charge state again 6 hours later.

-- Check if we are at 2 hours before midnight.
       
localTime = time.getlocal()
print(string.format("%04d-%02d-%02d %02d:%02d:%02d DST:%d", localTime["year"], localTime["mon"], localTime["day"], localTime["hour"], localTime["min"], localTime["sec"], localTime["dst"]))
       
print("Local Time variable: ", localTime["hour"])



if health_test_in_progress == 0 and localTime["hour"] == 17 and timestamp > 1569859000 then 
        print("Starting 6 hour discharge check") 
        health_test_in_progress = 1
        battery_gauge_start = charge_state_float - 0.5
        battery_health_timer = tmr.create()
        --battery_health_timer:register(86400000, tmr.ALARM_SINGLE, function() health_test_in_progress = 0  battery_gauge_stop = charge_state_float 
         battery_health_timer:register(86000, tmr.ALARM_SINGLE, function() health_test_in_progress = 0  battery_gauge_stop = charge_state_float                      
        -- Take reading tolerance into account. Better err on the positive side, particularly at weak loads.
        -- 0.5% error is quite humble. It might be necessary to increase this value to avoid false alarms about broken batteries.
        print("we are at battery health timer event", counter_serial_loop)

        if battery_gauge_start > 100 then battery_gauge_start = 100 end

        if battery_gauge_start >0 and battery_gauge_stop > 0 and average_power_consumption > 0 then health_estimate = (((6 * average_power_consumption) / (((battery_gauge_start - battery_gauge_stop) / 100) * rated_batt_capacity)) * 100) end


        print ("Battery health estimate: ", health_estimate)

        health_estimate = math.ceil(health_estimate)

        if health_estimate > 100 then health_estimate = 100 end

        end)
        battery_health_timer:start()
end

       
-- System health report
       
print("we are at system health report", counter_serial_loop)

critical_storage_charge_ratio = 5.0

print("we are at system health report - Step 1", counter_serial_loop)
storage_charge_ratio =  (rated_batt_capacity * (health_estimate / 100)) / (solar_module_capacity / 15)
print("we are at system health report - Step 2", counter_serial_loop)
system_status = " "
print("we are at system health report - Step 3", counter_serial_loop)
if (storage_charge_ratio > critical_storage_charge_ratio and charge_state > 50) then system_status = "Healthy. " Bit_3 = 1 end
print("we are at system health report - Step 4", counter_serial_loop)
if (storage_charge_ratio > critical_storage_charge_ratio and charge_state <= 50) then system_status = "Warning: Battery level low. Increased battery wear. "  Bit_4 = 1 end
print("we are at system health report - Step 5", counter_serial_loop)
if (storage_charge_ratio <= critical_storage_charge_ratio) then system_status = system_status .. "Warning: Energy storage capacity too small. Check battery size and/or wear. "  Bit_5 = 1 end
print("we are at system health report - Step 6", counter_serial_loop)
if (temp_corr_V_end == 14.2 and battery_temperature == 0) then system_status = system_status .. "Warning: Temperature sensor not connected. " Bit_6 = 1 end

print("we are at system health report - Step 7", counter_serial_loop)
if V_out == 0.0 then system_status = "Error: No communication with solar controller." Bit_7 = 1 temp_corr_V_end = 0 end
print("we are at system health report - Step 8", counter_serial_loop)
battery_temperature = tonumber(battery_temperature) 

if battery_temperature >= 40.0 then system_status = system_status .. "Battery overheating. " Bit_8 = 1 end
print("we are at system health report - Step 9", counter_serial_loop)
if battery_temperature <= -10.0 then system_status = system_status .. "Low battery temperature. " Bit_9 = 1 end
print("we are at system health report - Step 10", counter_serial_loop)
-- Check if the conditions for a router firmware update are met.
-- We can't do it when either the low voltage disconnect or the
-- watchdog are about to cut the routers power supply.
-- This could brick the device.                    
                    
if 0.2 > V_out - low_voltage_disconnect or tonumber(nextreboot) < 15 then Bit_10 = 1 end
print("we are at system health report - Step 11", counter_serial_loop)
bit_string_0 = (Bit_0 .. Bit_1 .. Bit_2 .. Bit_3)
bit_string_1 = (Bit_4 .. Bit_5 .. Bit_6 .. Bit_7)
bit_string_2 = (Bit_8 .. Bit_9 .. Bit_10 .. Bit_11)
print("we are at system health report - Step 12", counter_serial_loop)


bin2hextable = {
	["0000"] = "0",
	["0001"] = "1",
	["0010"] = "2",
	["0011"] = "3",
	["0100"] = "4",
	["0101"] = "5",
	["0110"] = "6",
	["0111"] = "7",
	["1000"] = "8",
	["1001"] = "9",
	["1010"] = "A",
        ["1011"] = "B",
        ["1100"] = "C",
        ["1101"] = "D",
        ["1110"] = "E",
        ["1111"] = "F"
	}



print("we are at bin2hextable", counter_serial_loop)
       
statuscode = (bin2hextable[bit_string_0] .. bin2hextable[bit_string_1] .. bin2hextable[bit_string_2])
-- statuscode_json = ("0x" .. statuscode)


-- Create CSV data set
print("we are at CSV data set create ", counter_serial_loop)

timestamp = time.get()
       
print(nodeid, packetrev, timestamp, firmware_type, nextreboot, powersave, V_oc, V_in, V_out, charge_state_int, health_estimate, battery_temperature, low_voltage_disconnect, temp_corr_V_end, rated_batt_capacity, solar_module_capacity, lat, long, statuscode)
      
ffopenmppt_log = nodeid .. ";" .. packetrev .. ";" .. timestamp .. ";" .. firmware_type .. ";" .. nextreboot .. ";" .. powersave .. ";".. V_oc .. ";".. V_in .. ";".. V_out .. ";".. charge_state_int .. ";" .. health_estimate .. ";".. battery_temperature .. ";".. low_voltage_disconnect .. ";".. temp_corr_V_end .. ";" .. rated_batt_capacity .. ";".. solar_module_capacity .. ";".. lat .. ";" .. long .. ";" ..  statuscode
       
if ffopenmppt_log5 ~= nil then 
       ffopenmppt_log1 = ffopenmppt_log2
       ffopenmppt_log2 = ffopenmppt_log3
       ffopenmppt_log3 = ffopenmppt_log4 
       ffopenmppt_log4 = ffopenmppt_log5
       ffopenmppt_log5 = ffopenmppt_log
       csvlog = ffopenmppt_log1 .. "\n" ..  ffopenmppt_log2 .. "\n" .. ffopenmppt_log3 .. "\n" ..  ffopenmppt_log4 .. "\n" .. ffopenmppt_log5
       
       elseif ffopenmppt_log5 == nil and ffopenmppt_log4 ~= nil then ffopenmppt_log5 = ffopenmppt_log csvlog = ffopenmppt_log1 .. "\n" ..  ffopenmppt_log2 .. "\n" .. ffopenmppt_log3 .. "\n" ..  ffopenmppt_log4 .. "\n" .. ffopenmppt_log5
       
       elseif ffopenmppt_log4 == nil and ffopenmppt_log3 ~= nil then ffopenmppt_log4 = ffopenmppt_log csvlog = ffopenmppt_log1 .. "\n" ..  ffopenmppt_log2 .. "\n" .. ffopenmppt_log3 .. "\n" ..  ffopenmppt_log4
       
       elseif ffopenmppt_log3 == nil and ffopenmppt_log2 ~= nil then ffopenmppt_log3 = ffopenmppt_log csvlog = ffopenmppt_log1 .. "\n" ..  ffopenmppt_log2 .. "\n" .. ffopenmppt_log3
       
       elseif ffopenmppt_log2 == nil and ffopenmppt_log1 ~= nil then ffopenmppt_log2 = ffopenmppt_log csvlog = ffopenmppt_log1 .. "\n" ..  ffopenmppt_log2
       
       elseif ffopenmppt_log1 == nil then ffopenmppt_log1 = ffopenmppt_log csvlog = ffopenmppt_log1
       
        end
        

--print(ffopenmppt_log)
       
print("we successfully finished CSV data set create ", counter_serial_loop)
       

print("we are at create pagestring", counter_serial_loop)

        pagestring = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Independent Solar Energy Mesh</h1><br><h2>Status of " .. nodeid
        pagestring = pagestring  .. " (local node)</h2><br><br>Summary: " .. charge_status  .. ". " .. system_status
        pagestring = pagestring  .. "<br>Charge state: " 
        pagestring = pagestring .. charge_state_int
        pagestring = pagestring .. "%<br>Next scheduled reboot by watchdog in: "
        pagestring = pagestring .. nextreboot
        pagestring = pagestring .. " minutes<br>Battery voltage: "
        pagestring = pagestring .. V_out
        pagestring = pagestring .. " Volt<br>Temperature corrected charge end voltage: "
        pagestring = pagestring .. temp_corr_V_end
        pagestring = pagestring .. " Volt<br>Battery temperature: "
        pagestring = pagestring .. battery_temperature
        pagestring = pagestring .. "&deg;C<br>Battery health estimate: "
        pagestring = pagestring .. health_estimate
        pagestring = pagestring .. "%<br>Power save level: "
        pagestring = pagestring .. powersave
        pagestring = pagestring .. "<br>Solar panel open circuit voltage: "
        pagestring = pagestring .. V_oc
        pagestring = pagestring .. " Volt<br>MPP-Tracking voltage: "
        pagestring = pagestring .. V_in
        pagestring = pagestring .. " Volt<br>Low voltage disconnect voltage: "
        pagestring = pagestring .. low_voltage_disconnect
        pagestring = pagestring  .. " Volt<br>Rated battery capacity (when new): "
        pagestring = pagestring  .. rated_batt_capacity
        pagestring = pagestring  ..  " Ah<br>Rated solar module power: "
        pagestring = pagestring .. solar_module_capacity
        pagestring = pagestring .. " Watt<br>Unix-Timestamp: "
        pagestring = pagestring .. timestamp
        pagestring = pagestring .. " (local time)<br>Solar controller type and firmware: "
        pagestring = pagestring .. firmware_type
        pagestring = pagestring  .. "<br>Latitude: "
        pagestring = pagestring .. lat .. "<br>Longitude: "
        pagestring = pagestring .. long
        pagestring = pagestring  .. "<br>Status code: 0x"
        pagestring = pagestring .. statuscode
        pagestring = pagestring .. "</h3>"
       --<h2>" .. ffopenmppt_log .. "<h2>"
       
print(pagestring)

       end
       
            end)






