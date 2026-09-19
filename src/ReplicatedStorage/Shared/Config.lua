return table.freeze({
    GameName = "Beat the Bot",
    OpponentName = "The Castle Guard",
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

    -- Roblox-native AI. If generation fails, typed moves do not consume a turn;
    -- quick moves remain available as the deterministic degraded mode.
    AIProvider = "Roblox",
    AIRequestMaxTokens = 90,
    AIReplyMaxBytes = 320,

    Choices = {
        { Id = "requirements", Text = "What do I need to enter?" },
        { Id = "permit", Text = "Here is my delivery permit." },
        { Id = "verify", Text = "Please check the royal seal." },
        { Id = "escort", Text = "You can escort me inside." },
        { Id = "flattery", Text = "Compliment the guard's reputation." },
        { Id = "authority", Text = "Invoke credible royal authority." },
        { Id = "joke", Text = "Try to make the guard laugh." },
        { Id = "bribe", Text = "Offer the guard some gold." },
    },
})