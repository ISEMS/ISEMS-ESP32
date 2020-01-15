--[[
Run a single duty cycle to completion.
]]

-- Bootstrap
dofile "test/nodemcu_mock.lua"
dofile "config.lua"

-- No periodic execution.
-- dofile "is.lua"

-- Run cycle.
Vref = 1100 --mV
dofile "mp2.lua"
