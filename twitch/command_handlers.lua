local _base = string.gsub(({...})[1], ".command_handlers$", "")

local socket = require "socket"
local ssl = require "ssl"

local types = require(_base .. ".commands").types
local config = require(_base .. ".config")
local utils = require(_base .. ".utils")

-- Prints IRC messages
local function setverbosity(_, isverbose)
    utils.verbosity = isverbose
end

-- Set Twitch IRC capabilities
local function setcapabilities(client, capabilities)
    client.is_cap_enabled = capabilities

    if client.conn then
        utils.send(client.conn, "CAP REQ :twitch.tv/commands twitch.tv/tags")
    end
end

-- Connect to Twitch IRC server
local function connect(client, nickname, token)
    utils.logger(("connecting to %s:%d"):format(config.TWITCH_IRC_URL, config.TWITCH_IRC_PORT))

    -- Attempt to connect to Twitch IRC server
    client.conn = assert(socket.connect(config.TWITCH_IRC_URL, config.TWITCH_IRC_PORT))
    client.conn = assert(ssl.wrap(client.conn, client.ssl_params))
    assert(client.conn:dohandshake())

    if client.is_cap_enabled then
        utils.send(client.conn, "CAP REQ :twitch.tv/commands twitch.tv/tags")
    end

    utils.send(client.conn, "PASS %s", (token:match("^oauth:") and token) or ("oauth:%s"):format(token))
    utils.send(client.conn, "NICK %s", nickname)

    -- Propagate event
    client.channel_events:push({
        event = "is_connected",
        result = true
    })
end

-- Disconnect to Twitch IRC server
local function disconnect(client)
    client.is_running = false
end

-- Join to Twitch channel
local function join(client, channel)
    client.channels[channel] = false

    if client.is_authenticated then
        utils.send(client.conn, "JOIN #%s", channel)
    end
end

-- Leave a Twitch channel
local function leave(client, channel)
    if client.channels[channel] then
        utils.send(client.conn, "PART #%s", channel)
    end

    client.channels[channel] = nil
end

-- Send a message
local function send(client, message, channel)
    if channel then
        if client.channels[channel] then
            utils.send(client.conn, "PRIVMSG #%s :%s", channel, message)
        else
            if not client.messages[channel] then
                client.messages[channel] = {}
            end

            table.insert(client.messages[channel], message)
        end
    else
        for channel in pairs(client.channels) do
            send(client, message, channel)
        end
    end
end

return {
    [types.SET_VERBOSITY] = setverbosity,
    [types.SET_CAPABILITIES] = setcapabilities,
    [types.CONNECT_IRC] = connect,
    [types.DISCONNECT_IRC] = disconnect,
    [types.JOIN_CHANNEL] = join,
    [types.LEAVE_CHANNEL] = leave,
    [types.SEND_MESSAGE] = send,
}