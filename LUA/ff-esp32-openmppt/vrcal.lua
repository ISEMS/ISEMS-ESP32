--[[
* **********************************************************************
 * Calibration LUA source code for FF-ESP32-OpenMPPT
 * Copyright (C) 2020  by Corinna 'Elektra' Aichele
 *
 * This file is part of the Open-Hardware and Open-Software project 
 * FF-ESP32-OpenMPPT.
 * 
 * This file is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * You should have received a copy of the GNU General Public License
 * along with this source file. If not, see http://www.gnu.org/licenses/. 
 ************************************************************************* ]]


-- IO14 GPIO = control Low-Voltage-Disconnect
-- IO32 Temp Sense,  Channel 4
-- IO34 V_in,  Channel 6
-- IO33 V_out,  Channel 5

-- channel 0:GPIO36, 1:GPIO37, 2:GPIO38, 3:GPIO39, 4:GPIO32, 5:GPIO33, 6:GPIO34, 7: GPIO35


function ADCmeasure (adcchannel, number_of_runs, result) 
    local result = 0
    local value1 = 0
    local value2 = 0
    local c = 0

    while c ~= number_of_runs do
    --GPIO35
    value1 = adc.read(adc.ADC1, adcchannel)
    value2 = value2 + value1
    print(value2, value1)
    c = c+1
    end
    
result = value2 / number_of_runs
result = math.floor(result)

print("ADC channel", adcchannel, " result value (12 bit):", result)
   
return result
end


adc.setwidth(adc.ADC1, 12)

adc.setup(adc.ADC1, 6, adc.ATTEN_0db)
adc.setup(adc.ADC1, 5, adc.ATTEN_0db)
adc.setup(adc.ADC1, 4, adc.ATTEN_11db)

print("")
print("############################################### NOTE: ##########################################")
print("Before you run this tool, set 12.800 V at the battery connectors of the device, this will result")
print("in 0.800 V between the low voltage side of resistor R26 and GND as external comparison reference.")
print("")


-- Dry run.
--GPIO33, V_out
--val2 = adc.read(adc.ADC1, 5)
val2 = ADCmeasure(5, 10)

print("Test run. ADC of V_out (12 bit) =", val2)



val2 = ADCmeasure(5, 30)

Vout = (val2 / 4095) * 1.1


print(" ADC of V_out (12 bit) =", val2)

print("V_out =", Vout)

-- If Vref would be accurate, the reading @ R8 would be 2978 @ 0.8 V
Vrcal = 1100 / (val2 / 2978)


print ("VrefCal:", Vrcal, "mV")

print("")

IntVrcal = math.ceil(Vrcal)

files = file.list()

if file.exists("VrefCal") then

    file.open("VrefCal", "r")
    print("Already calibrated. If you want to recalibrate delete the file VrefCal and set Vbatt to 12.80 V")
    print("VrefValue is set to:", file.readline())
    file.close()
    
else
    
    if IntVrcal < 1210 and IntVrcal > 990 then 
    print("Writing new calibration file VrefCal")
    file.open("VrefCal", "w+")
    file.write(IntVrcal)
    file.close()
    
    else 
    
    print("The calculated value is implausible. I'm NOT writing that value to the calibration file.")
    print("Did you follow the required procedure? Check the NOTE section above.")
    
    end
    
end

