local Definitions = {}
Definitions.PlayerTurnsEach = 3
Definitions.MaxArgumentBytes = 500
Definitions.Unlocks = table.freeze({
    { Points = 0, Id = "starter-chair", Label = "Starter Chair" },
    { Points = 30, Id = "blue-chair", Label = "Blue Chair" },
    { Points = 60, Id = "clear-thinker", Label = "Clear Thinker title" },
    { Points = 100, Id = "gold-chair", Label = "Gold Chair" },
})
Definitions.Topics = table.freeze({
    { Id="hints", Character="Rivet", Topic="Should hints be optional in building games?", AIPosition="Hints should stay available but optional.", Opening="Optional hints help new builders while leaving experts in control." },
    { Id="pieces", Character="Pip", Topic="Should build challenges limit the number of pieces?", AIPosition="Challenges should use a clear piece limit.", Opening="A shared piece limit makes choices meaningful and judging comparable." },
    { Id="scores", Character="Moss", Topic="Should team games show individual contribution scores?", AIPosition="Contribution details should stay private.", Opening="Private feedback can help improvement without creating a public blame board." },
})
function Definitions.Score(text)
    local lower = string.lower(text)
    local score, reasons = 10, { "Complete filtered turn +10" }
    if string.find(lower,"because",1,true) or string.find(lower,"so that",1,true) then score += 5; table.insert(reasons,"Gives a reason +5") end
    if string.find(lower,"for example",1,true) or string.find(lower,"for instance",1,true) or string.find(lower,"if ",1,true) then score += 5; table.insert(reasons,"Uses an example or scenario +5") end
    if string.find(lower,"but ",1,true) or string.find(lower,"however",1,true) or string.find(lower,"you said",1,true) then score += 5; table.insert(reasons,"Attempts a rebuttal +5") end
    return score, reasons
end
return Definitions
