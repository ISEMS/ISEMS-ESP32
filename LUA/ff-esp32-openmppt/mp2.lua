-- IO14 GPIO = control Low-Voltage-Disconnect / external power output
-- IO32 Temp Sense,  Channel 4
-- IO34 V_in,  Channel 6
-- IO33 V_out,  Channel 5

-- ADC channel 0:GPIO36, 1:GPIO37, 2:GPIO38, 3:GPIO39, 4:GPIO32, 5:GPIO33, 6:GPIO34, 7: GPIO35

-- DAC channel 1 is attached to GPIO25 - DAC channel 2 is attached to GPIO26
-- Value: 8bit =  0 to 255

-- MPP range of FF-OpenMPPT-ESP32 v1.0
Vmpp_max = 23.8 
Vmpp_min = 14.45

-- V_out_max and V_out_max_temp in mV
V_out_max = 14200
V_out_max_temp = 14200
V_oc = 0
Vcc = 3.045
ptc_series_resistance_R17 = 2200
low_voltage_disconnect = 11.90



function ADCmeasure (adcchannel, number_of_runs, result) 
    local result = 0
    local value1 = 0
    local value2 = 0
    local c = 0

    while c ~= number_of_runs do
    --GPIO35
    value1 = adc.read(adc.ADC1, adcchannel)
    value2 = value2 + value1
    --print(value2, value1)
    c = c+1
    end
    
result = value2 / number_of_runs
result = math.floor(result)

print("ADC channel", adcchannel, " result value (12 bit):", result)
   
return result
end

function Voutctrl (number_of_steps)
    
    print("### Voutctrl active ###\n", "V_out_max_temp:", V_out_max_temp, "V_out:", V_out)
    while number_of_steps > 0 do 
        val2 = ADCmeasure(5, 3)
        -- 0.0625 ratio of Voltage divider 1k/15k
        V_out_mV = ((val2 / 4095) * Vref) / 0.0625
        V_out_mV = math.ceil(V_out)
    
            if (V_out_max_temp + 50) < V_out_mV then 
            dac1value = dac1value + 1
            if dac1value > 254 then dac1value = 254
            print("WARNING: V_out_ctrl maximum Vmpp reached.") end
            dac.write(dac.CHANNEL_1, dac1value)
            print("Setting PWM to ", dac1value)
            number_of_steps = number_of_steps - 1 
            end
            
     if (V_out_max_temp + 50) >= V_out_mV then number_of_steps = 0 end
            
    end
end



--GPIO32, TempSens
--val3 = adc.read(adc.ADC1, 4)
val3 = ADCmeasure(4, 2)

if val3 > 4000 then 
    
    print("Error: Temperature sensor not connected")
    battery_temperature = 25.0
    tempsens_missing = 1
    adc.setup(adc.ADC1, 4, adc.ATTEN_11db)
    ptc_resistor_voltage = Vcc
    ptc_resistance = 2000
    
end
    
if val3 < 4000 then

tempsens_missing = 0
    
adc.setup(adc.ADC1, 4, adc.ATTEN_6db)
print("Temperature sensor connected")

-- Vref11dB = Vref * 0.0034
Vref6dB = Vref * 0.002

--GPIO32, TempSens
--val3 = adc.read(adc.ADC1, 4)
val3 = ADCmeasure(4, 15)

print("ADC Temp sens measure first run result:", val3)

--GPIO32, TempSens
--val3 = adc.read(adc.ADC1, 4)
val3 = ADCmeasure(4, 10)

print("ADC Temp sens measure second run result:", val3)


--GPIO32, TempSens
--val3 = adc.read(adc.ADC1, 4)
val3 = ADCmeasure(4, 10)

print("ADC Temp sens measure third run result:", val3)

ptc_resistor_voltage = (val3 / 4095) * Vref6dB

ptc_resistor_voltage = ptc_resistor_voltage / 1.112

print("PTC resistor Voltage =", ptc_resistor_voltage)

ptc_resistor_voltage_mV = ptc_resistor_voltage * 1000

-- I = (Vcc (2.8V) - ptc_resistor_voltage) / R17
ptc_resistor_current = (Vcc - ptc_resistor_voltage) / ptc_series_resistance_R17
ptc_resistance = ptc_resistor_voltage / ptc_resistor_current

-- KTY 81-210 is not very accurate. Best accuracy at 40 degrees Celsius

print("PTC resistance =", ptc_resistance)

-- battery_temperature = ((ptc_resistance - 1247) / 14.15) - 30 

-- Correcting non-linearity of KTY81-210 
 
