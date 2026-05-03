local _, addon = ...

addon.SplitProfile = addon.SplitProfile or {}

local DEFAULT_SPLIT_PROFILES = {
    [960] = { -- Temple of the Jade Serpent
        splits = {
            { name = "Wise Mari",            criteriaIndex = 1, criteriaId = 111686, totalQuantity = 1, encounterId = 1418 },
            { name = "Lorewalker Stonestep", criteriaIndex = 2, criteriaId = 20673,  totalQuantity = 1, encounterId = 1417 },
            { name = "Liu Flameheart",       criteriaIndex = 3, criteriaId = 19235,  totalQuantity = 1, encounterId = 1416 },
            { name = "Sha of Doubt",         criteriaIndex = 4, criteriaId = 19234,  totalQuantity = 1, encounterId = 1439 },
            { name = "Enemies",              criteriaIndex = 5, criteriaId = 0,      totalQuantity = 45 }
        }
    },
    [961] = { -- Stormstout Brewery
        splits = {
            { name = "Ook-ook",              criteriaIndex = 1, criteriaId = 19236, totalQuantity = 1, encounterId = 1412 },
            { name = "Hoptallus",            criteriaIndex = 2, criteriaId = 19237, totalQuantity = 1, encounterId = 1413 },
            { name = "Yan-Zhu the Uncasked", criteriaIndex = 3, criteriaId = 19108, totalQuantity = 1, encounterId = 1414 },
            { name = "Enemies",              criteriaIndex = 4, criteriaId = 0,     totalQuantity = 25 }
        }
    },
    [962] = { -- Gate of the Setting Sun
        splits = {
            { name = "Saboteur Kip'tilak", criteriaIndex = 1, criteriaId = 19245, totalQuantity = 1, encounterId = 1397 },
            { name = "Striker Ga'dok",     criteriaIndex = 2, criteriaId = 19246, totalQuantity = 1, encounterId = 1405 },
            { name = "Commander Ri'mok",   criteriaIndex = 3, criteriaId = 19247, totalQuantity = 1, encounterId = 1406 },
            { name = "Raigonn",            criteriaIndex = 4, criteriaId = 19248, totalQuantity = 1, encounterId = 1419 },
            { name = "Enemies",            criteriaIndex = 5, criteriaId = 0,     totalQuantity = 25 }
        }
    },
    [959] = { -- Shado-Pan Monastery
        splits = {
            { name = "Gu Cloudstrike",     criteriaIndex = 1, criteriaId = 19239, totalQuantity = 1, encounterId = 1303 },
            { name = "Master Snowdrift",   criteriaIndex = 2, criteriaId = 19244, totalQuantity = 1, encounterId = 1304 },
            { name = "Sha of Violence",    criteriaIndex = 3, criteriaId = 19240, totalQuantity = 1, encounterId = 1305 },
            { name = "Taran Zhu",          criteriaIndex = 4, criteriaId = 20672, totalQuantity = 1, encounterId = 1306 },
            { name = "Enemies",            criteriaIndex = 5, criteriaId = 0,     totalQuantity = 32 },
            { name = "Purified Defenders", criteriaIndex = 6, criteriaId = 21395, totalQuantity = 4 }
        }
    },
    [1011] = { -- Siege of Niuzao Temple
        splits = {
            { name = "Vizier Jin'bak",       criteriaIndex = 1, criteriaId = 19249, totalQuantity = 1, encounterId = 1465 },
            { name = "Commander Vo'jak",     criteriaIndex = 2, criteriaId = 19250, totalQuantity = 1, encounterId = 1502 },
            { name = "General Pa'valak",     criteriaIndex = 3, criteriaId = 19251, totalQuantity = 1, encounterId = 1447 },
            { name = "Wing Leader Ner'onok", criteriaIndex = 4, criteriaId = 19252, totalQuantity = 1, encounterId = 1464 },
            { name = "Enemies",              criteriaIndex = 5, criteriaId = 0,     totalQuantity = 65 }
        }
    },
    [994] = { -- Mogu'shan Palace
        splits = {
            { name = "Trial of the King",    criteriaIndex = 1, criteriaId = 20674, totalQuantity = 1, encounterId = 1442 },
            { name = "Gekkan",               criteriaIndex = 2, criteriaId = 20887, totalQuantity = 1, encounterId = 2129 },
            { name = "Xin the Weaponmaster", criteriaIndex = 3, criteriaId = 19257, totalQuantity = 1, encounterId = 1441 },
            { name = "Enemies",              criteriaIndex = 4, criteriaId = 0,     totalQuantity = 20 }
        }
    },
    [1007] = { -- Scholomance
        splits = {
            { name = "Instructor Chillheart", criteriaIndex = 1, criteriaId = 19259, totalQuantity = 1, encounterId = 1426 },
            { name = "Jandice Barov",         criteriaIndex = 2, criteriaId = 19260, totalQuantity = 1, encounterId = 1427 },
            { name = "Rattlegore",            criteriaIndex = 3, criteriaId = 19261, totalQuantity = 1, encounterId = 1428 },
            { name = "Lilian Voss",           criteriaIndex = 4, criteriaId = 19262, totalQuantity = 1, encounterId = 1429 },
            { name = "Darkmaster Gandling",   criteriaIndex = 5, criteriaId = 19263, totalQuantity = 1, encounterId = 1430 },
            { name = "Enemies",               criteriaIndex = 6, criteriaId = 0,     totalQuantity = 35 }
        }
    },
    [1001] = { -- Scarlet Halls
        splits = {
            { name = "Houndmaster Braun",   criteriaIndex = 1, criteriaId = 19266, totalQuantity = 1, encounterId = 1422 },
            { name = "Armsmaster Harlan",   criteriaIndex = 2, criteriaId = 19268, totalQuantity = 1, encounterId = 1421 },
            { name = "Flameweaver Koegler", criteriaIndex = 3, criteriaId = 19269, totalQuantity = 1, encounterId = 1420 },
            { name = "Enemies",             criteriaIndex = 4, criteriaId = 0,     totalQuantity = 50 }
        }
    },
    [1004] = { -- Scarlet Monastery
        splits = {
            { name = "Thalnos the Soulrender", criteriaIndex = 1, criteriaId = 19270, totalQuantity = 1, encounterId = 1423 },
            { name = "Brother Korloff",        criteriaIndex = 2, criteriaId = 19271, totalQuantity = 1, encounterId = 1424 },
            { name = "Durand and Whitemane",   criteriaIndex = 3, criteriaId = 533,   totalQuantity = 1, encounterId = 1425 },
            { name = "Enemies",                criteriaIndex = 4, criteriaId = 0,     totalQuantity = 40 }
        }
    }
}

