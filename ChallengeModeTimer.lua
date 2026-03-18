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
    if addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId] then
        addon.RunHistoryUI.selectedInstanceId = instanceId
    end
end

local function EnsureUIIsInitialized()
    if addon.OptionsUI and addon.OptionsUI:Get() then
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
    end

    if addon.OptionsUI.optionsFrame:IsShown() then
        addon.OptionsUI:Hide()
    else
        SelectCurrentInstanceInRunHistory()
        addon.OptionsUI:Show()
    end
end

local function InitializeAddon()
    if not ChallengeModeTimerDB then
        ChallengeModeTimerDB = {}
    end

    addon.Migrations:Run()

    HideBlizzardChallengeModeTimer()
    addon.Constants:Init()
    addon.RunHistory:Init()
    addon.RunUI:Init()
    addon.Run:Init()

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
