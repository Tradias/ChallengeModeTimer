local addonName, addon = ...

local function HideBlizzardChallengeModeTimer()
    if WatchFrame then
        WatchFrame:SetScript("OnEvent", nil)
        WatchFrame:Hide()
    end
end

local function SelectCurrentInstanceInRunHistory()
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    addon.RunHistoryUI:SetSelectedInstance(instanceId)
end

local function EnsureUIIsInitialized()
    if addon.OptionsUI:Get() then
        return
    end

    addon.OptionsUI:Init()
    addon.RunHistoryUI:Init()
    addon.AppearanceUI:Init()
end

local function OnSlashCommand(msg)
    EnsureUIIsInitialized()

    msg = strtrim(msg):lower()

    if msg == "history" then
        addon.RunHistory:InsertSampleRuns()
        return
    elseif msg == "test" then
        addon.Run:SetSampleRun()
        addon.RunUI:Show()
        return
    elseif msg == "debug" then
        addon.Utility:ToggleDebugMode()
        return
    elseif msg ~= "" then
        local number = tonumber(msg)
        if number then
            addon.Run:SetSampleRun(number)
            addon.RunUI:Show()
            return
        end
    end

    if addon.OptionsUI.optionsFrame:IsShown() then
        addon.OptionsUI:Hide()
    else
        SelectCurrentInstanceInRunHistory()
        addon.OptionsUI:Show()
    end
end

local function RegisterInterfaceOptions()
    local panel = CreateFrame("Frame", "ChallengeModeTimerOptionsPanel", UIParent)

    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetPoint("CENTER")
    button:SetSize(180, 50)
    button:SetText("/cmt")
    local fontObject = CreateFont("ChallengeModeTimerOptionsPanelButtonFont")
    fontObject:SetFont(addon.Constants.FONT, 32, "")
    button:SetNormalFontObject(fontObject)
    button:SetHighlightFontObject(fontObject)
    button:SetScript("OnClick", function() OnSlashCommand("") end)

    local category = Settings.RegisterCanvasLayoutCategory(panel, addonName)
    Settings.RegisterAddOnCategory(category)
end

local function InitializeAddon()
    if not ChallengeModeTimerDB then
        ChallengeModeTimerDB = {}
    end

    ChallengeModeTimerDB.version = 1

    HideBlizzardChallengeModeTimer()
    addon.Constants:Init()
    addon.RunHistory:Init()
    addon.RunUI:Init()
    addon.Run:Init()
    RegisterInterfaceOptions()

    SLASH_CHALLENGEMODETIMER1 = "/cmt"
    SlashCmdList["CHALLENGEMODETIMER"] = OnSlashCommand
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(_, _, loadedAddon)
    if loadedAddon == addonName then
        InitializeAddon()
        initFrame:UnregisterAllEvents()
    end
end)
