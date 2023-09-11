local args = {...}

local parser = require("irc-parser")('twitch')

local config = require("twitch.config")
local utils = require("twitch.utils")
local command_handlers = require("twitch.command_handlers")
local irc_handlers = require("twitch.twitch_commands")

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

while client.is_running do
    -- Process events
    if client.channel_commands:getCount() > 0 then
        local event = client.channel_commands:pop()
        assert(command_handlers[event.command], ("command '%s' not supported"):format(tostring(event.command)))
        command_handlers[event.command](client, unpack(event.args))
    end

    -- Process data readed
    if client.is_running and client.conn then
        local data = utils.recv(client.conn)
        if data then
            data = parser(data)
            if irc_handlers[data.command] then
                irc_handlers[data.command](client, data)
            end
        end
    end
end

if client.conn then
    client.conn:close()
end