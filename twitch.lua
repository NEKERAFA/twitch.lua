---
-- twitch.lua
-- A Twitch client written in Lua
--
-- @classmod twitch
-- @author Rafael Alcalde Azpiazu
-- @release 0.0.3
-- @license MIT

local socket = require 'socket'
local ssl = require 'ssl'
local cron = require 'cron'

local twitch = {
    _VERSION     = 'twitch.lua 0.0.3',
    _AUTHOR      = 'Rafael Alcalde Azpiazu',
    _DESCRIPTION = 'A Twitch client written in Lua',
    _URL         = 'https://github.com/NEKERAFA/twitch.lua',
    _LICENSE     = 'MIT'
}

local params = {
    mode = 'client',
    protocol = 'any',
    cafile = '/etc/ssl/certs/ca-certificates.crt',
    verify = 'peer',
    options = 'all'
}

local await_time = 2

-- Print log
local function logger(...)
    if _DEBUG then
        print(...)
    end
end

-- Print data as received
local function logger_recv(data)
    for _, str in ipairs(data) do
        logger(string.format('> %s', str))
    end
end

-- Print data as sended
local function logger_send(data)
    logger(string.format('< %s', data))
end

-- Send a data using string.format and log it
local function send(conn, data, ...)
    logger_send(string.format(data, ...))
    assert(conn:send(string.format(data .. '\r\n', ...)))
end

