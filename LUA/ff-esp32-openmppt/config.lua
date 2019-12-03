-- Configuration file for ESP-ISEMS-nodeid

-- Lines beginning with two dashes (--) are comments.

-- Latitude of Geolocation
lat = 52.520008

-- Longitude of Geolocation
long = 13.404954

-- Node-ID
nodeid = "ESP32-Meshnode-1"

-- Rated capacity of battery in Ampere hours (Ah)
rated_batt_capacity = 8.0

-- Rated power rating of the solar module in Watt. 
solar_module_capacity = 10

-- Average power consumption of the system in Ampere (A)
average_power_consumption = 0.08

-- Accesspoint IP
ap_ip="192.168.10.10"

-- Accesspoint Netmask
ap_netmask="255.255.255.0"

-- Internet gateway IP
ap_gateway="192.168.10.1"

-- DNS server IP
ap_dns="8.8.8.8"

-- Accesspoint Password (can not be blank)
ap_pwd="12345678"

-- Accesspoint SSID 
ap_ssid="esp32-isems-ap"

-- Wifi station AP SSID (the existing WiFi-AP that the device should connect to as a WiFi client)
sta_ssid="AP2.freifunk.net"

-- WPA key to connect to the existing AP as WiFi client
sta_pwd=""
