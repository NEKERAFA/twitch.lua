local args = {...}
local _base = args[1]

require(_base .. ".packages")

local parser = require("irc-parser")('twitch')

local config = require(_base .. ".config")
local utils = require(_base .. ".utils")

local client = {
    -- Command received channel
    channel_commands = love.thread.getChannel(config.CHANNEL_COMMANDS),
    -- Event emited channel
    channel_events = love.thread.getChannel(config.CHANNEL_EVENTS),

    -- Is thread running?
    is_running = true,

    -- IRC Socket connection
    conn = nil,
    -- TLS/SSL initialization parameters
    ssl_params = {
        mode = 'client',
        protocol = 'any',
        options = 'all',
        verify = 'none'
    },

    -- is twitch capabilities enabled?
    is_cap_enabled = args[3] or false,

    -- channels joined
    channels = {},
    -- messages pending
    messages = {},
}

-- Prints IRC message in the console
utils.verbosity = args[2] or utils.verbosity

-- IRC Command handlers
local _command_handlers = require(_base .. ".command_handlers")
-- Twitch IRC Command handlers
local _irc_handlers = require(_base .. ".twitch_commands")

while client.is_running do
    -- Process events
    if client.channel_commands:getCount() > 0 then
        local event = client.channel_commands:pop()
        assert(_command_handlers[event.command], ("command '%s' not supported"):format(tostring(event.command)))
        _command_handlers[event.command](client, unpack(event.args))
    end

    -- Process data readed
    if client.is_running then
        local data = utils.recv(client.conn)
        if data then
            data = parser(data)
            if _irc_handlers[data.command] then
                _irc_handlers[data.command](client, data)
            end
        end
    end
end

if client.conn then
    client.conn:close()
end