if ptc_resistance >= 2000 then 
 deviation_K = (ptc_resistance - 2000) / 16.4
 deviation_factor = (deviation_K * 0.0022) + 1
 corrected_deviation_factor = 16 * deviation_factor
 battery_temperature = 25 + ((ptc_resistance - 2000) / corrected_deviation_factor)
 end
 
if ptc_resistance < 2000 then 
 deviation_K = (2000 - ptc_resistance) / 15.1
 deviation_factor = (deviation_K * 0.0027) + 1
 corrected_deviation_factor = 15.6 / deviation_factor
 battery_temperature = 25 - ((2000 - ptc_resistance) / corrected_deviation_factor)
 end

--[[ Calculate and adjust charge end voltage depending on 
     battery battery_temperature for voltage regulated lead acid battery chemistry 
     Correction factor 5 mV per cell for one degree Celsius 
     12 V lead acid type has 6 cells]]

print ("Resistance of PTC =", ptc_resistance, "Battery_temperature =", battery_temperature) 

adc.setup(adc.ADC1, 4, adc.ATTEN_11db)

end

V_out_max_temp = V_out_max - ((battery_temperature - 25.00) * 30)

if battery_temperature > 42.00 then V_out_max_temp = 13100 end

battery_temperature = battery_temperature * 100
battery_temperature = math.floor(battery_temperature)
battery_temperature = battery_temperature / 100

V_out_max_temp = math.floor(V_out_max_temp)

V_out_max_temp = V_out_max_temp / 1000





--GPIO34, V_in
--val1 = adc.read(adc.ADC1, 6)
val1 = ADCmeasure(6, 15)

-- 0.03571 ratio of Voltage divider 1k/27k
V_in = ((val1 / 4095) * Vref) / 0.035714
-- Correction factor 
V_in = (V_in * 1.05) + 300
V_in = math.ceil(V_in) 
V_in = V_in / 1000

--GPIO33, V_out
--val2 = adc.read(adc.ADC1, 5)
val2 = ADCmeasure(5, 15)

-- 0.0625 ratio of Voltage divider 1k/15k
V_out_mV = ((val2 / 4095) * Vref) / 0.0625
V_out_mV = math.ceil(V_out_mV)
V_out = V_out_mV / 1000

--print("V_in =",val1,"V_out =",val2," TempSens =",val3)

--print("V_in =",V_in,"V  V_out =",V_out,"V  TempSens =",val3)

if V_out_max_temp < V_out_mV then Voutctrl(12) end

if V_in >= 13 and V_out_max_temp > V_out_mV then 

dac1value= 254
dac.write(dac.CHANNEL_1, dac1value)
print("Setting PWM to ", dac1value)
print("Pre-Run: Measure V_in idle") 
val1 = ADCmeasure(6, 40)
print(val1)
print("Measure V_in idle") 
val1 = ADCmeasure(6, 10)
print(val1)

V_oc = ((val1 / 4095) * (Vref / 0.03571))
V_oc = math.ceil(V_oc)
v_mpp_estimate = V_oc / 1.24
v_mpp_estimate = math.floor(v_mpp_estimate)
v_mpp_estimate = v_mpp_estimate / 1000
V_oc = (V_oc / 1000) + 0.3
print("V_oc=", V_oc)
print("V_mpp_estimate=", v_mpp_estimate)
dac1value = (v_mpp_estimate - Vmpp_min) / ((Vmpp_max - Vmpp_min) / 254)
dac1value = math.floor(dac1value)
if dac1value > 254 then dac1value = 254 end
if dac1value < 0 then dac1value = 0 end
dac.write(dac.CHANNEL_1, dac1value)
print("Setting PWM to ", dac1value)


end

if V_in < V_out then 
    
    dac1value = 0
    dac.write(dac.CHANNEL_1, dac1value)

end
    
if V_out < low_voltage_disconnect then
        print("Disabled power output")
        gpio.wakeup(14, gpio.INTR_LOW)
        gpio.write(14, 0)
        low_voltage_disconnect_state = 0
        node.dsleep(60000000)
end
    
if V_out > 12.3 and load_disabled == false then 
        gpio.wakeup(14, gpio.INTR_HIGH)
        gpio.write(14, 1)
        low_voltage_disconnect_state = 1
        print("Enabled power output")
end

--GPIO33, V_out
--val2 = adc.read(adc.ADC1, 5)
val2 = ADCmeasure(5, 15)

-- 0.0625 ratio of Voltage divider 1k/15k
V_out = (val2 / 4095) * (Vref / 0.0625)


V_out = math.ceil(V_out)
V_out = V_out / 1000

print("Measure V_in") 
val1 = ADCmeasure(6, 10)
print(val1)

