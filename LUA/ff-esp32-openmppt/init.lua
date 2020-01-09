startdelaytimer = tmr.create()
startdelaytimer:register(10000, tmr.ALARM_SINGLE, function() dofile"is.lua" end)
startdelaytimer:start()

