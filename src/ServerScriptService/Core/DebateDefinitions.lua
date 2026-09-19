local Definitions = {}

Definitions.Turns = 4
Definitions.Characters = table.freeze({
    Rivet = table.freeze({
        Id = "Rivet", Topic = "Should hints be optional in building games?", Position = "Hints should stay available but optional.",
        Voice = "Precise and practical", Accent = "CYAN", Silhouette = "antenna",
        Opening = "Optional hints protect new builders without slowing experts.",
        Replies = table.freeze({
            "You say choice prevents frustration. How would you stop players from missing tools they need?",
            "That example supports flexibility, but it does not show whether beginners recognize when to ask for help.",
            "Your claim is that control improves learning. I concede control matters; I still think discoverability matters too.",
            "My position remains: keep hints available and optional, with a clear way to request them.",
        }),
    }),
    Pip = table.freeze({
        Id = "Pip", Topic = "Should build challenges limit the number of pieces?", Position = "Challenges should use a clear piece limit.",
        Voice = "Fast, playful, constraint-driven", Accent = "GOLD", Silhouette = "square",
        Opening = "A piece limit makes every choice count and keeps judging fair.",
        Replies = table.freeze({
            "You value creative freedom. What makes an unlimited build comparable to a compact one?",
            "Your example shows scale can be fun, but the challenge still needs a shared constraint.",
            "I accept that limits can block one idea. My rebuttal is that constraints can create different ideas.",
            "I keep the piece limit because it makes the challenge readable, fair, and replayable.",
        }),
    }),
    Moss = table.freeze({
        Id = "Moss", Topic = "Should team games show individual contribution scores?", Position = "Show contribution privately, not as a public leaderboard.",
        Voice = "Calm and reflective", Accent = "GREEN", Silhouette = "round",
        Opening = "Private contribution feedback helps players improve without turning teammates against each other.",
        Replies = table.freeze({
            "You want recognition for effort. How would a public score account for quiet support work?",
            "That example rewards visible actions, but it may miss planning, teaching, or recovery.",
            "I concede public praise can motivate. My claim is that private detail protects cooperation better.",
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