V_in = ((val1 / 4095) * (Vref / 0.03571))
V_in = (V_in * 1.05) + 300
V_in = math.ceil(V_in)
V_in = V_in / 1000

print("V_in =",val1,"V_out =",val2," TempSens =",val3)

print("Vref =", Vref, "V_oc =",V_oc, "V_in =",V_in,"V  V_out =",V_out,"V  TempSens =",val3, "Battery temperature =", battery_temperature)
       
print("Resistor Voltage =", ptc_resistor_voltage)

print("PTC resistance =", ptc_resistance)


-- #################################################################################################
-- Below: Common parts from previous program isems.lua that reads data from AVR 8bit via serial port
-- #################################################################################################



print(lat)
print(nodeid)

packetrev = "1"
counter_serial_loop = 0
health_estimate = 100
powersave = 0
timestamp = 123456789
firmware_type = "FF-ESP_1A"
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

       
print("###########################################################################################")
print("V_in:", V_in, "V_out:", V_out, "V_out_max:", V_out_max, "V_out_max_temp:", V_out_max_temp)
print("###########################################################################################")

        charge_status = "Unknown"
       
        if (V_in >= V_out and V_out ~= 0) then charge_status = "Charging" Bit_0 = 1 end

        if (V_in < V_out) then charge_status = "Discharging" Bit_1 = 1 end

        if (V_out == 0.0 and V_in == 0.0) then charge_status = "No information" end

        if (V_oc == 0.0 and V_in < V_out) then V_in = 0.0 end

        if (V_oc == 0.0 and V_in > V_out) then V_oc = V_in end

        if (V_out_max_temp == 0.0) then V_out_max_temp = 14.2 end 

-- Charge state estimate
-- To estimate charge state when discharging is relatively simple, due to low and constant load.
       
       --print("we are at charge state estimate")
       print("V_in:", V_in, "V_out:", V_out)
        
        if V_in < V_out and V_out > 12.60 then charge_state = (95 + ((V_out - 12.6) * 20)) end 

        if V_in < V_out and V_out < 12.60 then charge_state = (10 + ((V_out - 11.6) * 85)) end
        
 

        -- Estimate while charging without measuring current – tricky!

        -- Detect and handle charge end
        -- At charge end, the battery can no longer take the full energy offered by the solar module. Once we are at 100% charge, the MPPT voltage almost reaches V_oc 

        if V_out >= (V_out_max_temp - 0.05) then charge_state = (((V_out - 12.0) / ((V_out_max_temp - 12.0) /100)) * (V_in / (V_oc - 0.5) )) end

       
                    
        -- Detect and handle very low charge current
        -- At very low charge current, the V_oc versus V_mpp ratio is smaller than the MPP controller calculates.

        if V_out < (V_out_max_temp - 0.05) and V_in > V_out and 1.22 > (V_oc / V_in) and V_out > 12.6 then charge_state = (85 + ((V_out - 12.6) * 30)) end
       
                    
        -- Detect and handle considerable charge current
        -- At considerable charge current, the V_oc versus V_mpp ratio matches the ratio the MPP controller calculates. Unless the current doesn't go down close to zero, we haven't reached charge limit.

        if V_out < (V_out_max_temp - 0.05) and 1.22 < (V_oc / V_in) then charge_state = (V_out - (V_out_max_temp * 0.85)) / ((V_out_max_temp - (V_out_max_temp * 0.85)) / 90) end

       
if  charge_state_float == nil then charge_state_float = charge_state end

    
--[[ Handle the corner case when the router has spent time running without serial data from the controller.
-- Kickstart from charge state estimate, as soon as the controller is connected again.]]

if (charge_state_float < (charge_state - 30)) then charge_state_float = charge_state
end 
       

-- Sanity check of battery level gauge: Move slowly

if charge_state > charge_state_float then charge_state = charge_state_float + 0.25 end

if charge_state < charge_state_float and V_out > 0 then charge_state = charge_state_float - 0.25 end

charge_state_float = charge_state 

charge_state_int = math.ceil(charge_state)



-- if V_out >= (V_out_max_temp - 0.05) and V_in >= (V_oc * 0.95) and V_in > 16.00 then charge_status = "Fully charged" Bit_2 = 1 end

if charge_state_int > 100 then charge_state_int = 100 end

if charge_state_int == 100 then charge_status = "Fully charged" Bit_2 = 1 Bit_0 = 0 end 

