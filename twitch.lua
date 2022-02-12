---
-- twitch.lua
-- A Twitch client written in Lua
--
-- @classmod twitch
-- @author Rafael Alcalde Azpiazu
-- @release 0.0.1
-- @license GPLv3

local socket = require "socket"
local ssl = require "ssl"

local twitch = {
    _VERSION     = 'twitch.lua 0.0.1',
    _AUTHOR      = 'Rafael Alcalde Azpiazu',
    _DESCRIPTION = 'A Twitch client written in Lua',
    _URL         = 'https://github.com/NEKERAFA/twitch.lua',
    _LICENSE     = 'GNU General Public License v3.0 (GPLv3)'
}

local params = {
    mode = "client",
    protocol = "any",
    cafile = "/etc/ssl/certs/ca-certificates.crt",
    verify = "peer",
    options = "all"
}

local await_time = 2

-- Print data as received
local function print_recv(data)
    for _, str in ipairs(data) do
        print(string.format("> %s", str))
    end
end

-- Print data as sended
local function print_send(data)
    print(string.format("< %s", data))
end

-- Send a data using string.format and log it
local function send(conn, data, ...)
    print_send(string.format(data, ...))
    assert(conn:send(string.format(data .. "\r\n", ...)))
end

-- Receive a list of lines and log it
local function receive(conn)
    local data = {}
    local recv

    conn:settimeout(await_time)
    while not recv do
        recv = conn:receive("*l")
        if not recv then
            break
        end

        table.insert(data, recv)
        recv = nil
    end
    conn:settimeout()

    if (#data > 0) then print_recv(data) end

    return data
end

-- Custom command to print when a command is not saved
local function notfound(client, channel, command, username)
    client:message(string.format("@%s: %s command not found", username), channel)
end

--- Joins to a channel
-- @param channel the name of the channel
function twitch:join(channel)
    self.channels[channel] = {}
    send(self.socket, "JOIN #%s", channel)
    print()

    receive(self.socket)
    print()
end

--- Leaves a channel
-- @param channel the name of the channel
function twitch:leave(channel)
    if self.channels[channel] then
        self.channels[channel] = nil
        send(self.socket, "PART #%s", channel)
        print()

        receive(self.socket)
        print()
    end
end

--- Prints a message
-- @param text the message to send
-- @param[opt] channel the channel which will send, nil to broadcast
function twitch:message(text, channel)
    if channel == nil then
        for channel in pairs(self.channels) do
            send(self.socket, "PRIVMSG #%s :%s", channel, text)
            print()
        end
    else
        send(self.socket, "PRIVMSG #%s :%s", channel, text)
        print()
    end
end


--- Attaches a function to a command
-- @param command the command name
-- @param[opt] channel the channel name, nil to attach the command to all channels
-- @param func the function of the command. It receives the following arguments: twitch client, channel, username, command args.
function twitch:attach(command, channel, func)
    if func_command == nil then
        local func_command = channel

        for _, channel in pairs(self.channels) do
            channel[command] = func_command
        end
    else
        self.channels[channel][command] = func_command
    end
end

--- Detaches a command
-- @param command the command name
-- @param channel[opt] channel the channel name, nil to detach the command in all channels 
function twitch:detach(command, channel)
    if channel == nil then
        for _, channel in pairs(self.channels) do
            channel[command] = nil
        end
    else
        self.channels[channel][command] = nil
    end
end

--- Runs a loop that receives al changes in the joined channels and executes their commands
function twitch:loop()
    while true do
        local msg = assert(self.socket:receive("*l"))

        if msg == "PING :tmi.twitch.tv" then
            print()
            print_recv({ msg })
            send(self.socket, "PONG :tmi.twitch.tv")
            print()
        else
            print_recv({ msg })

            local username, channel, text = string.match(msg, "^:(.+)!.+@.+%.tmi%.twitch%.tv PRIVMSG #(.+) :(.+)$")

            if (username ~= nil) then
                local command = string.match(text, "^!(.+)$")

                if command then
                    local args = {}
                    for arg in string.gmatch(command, "([^%s]+)") do
                        table.insert(args, arg)
                    end

                    if self.channels[channel][args[1]] == nil || self.channels[channel]["notfound"] then
                        print()

                        (self.channels[channel]["notfound"] or notfound)(self, channel, args[1], username)
                    else
                        self.channels[channel][args[1]](self, channel, username, table.unpack(args, 2))
                    end
                end
            end
        end
    end
end

--- Leaves all channels and close the connection
function twitch:close()
    for channel in pairs(self.channels) do
        self:leave(channel)
    end

    print("socket closed")
    self.socket:close()
end

return setmetatable({
    --- Connects with Twitch IRC server and returns a client
    -- @param nickname the username that the chatbot uses to send chat messages
    -- @param token the token to authenticate your chatbot with Twitch's servers.
    -- @return a twitch client
    connect = function (nickname, token)
        local obj = setmetatable({
            channels = {}
        }, {
            __index = twitch,
        })
        
        local sock = socket.connect("irc.chat.twitch.tv", 6697)

        obj.socket = assert(ssl.wrap(sock, params))
        assert(obj.socket:dohandshake())

        print_send("PASS ****")
        obj.socket:send(string.format("PASS %s\r\n", (token:match("^oauth:") and token) or ("oauth:" .. token)))
        print_send(string.format("NICK %s", nickname))
        obj.socket:send(string.format("NICK %s\r\n", nickname))
        print()

        receive(obj.socket)
        print()

        return obj
    end
}, { __index = twitch })
