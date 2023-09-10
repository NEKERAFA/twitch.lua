local utils = { verbosity = true }

-- Print log
function utils.logger(...)
    if utils.verbosity then
        local output = ""
        for _, str in ipairs({...}) do
            output = ("%s%s "):format(output, tostring(str))
        end

        io.stdout:write(output .. "\n")
    end
end

-- Print received data
local function logger_recv(data) utils.logger(">", tostring(data)) end

-- Print sended data
local function logger_send(data, ...) utils.logger("<", string.format(tostring(data), ...)) end

function utils.send(conn, data, ...)
    local data_formatted = string.format(tostring(data), ...)
    logger_send(data_formatted)
    return conn:send(("%s\n\r"):format(data_formatted))
end

function utils.recv(conn, timeout)
    conn:settimeout(timeout or 0.1)
    local data, err = conn:receive("*l")
    conn:settimeout()

    if not data then return nil, err end
    logger_recv(data)
    return data
end

return utils