if charge_state_int < 0 then charge_state_int = 0 end


       
-- Battery health estimate calculation
                    
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

        if battery_gauge_start > 100 then battery_gauge_start = 100 end

        if battery_gauge_start >0 and battery_gauge_stop > 0 and average_power_consumption > 0 then health_estimate = (((6 * average_power_consumption) / (((battery_gauge_start - battery_gauge_stop) / 100) * rated_batt_capacity)) * 100) end


        print ("Battery health estimate: ", health_estimate)

        health_estimate = math.ceil(health_estimate)

        if health_estimate > 100 then health_estimate = 100 end

        end)
        battery_health_timer:start()
end

       
-- System health report
       


critical_storage_charge_ratio = 5.0


storage_charge_ratio =  (rated_batt_capacity * (health_estimate / 100)) / (solar_module_capacity / 15)

system_status = " "

if (storage_charge_ratio > critical_storage_charge_ratio and charge_state > 50) then system_status = "Healthy. " Bit_3 = 1 end

if (storage_charge_ratio > critical_storage_charge_ratio and charge_state <= 50) then system_status = "Warning: Battery level low. Increased battery wear. "  Bit_4 = 1 end

if (storage_charge_ratio <= critical_storage_charge_ratio) then system_status = system_status .. "Warning: Energy storage capacity too small. Check battery size and/or wear. "  Bit_5 = 1 end

if tempsens_missing == 1 then system_status = system_status .. "Warning: Temperature sensor not connected. " Bit_6 = 1 end

if V_out == 0.0 then system_status = "Error: No communication with solar controller." Bit_7 = 1 V_out_max_temp = 0 end

battery_temperature = tonumber(battery_temperature) 

if battery_temperature >= 40.0 then system_status = system_status .. "Battery overheating. " Bit_8 = 1 end

if battery_temperature <= -10.0 then system_status = system_status .. "Low battery temperature. " Bit_9 = 1 end
          
                    
if 0.2 > V_out - low_voltage_disconnect or tonumber(nextreboot) < 15 then Bit_10 = 1 end



bit_string_0 = (Bit_0 .. Bit_1 .. Bit_2 .. Bit_3)
bit_string_1 = (Bit_4 .. Bit_5 .. Bit_6 .. Bit_7)
bit_string_2 = (Bit_8 .. Bit_9 .. Bit_10 .. Bit_11)


print("bitstrings: ", bit_string_0, bit_string_1, bit_string_2)

statuscode = (bin2hextable[bit_string_0] .. bin2hextable[bit_string_1] .. bin2hextable[bit_string_2])
-- statuscode_json = ("0x" .. statuscode)

print("statuscode =", statuscode)

freeRAM = node.heap()

-- CSV payload

timestamp = time.get()

-- print("Creating csvlog.")
       
-- print(nodeid, packetrev, timestamp, firmware_type, nextreboot, powersave, V_oc, V_in, V_out, charge_state_int, health_estimate, battery_temperature, low_voltage_disconnect, V_out_max_temp, rated_batt_capacity, solar_module_capacity, lat, long, statuscode)
      
ffopenmppt_log = nodeid .. ";" .. packetrev .. ";" .. timestamp .. ";" .. firmware_type .. ";" .. nextreboot .. ";" .. powersave .. ";".. V_oc .. ";".. V_in .. ";".. V_out .. ";".. charge_state_int .. ";" .. health_estimate .. ";".. battery_temperature .. ";".. low_voltage_disconnect .. ";".. V_out_max_temp .. ";" .. rated_batt_capacity .. ";".. solar_module_capacity .. ";".. lat .. ";" .. long .. ";" ..  statuscode

print("CSV payload:", ffopenmppt_log)
       
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




node_uptime = math.floor((node.uptime() / 1000000))

-- HTML output
        pagestring = "HTTP/1.0 200 OK\r\nContent-Type: text/html\r\n\r\n<h1>Independent Solar Energy Mesh</h1><br><h2>Status of " .. nodeid
        pagestring = pagestring  .. " (local node)</h2><br><br>Summary: " .. charge_status  .. ". " .. system_status
        pagestring = pagestring  .. "<br>Charge state: " 
        pagestring = pagestring .. charge_state_int
        pagestring = pagestring .. "%<br>Next scheduled reboot by watchdog in: "
        pagestring = pagestring .. nextreboot
        pagestring = pagestring .. " minutes<br>Battery voltage: "
        pagestring = pagestring .. V_out
        pagestring = pagestring .. " Volt<br>Battery temperature: "
        pagestring = pagestring .. " Volt<br>Temperature corrected charge end voltage: "
        pagestring = pagestring .. V_out_max_temp
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
        pagestring = pagestring .. "<br>Free RAM in Bytes: " .. freeRAM
        pagestring = pagestring .. "<br>Uptime in seconds: " .. node_uptime   
        pagestring = pagestring .. "</h3> <h2> <a href=\"help.html\">Howto</a></h2>"
       
print(pagestring)