-- Receive a list of lines and log it
local function receive(conn)
    local data = {}
    local recv

    conn:settimeout(await_time)
    while not recv do
        recv = conn:receive('*l')
        if not recv then
            break
        end

        table.insert(data, recv)
        recv = nil
    end
    conn:settimeout()

    if (#data > 0) then logger_recv(data) end

    return data
end

local function has_channel(client, channel)
    return client.channels[channel] ~= nil
end

local channel_joined = 'client is joined to the channel %q'

--- Joins to a channel
-- @param channel the name of the channel
function twitch:join(channel)
    assert(not has_channel(self, channel), string.format(channel_joined, channel))
    self.channels[channel] = {}
    send(self.socket, 'JOIN #%s', channel)
    logger()

    receive(self.socket)
    logger()
end


local channel_not_joined = 'client is not joined to the channel %q'

local function check_channel(client, channel)
    assert(has_channel(client, channel) , string.format(channel_not_joined, channel))
end

--- Leaves a channel
-- @param channel the name of the channel
function twitch:leave(channel)
    check_channel(self, channel)

    self.channels[channel] = nil
    send(self.socket, 'PART #%s', channel)
    logger()

    receive(self.socket)
    logger()
end

--- Prints a message
-- @param[opt] channel the channel which will send, nil to broadcast
-- @param text the message to send
function twitch:send(channel, text)
    if text == nil then
        local text = channel

        for channel in pairs(self.channels) do
            send(self.socket, 'PRIVMSG #%s :%s', channel, text)
            logger()
        end
    else
        check_channel(self, channel)
        send(self.socket, 'PRIVMSG #%s :%s', channel, text)
        logger()
    end
end

local function has_command(client, channel, command)
    return (client.channels[channel] ~= nil) and (client.channels[channel][command] ~= nil)
end

local command_attached = 'command %q was attached to channel %q'

--- Attaches a function to a command
-- @param command the command name
-- @param[opt] channel the channel name, nil to attach the command to all channels
-- @param func the function of the command. It receives the following arguments: twitch client, channel, username, command args.
function twitch:attach(command, channel, func)
    if func == nil then
        local func = channel

        for channel in pairs(self.channels) do
            assert(not has_command(self, channel), string.format(command_attached, command, channel))
            self.channels[channel][command] = func
        end
    else
        check_channel(self, channel)
        assert(not has_command(self, channel), string.format(command_attached, command, channel))
        self.channels[channel][command] = func
    end
end

local command_not_attached = 'command %q is not attached to channel %q'

local function check_command(client, channel, command)
    assert(has_channel(client, channel), string.format(channel_not_joined, channel))
    assert(has_command(client, channel, command), string.format(command_not_attached, command, channel))
end

--- Detaches a command
-- @param command the command name
-- @param[opt] channel the channel name, nil to detach the command in all channels 
function twitch:detach(command, channel)
    if channel == nil then
        for channel in pairs(self.channels) do
            check_command(self, channel, command)
            self.channels[channel][command] = nil
        end
    else
        check_command(self, channel, command)
        self.channels[channel][command] = nil
    end
end

local function has_timer(client, name)
    return client.timers[name] ~= nil
end

local timer_added = 'timer %q was added'

--- Adds a timer that executes a command every n seconds
-- @param name the name of the timer
-- @param seconds the elapsed time to fire the command
-- @param func the function that be launched. The first argument will be the client
function twitch:settimer(name, seconds, func)
    assert(not has_timer(self, name), string.format(timer_added, name))
    self.timers[name] = cron.every(seconds, func, self)
end

local timer_not_added = 'timer %q is not added'

local function check_timer(client, name)
    assert(has_timer(client, name), string.format(timer_not_added, name))
end

--- Removes a timer
-- @param name The name of the timer to remove
function twitch:removetimer(name)
    check_timer(self, name)
    self.timers[name] = nil
end

local parse_privmsg = '^:(%w+)!%w+@%w+%.tmi%.twitch%.tv PRIVMSG #(%w+) :(.+)$'

function twitch:receive()
    self.socket:settimeout(0.5)
    msg, err = self.socket:receive('*l')
    if err == 'wantread' then
        self.socket:settimeout()
        return nil, 'wantread'
    else
        assert(msg, err)
    end

    local username, channel, text = string.match(msg, parse_privmsg)
    if username == nil then
        self.socket:settimeout()
        return msg
    else
        self.socket:settimeout()
        return msg, username, channel, text
    end
end

--- Runs a loop that receives al changes in the joined channels and executes their commands
function twitch:loop(check_exit)
    local running = true

    local last_time = socket.gettime()
    while running do
        local msg, username, channel, text = self:receive()

        if msg == nil then
            if username == 'wantread' then
                if check_exit then
                    running = check_exit()
                end
            end
        else
            if msg == 'PING :tmi.twitch.tv' then
                logger()
                logger_recv({ msg })
                send(self.socket, 'PONG :tmi.twitch.tv')
                logger()
            else
                logger_recv({ msg })
                logger()

                local command = string.match(text, '^!(.+)$')

                if command then
                    local args = {}
                    for arg in string.gmatch(command, '([^%s]+)') do
                        table.insert(args, arg)
                    end

                    if (self.channels[channel][args[1]] == nil) then
                        if self.commandnotfound then
                            self.commandnotfound(self, channel, username, args[1])
                            logger()
                        end
                    else
                        self.channels[channel][args[1]](self, channel, username, unpack(args, 2))
                        logger()
                    end
                end
            end

            if check_exit then
                running = check_exit()
            end
        end

        local current_time = socket.gettime()
        local elapsed = current_time - last_time

        for _, timer in pairs(self.timers) do
            timer:update(elapsed)
        end

        last_time = current_time
    end

    self.socket:settimeout()
end

--- Leaves all channels and close the connection
function twitch:close()
    for channel in pairs(self.channels) do
        self:leave(channel)
    end

    logger('socket closed')
    self.socket:close()
end

return setmetatable({
    --- Connects with Twitch IRC server and returns a client
    -- @param nickname the username that the chatbot uses to send chat messages
    -- @param token the token to authenticate your chatbot with Twitch's servers.
    -- @return a twitch client
    connect = function(nickname, token)
        local obj = setmetatable({
            channels = {}, timers = {}
        }, {
            __index = twitch,
        })
        
        local sock = socket.connect('irc.chat.twitch.tv', 6697)

        obj.socket = assert(ssl.wrap(sock, params))
        assert(obj.socket:dohandshake())

        send(obj.socket, 'PASS %s', (token:match('^oauth:') and token) or ('oauth:' .. token))
        send(obj.socket, 'NICK %s', nickname)
        logger()

        receive(obj.socket)
        logger()

        return obj
    end
}, { __index = twitch })
