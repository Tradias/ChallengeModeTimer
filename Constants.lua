local addonName, addon = ...

addon.Constants = addon.Constants or {}

addon.LST = LibStub("ScrollingTable")

addon.LSM = LibStub("LibSharedMedia-3.0")

function addon.Constants:Init()
    addon.Constants.FONT = addon.LSM:Fetch("font", "2002") or "Fonts\\2002.TTF"
    local fontObject = CreateFont("ChallengeModeTimerDropdownFontObject")
    fontObject:SetFont(addon.Constants.FONT, 12, "")
    addon.Constants.FONT_OBJECT = fontObject
end
