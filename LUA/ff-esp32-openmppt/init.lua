
boottimer = tmr.create()
print("Booting in 5 seconds, enter stop() to cancel")
boottimer:register(5000, tmr.ALARM_SINGLE, function() print("Starting is.lua now. "); require"is"; end)
boottimer:start()

function stop()
	boottimer:stop()
end
