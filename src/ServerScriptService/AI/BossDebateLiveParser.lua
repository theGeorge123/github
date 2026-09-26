local Parser={}

local forbidden={
    "http://","https://","www.","citation","source:","sources:",
    "winner","you win","you lose","score","reward","elo",
    "system prompt","developer instruction","hidden instruction",
}

local function trim(value)
    return value:match("^%s*(.-)%s*$")
end

function Parser.Parse(text,limits)
    if type(text)~="string"or text==""then return nil,"EMPTY_RESPONSE"end
    limits=type(limits)=="table"and limits or{}
    local maxOutput=limits.MaxOutputBytes or 768
    local maxReply=limits.MaxReplyBytes or 320
    if #text>maxOutput then return nil,"OUTPUT_TOO_LARGE"end
    if utf8.len(text)==nil then return nil,"INVALID_UTF8"end
    if string.find(text,"\n",1,true)or string.find(text,"\r",1,true)then return nil,"BAD_SCHEMA"end
    local reply=text:match("^REPLY=(.+)$")
    if not reply then return nil,"BAD_SCHEMA"end
    reply=trim(reply)
    if reply==""or#reply>maxReply or utf8.len(reply)==nil then return nil,"BAD_SCHEMA"end
    local lower=string.lower(reply)
    for _,token in ipairs(forbidden)do
        if string.find(lower,token,1,true)then return nil,"BAD_SCHEMA"end
    end
    return {Reply=reply}
end

return Parser
