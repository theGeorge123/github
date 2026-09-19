local History = {}

function History.Push(history, playerMessage, opponentMessage, maxTurns)
    assert(type(history) == "table", "history must be a table")
    table.insert(history, { Player = playerMessage, Guard = opponentMessage })
    while #history > maxTurns do
        table.remove(history, 1)
    end
    return history
end

return History