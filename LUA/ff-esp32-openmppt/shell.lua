cmds_shell={}

function cmds_shell.exit(ctx)
	ctx:exit()
end

shell={}

function shell.cmd_tables()
	local list={}
	for key,item in pairs(_G) do
                if (key:sub(0,5) == 'cmds_') then
			table.insert(list,item)
		end
	end
	return list
end

function shell.help(ctx,tables)
	local list={}
	ctx.stdout:print("Following commands exist:")
	for key,item in pairs(tables) do
		for key,item in pairs(item) do
			if (type(item) == "function") then
				table.insert(list,key)
			end
		end
	end
	table.sort(list)
	for k,v in pairs(list) do ctx.stdout:print(v) end
	return 0
end

function shell.cmd2(ctx,tables,cmd,...)
    
    
	if (cmd == 'help' or cmd == nil) then
		return shell.help(ctx,tables)
	end
	for key,item in pairs(tables) do
		local f=item[cmd]
		if (f) then
			local status,ret=pcall(f,ctx,...)
			if (status) then
				return ret
			end
			ctx.stderr:print(ret)
			return -2
		end
	end
	ctx.stderr:print("Command '"..cmd.."' not found, use 'help' for help")
	return -22
end

function shell.cmd(ctx,c)
	-- ctx.stderr:print("cmd '"..c.."'")
	local args=shell.words(c)
	if (args[1] == nil or args[1] == "") then return end
	local ret=shell.cmd2(ctx,shell.cmd_tables(),unpack(args))
	if (ret == nil) then ret=0 end
	if (ret < 0) then
		ctx.stderr:print("ERR "..ret)
	elseif (ret > 0) then
		ctx.stderr:print("OK "..ret)
	else
		ctx.stderr:print("OK")
	end
end

function shell.filter(ctx,from,to,tomode,filterfunc,post)
	local fd1=shell.open(ctx,from,"r")
	if (fd1 == nil) then return -1 end
	local fd2=shell.open(ctx,to,tomode)
	local ret=0
	if (fd2) then
		while true do
			str=fd1:readline()
			if (str == nil) then
				break
			end
			str=filterfunc(str)
			if (str) then
				if (shell.write(ctx,to,fd2,str) == nil) then
					ret=-1
					break
				end
			end
		end
		if (post) then
			if (shell.write(ctx,to,fd2,post) == nil) then
				ret=-1
			end
		end
		fd2:close()
	end
	fd1:close()
	return ret
end

function shell.on(ctx,data)
	if (data == "\r" or data == "\n") then
		ctx.stderr:write("\r\n")
		shell.cmd(ctx,ctx.cmdline)
		ctx.cmdline=""
		shell.prompt(ctx)
	elseif (data == "\b") then
		local len=ctx.cmdline:len()
		if (len > 0) then
			ctx.cmdline=ctx.cmdline:sub(0,len-1)
			ctx.stderr:write("\b \b")
		end
	else
		ctx.cmdline=ctx.cmdline..data
		ctx.stderr:write(data)
	end
end

function shell.open(ctx,name,mode)
	local fd=file.open(name,mode)
	if (fd == nil) then
		ctx.stderr:print("Failed to open '"..name.."'")
	end
	return fd
end

function shell.prompt(ctx)
	ctx.stderr:write("# ")
end

function shell.rename(ctx,old,new)
	file.remove(new)
	if (file.rename(old,new)) then
		return 0
	end
        ctx.stderr.print("Failed to rename '"+old+"' to '"+new+"'")
	return -1
end

function shell.run()
	uart_ctx={}
	uart_ctx.stdin=io:new{write=function(self,str) uart.write(0, str) end}
	uart_ctx.cmdline=""
	uart.on(0,"data", 0, function(data) uart_ctx.stdin:on(data) end, 0)
	uart_ctx.stdin.on=function(self,data) shell.on(uart_ctx,data) end
	uart_ctx.stdout=uart_ctx.stdin;
	uart_ctx.stderr=uart_ctx.stdin;
	uart_ctx.exit=function(self) uart_ctx={}; uart.on("data") end
	shell.prompt(uart_ctx)
end

function shell.words(str)
	local args={}
	for arg in str:gmatch("%S+") do table.insert(args, arg) end
	return args
end

function shell.write(ctx,file,fd,data)
	local ret=fd:write(data)
	if (ret == nil) then
		ctx.stderr:print("Failed to write to '"+file+"'")
	end
	return ret
end


io={}

function io:new (o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function io.print(self,...)
	local n = select("#",...)
	for i = 1,n do
		local v = tostring(select(i,...))
		self:write(v)
		if i~=n then self:write("\t") end
	end
	self:write("\n")
end

