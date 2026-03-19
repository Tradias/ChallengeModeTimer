local addonName, addon = ...

addon.Constants = addon.Constants or {}

addon.LST = LibStub("ScrollingTable")

addon.LSM = LibStub("LibSharedMedia-3.0")

-- Challenge Mode dungeon info (Mists of Pandaria)
addon.Constants.CHALLENGE_MODE_DUNGEONS = {
    [960] = {
        englishName = "Temple of the Jade Serpent",
        medals = {
            title = 330,    -- 5:30
            platinum = 615, -- 10:15
            gold = 900,     -- 15:00
            silver = 1500,  -- 25:00
            bronze = 2700   -- 45:00
        },
    },
    [961] = {
        englishName = "Stormstout Brewery",
        medals = {
            title = 390,    -- 6:30
            platinum = 495, -- 8:15
            gold = 720,     -- 12:00
            silver = 1260,  -- 21:00
            bronze = 2700   -- 45:00
        },
    },
    [962] = {
        englishName = "Gate of the Setting Sun",
        medals = {
            title = 330,    -- 5:30
            platinum = 480, -- 8:00
            gold = 780,     -- 13:00
            silver = 1320,  -- 22:00
            bronze = 2700   -- 45:00
        },
    },
    [959] = {
        englishName = "Shado-Pan Monastery",
        medals = {
            title = 630,    -- 10:30
            platinum = 840, -- 14:00
            gold = 1260,    -- 21:00
            silver = 2100,  -- 35:00
            bronze = 3599   -- 59:59
        },
    },
    [1011] = {
        englishName = "Siege of Niuzao Temple",
        medals = {
            title = 615,    -- 10:15
            platinum = 735, -- 12:15
            gold = 1050,    -- 17:30
            silver = 1800,  -- 30:00
            bronze = 3000   -- 50:00
        },
    },
    [994] = {
        englishName = "Mogu'shan Palace",
        medals = {
            title = 405,    -- 6:45
            platinum = 495, -- 8:15
            gold = 720,     -- 12:00
            silver = 1440,  -- 24:00
            bronze = 2700   -- 45:00
        },
    },
    [1007] = {
        englishName = "Scholomance",
        medals = {
            title = 435,    -- 7:15
            platinum = 615, -- 10:15
            gold = 1140,    -- 19:00
            silver = 1980,  -- 33:00
            bronze = 3300   -- 55:00
        },
    },
    [1001] = {
        englishName = "Scarlet Halls",
        medals = {
            title = 255,    -- 4:15
            platinum = 480, -- 8:00
            gold = 780,     -- 13:00
            silver = 1320,  -- 22:00
            bronze = 2700   -- 45:00
        },
    },
    [1004] = {
        englishName = "Scarlet Monastery",
        medals = {
            title = 330,    -- 5:30
            platinum = 540, -- 9:00
            gold = 780,     -- 13:00
            silver = 1320,  -- 22:00
            bronze = 2700   -- 45:00
        },
    }
}

addon.Constants.CHALLENGE_MODE_DIFFICULTY_ID = 8

function addon.Constants:Init()
    addon.Constants.FONT = addon.LSM:Fetch("font", "2002") or "Fonts\\2002.TTF"
    local fontObject = CreateFont("ChallengeModeTimerDropdownFontObject")
    fontObject:SetFont(addon.Constants.FONT, 12, "")
    addon.Constants.FONT_OBJECT = fontObject
end
