local commands = {}

-- Command Types
commands.types = {
    CONNECT_IRC      = "irc.connect",
    SET_VERBOSITY    = "irc.set_verbosity",
    SET_CAPABILITIES = "irc.set_capabilities",
    DISCONNECT_IRC   = "irc.disconnect",
    JOIN_CHANNEL     = "channel.join",
    LEAVE_CHANNEL    = "channel.leave",
    SEND_MESSAGE     = "message.send",
}

-- Command Builders
local function build_command(type, args)
    return {
        command = type,
        args = args or {}
    }
end

function commands.setverbosity(isverbose)
    return build_command(commands.types.SET_VERBOSITY, { isverbose })
end

function commands.setcapabilities(capabilities)
    return build_command(commands.types.SET_CAPABILITIES, { capabilities })
end

function commands.connectirc(nickname, token)
    return build_command(commands.types.CONNECT_IRC, { nickname, token })
end

function commands.disconnectirc()
    return build_command(commands.types.DISCONNECT_IRC)
end

function commands.join(channel)
    return build_command(commands.types.JOIN_CHANNEL, { channel })
end

function commands.leave(channel)
    return build_command(commands.types.LEAVE_CHANNEL, { channel })
end

function commands.send(channel, message)
    return build_command(commands.types.SEND_MESSAGE, { message, channel })
end

return commands