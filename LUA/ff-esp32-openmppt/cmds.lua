cmds_base={}
console_users={}

function cmds_base.cat(ctx,filename)
	fd = shell.open(ctx,filename, "r")
	if fd == nil then
		return -1
	end
	while true do
		str=fd:readline()
		if (str == nil) then
			break
		end
		ctx.stdout:write(str)
	end
	fd:close()
	return 0
end

local function console(ctx,onoff)
	local users = 0
	local old=false
	for k,v in pairs(console_users) do
		users=users+1
	end
	if (onoff) then
		if (console_users[ctx] == nil) then
			console_users[ctx]=1
			users=users+1
			if (users == 1) then
				node.output(function(str) for key,item in pairs(console_users) do key.stderr:write(str) end end, 0)
			end
		else
			old=true
		end
	else
		if (console_users[ctx]) then
			old=true
			console_users[ctx]=nil
			users=users-1
			if (users == 0) then
				node.output(nil)
			end
		end
	end
	return old,users
end

function cmds_base.console(ctx,onoff)
	local old,users=console(ctx,onoff == "on")
	ctx.stdout:print("Console users:",users)
end

function cmds_base.cp(ctx,src,dst)
	local ret=0
	fd1=shell.open(ctx,src,"r")
	if (fd1 == nil) then
		return -1
	end
	fd2=shell.open(ctx,dst,"w")
	if (fd2) then
		while true do
			local data=fd1:read()
			if (data == nil) then
				break
			end
			if (fd2:write(data) == false) then
				ctx.stderr:print("write error")
				ret=-1
				break
			end
		end
		fd1:close()
		fd2:close()
	else
		fd1:close()
		ret=-1
	end
	return ret
end

function cmds_base.df(ctx)
	remaining, used, total=file.fsinfo()
	ctx.stdout:print("File system info:\nTotal : "..total.." (k)Bytes\nUsed : "..used.." (k)Bytes\nRemain: "..remaining.." (k)Bytes\n")
	return 0
end

function cmds_base.dump(ctx,...)
	local obj=_G
	for i,v in ipairs(arg) do
		ctx.stdout:print("Getting",v)
		obj=obj[v]
		if (type(obj) == "function" or type(obj) == "lightfunction") then
			obj=debug.getinfo(obj)
		end
	end
	if (type(obj) == "string" or type(obj) == "number") then
		ctx.stdout:print(obj,type(obj))
	else
		for key,item in pairs(obj) do
			ctx.stdout:print(key,type(item))
		end
	end
	return 0
end

function cmds_base.free(ctx)
	ctx.stdout:print(node.heap())
	return 0
end

function cmds_base.ls(ctx)
	for key,value in pairs(file.list()) do
		ctx.stdout:print(key,value)
	end
	return 0
end

function cmds_base.lua(ctx,...)
	local old,users=console(ctx,true)
	local s=table.concat(arg," ")
	loadstring(s)()
	console(ctx,old)
	return 0
end

function cmds_base.md5sum(ctx,file)
	local hash=crypto.new_hash("MD5")
	fd = shell.open(ctx,filename, "r")
	if fd == nil then
		return -1
	end
	while true do
		local data=fd:read()
		if (data == nil) then
			break
		end
		hash:update(data)
	end
	ctx.stdout:print(encoder.toHex(hash:finalize()))
	return 0
end

function cmds_base.mv(ctx,old,new)
	if (file.rename(old,new)) then
		return 0
	end
	ctx.stderr.print("Failed to rename '"+old+"' to '"+new+"'")
	return -1
end

function cmds_base.print(ctx,...)
	ctx.stdout:print(...)
	return 0
end

function cmds_base.wifiscan(ctx,...)
        wifi.sta.scan({ hidden = 1 }, function(err,arr)
        if err then
        ctx.stderr.print ("Scan failed:", err)
        else
        ctx.stdout:print("\n", string.format("%-26s","SSID"),"Channel        BSSID            RSSI  Auth   Bandwidth")
        for i,ap in ipairs(arr) do
        ctx.stdout:print(string.format("%-32s",ap.ssid),ap.channel,ap.bssid,ap.rssi,ap.auth,ap.bandwidth)
        end
        ctx.stdout:print("-- Total APs: ", #arr)
        end
    end)
	return 0
end



function cmds_base.reboot(ctx)
	node.restart()
	return 0
end

function cmds_base.rm(ctx,name)
	file.remove(name)
	return 0
end

function cmds_base.uptime(ctx)
	local us=node.uptime()
	local ms=math.floor(us/1000)
	us=us%1000
	local s=math.floor(ms/1000)
	ms=ms%1000
	ctx.stdout:print(s,"s",ms,"ms",us,"us")
	return 0
end
