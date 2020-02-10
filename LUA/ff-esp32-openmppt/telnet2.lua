-- Telnet server for ISEMS / Nodemcu with Unix-like shell

require"cmds"
require"shell"

if (telnet_srv2) then
	print("closing previous server")
	pcall(function() telnet_srv2:close() end)
end
telnet_srv2 = net.createServer(net.TCP, 180)
telnet_srv2:listen(2333, function(socket)
    local fifo = {}
    local fifo_drained = true
    local ctx = {}

    local function sender(c)
        if #fifo > 0 then
            c:send(table.remove(fifo, 1))
        else
            fifo_drained = true
        end
    end

    local function write(self,str)
	table.insert(fifo, str)
	if socket ~= nil and fifo_drained then
	    fifo_drained = false
	    sender(socket)
        end
    end


    socket:on("receive", function(c, l)
	shell.cmd(ctx, l)
	shell.prompt(ctx)
    end)
    socket:on("disconnection", function(c)
    end)
    socket:on("sent", sender)

    ctx.stdin=io:new{write=write}
    ctx.stdout=ctx.stdin
    ctx.stderr=ctx.stdin
    ctx.exit=function(ctx) ctx={} socket:close() socket=nil end

    shell.prompt(ctx)
end)
