local events = {}

-- Event types
events.types = {
    IS_CONNECTED     = "is_connected",
    IS_AUTHENTICATED = "is_authenticated",
    CHANNEL_JOINED   = "channel_joined",
    MESSAGE_RECEIVED = "message_received"
}

-- Event builders
local function build_event(type, result)
    return {
        event = type,
        result = result or nil
    }
end

function events.isconnected(connection)
    return build_event(events.types.IS_CONNECTED, connection)
end

function events.isauthenticated(authentication)
    return build_event(events.types.IS_AUTHENTICATED, authentication)
end

function events.channeljoined(channel)
    return build_event(events.types.CHANNEL_JOINED, channel)
end

function events.message(tags, nickname, channel, message)
    return build_event(events.types.MESSAGE_RECEIVED, {
        date = os.date("!%FT%Tz"),
        tags = tags,
        nickname = nickname,
        channel = channel,
        message = message
    })
end

return events