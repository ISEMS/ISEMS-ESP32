### Instructions for flashing with a Linux operating system.

* Install esptool. In Debian and Ubuntu it is available from the package
management system. 

* Disconnect the FF-ESP32-OpenMPPT from all power sources. 

* Wire IO0 to GND. 

* Make these connections between the USB to serial dongle and the board:



>**3V3 to 3V3**
    
>**TX to RX**

>**RX to TX**

>**GND to GND**

* Change into the directory where all the firmware .bin files are located.

* Copy and paste the following line to the command line:

> esptool.py --chip esp32 --port /dev/ttyUSB0 --baud 115200 --before default_reset --after hard_reset write_flash -z --flash_mode dio --flash_freq 40m --flash_size detect 0x1000 bootloader.bin 0x10000 NodeMCU.bin 0x8000 partitions.bin

* Press **Enter**

