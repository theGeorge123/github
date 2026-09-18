local Config = {}

Config.GameName = "Crystal Rush"
Config.Intermission = 15
Config.RoundDuration = 90
Config.CrystalCount = 45
Config.CrystalRespawnDelay = 2
Config.CoinReward = 5
Config.XPReward = 3
Config.RoundSurvivalCoins = 40
Config.RoundWinCoins = 100

Config.ArenaSize = 160
Config.ArenaY = 20
Config.HazardStartY = -4
Config.HazardEndY = 26

Config.BaseWalkSpeed = 16
Config.BaseJumpPower = 50

Config.Upgrades = {
    Speed = {
        maxLevel = 10,
        baseCost = 100,
        costGrowth = 1.55,
        valuePerLevel = 1.5,
    },
    Jump = {
        maxLevel = 10,
        baseCost = 100,
        costGrowth = 1.55,
        valuePerLevel = 4,
    },
    Magnet = {
        maxLevel = 10,
        baseCost = 125,
        costGrowth = 1.6,
        valuePerLevel = 3,
    },
}

function Config.getUpgradeCost(name, level)
    local data = Config.Upgrades[name]
    if not data then
        return math.huge
    end
    return math.floor(data.baseCost * (data.costGrowth ^ level))
end

return Config
