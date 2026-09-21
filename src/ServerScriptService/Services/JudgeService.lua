local JudgeService = {}

local JUDGES = {
    {Id = "Rivet", CriterionId = "reason", Label = "STRUCTURE — uses because/since/so that", Accent = "CYAN"},
    {Id = "Pip", CriterionId = "example", Label = "EVIDENCE — uses an example or scenario", Accent = "GOLD"},
    {Id = "Moss", CriterionId = "rebuttal_attempt", Label = "REBUTTAL — responds with however/but", Accent = "GREEN"},
}

local LINES = {
    Rivet = {
        Opening = {"I am checking for a clear reason.", "Show the link between your claim and why it follows."},
        Rebuttal = {"Keep the response structured.", "A clear because can make the reply easier to follow."},
        Closing = {"Tie your conclusion back to one reason.", "Close the loop: claim, because, conclusion."},
    },
    Pip = {
        Opening = {"A concrete example will make this easier to picture.", "Give us a situation, not only a claim."},
        Rebuttal = {"Test that response with an example.", "Show what this would look like in practice."},
        Closing = {"Leave us with one specific consequence.", "A final example can ground the close."},
    },
    Moss = {
        Opening = {"Listen closely; you will need to answer the other side.", "Make a claim the other player can respond to."},
        Rebuttal = {"Address what was said, then explain your disagreement.", "Use however or but to mark the response clearly."},
        Closing = {"Show why your case survives the other side's point.", "Finish by answering the strongest opposing point."},
    },
}

local function criterionById(criteria, id)
    for _, criterion in ipairs(criteria or {}) do
        if criterion.Id == id then return criterion end
    end
    return nil
end

function JudgeService.GetJudges()
    return JUDGES
end

function JudgeService.Evaluate(text, role, turnNumber, evaluator)
    assert(type(evaluator) == "function", "JudgeService requires the authoritative checklist evaluator")
    local score, reasons, criteria = evaluator(text)
    local reactions = {}
    for index, judge in ipairs(JUDGES) do
        local criterion = criterionById(criteria, judge.CriterionId)
        local options = LINES[judge.Id][role] or LINES[judge.Id].Opening
        local line = options[((turnNumber or 1) + index - 2) % #options + 1]
        table.insert(reactions, {
            Judge = judge.Id,
            CriterionId = judge.CriterionId,
            Earned = criterion and criterion.Earned == true or false,
            Points = criterion and criterion.Points or 0,
            Commentary = "SCRIPTED CHECKLIST — " .. line,
            Label = judge.Label,
        })
    end
    return score, reasons, criteria, reactions
end

function JudgeService.Verdicts(scores)
    assert(type(scores) == "table" and #scores == 2, "Two scores required")
    local first, second = scores[1], scores[2]
    local winnerUserId = nil
    if first.Points ~= second.Points then winnerUserId = first.Points > second.Points and first.UserId or second.UserId end
    return {
        WinnerUserId = winnerUserId,
        IsTie = winnerUserId == nil,
        Disclosure = "SCRIPTED PRACTICE — checklist totals only; the panel did not judge truth or argument quality.",
        Lines = {
            {Judge="Rivet", Text="SCRIPTED VERDICT — Structure points came from visible reason markers."},
            {Judge="Pip", Text="SCRIPTED VERDICT — Evidence points came from visible example markers."},
            {Judge="Moss", Text="SCRIPTED VERDICT — Rebuttal points came from visible response markers."},
        },
    }
end

return JudgeService
