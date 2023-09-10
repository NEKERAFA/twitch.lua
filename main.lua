local twitch = require "twitch.twitch"

local messages = {}

function love.load()
    twitch.connectIRC()
    twitch.joinChannel("nekerafa")
end

function love.update(dt)
    twitch.update(dt)

    if twitch.getCount() then
        table.insert(messages, twitch.receive())
    end
end

function love.draw()
    for i, message in ipairs(messages) do
        love.graphics.print(("%s: %s"):format(message.tags["display-name"] or message.nickname, message.message), 10, 10 + (i - 1) * 20)
    end
end

function love.quit()
    twitch.disconnectIRC()
end