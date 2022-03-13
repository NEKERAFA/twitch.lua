local _base = ...
local _path = string.gsub(_base, '%.', '/')

local twitch = {
    channels = {},
    timers = {}
}

local twitch_thread = love.thread.newThread(_path .. '/twitch_thread.lua')
local twitch_ctrl = love.thread.getChannel('twitch_ctrl')
local twitch_recv = love.thread.getChannel('twitch_recv')
local twitch_send = love.thread.getChannel('twitch_send')

function twitch.connect(nickname, token)
    twitch_ctrl:push({ command = 'connect', nickname = nickname, token = token })
    twitch_thread:start()
end

function twitch.join(channel)
    if twitch.channels[channel] then
        return nil, string.format('has already joined the %q channel', channel)
    end

    local msgId = twitch_ctrl:push({ command = 'join', channel = channel })
    twitch.channels[channel] = {}

    return function ()
        return twitch_ctrl:hasRead(msgId)
    end
end

function twitch.leave(channel)
    if not twitch.channels[channel] then
        return nil, string.format('has not joined the %q channel', channel)
    end

    local msgId = twitch_ctrl:push({ command = 'leave', channel = channel })
    twitch.channels[channel] = nil

    return function ()
        return twitch_ctrl:hasRead(msgId)
    end
end

function twitch.send(channel, msg)
    if msg == nil then
        msg = channel
        channel = nil
    end

    if channel and not twitch.channels[channel] then
        return nil, string.format('has not joined the %q channel', channel)
    end

    local msgId = twitch_send:push({ channel = channel, msg = msg })

    return function ()
        return twitch_send:hasRead(msgId)
    end
end

function twitch.receive(channel)
    if channel then
        local message = nil
        local buffer = {}

        -- Checks if there are messages
        while twitch.hasmessages() do
            local data = twitch_recv:pop()
            if data.channel == channel then
                message = data
                break
            end

            table.insert(buffer, data)
        end

        -- If we pop some messages, we return to the channel queue
        if #buffer > 0 then
            for _, data in ipairs(buffer) do
                twitch_recv:push(data)
            end
        end

        return message
    end

    return twitch_recv:pop()
end

function twitch.hasmessages()
    return twitch_recv:getCount() > 0
end

function twitch.attach(command, channel, func)
    if func == nil then
        func = channel
        channel = nil
    end

    if channel then
        if not twitch.channels[channel] then
            return nil, string.format('has not joined the %q channel', channel)
        end

        if twitch.channels[channel] and twitch.channels[channel][command] then
            return nil, string.format('the command %q was attached to the channel %q', channel)
        end

        twitch.channels[channel][command] = func
    else
        for _, commands in pairs(twitch.channels) do
            if not commands[command] then
                commands[command] = func
            end
        end
    end

    return true
end

function twitch.detach(command, channel)
    if not channel then
        if not twitch.channels[channel] then
            return nil, string.format('has not joined the %q channel', channel)
        end

        if not twitch.channels[channel][command] then
            return nil, string.format('the command %q is not attached to the channel %q', channel)
        end

        twitch.channels[channel][command] = nil
    else
        for _, commands in ipairs(twitch.channels) do
            if commands[command] then
                command[command] = nil
            end
        end
    end

    return true
end

function twitch.settimer(name, seconds, func)
    if twitch.timers[name] then
        return nil, string.format('%q timer already exists', name)
    end

    twitch.timers[name] = { clock = 0, maxtime = seconds, func = func }

    return true
end

function twitch.removetimer(name)
    if not twitch.timers[name] then
        return nil, string.format('%q timer does not exist', name)
    end

    twitch.timers[name] = nil

    return true
end

function twitch.update(dt)
    if twitch.hasmessages() then
        local message = twitch:receive()

        if message.command then
            for channel, commands in pairs(twitch.channels) do
                if channel == message.command and commands[message.command] then
                    commands[message.command](message.channel, message.username, unpack(message.args))
                end
            end
        end
    end

    for _, timer in pairs(twitch.timers) do
        timer.clock = timer.clock + dt

        if timer.clock >= timer.maxtime then
            timer.func()
            timer.clock = timer.maxtime - timer.clock
        end
    end
end

function twitch.close()
    twitch_ctrl:push({ command = 'close' })
    twitch_thread:wait()
end

return twitch