# FF-ESP32-OpenMPPT Beginner Howto

#### Getting started

##### Preparation

I'm assuming the Nodemcu/FreeRTOS firmware and ISEMS programs are installed and the default configuration is in place. If you purchased a kit, this is the default. If everything is missing (starting with a blank ESP32 module without firmware), check out the [firmware](https://github.com/ISEMS/ISEMS-ESP32/blob/master/PRECOMPILED-FIRMWARE/FLASHING-INSTRUCTIONS.md) first.

If the ISEMS software is missing, go [here](https://github.com/ISEMS/ISEMS-ESP32/blob/master/LUA/ff-esp32-openmppt/README.md).

The ISEMS programs require certain NODEMCU and LUA modules that come with the ISEMS firmware.

##### Let's play around a bit

Connect to the WiFi Accesspoint `esp32-isems-ap`, the WPA2 password is `12345678`. Open the index page **http://192.168.10.10** in a web browser. This will show you status information in a human readable form.

Whenever you connect to the device without asking for a valid page URL you'll end up here. There is no "404 - Page not found"- error. So **http://192.168.10.10/fewdiguglmugl** will give you just the same ;)

There are four valid pages in total:

* **/index** - a wildcard, actually - shows the status page. 

* **/.log** a CSV list of the last 5 logging entries of the MPP-Tracking program. This page is actually only useful for robots to retrieve the logs via HTTP GET. Most graphical browsers will just show all entries in one line.

* **/help**  shows a brief help summary

* **/random** will show you a random string for the cryptographic Digest Auth scheme, if this feature is enabled. For now, it will tell you that web encryption is off.

Commands on the device can be executed remotely by sending HTTP GET requests + secret-key. There is a comfortable but unsafe way to use this feature and a less comfortable, but safe(r) way.

The comfortable way is the default for now. Before connecting the device to a public network, the safe way should be enabled. The latter is discussed further down below.


#### HTTP Control Commands
* **/ftp+key** – starts ftp server and pauses the main MPP-Tracking program

* **/reboot+key** – triggers a reboot of the device.

* **/telnet+key**  – starts an open (!) telnet LUA command line interface at port 2323

* **/shell+key** – starts an open (!) Unix-like minimal commandline interface at telnet port 2333

* **/mpptstart+key** – restarts the main MPP-Tracking program. It is automatically paused when FTP starts in order to save CPU and RAM.

* **/loadoff+key** Turn load off.

* **/loadon+key** Turn load on.


**Caveats**
Use your unencrypted passwords only over a encrypted WiFi and if you trust the network. FTP and HTTP keys can be sniffed easily, as they are sent unencrypted. HTTP commands are case sensitive. Remember that this is a tiny device with very limited ressources. If all features are enabled, the device might occasionally run out of memory, therefore crash and reboot.




#### Configuration setup 

Let's assume the Nodemcu/FreeRTOS firmware and the ISEMS programs are already flashed and installed. The only task really left to do before physically deploying the new device is to adjust the configuration file, uploading it into the device and reboot.

A new default **config.lua** file is available from the ISEMS-ESP32 LUA directory at Github. A simple source code editor like **notepad*, **nano*, **vi*, **joe*, **kate*, etc. is required to edit the file, *not* the editor of an office suite.

First, take a look at the configuration file as a whole:

```
-- Configuration file for ESP-ISEMS-nodeid
-- Lines beginning with two dashes (--) are comments.

-- Secret key for triggering commands via HTTP
-- Beware: HTTP is unencrypted, so can be sniffed.

    webkey="secret123"

-- Require sha256'ed one-time webkey (strongly
   recommended in public networks)
-- This will avoid exposing the webkey over the air.

	encrypted_webkey = false

-- FTP password. Username is "admin"
-- Since FTP login and traffic is not encrypted, the password can be sniffed. 
	ftppass='pass123'

-- Autoreboot timer in minutes
-- The device will reboot once this timer expires.
-- Set to 0 if you don't want to use this feature.

	nextreboot=3600
	

-- Latitude of Geolocation
	lat = 52.52

-- Longitude of Geolocation
	long = 13.4

-- Node-ID The individual id name or the device.
	nodeid="ESP32-Meshnode-Default"

-- Rated capacity of battery in Ampere hours (Ah)
	rated_batt_capacity = 7.2

-- Rated power rating of the solar module in Watt. 
	solar_module_capacity = 10

-- Average power consumption of the system in Ampere (A)
	average_power_consumption = 0.05

-- Accesspoint IP
	ap_ip="192.168.10.10"

-- Accesspoint Netmask
	ap_netmask="255.255.255.0"

-- Internet gateway IP
	ap_gateway="192.168.10.10"

-- Accesspoint WiFi channel
	ap_channel="9"

-- WiFi mode 
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE

	wlanmode = 2

-- DNS server IP
	ap_dns="8.8.8.8"

-- Accesspoint Password (minimum 8 alphanumeric characters and can not be blank)
	ap_pwd="12345678"

-- Accesspoint SSID 
	ap_ssid="esp32-isems-ap"

-- Wifi station AP SSID (the existing WiFi-AP that the device should connect to as a WiFi client)
	sta_ssid="freifunk.net"

-- WPA key to connect to the existing AP as WiFi client
	sta_pwd=""


-- Enable (true) or disable (false) nodemcu internal debugging output.
-- Default is (false). (true) might be very verbose and spam the LUA command line
-- via serial port or telnet shell.

	node.osprint(false)

-- The telemetry channel to send metrics to.
-- See also MQTT and HTTP configuration below.
	telemetry_channel = "isems/testdrive/foobar/"

-- Telemetry configuration for MQTT
	mqtt_enabled = false
	mqtt_broker_host = "isems.mqtthub.net"
	mqtt_broker_port = 1883

-- Telemetry configuration using HTTP
	http_enabled = false
	telemetry_http_endpoint = "https://isems.mqtthub.net/api/"
```
	


The configuration file should be pretty much self-explanatory.

While editing, it should be observerd that variables in quotation marks are alphanumeric text strings. Don't leave the quotations marks away by accident while editing. **true** and **false** are logic boolean, they go without quotation marks. Numbers are just numbers without quotations marks, too.


When modifying the **Accesspoint SSID** and **Wifi station AP SSID** names, only alphanumeric characters and the dash (**-**) are allowed.

As usual, the configuration comes with default passwords for administrative tasks. Since anyone interested can find these passwords on the Internet, they should be changed straight away.

It is recommended to operate the device in Accesspoint mode in most cases, which is the default. This way it can operate as a communication relay in an exposed position like a hill, mountain top, high building or pole. The device will operate as a wireless bridge between clients. One client can be an uplink to the Internet.

With the default setup file **config.lua**, the device will use the IP 192.168.10.10 in Accesspoint mode and it will automatically hand out up to four IP adresses to the clients, starting with 192.168.10.11 up to 15

If you intend to use WiFi clients with fixed IPs – which is necessary to set up routing – use any adresses between 192.168.10.1 and 192.168.10.254, while excluding 10 to 15.

If you have been programming in LUA before, you'll notice that the configuration file is just a LUA programm file that is used to merely define variables – hence the suffix **.lua** While you can add and execute your own programming code in the file, it is recommended *not* to do so. It is easy to shoot yourself in the foot. If LUA detects a *syntax error* in **config.lua**, the device will stay offline. That is not a problem while having direct access to the device via serial port, but will cause hassle if **config.lua** is uploaded to a remove device.


### Uploading config.lua to the device

There are two options for this task: Via WiFi and via serial programming port. The programming port offers complete control. If you want to do more advanced things with the device, a serial port dongle is required. A serial port is also crucial if something gets messed up.

##### Using the serial port

Connect a serial port adapter (with 3.3 V logic level) to the board and wire:

> **3.3V to 3.3V**

>**TX to RX**

>**RX to TX** 

>**GND to GND** 


My favorite tool for uploading code is **nodemcu-tool**, but there are other options listed [here.](https://nodemcu.readthedocs.io/en/master/getting-started/)

Once you have found and installed the upload tool you are happy with, copy **config.lua** into the device. 

Example with nodemcu-tool: 

`nodemcu-tool upload config.lua`

Now reboot the device via the serial terminal:

`nodemcu-tool terminal`

Once you are in, type:

`node.restart()`


Boot messages will start rushing over the screen. The device will then idle for 5 seconds before starting the main program **is.lua**

In case the boot process has to be interrupted, type stop() and press ENTER now.


# Using the sha256'ed webkey option

This method provides a primitive cryptographic authentication method (*Digest Auth*) to avoid untrusted people on an open network taking control over the device.

Being designed as a least cost and least power IOT device, the ESP32 has just 520 kByte of RAM. We are trying to make the best use of it and a lot of RAM is already required to handle WiFi tasks and TX/RX chains. The use of proper HTTP SSL Transport Layer Security will consume quite a lot of the scarce and therefore precious RAM. 


If the option
`encrypted_webkey = true`is set in the configuration file, the device will not accept the plain text web key for security reasons anymore: Plain text can be sniffed easily by monitoring traffic in the network. Any fool with a sniffing tool can do that.


### The manual and painful method of using our primitive Digest AUTH scheme - before scripting it.


The ISEMS system generates a public one-time random string (a nonce). It can be downloaded from the address `http://ISEMSDEVICE/random` by everyone.

Now, let's assume the public nonce is **000abcdefg999** and the web password is **secret123**. The **sha256** cryptographic hash of both parts concatenated (copied) together into the single string **000abcdefg999secret123** generates our one-time password.

There are online calculators for sha256 [hashes](https://hashgenerator.de/). So despite being a bit cumbersome, the whole process can be completed with a graphical browser, if you are not concerned about sending the string to an online calculator. That might be ok, if this type of interaction is rarely needed.

A command line example using sha256sum:

```
echo -n "000abcdefg999secret123" | sha256sum

6bc4a3b20e343baae9ff15cf61acc8861ef47650c55e0f24866394f72ebbf574
```


That's the new one-time key. We are now ready to safely send a command to the ISEMS system - turn the load output on, for example.

Calling the following URL in a browser or with a tool like **curl**, **wget**, **you-name-it** will now turn on the external load:

**http://ISEMSDEVICE/loadon+6bc4a3b20e343baae9ff15cf61acc8861ef47650c55e0f24866394f72ebbf574**

The reply will be `Load enabled.`


This way, the password is never exposed over the network. An attacker could still sniff the sha256'ed key and try a replay attack, but every time a sha256'ed webkey is used, it is thrown away and a new nonce is generated.








