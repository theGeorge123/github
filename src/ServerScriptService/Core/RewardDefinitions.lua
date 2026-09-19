return {
    Insight = {
        RankedCompletion = 8,
        RankedWin = 12,
        FirstWinOfDay = 10,
        DailyCompletion = 20,
        DailyWin = 10,
        DailyPractice = 3,
        VIPMultiplier = 1.25,
    },
    Mastery = {
        AttemptXP = 10,
        WinXP = 30,
        Thresholds = {
            [0] = 0,
            [1] = 40,
            [2] = 100,
            [3] = 200,
            [4] = 350,
        },
        Milestones = {
            [1] = "frame",
            [2] = "title",
            [3] = "victory",
            [4] = "aura",
        },
    },
    DailyStreak = {
        [1] = { Insight = 10 },
        [3] = { Item = "frame_streak_3" },
        [7] = { Item = "title_streak_7" },
        [14] = { Item = "victory_streak_14" },
        [30] = { Item = "aura_streak_30" },
    },
}