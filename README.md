# ISEMS-ESP32

This is a port of the ISEMS solar node software that we wrote for OpenWRT/Linux for ESP32 Microcontrollers from Espressif Systems. Since the Linux tool is based on LUA we have chosen the ESP32 version of NodeMCU as the firmware base.

You can use a ESP32 board/module like NodeMCU, WROOM, WROVER and connect it to the serial port of the Freifunk OpenMPPT Solar controller. Simply connect GND, 3V3 and RX (OpenMPPT) <--> TX (ESP32) Pin 17, TX (OpenMPPT) --> RX (ESP32) Pin 16.

It is desirable to use a switched mode DC/DC buck converter instead of the linear voltage regulator of the Freifunk OpenMPPT. If the ESP32 operates as WiFi client, we can get away with the 100mA of the linear voltage regulator, but we do waste energy. If the ESP32 is set to software AP or software AP + software AP client, the ESP32 and the ATmega8 in the Freifunk OpenMPPT will randomly lock up.

A Freifunk OpenMPPT pcb with ESP32 WROOM integrated is currently in the design phase. So stay tuned!
