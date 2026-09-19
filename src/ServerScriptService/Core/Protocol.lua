local Protocol = {}

function Protocol.Validate(payload, match, maxBytes)
    if type(payload) ~= "table" or type(payload.MatchId) ~= "string" then
        return false
    end
    if payload.MatchId ~= match.Id or payload.Turn ~= match.State.Turns + 1 then
        return false
    end
    if payload.Kind == "Choice" then
        return type(payload.Value) == "string" and #payload.Value <= 30
    end
    if payload.Kind ~= "Text" or type(payload.Value) ~= "string" then
        return false
    end
    local message = payload.Value
    return #message > 0 and #message <= maxBytes and utf8.len(message) ~= nil
        and string.find(message, "%S") ~= nil and string.find(message, "%c") == nil
end

return Protocol
