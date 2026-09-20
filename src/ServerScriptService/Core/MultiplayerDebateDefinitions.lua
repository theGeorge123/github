local WritingChecklist = require(script.Parent.WritingChecklist)
local Definitions = {}
Definitions.PlayerTurnsEach = 3
Definitions.TurnSeconds = 45
Definitions.MaxArgumentBytes = 500
Definitions.Unlocks = table.freeze({
    { Points = 0, Id = "starter-chair", Label = "Starter Chair", Kind = "chair" },
    { Points = 30, Id = "blue-chair", Label = "Blue Chair", Kind = "chair" },
    { Points = 60, Id = "clear-thinker", Label = "Clear Thinker title", Kind = "title" },
    { Points = 100, Id = "gold-chair", Label = "Gold Chair", Kind = "chair" },
})
Definitions.Topics = table.freeze({
    { Id="hints", Character="Rivet", Topic="Should hints be optional in building games?", AIPosition="Hints should stay available but optional.", Opening="Optional hints help new builders while leaving experts in control." },
    { Id="pieces", Character="Pip", Topic="Should build challenges limit the number of pieces?", AIPosition="Challenges should use a clear piece limit.", Opening="A shared piece limit makes choices meaningful and judging comparable." },
    { Id="scores", Character="Moss", Topic="Should team games show individual contribution scores?", AIPosition="Contribution details should stay private.", Opening="Private feedback can help improvement without creating a public blame board." },
})
function Definitions.Score(text)
    return WritingChecklist.Evaluate(text)
end
return Definitions
