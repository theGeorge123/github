-- BossDebateController: SCRIPTED PRACTICE UI (solo, vs authored prompts).
-- Presentation only. Every practice rule, turn token, filter, and disclosure is
-- server-authoritative via BossDebateState / BossDebateSubmit. The bot is never
-- presented as a human, and practice never produces scores, winners, or rewards.
local RunService = game:GetService("RunService")

local Controller = {}

function Controller.Init(remotes, parent, buttonFactory, labelFactory, colors, hooks)
    hooks = hooks or {}
    local state = remotes:WaitForChild("BossDebateState", 10)
    local submit = remotes:WaitForChild("BossDebateSubmit", 10)
    local multiplayerState = remotes:WaitForChild("MultiplayerDebateState", 10)
    local multiplayerSubmit = remotes:WaitForChild("MultiplayerDebateSubmit", 10)
    if not state or not submit or not multiplayerState or not multiplayerSubmit then
        warn("BeatTheBot boss controller: remotes missing; scripted practice UI disabled")
        return nil
    end

    -- Left card: availability + entry point for solo practice. Biased below the
    -- vertical center so it clears the chat input bar at top-left.
    local card = Instance.new("Frame")
    card.AnchorPoint = Vector2.new(0, 0.5)
    card.Position = UDim2.new(0, 14, 0.5, 48)
    card.Size = UDim2.fromOffset(232, 268)
    card.BackgroundColor3 = colors.bg
    card.Parent = parent
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 12)
    cc.Parent = card

    local title = labelFactory(card, "BOSS DEBATE", 20, colors.gold, true)
    title.Position = UDim2.fromOffset(14, 10)
    title.Size = UDim2.new(1, -28, 0, 30)

    local disclosure = labelFactory(card, "Checking server availability...", 13, colors.muted)
    disclosure.Position = UDim2.fromOffset(14, 44)
    disclosure.Size = UDim2.new(1, -28, 0, 108)
    disclosure.TextYAlignment = Enum.TextYAlignment.Top

    local cta = buttonFactory(card, "LOCKED", colors.panel)
    cta.Position = UDim2.fromOffset(14, 160)
    cta.Size = UDim2.new(1, -28, 0, 44)
    cta.Active = false
    cta.AutoButtonColor = false

    local friend = buttonFactory(card, "INVITE FRIEND / PRIVATE", colors.panel)
    friend.Position = UDim2.fromOffset(14, 212)
    friend.Size = UDim2.new(1, -28, 0, 44)

    -- Practice panel: scale-based so it fits phones and desktops.
    local practice = Instance.new("Frame")
    practice.AnchorPoint = Vector2.new(0.5, 0.5)
    practice.Position = UDim2.fromScale(0.5, 0.5)
    practice.Size = UDim2.new(0.92, 0, 0.92, 0)
    practice.BackgroundColor3 = colors.bg
    practice.Visible = false
    practice.Parent = parent
    local pc = Instance.new("UICorner")
    pc.CornerRadius = UDim.new(0, 14)
    pc.Parent = practice
    local psc = Instance.new("UISizeConstraint")
    psc.MaxSize = Vector2.new(470, 600)
    psc.MinSize = Vector2.new(280, 330)
    psc.Parent = practice
    -- Shrink on short viewports (landscape phones) so the input row stays on screen.
    local uiScale = Instance.new("UIScale")
    uiScale.Parent = practice
    local function fitPractice()
        uiScale.Scale = math.min(1, parent.AbsoluteSize.Y / 350)
    end
    fitPractice()
    parent:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitPractice)

    local pt = labelFactory(practice, "SCRIPTED PRACTICE", 22, colors.gold, true)
    pt.Position = UDim2.new(0, 14, 0.015, 0)
    pt.Size = UDim2.new(1, -28, 0.07, 0)

    local banner = labelFactory(practice, "VS AUTHORED PROMPTS \u{2022} NOT A REAL OPPONENT \u{2022} NO SCORE, WINNER, OR REWARDS", 12, colors.magenta, true)
    banner.Position = UDim2.new(0, 14, 0.085, 0)
    banner.Size = UDim2.new(1, -28, 0.05, 0)

    local status = labelFactory(practice, "", 13, colors.muted)
    status.Position = UDim2.new(0, 14, 0.14, 0)
    status.Size = UDim2.new(1, -28, 0.16, 0)
    status.TextYAlignment = Enum.TextYAlignment.Top

    local turnStatus = labelFactory(practice, "", 14, colors.green, true)
    turnStatus.Position = UDim2.new(0, 14, 0.315, 0)
    turnStatus.Size = UDim2.new(0.6, 0, 0.055, 0)

    local timer = Instance.new("TextLabel")
    timer.AnchorPoint = Vector2.new(1, 0)
    timer.Position = UDim2.new(1, -14, 0.315, 0)
    timer.Size = UDim2.new(0.32, 0, 0.055, 0)
    timer.BackgroundColor3 = colors.panel
    timer.TextColor3 = colors.white
    timer.Font = Enum.Font.GothamBold
    timer.TextSize = 16
    timer.Text = ""
    timer.Parent = practice
    local tc = Instance.new("UICorner")
    tc.CornerRadius = UDim.new(0, 8)
    tc.Parent = timer

    local log = Instance.new("ScrollingFrame")
    log.Position = UDim2.new(0, 14, 0.38, 0)
    log.Size = UDim2.new(1, -28, 0.27, 0)
    log.BackgroundColor3 = colors.panel
    log.AutomaticCanvasSize = Enum.AutomaticSize.Y
    log.CanvasSize = UDim2.new()
    log.BorderSizePixel = 0
    log.Parent = practice
    local lc = Instance.new("UICorner")
    lc.CornerRadius = UDim.new(0, 8)
    lc.Parent = log
    local ll = Instance.new("UIListLayout")
    ll.Padding = UDim.new(0, 6)
    ll.Parent = log

    local box = Instance.new("TextBox")
    box.MultiLine = true
    box.TextWrapped = true
    box.PlaceholderText = "Write your assigned position..."
    box.Text = ""
    box.TextColor3 = colors.white
    box.PlaceholderColor3 = colors.muted
    box.TextSize = 16
    box.Font = Enum.Font.Gotham
    box.BackgroundColor3 = colors.panel
    box.Position = UDim2.new(0, 14, 0.66, 0)
    box.Size = UDim2.new(1, -28, 0.15, 0)
    box.Parent = practice
    local bc = Instance.new("UICorner")
    bc.CornerRadius = UDim.new(0, 8)
    bc.Parent = box

    local send = buttonFactory(practice, "SEND TURN", colors.blue)
    send.Position = UDim2.new(0, 14, 0.82, 0)
    send.Size = UDim2.new(0.62, -18, 0.095, 0)
    send.Active = false

    local leave = buttonFactory(practice, "LEAVE", colors.panel)
    leave.Position = UDim2.new(0.62, 4, 0.82, 0)
    leave.Size = UDim2.new(0.38, -18, 0.095, 0)

    local background = buttonFactory(practice, "FIND REAL PLAYER IN BACKGROUND", colors.green)
    background.Position = UDim2.new(0, 14, 0.925, 0)
    background.Size = UDim2.new(1, -28, 0.06, 0)
    background.TextSize = 13

    local switch = buttonFactory(practice, "", colors.gold)
    switch.Position = UDim2.new(0, 14, 0.925, 0)
    switch.Size = UDim2.new(1, -28, 0.06, 0)
    switch.TextSize = 13
    switch.Visible = false

    local session = nil
    local round = nil
    local turnToken = nil
    local submission = 0
    local pending = nil
    local offerId = nil
    local acceptAfterLeave = false
    local backgroundSearching = false
    local deadline = nil
    local practiceOpen = false

    local function setPracticeOpen(open)
        practiceOpen = open
        practice.Visible = open
        card.Visible = not open
        if open and hooks.onPracticeOpened then
            hooks.onPracticeOpened()
        elseif not open and hooks.onPracticeClosed then
            hooks.onPracticeClosed()
        end
    end


    local onboardingShown = false
    local function showOnboarding()
        if onboardingShown then return end
        onboardingShown = true
        local steps = {
            "1 / 4  ASSIGNED SIDE: defend the position shown in this panel.",
            "2 / 4  THREE TURNS: opening, rebuttal, closing - 45 seconds each.",
            '3 / 4  CHECKLIST: RIVET checks "because", PIP checks "for example", MOSS checks "however".',
            "4 / 4  SCRIPTED PRACTICE: visible writing features only - NOT A REAL OPPONENT.",
        }
        local card = labelFactory(parent, "", 18, colors.white, true)
        card.Name = "BossFirstTimeOnboarding"
        card.AnchorPoint = Vector2.new(0.5, 0.5)
        card.Position = UDim2.fromScale(0.5, 0.42)
        card.Size = UDim2.fromOffset(460, 150)
        card.BackgroundTransparency = 0
        card.BackgroundColor3 = colors.bg
        card.ZIndex = 100
        card.TextXAlignment = Enum.TextXAlignment.Center
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 14)
        c.Parent = card
        task.spawn(function()
            for _, copy in ipairs(steps) do
                if not card.Parent then return end
                card.Text = copy
                task.wait(7.5)
            end
            if card.Parent then card:Destroy() end
        end)
    end

    local function addRow(who, text, col)
        local x = labelFactory(log, who .. "\n" .. text, 14, col, who ~= "SYSTEM")
        x.Size = UDim2.new(1, -12, 0, 56)
        x.AutomaticSize = Enum.AutomaticSize.Y
        x.TextYAlignment = Enum.TextYAlignment.Top
        x.Parent = log
        log.CanvasPosition = Vector2.new(0, 99999)
        return x
    end

    local function clearLog()
        for _, x in ipairs(log:GetChildren()) do
            if x:IsA("TextLabel") then x:Destroy() end
        end
    end

    -- Countdown from the server-provided deadline; display only.
    RunService.Heartbeat:Connect(function()
        if deadline == nil then
            timer.Text = ""
            return
        end
        local remaining = deadline - workspace:GetServerTimeNow()
        if remaining <= 0 then
            timer.Text = "0:00"
            timer.TextColor3 = colors.magenta
            return
        end
        timer.Text = ("%d:%02d"):format(math.floor(remaining / 60), math.floor(remaining % 60))
        timer.TextColor3 = remaining <= 10 and colors.magenta or colors.white
    end)

    cta.Activated:Connect(function()
        if cta.Active then
            submit:FireServer({ Action = "EnterPractice" })
        end
    end)

    friend.Activated:Connect(function()
        disclosure.Text = "Use Roblox Invite Friends or a private server, then both players choose multiplayer. No bot will impersonate a player."
    end)

    background.Activated:Connect(function()
        if backgroundSearching then
            multiplayerSubmit:FireServer("cancelBackground")
        else
            multiplayerSubmit:FireServer("backgroundQueue")
        end
    end)

    switch.Activated:Connect(function()
        if offerId and session then
            acceptAfterLeave = true
            submit:FireServer({ Action = "LeavePractice", SessionId = session })
            switch.Text = "FINISHING SCRIPTED TURN..."
            switch.Active = false
        end
    end)

    send.Activated:Connect(function()
        if not session or not turnToken or pending or box.Text == "" then return end
        submission += 1
        pending = submission
        send.Active = false
        submit:FireServer({
            Action = "SubmitArgument",
            SessionId = session,
            RoundGeneration = round,
            TurnToken = turnToken,
            SubmissionId = pending,
            Text = box.Text,
        })
    end)

    leave.Activated:Connect(function()
        if session then
            submit:FireServer({ Action = "LeavePractice", SessionId = session })
        end
        setPracticeOpen(false)
    end)

    state.OnClientEvent:Connect(function(message)
        if message.Kind == "BossAvailability" then
            disclosure.Text = message.Disclosure
            cta.Text = message.Tier == "SCRIPTED_PRACTICE" and "PLAY SCRIPTED PRACTICE NOW" or message.Tier
            cta.Active = message.Tier == "SCRIPTED_PRACTICE"
            cta.AutoButtonColor = cta.Active
        elseif message.Kind == "BossPracticeStarted" then
            session = message.SessionId
            round = message.RoundGeneration
            setPracticeOpen(true)
            clearLog()
            status.Text = message.Disclosure .. "\nYOU: " .. message.PlayerPosition .. "\nAUTHORED OPPOSITION: " .. message.BossPosition
            addRow("TOPIC", message.Topic.Question, colors.gold)
            showOnboarding()
        elseif message.Kind == "BossPlayerTurn" then
            turnToken = message.TurnToken
            deadline = message.Deadline
            turnStatus.Text = "YOUR TURN"
            send.Active = true
            send.Text = "SEND TURN"
            if offerId then
                switch.Visible = true
                switch.Active = true
                switch.Text = "SWITCH TO REAL PLAYER"
            end
        elseif message.Kind == "BossArgumentAccepted" then
            if message.SubmissionId == pending then
                pending = nil
                box.Text = ""
            end
            addRow("YOU", message.FilteredText, colors.white)
            for _, reaction in ipairs(message.JudgeReactions or {}) do addRow(reaction.Judge, reaction.Text, reaction.Earned and colors.green or colors.muted) end
        elseif message.Kind == "BossScriptedReply" then
            addRow(message.Label, message.Text, colors.gold)
        elseif message.Kind == "BossArgumentRejected" then
            if message.SubmissionId == pending or message.SubmissionId == nil then
                pending = nil -- draft stays in the box; the player can edit and retry
                send.Active = message.CanRetry == true
                send.Text = message.CanRetry and "TRY AGAIN" or "UNAVAILABLE"
                status.Text = message.Message
            end
        elseif message.Kind == "BossPracticeComplete" then
            send.Active = false
            deadline = nil
            turnStatus.Text = ""
            status.Text = message.Message
            addRow("COMPLETE", "No score, winner, or rewards.", colors.green)
        elseif message.Kind == "BossPracticeEnded" then
            session = nil
            round = nil
            turnToken = nil
            pending = nil
            deadline = nil
            turnStatus.Text = ""
            setPracticeOpen(false)
            if acceptAfterLeave and offerId then
                acceptAfterLeave = false
                multiplayerSubmit:FireServer("acceptOffer", { OfferId = offerId })
            end
        end
    end)

    multiplayerState.OnClientEvent:Connect(function(message)
        if message.Kind == "BackgroundQueue" then
            backgroundSearching = message.Status == "SEARCHING"
            background.Text = backgroundSearching and "CANCEL BACKGROUND SEARCH" or "FIND REAL PLAYER IN BACKGROUND"
            status.Text = message.Message
        elseif message.Kind == "MatchOffer" then
            offerId = message.OfferId
            status.Text = message.Message
            if turnToken then
                switch.Visible = true
                switch.Active = true
                switch.Text = "SWITCH TO " .. string.upper(message.OpponentName)
            end
        elseif message.Kind == "Start" then
            offerId = nil
            backgroundSearching = false
            switch.Visible = false
        elseif message.Kind == "Error" and message.Code == "STALE_OFFER" then
            offerId = nil
            switch.Visible = false
            status.Text = message.Message
        end
    end)

    submit:FireServer({ Action = "GetAvailability" })
    return {
        Card = card,
        IsPracticeActive = function()
            return practiceOpen
        end,
    }
end

return Controller
