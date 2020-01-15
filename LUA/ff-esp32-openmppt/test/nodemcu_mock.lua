--[[
Mock the API of a NodeMCU device.
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
