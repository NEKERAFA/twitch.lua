-- twitch.lua - NEKERAFA - 8th february 2022
-- A Twitch client written in Lua
--
-- Under GNU General Public License v3.0

local twitch = {
    _VERSION     = 'twitch.lua 0.0.1',
    _AUTHOR      = 'Rafael Alcalde Azpiazu',
    _DESCRIPTION = 'A Twitch client written in Lua',
    _URL         = 'https://github.com/NEKERAFA/twitch.lua',
    _LICENSE     = 'Under GNU General Public License v3.0 (GPLv3)'
}

local socket = require "socket"
local ssl = require "ssl"

local params = {
    mode = "client",
    protocol = "any",
    cafile = "/etc/ssl/certs/ca-certificates.crt",
    verify = "peer",
    options = "all"
}

local await_time = 2

local function print_recv(data)
    for _, str in ipairs(data) do
        print(string.format("> %s", str))
    end
end

local function print_send(data)
    print(string.format("< %s", data))
end

local function send(conn, data, ...)
    print_send(string.format(data, ...))
    assert(conn:send(string.format(data .. "\r\n", ...)))
end

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

local function notfound(client, channel, username)
    client:message(channel, string.format("@%s: 404 - command not found", username))
end

---
---
---
function twitch:join(channel)
    self.channels[channel] = {}
    send(self.socket, "JOIN #%s", channel)
    print()

    receive(self.socket)
    print()
end

function twitch:leave(channel)
    if self.channels[channel] then
        self.channels[channel] = nil
        send(self.socket, "PART #%s", channel)
        print()

        receive(self.socket)
        print()
    end
end

function twitch:message(channel, text)
    if text == nil then
        local text = channel

        for channel in pairs(self.channels) do
            send(self.socket, "PRIVMSG #%s :%s", channel, text)
            print()
        end
    else
        send(self.socket, "PRIVMSG #%s :%s", channel, text)
        print()
    end
end


---
function twitch:attach(command, channel, func_command)
    if func_command == nil then
        local func_command = channel

        for _, channel in pairs(self.channels) do
            channel[command] = func_command
        end
    else
        self.channels[channel][command] = func_command
    end
end

function twitch:detach(command, channel)
    if channel == nil then
        for _, channel in pairs(self.channels) do
            channel[command] = nil
        end
    else
        self.channels[channel][command] = nil
    end
end

function twitch:runcommands()
    while true do
        local msg = assert(self.socket:receive("*l"))
        print_recv({ msg })
        
        if msg == "PING :tmi.twitch.tv" then
            send(self.socket, "PONG :tmi.twitch.tv")
            print()
        else
            local username, channel, text = string.match(msg, "^:(.+)!.+@.+%.tmi%.twitch%.tv PRIVMSG #(.+) :(.+)$")

            if (username ~= nil) then
                local command = string.match(text, "^!(.+)$")

                if command then
                    local args = {}
                    for arg in string.gmatch(command, "([^%s]+)") do
                        table.insert(args, arg)
                    end

                    if self.channels[channel][args[1]] == nil then
                        print()

                        notfound(self, channel, username)
                    else
                        self.channels[channel][args[1]](self, channel, username, table.unpack(args, 2))
                    end
                end
            end
        end
    end
end

function twitch:close()
    for channel in pairs(self.channels) do
        self:leave(channel)
    end

    print("socket closed")
    self.socket:close()
end

return setmetatable({ 
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
        obj.socket:send(string.format("PASS %s\r\n", token))
        print_send(string.format("NICK %s", nickname))
        obj.socket:send(string.format("NICK %s\r\n", nickname))
        print()

        receive(obj.socket)
        print()

        return obj
    end
}, { __index = twitch })
