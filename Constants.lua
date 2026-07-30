---@type string, ChallengeModeTimerAddon
local _, addon = ...

---@class ConstantsModule
addon.Constants = addon.Constants or {}

addon.LST = LibStub("ScrollingTable")

addon.LSM = LibStub("LibSharedMedia-3.0")

function addon.Constants:Init()
    addon.Constants.DEFAULT_FONT_NAME = "DejaVu Sans"
    addon.Constants.FONT = "Interface\\Addons\\ChallengeModeTimer\\Media\\Fonts\\DejaVuLGCSans.ttf"
    addon.LSM:Register("font", addon.Constants.DEFAULT_FONT_NAME, addon.Constants.FONT)

    local fontObject = CreateFont("ChallengeModeTimerFontObject")
    fontObject:SetFont(addon.Constants.FONT, 13, "")
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
