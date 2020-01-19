--[[
Telemetry implementation for MQTT and HTTP.
]]

function get_telemetry_data()
    --[[
    Collect all metric values from global variables
    and bundle them into a single telemetry data container.

    Note: This might well be improved but for now it's better than nothing.
    ]]
    data = {
        nodeId = nodeid,
        isemsRevision = packetrev,
        timestamp = timestamp,
        timeToShutdown = nextreboot,
        isPowerSaveMode = powersave,
        openCircuitVoltage = V_oc,
        mppVoltage = V_in,
        batteryVoltage = V_out,
        batteryChargeEstimate = charge_state_int,
        batteryHealthEstimate = health_estimate,
        batteryTemperature = battery_temperature,
        lowVoltageDisconnectVoltage = low_voltage_disconnect,
        temperatureCorrectedVoltage = V_out_max_temp,
        rateBatteryCapacity = rated_batt_capacity,
        ratedSolarModuleCapacity = solar_module_capacity,
        latitude = lat,
        longitude = long,
        status = statuscode,
    }
    return data
end

function mqtt_publish(data)
    --[[
    MQTT telemetry

    Encode telemetry data as JSON and publish message to
    MQTT broker at topic configured within "config.lua".
    ]]

    print("Submitting telemetry data to MQTT broker.")

    -- JSON payload
    -- https://nodemcu.readthedocs.io/en/master/modules/sjson/
    -- https://github.com/ISEMS/isems-data-collector/blob/926eb4a3/test_importer.py
    print("Creating JSON payload.")
    sjson.encode(data)
    ok, json = pcall(sjson.encode, data)
    if ok then
        print("JSON payload:", json)
    else
        print("ERROR: Encoding to JSON failed!")
        return
    end

    -- https://nodemcu.readthedocs.io/en/master/modules/mqtt/
    m = mqtt.Client("isems-" .. nodeid, 120)
    m:connect(mqtt_broker_host, mqtt_broker_port, 0,
        function(client)
            print("Connected to MQTT broker.")
            client:publish(mqtt_topic, json, 0, 0, function(client)
                print("MQTT message sent.")
            end)
        end,
        function(client, reason)
            print("MQTT connect failed. Reason: " .. reason)
        end
    )

end

function http_post(data)
    --[[
    HTTP telemetry

    Encode telemetry data as JSON and send as POST request
    to HTTP endpoint configured within "config.lua".
    ]]

    print("Submitting telemetry data to HTTP endpoint.")

    -- JSON payload
    -- https://nodemcu.readthedocs.io/en/master/modules/sjson/
    -- https://github.com/ISEMS/isems-data-collector/blob/926eb4a3/test_importer.py
    print("Creating JSON payload.")
    ok, json = pcall(sjson.encode, data)
    if ok then
        print("JSON payload:", json)
    else
        print("ERROR: Encoding to JSON failed!")
        return
    end

-- https://nodemcu.readthedocs.io/en/dev-esp32/modules/http/
 
headers = {
  ["Content-Type:"] = "application/json\r\n",
}
body = json
http.post(http_endpoint, { headers = headers }, body,
  function(code, data)
    if (code < 0) then
      print("HTTP request failed")
    else
      print(code, data)
    end
  end)

end


if mqtt_enabled == true then
    print("Preparing mqtt data.")
    mqtt_publish(get_telemetry_data())
end

if http_enabled == true then
    print("Http post mqtt data.")
    http_post(get_telemetry_data())
end
