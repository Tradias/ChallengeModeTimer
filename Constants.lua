local addonName, addon = ...

addon.Constants = addon.Constants or {}

addon.LST = LibStub("ScrollingTable")

addon.LSM = LibStub("LibSharedMedia-3.0")

addon.Constants.CHALLENGE_MODE_DIFFICULTY_ID = 8

-- Challenge Mode dungeon info (Mists of Pandaria)
addon.Constants.CHALLENGE_MODE_DUNGEONS = {
    [960] = {
        englishName = "Temple of the Jade Serpent",
        medals = {
            330,  -- title 5:30
            615,  -- platinum 10:15
            900,  -- gold 15:00
            1500, -- silver 25:00
            2700  -- bronze 45:00
        },
    },
    [961] = {
        englishName = "Stormstout Brewery",
        medals = {
            390,  -- title 6:30
            495,  -- platinum 8:15
            720,  -- gold 12:00
            1260, -- silver 21:00
            2700  -- bronze 45:00
        },
    },
    [962] = {
        englishName = "Gate of the Setting Sun",
        medals = {
            330,  -- title 5:30
            480,  -- platinum 8:00
            780,  -- gold 13:00
            1320, -- silver 22:00
            2700  -- bronze 45:00
        },
    },
    [959] = {
        englishName = "Shado-Pan Monastery",
        medals = {
            630,  -- title 10:30
            840,  -- platinum 14:00
            1260, -- gold 21:00
            2100, -- silver 35:00
            3599  -- bronze 59:59
        },
    },
    [1011] = {
        englishName = "Siege of Niuzao Temple",
        medals = {
            615,  -- title 10:15
            735,  -- platinum 12:15
            1050, -- gold 17:30
            1800, -- silver 30:00
            3000  -- bronze 50:00
        },
    },
    [994] = {
        englishName = "Mogu'shan Palace",
        medals = {
            405,  -- title 6:45
            495,  -- platinum 8:15
            720,  -- gold 12:00
            1440, -- silver 24:00
            2700  -- bronze 45:00
        },
    },
    [1007] = {
        englishName = "Scholomance",
        medals = {
            435,  -- title 7:15
            615,  -- platinum 10:15
            1140, -- gold 19:00
            1980, -- silver 33:00
            3300  -- bronze 55:00
        },
    },
    [1001] = {
        englishName = "Scarlet Halls",
        medals = {
            255,  -- title 4:15
            480,  -- platinum 8:00
            780,  -- gold 13:00
            1320, -- silver 22:00
            2700  -- bronze 45:00
        },
    },
    [1004] = {
        englishName = "Scarlet Monastery",
        medals = {
            330,  -- title 5:30
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

for _, dungeonData in pairs(addon.Constants.CHALLENGE_MODE_DUNGEONS) do
    local medals = dungeonData.medals
    dungeonData.formattedMedalTimes = {
        FormatMedalTime(medals[1]),
        FormatMedalTime(medals[2]),
        FormatMedalTime(medals[3]),
        FormatMedalTime(medals[4]),
        FormatMedalTime(medals[5]),
    }
end

addon.Constants.MEDAL_LABELS = {
    "Title?",
    "Plat",
    "Gold",
    "Silver",
    "Bronze"
}

addon.Constants.MEDAL_COLORS = {
    { 0.3,  0.8,  1 },    -- title
    { 0.9,  0.9,  1 },    -- platinum
    { 1,    0.82, 0 },    -- gold
    { 0.85, 0.85, 0.85 }, -- silver
    { 0.8,  0.55, 0.25 }  -- bronze
}

function addon.Constants:Init()
    addon.Constants.FONT = addon.LSM:Fetch("font", "2002") or "Fonts\\2002.TTF"
    local fontObject = CreateFont("ChallengeModeTimerDropdownFontObject")
    fontObject:SetFont(addon.Constants.FONT, 12, "")
    addon.Constants.FONT_OBJECT = fontObject
end

function addon.Constants:GetMedalInfo(instanceId, runDuration)
    local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
    for index, medalTime in ipairs(dungeonData.medals) do
        if runDuration < medalTime then
            local label = addon.Constants.MEDAL_LABELS[index]
            local color = addon.Constants.MEDAL_COLORS[index]
            local timeText = dungeonData.formattedMedalTimes[index]
            return label, color, timeText
        end
    end
    return nil, nil, nil
end
