---
-- twitch.lua
-- A Twitch client written for LÖVE
--
-- @classmod twitch
-- @author Rafael Alcalde Azpiazu (NEKERAFA)
-- @release 0.6.0-love2d
-- @license MIT

local _base = string.gsub(({...})[1], ".twitch$", "")
local path = string.gsub(_base, '%.', '/')

local config = require(_base .. ".config")
local commands = require(_base .. ".commands")
local events = require(_base .. ".events").types

local twitch = {
    _VERSION     = '0.6.0-love2d',
    _AUTHOR      = 'Rafael Alcalde Azpiazu (NEKERAFA)',
    _DESCRIPTION = 'A Twitch client written for LÖVE',
    _URL         = 'https://github.com/NEKERAFA/twitch.lua',
    _LICENSE     = 'MIT',
}

-- IRC client thread
local irc_client = love.thread.newThread(path .. '/irc_client.lua')

-- Command channel
local channel_commands = love.thread.getChannel(config.CHANNEL_COMMANDS)
-- Event emited channel
local channel_events = love.thread.getChannel(config.CHANNEL_EVENTS)

-- IRC client verbosity
local is_irc_verbose = true
-- is IRC client connected?
local is_irc_connected = false
-- is IRC authenticate?
local is_irc_authenticated
-- is twitch capabilities enabled?
local is_cap_enabled = true
-- Channels joined
local channels = {}
-- Messages received
local messages = setmetatable({ size = 0 }, {__len = function(o) return o.size end})

-- Get an anonymous nickname
local function get_anon_nickname()
    local num = math.floor(love.timer.getTime() * 1000)
    return ("justinfan%06d"):format(num % 1000000)
end

--- Prints IRC messages.
-- @param isverbose true to show IRC messages, false otherwise.
function twitch.setIRCVerbosity(isverbose)
    is_irc_verbose = isverbose and true -- cast to boolean
    channel_commands:push(commands.setverbosity(is_irc_verbose))
end

--- Gets aditional metadata when receives IRC messages, like receive JOIN and PART messages when users join chat room or get color or display user name when receives PRIVMSG messages
function twitch.setTwitchCapabilities(capabilities)
    is_cap_enabled = capabilities and true -- cast to boolean
    channel_commands:push(commands.setcapabilities(is_cap_enabled))
end

--- Connect to IRC server. If nickname and token is omited, it use an only-read connection.
-- @param[opt] nickname the Twitch username in IRC server.
-- @param[opt] token the access token to authenticate with IRC server.
function twitch.connectIRC(nickname, token)
    irc_client:start(_base, is_irc_verbose, is_cap_enabled)

    if not nickname then
        twitch.connectIRCAnonymously()
    else
        assert(token, ("bad argument #2 to connectIRC (string expected, got %s)"):format(type(token)))
        channel_commands:push(commands.connectirc(nickname, token))
    end
end

--- Checks if IRC client is connected to IRC server.
-- @return true if the IRC client is connected, false otherwise.
function twitch.isIRCConnected()
    if not irc_client:isRunning() then return false end
    return is_irc_connected
end

--- Checks if IRC authentication is successful.
-- @return true if the authentication is successful, false otherwise.
function twitch.isIRCAuthenticated()
    if not irc_client:isRunning() then return false end
    return is_irc_authenticated
end

--- Connect to IRC server using only-read connection.
function twitch.connectIRCAnonymously()
    twitch.connectIRC(get_anon_nickname(), "123456")
end

--- Disconnect IRC client.
function twitch.disconnectIRC()
    if irc_client:isRunning() then
        channel_commands:push(commands.disconnectirc())
        irc_client:wait()
    end
end

--- Join to an IRC channel.
-- @param channel the name of the channel.
function twitch.joinChannel(channel)
    channels[channel] = false
    channel_commands:push(commands.join(channel))
end

--- Checks if IRC client is joined to the channel.
function twitch.isChannelJoined(channel)
    return channels[channel]
end

--- Leaves an IRC channel.
-- @param channel the name of the channel.
function twitch.leaveChannel(channel)
    channels[channel] = nil
    channel_commands:push(commands.leave(channel))
end

--- Send a IRC message.
-- @param channel[opt] the channel which send the message, nil to broadcast.
-- @param message the message to send.
function twitch.send(channel, message)
    if message == nil then
        message = channel
        channel = nil
    end

    channel_commands:push(commands.send(channel, message))
end

--- Get next IRC message received.
-- @param channel[opt] the channel to filter.
-- @return nil if there is any message receive, otherwise return a message object with following values:
-- <ul style="list-style-type: circle">
-- <li><span class='parameter'>date</span> The date when the message is received as ISO 8601 string.
-- <li><span class='parameter'>tags</span> Twitch IRC tags if you request the irc capabilities.
-- <li><span class='parameter'>nickname</span> The nickname of the person who send the message.
-- <li><span class='parameter'>channel</span> The channel which message was sended.
-- <li><span class='parameter'>message</span> The message as string.
-- </ul>
function twitch.receive(channel)
    local message = nil
    local pos = 1

    if channel then
        while not message and pos < #messages do
            if messages[pos].channel == channel then
                message = messages[pos]
            else
                pos = pos + 1
            end
        end
    elseif #messages > 0 then
        message = messages[pos]
    end

    if message then
        table.remove(messages, pos)
        messages.size = messages.size - 1
    end

    return message
end

--- Get the number of messages pending.
function twitch.getCount()
    return #messages
end

--- Updates internal state.
-- @param dt time since the last update in seconds.
function twitch.update(dt)
    -- Process events
    if channel_events:getCount() > 0 then
        local e = channel_events:pop()

        if e.event == events.IS_CONNECTED then
            is_irc_connected = e.result
        elseif e.event == events.IS_AUTHENTICATED then
            is_irc_authenticated = e.result
        elseif e.event == events.CHANNEL_JOINED then
            channels[e.result] = true
        elseif e.event == events.MESSAGE_RECEIVED then
            table.insert(messages, e.result)
            messages.size = messages.size + 1
        end
    end
end

return twitch