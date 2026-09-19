local Definitions = {}

Definitions.Turns = 4
Definitions.Characters = table.freeze({
    Rivet = table.freeze({
        Id = "Rivet", Topic = "Should hints be optional in building games?", Position = "Hints should stay available but optional.", PlayerPosition = "Hints should be off unless a player asks for them.",
        Voice = "Precise and practical", Accent = "CYAN", Silhouette = "antenna",
        Opening = "Optional hints protect new builders without slowing experts.",
        Replies = table.freeze({
            "Practice prompt: explain how players would discover tools they do not know exist.",
            "Practice prompt: compare player control with the needs of a first-time builder.",
            "Practice prompt: address the trade-off between control and discoverability.",
            "My position remains: keep hints available and optional, with a clear way to request them.",
        }),
    }),
    Pip = table.freeze({
        Id = "Pip", Topic = "Should build challenges limit the number of pieces?", Position = "Challenges should use a clear piece limit.", PlayerPosition = "Build challenges should allow unlimited pieces.",
        Voice = "Fast, playful, constraint-driven", Accent = "GOLD", Silhouette = "square",
        Opening = "A piece limit makes every choice count and keeps judging fair.",
        Replies = table.freeze({
            "Practice prompt: explain how unlimited and compact builds could be judged fairly.",
            "Practice prompt: compare creative scale with a shared challenge constraint.",
            "Practice prompt: address whether constraints block ideas or create different ideas.",
            "I keep the piece limit because it makes the challenge readable, fair, and replayable.",
        }),
    }),
    Moss = table.freeze({
        Id = "Moss", Topic = "Should team games show individual contribution scores?", Position = "Show contribution privately, not as a public leaderboard.", PlayerPosition = "Team games should show individual contribution publicly.",
        Voice = "Calm and reflective", Accent = "GREEN", Silhouette = "round",
        Opening = "Private contribution feedback helps players improve without turning teammates against each other.",
        Replies = table.freeze({
            "Practice prompt: explain how a public score could account for quiet support work.",
            "Practice prompt: compare visible actions with planning, teaching, and recovery.",
            "Practice prompt: address the trade-off between public motivation and cooperation.",
            "My position remains private feedback: useful evidence for the player without a public blame board.",
        }),
    }),
})

Definitions.Order = table.freeze({ "Rivet", "Pip", "Moss" })
Definitions.Rubric = table.freeze({
    { Name = "Relevance", Weight = 20, Hint = "Addresses the topic and the other side." },
    { Name = "Reasoning", Weight = 30, Hint = "Connects claims to clear reasons." },
    { Name = "Evidence / examples", Weight = 20, Hint = "Uses fitting examples without inventing facts." },
    { Name = "Rebuttal / consistency", Weight = 30, Hint = "Answers claims and stays consistent." },
})
return Definitions
