local _, addon = ...

addon.Constants = addon.Constants or {}

addon.LST = LibStub("ScrollingTable")

addon.LSM = LibStub("LibSharedMedia-3.0")

function addon.Constants:Init()
    addon.Constants.FONT = addon.LSM:Fetch("font", "2002") or "Fonts\\2002.TTF"
    local fontObject = CreateFont("ChallengeModeTimerDropdownFontObject")
    fontObject:SetFont(addon.Constants.FONT, 12, "")
    addon.Constants.FONT_OBJECT = fontObject
end

addon.Constants.CLASS_FILE_TO_CLASS_ID = {
    ["WARRIOR"] = 1,
    ["PALADIN"] = 2,
    ["HUNTER"] = 3,
    ["ROGUE"] = 4,
    ["PRIEST"] = 5,
    ["DEATHKNIGHT"] = 6,
    ["SHAMAN"] = 7,
    ["MAGE"] = 8,
    ["WARLOCK"] = 9,
    ["MONK"] = 10,
    ["DRUID"] = 11,
}