local MAX_SPLIT_NAME_WIDTH = 0
for _, splitProfile in pairs(DEFAULT_SPLIT_PROFILES) do
    for _, splitDefinition in ipairs(splitProfile.splits) do
        local width = addon.Utility:GetTextWidth(splitDefinition.name)
        if width > MAX_SPLIT_NAME_WIDTH then
            MAX_SPLIT_NAME_WIDTH = width
        end
    end
end

local DOT_DOT_DOT_WIDTH = addon.Utility:GetTextWidth("...")

local function FormatSplitLabel(split, splitDefinition, abbreviate)
    local totalQuantity = splitDefinition.totalQuantity
    local currentQuantity = split.quantity
    local splitLength = ""
    if split.duration ~= 0 and split.startDuration then
        splitLength = string.format(" (%ds)", math.floor(split.duration - split.startDuration + 0.5))
    end
    local splitName = splitDefinition.name
    if abbreviate then
        local splitNameWidth = addon.Utility:GetTextWidth(splitName)
        local overflow = math.max(0, splitNameWidth + addon.Utility:GetTextWidth(splitLength) - MAX_SPLIT_NAME_WIDTH)
        if overflow > 0 then
            splitName = addon.Utility:ShortenTextToWidth(splitName, splitNameWidth - overflow - DOT_DOT_DOT_WIDTH) ..
                "..."
        end
    end
    return string.format("%d/%d %s%s", currentQuantity, totalQuantity, splitName, splitLength)
end

function addon.SplitProfile:Get(instanceId)
    return DEFAULT_SPLIT_PROFILES[instanceId]
end

function addon.SplitProfile:CreateSplit()
    return {
        completed = false,
        duration = 0,
        quantity = 0
    }
end

function addon.SplitProfile:IsEnemyCount(splitDefinition)
    return splitDefinition.criteriaId == 0
end

function addon.SplitProfile:FormatSplitLabel(split, splitDefinition)
    return FormatSplitLabel(split, splitDefinition, false)
end

function addon.SplitProfile:FormatAbbreviatedSplitLabel(split, splitDefinition)
    return FormatSplitLabel(split, splitDefinition, true)
end
