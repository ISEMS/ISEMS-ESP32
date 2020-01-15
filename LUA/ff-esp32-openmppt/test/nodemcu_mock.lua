--[[
Mock the API of a NodeMCU device.
]]


--[[
Mocks for NodeMCU core modules.
]]
time = {
    get = function()
        return os.time()
    end,
    getlocal = function()
        date = os.date("*t")
        date["mon"] = date["month"]
        date["dst"] = "1"
        return date
    end,
}

node = {
    dsleep = function() end,
}

file = {
    list = function() end,
    exists = function() end,
}

gpio = {
    config = function() end,
    wakeup = function() end,
    write = function() end,
}

dac = {
    enable = function() end,
}

adc = {
    setup = function() end,
    setwidth = function() end,
    read = function() return 42.42 end,
}


--[[
Requires nodemcu-lua-mocks to be installed for JSON support.
https://github.com/fikin/nodemcu-lua-mocks
]]

local sjson = require("sjson")
sjson.encode = function(data)
    encoder = sjson.encoder(data)
    return encoder:read(8192)
end


--[[
TODO: Add mocks for mqtt and http modules.
Currently, "test/run_basic" will croak with::

    lua: telemetry.lua:59: attempt to index a nil value (global 'mqtt')
]]
