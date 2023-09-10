# twitch.lua
A Twitch client written in Lua 5.1. This module is compatible with LÖVE

[![Powered by Lua](https://img.shields.io/badge/powered%20by-Lua-blue)](https://www.lua.org/) [![Made by LÖVE](https://img.shields.io/badge/love2d-11.4-e64998)](https://love2d.org/) [![GitHub license](https://img.shields.io/github/license/NEKERAFA/twitch.lua)](https://github.com/NEKERAFA/twitch.lua/blob/main/LICENSE)

## Dependencies

- [Lua 5.1](http://www.lua.org/)
- [LuaSocket](https://github.com/diegonehab/luasocket)
- [LuaSec](https://github.com/brunoos/luasec)
- [lua-irc-parser](https://github.com/jprjr/lua-irc-parser)

> Note: If you use it in LÖVE, you will need to install LuaSec only, because LÖVE has a LuaSocket build-in version.

## Example

```lua
local twitch = require "twitch"

local messages = {}

function love.load()
    twitch.connectIRC() -- Connect using twitch read-only connection
    twitch.joinChannel("channel") -- Connect to a channel
end

function love.update(dt)
    twitch.update(dt)

    if twitch.getCount() then
        table.insert(messages, twitch.receive()) -- Add new twitch messages to print all
    end
end

function love.draw()
    for i, message in ipairs(messages) do
        -- Prints "username: Hello world!"
        love.graphics.print(("%s: %s"):format(message.tags["display-name"] or message.nickname, message.message), 10, 10 + (i - 1) * 20)
    end
end

function love.quit()
    twitch.disconnectIRC() -- Disconnect of twitch irc
end
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