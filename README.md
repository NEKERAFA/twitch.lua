# twitch.lua
A Twitch client written in Lua

[![Powered by Lua](https://img.shields.io/badge/powered%20by-Lua-blue?logo=)](https://www.lua.org/) [![GitHub license](https://img.shields.io/github/license/NEKERAFA/twitch.lua)](https://github.com/NEKERAFA/twitch.lua/blob/main/LICENSE)

## Dependencies

- [Lua 5.4](http://www.lua.org/)
- [LuaSocket](https://github.com/diegonehab/luasocket)
- [LuaSec](https://github.com/brunoos/luasec)

### Installing dependencies

**Using LuaRocks**

```sh
git submodule update --init
luarocks install luasocket --tree dependencies
luarocks install luasec --tree dependencies
```

## Documentation

See [https://nekerafa.github.io/twitch.lua](https://nekerafa.github.io/twitch.lua)