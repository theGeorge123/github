return table.freeze({
    CharacterId = "rivet",
    TopicId = "optional_hints",
    CharacterPosition = "Optional hints should unlock after two attempts.",
    PlayerPosition = "Optional hints should be available immediately.",
    Exchanges = table.freeze({
        table.freeze({
            Id = "P1",
            Text = "Immediate optional hints let each player choose the support they need.",
        }),
        table.freeze({
            Id = "P2",
            Text = "Players who want discovery can ignore them, while others avoid getting stuck.",
        }),
        table.freeze({
            Id = "P3",
            Text = "Reply to my choice argument and explain one trade-off without inventing facts.",
        }),
    }),
})
