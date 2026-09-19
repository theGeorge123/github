local CosmeticDefinitions = {}

local items = {
    frame_streak_3 = { Id = "frame_streak_3", Name = "Three-Day Resolve", Category = "ProfileFrames", Rarity = "Uncommon", Source = "DailyStreak", VIPOnly = false },
    title_streak_7 = { Id = "title_streak_7", Name = "Persistent", Category = "Titles", Rarity = "Rare", Source = "DailyStreak", VIPOnly = false },
    victory_streak_14 = { Id = "victory_streak_14", Name = "Fourteen Flames", Category = "VictoryFX", Rarity = "Epic", Source = "DailyStreak", VIPOnly = false },
    aura_streak_30 = { Id = "aura_streak_30", Name = "Thirty-Day Oracle", Category = "Auras", Rarity = "Legendary", Source = "DailyStreak", VIPOnly = false },
    vip_nameplate = { Id = "vip_nameplate", Name = "Observatory Member", Category = "Nameplates", Rarity = "VIP", Source = "VIP", VIPOnly = true },
    vip_aura = { Id = "vip_aura", Name = "Celestial Signal", Category = "Auras", Rarity = "VIP", Source = "VIP", VIPOnly = true },
    founder_title = { Id = "founder_title", Name = "Citadel Founder", Category = "Titles", Rarity = "Founder", Source = "Founder", VIPOnly = false },
}

local mastery = {
    frame = { Category = "ProfileFrames", Name = "Mastery Frame" },
    title = { Category = "Titles", Name = "Master of" },
    victory = { Category = "VictoryFX", Name = "Mastery Victory" },
    aura = { Category = "Auras", Name = "Mastery Aura" },
}

function CosmeticDefinitions.MasteryItem(kind, opponentId)
    assert(mastery[kind], "Unknown mastery cosmetic kind")
    return string.format("%s_mastery_%s", kind, opponentId)
end

function CosmeticDefinitions.Get(id)
    if items[id] then
        return items[id]
    end
    for prefix, template in pairs(mastery) do
        local marker = prefix .. "_mastery_"
        if string.sub(id, 1, #marker) == marker and #id > #marker then
            return {
                Id = id,
                Name = template.Name .. " " .. string.sub(id, #marker + 1),
                Category = template.Category,
                Rarity = "Mastery",
                Source = "Mastery",
                VIPOnly = false,
            }
        end
    end
    return nil
end

function CosmeticDefinitions.AllStatic()
    return items
end

return CosmeticDefinitions