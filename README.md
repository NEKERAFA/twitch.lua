# twitch.lua
A Twitch client written in Lua 5.1. This module is compatible with LÖVE

[![Powered by Lua](https://img.shields.io/badge/powered%20by-Lua-blue?logo=)](https://www.lua.org/) [![Made by LÖVE](https://img.shields.io/badge/love2d-11.4-e64998.svg)](https://love2d.org/) [![GitHub license](https://img.shields.io/github/license/NEKERAFA/twitch.lua)](https://github.com/NEKERAFA/twitch.lua/blob/main/LICENSE)

## Dependencies

- [Lua 5.1](http://www.lua.org/)
- [LuaSocket](https://github.com/diegonehab/luasocket)
- [LuaSec](https://github.com/brunoos/luasec)
- [cron.lua](https://github.com/kikito/cron.lua)

> Note: If you use it in LÖVE, you will need to install LuaSec only, because LÖVE has a LuaSocket build-in version.

## Example

```lua
local twitch = require "twitch"

-- Creates an "echo" command
local function echo(client, channel, username, ...)
    local msg = ""
    for _, value in ipairs({...}) do
        msg = msg .. value .. " "
    end

    -- Sends the data received
    client:send(channel, string.format("@%s %s", username, msg))
end

-- Connects to Twitch server
local client = twitch.connect("<USERNAME>", "<OAUTH_OKEN>")

-- Joins to our channel
client:join("<CHANNEL>")

-- Sends a message in our channel
client:send("Hello world!")

-- Adds a command
client:attach("echo", "<CHANNEL>", echo)

-- Closes the connection
client:close()
```

See more in [https://github.com/NEKERAFA/moon-bot](https://github.com/NEKERAFA/moon-bot), a twitch bot that uses this project

## Documentation

See [https://nekerafa.github.io/twitch.lua](https://nekerafa.github.io/twitch.lua)


## License

> MIT License
>
> Copyright (c) 2019 Rafael Alcalde Azpiazu
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in all
> copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND
> NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
> SOFTWARE.