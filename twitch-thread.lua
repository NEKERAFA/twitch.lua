local twitch = require 'twitch'

local twitch_ctrl = love.thread.getChannel('twitch_ctrl')
local twitch_recv = love.thread.getChannel('twitch_recv')
local twitch_send = love.thread.getChannel('twitch_send')

local client = nil

local running = true
while running do
    -- Process events
    if twitch_ctrl:getCount() > 0 then
        local event = twitch_ctrl:pop()

        if event.command == 'connect' then
            client = twitch.connect(event.nickname, event.token)
        elseif event.command == 'join' then
            client:join(event.channel)
        elseif event.command == 'leave' then
            client:leave(event.channel)
        elseif event.command == 'close' then
            running = false
            break
        end
    end

    if running and client then
        -- Send data
        if twitch_send:getCount() > 0 then
            local data = twitch_send:pop()
            client:send(data.channel, data.msg)
        end

        -- Read data
        local msg, username, channel, text = client:receive()
        if msg then
            if msg == 'PING :tmi.twitch.tv' then
                client:rawsend('PONG :tmi.twitch.tv')
            else
                local data = { username = username, channel = channel, text = text }
                local command = string.match(text, '^!(.+)$')

                if command then
                    local args = {}
                    for arg in string.gmatch(command, '([^%s]+)') do
                        table.insert(args, arg)
                    end

                    data.command = command
                    data.args = args
                end

                twitch_recv:push(data)
            end
        end
    end
end