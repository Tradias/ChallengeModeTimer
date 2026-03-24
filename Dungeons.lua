local _, addon = ...

addon.Dungeons = addon.Dungeons or {}

-- Challenge Mode dungeon info (Mists of Pandaria)
local CHALLENGE_MODE_DUNGEONS = {
    [960] = {
        name = "Temple of the Jade Serpent",
        medals = {
            480,  -- title 8:00
            615,  -- platinum 10:15
            900,  -- gold 15:00
            1500, -- silver 25:00
            2700  -- bronze 45:00
        },
    },
    [961] = {
        name = "Stormstout Brewery",
        medals = {
            375,  -- title 6:15
            495,  -- platinum 8:15
            720,  -- gold 12:00
            1260, -- silver 21:00
            2700  -- bronze 45:00
        },
    },
    [962] = {
        name = "Gate of the Setting Sun",
        medals = {
            315,  -- title 5:15
            480,  -- platinum 8:00
            780,  -- gold 13:00
            1320, -- silver 22:00
            2700  -- bronze 45:00
        },
    },
    [959] = {
        name = "Shado-Pan Monastery",
        medals = {
            600,  -- title 10:00
            840,  -- platinum 14:00
            1260, -- gold 21:00
            2100, -- silver 35:00
            3599  -- bronze 59:59
        },
    },
    [1011] = {
        name = "Siege of Niuzao Temple",
        medals = {
            585,  -- title 9:45
            735,  -- platinum 12:15
            1050, -- gold 17:30
            1800, -- silver 30:00
            3000  -- bronze 50:00
        },
    },
    [994] = {
        name = "Mogu'shan Palace",
        medals = {
            380,  -- title 6:20
            495,  -- platinum 8:15
            720,  -- gold 12:00
            1440, -- silver 24:00
            2700  -- bronze 45:00
        },
    },
    [1007] = {
        name = "Scholomance",
        medals = {
            405,  -- title 6:45
            615,  -- platinum 10:15
            1140, -- gold 19:00
            1980, -- silver 33:00
            3300  -- bronze 55:00
        },
    },
    [1001] = {
        name = "Scarlet Halls",
        medals = {
            240,  -- title 4:00
            480,  -- platinum 8:00
            780,  -- gold 13:00
            1320, -- silver 22:00
            2700  -- bronze 45:00
        },
    },
    [1004] = {
        name = "Scarlet Monastery",
        medals = {
            315,  -- title 5:15
            540,  -- platinum 9:00
            780,  -- gold 13:00
            1320, -- silver 22:00
            2700  -- bronze 45:00
        },
    }
}

local function FormatMedalTime(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", minutes, secs)
end

for _, dungeon in pairs(CHALLENGE_MODE_DUNGEONS) do
    local medals = dungeon.medals
    dungeon.formattedMedalTimes = {
        FormatMedalTime(medals[1]),
        FormatMedalTime(medals[2]),
        FormatMedalTime(medals[3]),
        FormatMedalTime(medals[4]),
        FormatMedalTime(medals[5]),
    }
end

local MEDAL_LABELS = {
    "Title?",
    "Plat",
    "Gold",
    "Silver",
    "Bronze",
    "No Medal"
}

local MEDAL_LABELS_LOWERCASE = {
    ["title"] = true
}

for _, label in ipairs(MEDAL_LABELS) do
    MEDAL_LABELS_LOWERCASE[string.lower(label)] = true
end

local MEDAL_COLORS = {
    { 0.3,  0.8,  1 },    -- title
    { 0.9,  0.9,  1 },    -- platinum
    { 1,    0.82, 0 },    -- gold
    { 0.85, 0.85, 0.85 }, -- silver
    { 0.8,  0.55, 0.25 }, -- bronze
    { 1,    1,    1 },    -- no medal
}

local NO_MEDAL_INDEX = 6

addon.Dungeons.INCOMPLETE_MEDAL_INDEX = 7

addon.Dungeons.CHALLENGE_MODE_DIFFICULTY_ID = 8

function addon.Dungeons:Get(instanceId)
    if instanceId then
        return CHALLENGE_MODE_DUNGEONS[instanceId]
    end
    return CHALLENGE_MODE_DUNGEONS
end

function addon.Dungeons:GetMedalIndexByDuration(instanceId, runDuration)
    local dungeon = CHALLENGE_MODE_DUNGEONS[instanceId]
    for index, medalTime in ipairs(dungeon.medals) do
        if runDuration < medalTime then
            return index
        end
    end
    return NO_MEDAL_INDEX
end

function addon.Dungeons:GetMedalLabelByIndex(medalIndex)
    return MEDAL_LABELS[medalIndex]
end

function addon.Dungeons:GetMedalColorByIndex(medalIndex)
    return MEDAL_COLORS[medalIndex]
end

function addon.Dungeons:GetMedalInfoByDuration(instanceId, runDuration)
    local medalIndex = addon.Dungeons:GetMedalIndexByDuration(instanceId, runDuration)
    local label = MEDAL_LABELS[medalIndex]
    local color = MEDAL_COLORS[medalIndex]
    local dungeon = CHALLENGE_MODE_DUNGEONS[instanceId]
    local timeText = dungeon.formattedMedalTimes[medalIndex]
    return label, color, timeText
end

function addon.Dungeons:IsMedalLabel(text)
    return not not MEDAL_LABELS_LOWERCASE[text]
end
