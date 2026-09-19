local ResponseParser = {}

local allowedIntents = {
    requirements = true, permit = true, verify = true, escort = true,
    flattery = true, authority = true, urgency = true, joke = true,
    bribe = true, threat = true, irrelevant = true,
}

local allowedStrengths = {
    weak = true, normal = true, strong = true,
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function unwrap(value)
    value = trim(value)
    local tick = string.char(96)
    while string.sub(value, 1, 1) == tick do
        value = string.sub(value, 2)
    end
    while string.sub(value, -1) == tick do
        value = string.sub(value, 1, -2)
    end
    local doubleQuoted = value:match('^"(.*)"$')
    local singleQuoted = value:match("^'(.*)'$")
    return trim(doubleQuoted or singleQuoted or value)
end

local function utf8SafeLimit(value, maxBytes)
    if not maxBytes or #value <= maxBytes then
        return value
    end
    local cut = string.sub(value, 1, maxBytes)
    while #cut > 0 and utf8.len(cut) == nil do
        cut = string.sub(cut, 1, #cut - 1)
    end
    return cut
end

local function cleanReply(reply, maxBytes)
    reply = unwrap(reply):gsub("[\r\n]+", " "):gsub("%s+", " ")
    if reply == "" then
        return nil
    end
    reply = utf8SafeLimit(reply, maxBytes)
    if reply == "" or utf8.len(reply) == nil then
        return nil
    end
    return reply
end

function ResponseParser.Parse(text, maxReplyBytes)
    if type(text) ~= "string" then
        return nil, "missing text"
    end

    local fields = {}
    local fence = string.rep(string.char(96), 3)

    for line in text:gmatch("[^\r\n]+") do
        local cleaned = trim(line)
        if string.sub(cleaned, 1, 3) ~= fence then
            cleaned = cleaned:gsub("^[%s%*#>%-%+]+", ""):gsub("[%s%*]+$", "")
            local key, value = cleaned:match("^([%a_]+)%s*[:=%-]%s*(.-)%s*$")
            if key and value then
                fields[string.lower(key)] = value
            end
        end
    end

    local intent = string.lower(unwrap(fields.tactic or fields.intent))
    local strength = string.lower(unwrap(fields.strength))
    local reply = cleanReply(fields.reply or fields.response, maxReplyBytes)

    if not allowedIntents[intent] then
        return nil, "invalid tactic"
    end
    if not allowedStrengths[strength] then
        return nil, "invalid strength"
    end
    if not reply then
        return nil, "invalid reply"
    end

    return {
        Intent = intent,
        Strength = strength,
        Reply = reply,
        Provider = "Roblox",
    }
end

return ResponseParser