local LocalAdapter = {}

local patterns = {
    { "threat", { "attack", "kill", "punch", "hurt" } },
    { "bribe", { "gold", "bribe", "pay you", "money" } },
    { "requirements", { "what do i need", "requirements", "how can i enter", "rules", "what is required" } },
    { "verify", { "check", "verify", "inspect", "seal", "authentic" } },
    { "escort", { "escort", "come with", "follow me", "supervise", "watch me" } },
    { "permit", { "permit", "papers", "document", "delivery pass" } },
    { "joke", { "joke", "ladder", "funny", "laugh" } },
}

function LocalAdapter.Decide(context)
    local message = " " .. string.lower(context.Message):gsub("[^%w%s]", " "):gsub("%s+", " ") .. " "
    for _, entry in ipairs(patterns) do
        for _, phrase in ipairs(entry[2]) do
            if string.find(message, " " .. phrase .. " ", 1, true) then
                return { Intent = entry[1] }
            end
        end
    end
    return { Intent = "unknown" }
end

return LocalAdapter
