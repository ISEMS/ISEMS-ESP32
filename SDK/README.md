# Firmware and flashing

**Reasons to start here:** 

* Flash a new device

* Add/remove NODEMCU modules required by new/updated ISEMS firmware or external sensors/extensions

* Update FREE-RTOS

* Roll your own firmware

**Compile the firmware:**

Go to the [NODEMCU GIT directory](https://github.com/nodemcu/nodemcu-firmware/tree/dev-esp32) and clone ('**git clone**') or download the dev-esp32 branch. 

The documentation for NODEMCU on ESP32 is here: https://nodemcu.readthedocs.io/en/dev-esp32/

**Note: Documentation and modules for ESP32 is slightly different to ESP8266. If you are looking for documentation for library modules and their syntax, make sure that you are actually looking at the version for ESP32 (dev-esp32)**  

Install the SDK. Copy **sdkconfig** from folder into the SDK root directory.

Run:

`make menuconfig`

The modules enabled in the ISEMS sdkconfig contain all module dependencies to run the current ISEMS Lua programs.
Make chances if necessary.

**To flash the firmware:**

In order to flash the firmware, turn the power of the FF-ESP32-OpenMPPT
board off.  Wire pin IO0 to GND with a jumper cable. This will put the ESP32 chip in
flashing mode when it is powered up again. Connect a serial port adapter (3.3 V logic level) to the board and wire:

> **3.3V to 3.3V**

>**TX to RX**

>**RX to TX** 

>**GND to GND** 

In this case, the 3.3V power pin of the USB serial port adapter is supplying power to the ESP32 on the FF-ESP32 board.


Now the system is set up to run: 

`make flash`

in the NODEMCU SDK folder. This command will compile the firmware and flash it to the device.

If flashing doesn't work because the communication with the board fails, make sure:

* TX and RX pins haven't been swapped (there is a 50% chance ;)

* IO0 is wired to GND

* The ESP32 chip has been power-cycled and has been powered off long enough for the internal capacitors to discharge to avoid the chip hanging in a brown-out state.

* The USB serial dongle itself is up and running.

### Uploading code

Once flashing is done, power the device off. Remove the connection between IO0 and GND. Don't forget that you have to disconnect the 3.3 V pin of the USB serial dongle to perform power-cycle.

**Documentation about uploading code is available in the LUA folder.**

