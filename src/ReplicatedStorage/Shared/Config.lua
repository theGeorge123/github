return table.freeze({
    GameName = "Beat the Bot",
    -- 0.5.3: brighter guardian-temple presentation and more interactive debate UX; live debate and probe remain disabled.
    Version = "0.5.3",
    ProfileSchema = 2,
    OpponentRating = 1000,
    InitialRating = 1000,
    RatingK = 32,
    MaxTurns = 8,
    MatchSeconds = 180,
    MaxMessageBytes = 240,
    RequestCooldown = 1,
    ArenaCount = 4,
    ArenaResetSeconds = 5,
    LeaseSeconds = 180,
    SaveInterval = 45,
    StoreName = "BeatTheBot_Profiles_v1",
    StudioPersistence = false,

    -- Private debate prototype gates. Both remain off until an authorized private test.
    DebateEnabled = true,
    DebateLiveEnabled = false,
    DebateProbe = {Enabled=false,MaxOutputBytes=2048,MaxTextBytes=500,MaxTokens=120,SlowThresholdMs=12000},
    BossDebate = {
        Enabled = true,
        ScriptedPracticeEnabled = true,
        MaxArgumentBytes = 500,
        PlayerTurnSeconds = 45,
        PlayerTurns = 6,
    },

    AIProvider = "Roblox",
    AIRequestMaxTokens = 90,
    AIReplyMaxBytes = 320,
    AIResponseMaxBytes = 2048,

    Entitlements = {
        VIPUserIds = {},
        FounderUserIds = {},
    },

    Choices = {
        { Id = "requirements", Text = "Ask what would satisfy the rules." },
        { Id = "permit", Text = "Explain your credentials or authorization." },
        { Id = "verify", Text = "Offer a concrete detail they can verify." },
        { Id = "escort", Text = "Offer a supervised, lower-risk compromise." },
        { Id = "flattery", Text = "Appeal to their pride or reputation." },
        { Id = "authority", Text = "Invoke credible authority." },
        { Id = "urgency", Text = "Explain why delay creates a real problem." },
        { Id = "joke", Text = "Use humor to lower the tension." },
        { Id = "bribe", Text = "Offer them something improper." },
        { Id = "threat", Text = "Try intimidation." },
    },
})
