local utils = require("twitch.utils")
local events = require("twitch.events")

local function pong(client)
    utils.send(client.conn, "PONG :tmi.twitch.tv")
end

local function login_success(client)
    client.is_authenticated = true
    client.channel_events:push(events.isauthenticated(true))
end

local function notice(client, data)
    if data.params[2] == "Login authentication failed" then
        client.is_authenticated = false
        client.channel_events:push(events.isauthenticated(false))
    end
end

local function join(client, data)
    local channel = string.sub(data.params[2], 2)
    client.channels[channel] = true
    client.channel_events:push(events.channeljoined(channel))

    if client.messages[channel] then
        for _, message in ipairs(client.messages[channel]) do
            utils.send(client.conn, "PRIVMSG #%s :%s", channel, message)
        end
        client.messages[channel] = nil
    end
end

local function join_pending(client)
    for channel in pairs(client.channels) do
        utils.send(client.conn, "JOIN #%s", channel)
    end
end

local function message(client, data)
    client.channel_events:push(events.message(data.tags, data.source.nick, data.params[1]:sub(2), data.params[2]))
end

return {
    ["PING"] = pong,
    ["001"] = login_success,
    ["376"] = join_pending,
    ["NOTICE"] = notice,
    ["366"] = join,
    ["PRIVMSG"] = message,
}
