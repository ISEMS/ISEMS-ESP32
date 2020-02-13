# Uploading code

Once the NodeMCU FreeRTOS firmware is flashed to the FF-ESP32-OpenMPPT, the system is ready for uploading ISEMS (or whatever) Lua program code. Uploading code is different to flashing and can be performed with a serial dongle when the device is running.

Connect a serial port adapter (3.3 V logic level) to the board and wire:

> **3.3V to 3.3V**

>**TX to RX**

>**RX to TX** 

>**GND to GND** 

In this case, the 3.3V power pin of the USB serial port adapter is supplying power to the ESP32 on the FF-ESP32 board.

My favorite tool for uploading code is **nodemcu-tool**, but there are other
options listed [here.](https://nodemcu.readthedocs.io/en/master/getting-started/)

Once you have found and installed the upload tool you are happy with, copy all .lua files from the LUA folder into the device.

If your device is the FF-ESP32-OpenMPPT, upload the files from LUA/ff-esp32-openmppt.

Example with nodemcu-tool: 

`nodemcu-tool upload cmds.lua  config.lua  init.lua  is.lua  mp2.lua  shell.lua  telemetry.lua  telnet2.lua  telnet.lua  vrcal.lua`

While we are at it, check that the ESP32 chip is calibrated for accurate measurements. Check if there is a calibration file in the flash storage:

`nodemcu-tool fsinfo`

The calibration file is named **VrefCal**. It is a good idea to make a backup of this file, in case the flash is going to be erased.

`nodemcu-tool download VrefCal`

If **VrefCal** is present, the device is ready to go. If not, check out the calibration instructions in CALIBRATION.md

