The ESP32 chip has an internal voltage reference that needs to be calibrated for accurate measurements. 

If you have just build a new FF-ESP32-OpenMPPT device on your own (and not a finished product or preflashed kit) or the calibration got lost for some reason, the device can be calibrated again. The process requires a lab power supply and a good digital voltmeter.

Connect to the FF-ESP32-OpenMPPT with a serial port dongle (3.3 Volt logic level) as
desrcibed in /LUA/README.md. Do not connect the 3.3V pin of the USB serial dongle to the 3.3V pin header.
We use the internal 3.0 Volt rail while calibrating.

Connect a lab power supply to the battery terminals of the FF-ESP32-OpenMPPT (observe polarity). Adjust the voltage at the battery terminals of the FF-ESP32-OpenMPPT to exactly 12.80 Volt. Check with the voltmeter and measure directly at the terminals of the FF-ESP32-OpenMPPT, as the wires between the lab supply will cause a small voltage drop.

Start a serial terminal programm. 

Example:
`nodemcu-tool terminal`

Reboot the device by typing

`node.restart()`

in the terminal and press Enter.

After the device has restarted, stop the init process. Type 

`stop()`

in the terminal and press Enter - within 5 seconds after the shell prompt appears.

Now type:

dofile"vrcal.lua"

Check the result.


**Note:** Connecting the EN pin to GND on the pin header for a short time will trigger a reboot of the ESP32. Whenever resetting the FF-ESP32-OpenMPPT board by power-cycling the entire board, make sure the is disconnected from all power sources (battery, solar module, programming adaptor) for at least 15 seconds. There are relatively huge capacitors in the circuit that discharge slowly, so the device might not reset properly if it is reconnected too early (less than 15 seconds).

