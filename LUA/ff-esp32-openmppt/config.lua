-- Configuration file for ESP-ISEMS-nodeid

-- Lines beginning with two dashes (--) are comments.

-- Secret key for triggering commands via HTTP GET
-- Beware: Http is unencrypted, so can be sniffed.

webkey="secret123"

-- Require sha256'ed one-time webkey (strongly recommended in public networks)
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

-- Node-ID
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
--ap_gateway="10.36.158.33"
ap_gateway="192.168.10.10"

-- Accesspoint WiFi channel
ap_channel="9"

-- WiFi mode 
-- One of: 1 = STATION, 2 = SOFTAP, 3 = STATIONAP, 4 = NULLMODE

wlanmode = 2

latlong = 3.00

-- DNS server IP
ap_dns="8.8.8.8"

-- Accesspoint Password (can not be blank)
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

