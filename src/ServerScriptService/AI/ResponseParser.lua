local ResponseParser = {}

local allowedIntents = {
    requirements = true,
    permit = true,
    verify = true,
    escort = true,
    flattery = true,
    authority = true,
    urgency = true,
    joke = true,
    bribe = true,
    threat = true,
    irrelevant = true,
}

local allowedStrengths = {
    weak = true,
    normal = true,
    strong = true,
}

local function trim(value)
    return tostring(value or ""):match("^%s*(.-)%s*$")
end

local function cleanReply(reply, maxBytes)
    reply = trim(reply):gsub("[\r\n]+", " "):gsub("%s+", " ")
    if reply == "" then
        return nil
    end
    if maxBytes and #reply > maxBytes then
        reply = string.sub(reply, 1, maxBytes)
    end
    return reply
end

function ResponseParser.Parse(text, maxReplyBytes)
    if type(text) ~= "string" then
        return nil, "missing text"
    end

    local fields = {}

    for line in text:gmatch("[^\r\n]+") do
        local cleaned = line:gsub("^[%s%*#%-]+", ""):gsub("[%s%*]+$", "")
        local key, value = cleaned:match("^([%a_]+)%s*[:=]%s*(.-)%s*$")
        if key and value then
            fields[string.lower(key)] = value
        end
    end

    local intent = string.lower(trim(fields.tactic or fields.intent))
    local strength = string.lower(trim(fields.strength))
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