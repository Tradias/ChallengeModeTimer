local _, addon = ...

LoadAddOn("Blizzard_DebugTools")

addon.Run = addon.Run or {}

local g_runs = {}
local g_currentRun = nil
local g_currentInstanceId = 0
local g_ticker = nil
local g_watchFrameWasShown = nil
local g_watchFrameScript = nil

local function HideBlizzardChallengeModeTimer()
    if WatchFrame then
        g_watchFrameScript = WatchFrame:GetScript("OnEvent")
        g_watchFrameWasShown = WatchFrame:IsShown()
        WatchFrame:SetScript("OnEvent", nil)
        WatchFrame:Hide()
    end
end

local function RestoreBlizzardChallengeModeTimer()
    if WatchFrame then
        WatchFrame:SetScript("OnEvent", g_watchFrameScript)
        if g_watchFrameWasShown then
            WatchFrame:Show()
        end
    end
end

local function InitializeRuns()
    for instanceId, _ in pairs(addon.Dungeons:Get()) do
        local currentRun = addon.RunHistory:GetCurrentRun(instanceId)
        -- Making a deep copy to ensure we are not hammering at ChallengeModeTimerDB while the run is running
        g_runs[instanceId] = addon.Utility:DeepCopy(currentRun)
    end
end

local function CreateRunSplits(run)
    run.splits = {}
    local splitProfile = addon.SplitProfile:Get(run.state.instanceId)
    for _, _ in ipairs(splitProfile.splits) do
        table.insert(run.splits, addon.SplitProfile:CreateSplit())
    end
end

local function CreateRunState(instanceId)
    return {
        instanceId = instanceId,
        active = false,
        running = false,
        startTime = 0,                -- GetTime()
        isStartTimeAccurate = false,
        lastSeenWorldElapsedTime = 0, -- GetWorldElapsedTime(1)
        pendingSplitUpdateIndices = {}
    }
end

local function InActiveChallengeMode()
    local _, _, timerType = GetWorldElapsedTime(1)
    return timerType == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE
end

local function InChallengeMode()
    -- Only works for CMs that have been started once after logging in
    local scenarioType = select(10, C_Scenario.GetInfo())
    return scenarioType == LE_SCENARIO_TYPE_CHALLENGE_MODE
end

local function WoWGetWorldElapsedTime()
    local _, worldElapsedTime = GetWorldElapsedTime(1)
    return worldElapsedTime
end

local function SetDurationFromNow(run)
    run.duration = addon.Utility:RoundDuration(GetTime() - run.state.startTime)
end

local function SetStartTime(run, startTime)
    run.state.startTime = startTime
    SetDurationFromNow(run)
end

local function BuildRunners()
    local runners = {}
    for _, unit in ipairs({ "player", "party1", "party2", "party3", "party4" }) do
        local name = UnitName(unit)
        local _, classId = UnitClassBase(unit)
        if name and classId then
            table.insert(runners, {
                name = name,
                classId = classId
            })
        end
    end
    return runners
end

local function BuildRunnersFromChallengeCompletionInfo(challengeCompletionInfo)
    local playerName = UnitName("player")
    local _, playerClassId = UnitClassBase("player")
    local runners = {
        { name = playerName, classId = playerClassId }
    }
    local members = challengeCompletionInfo.members
    for _, member in ipairs(members) do
        if member.name ~= playerName then
            local _, classFile = GetPlayerInfoByGUID(member.memberGUID)
            table.insert(runners, {
                name = member.name,
                classId = addon.Constants.CLASS_FILE_TO_CLASS_ID[classFile]
            })
        end
    end
    return runners
end

local function SetCurrentRun(run)
    g_currentRun = run
    addon.RunUI:SetRun(g_currentRun)
end

local function SetCurrentIfActiveOrPreviousRun(run)
    if run.state.active then
        SetCurrentRun(run)
        return
    end
    local previousRun = addon.RunHistory:GetPreviousRun(run.state.instanceId)
    if previousRun then
        previousRun = addon.Utility:DeepCopy(previousRun)
        previousRun.state = CreateRunState(run.state.instanceId)
        SetCurrentRun(previousRun)
    else
        SetCurrentRun(run)
    end
end

local function CancelTicker()
    if g_ticker then
        g_ticker:Cancel()
        g_ticker = nil
    end
end

local function OnTimerTick(run)
    SetDurationFromNow(run)
    addon.RunUI:UpdateTimerText(run.duration)
end

local function StartTimer(run)
    OnTimerTick(run)
    g_ticker = C_Timer.NewTicker(0.1, (function() OnTimerTick(run) end))
end

local function ChangeRunning(run, isRunning)
    run.state.running = isRunning
    if isRunning then
        StartTimer(run)
    else
        CancelTicker()
    end
end

local function HasPendingSplitUpdate(run, index)
    for _, splitUpdateIndex in ipairs(run.state.pendingSplitUpdateIndices) do
        if splitUpdateIndex == index then
            return true
        end
    end
    return false
end

local function AddPendingSplitUpdate(run, index)
    if HasPendingSplitUpdate(run, index) then
        return
    end
    table.insert(run.state.pendingSplitUpdateIndices, index)
end

local function HasOnlyOneIncompleteSplit(run)
    local count = 0
    for _, split in ipairs(run.splits) do
        if not split.completed then
            if count == 1 then
                return false
            end
            count = count + 1
        end
    end
    return count == 1
end

local function UpdateSplitDuration(run, split, criteriaInfo)
    split.duration = addon.Utility:RoundDuration(GetTime() - run.state.startTime - criteriaInfo.elapsed)
end

local function UpdateSplit(run, split, splitDefinition)
    local isUpdated = false
    local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(splitDefinition.criteriaIndex)
    if not criteriaInfo then
        return isUpdated
    end
    addon.Utility:DebugPrint("split completed: " .. tostring(split.completed) .. " criteriaID: " ..
        criteriaInfo.criteriaID ..
        " completed: " ..
        tostring(criteriaInfo.completed) ..
        " elapsed: " ..
        criteriaInfo.elapsed ..
        "s/" ..
        WoWGetWorldElapsedTime() ..
        "s " ..
        criteriaInfo.quantity ..
        "/" ..
        criteriaInfo.totalQuantity .. " run.state.isStartTimeAccurate: " .. tostring(run.state.isStartTimeAccurate))
    if split.quantity < criteriaInfo.quantity then
        isUpdated = true
        split.quantity = criteriaInfo.quantity
    end
    if criteriaInfo.completed then
        isUpdated = (split.quantity < splitDefinition.totalQuantity)
        split.quantity = splitDefinition.totalQuantity
    end
    if not split.completed and criteriaInfo.completed then
        if HasOnlyOneIncompleteSplit(run) then
            return isUpdated
        end
        split.completed = true
        isUpdated = true
        if run.state.isStartTimeAccurate then
            UpdateSplitDuration(run, split, criteriaInfo)
        elseif splitDefinition.criteriaId ~= 20673 then -- Lorewalker Stonestep `criteriaInfo.elapsed` is always 0
            AddPendingSplitUpdate(run, splitDefinition.criteriaIndex)
        end
    end
    return isUpdated
end

local function UpdatePendingSplits(run)
    local pendingSplitUpdateIndices = run.state.pendingSplitUpdateIndices
    local needsUIUpdate = #pendingSplitUpdateIndices > 0
    run.state.pendingSplitUpdateIndices = {}
    for _, splitUpdateIndex in ipairs(pendingSplitUpdateIndices) do
        local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(splitUpdateIndex)
        UpdateSplitDuration(run, run.splits[splitUpdateIndex], criteriaInfo)
    end
    if needsUIUpdate then
        addon.RunUI:UpdateSplits()
    end
end

local function UpdateCriteriaSplit(criteriaId)
    local run = g_runs[g_currentInstanceId]
    local splitProfile = addon.SplitProfile:Get(g_currentInstanceId)
    for index, splitDefinition in ipairs(splitProfile.splits) do
        if splitDefinition.criteriaId == criteriaId then
            return UpdateSplit(run, run.splits[index], splitDefinition)
        end
    end
    for index, splitDefinition in ipairs(splitProfile.splits) do
        if addon.SplitProfile:IsEnemyCount(splitDefinition) then
            return UpdateSplit(run, run.splits[index], splitDefinition)
        end
    end
    return false
end

local function CompleteFinalSplit(run)
    -- Set duration of the final split but only if there is only one incomplete split
    local splitProfile = addon.SplitProfile:Get(run.state.instanceId)
    local finalSplit
    local incompleteSplitCount = 0
    for index, split in ipairs(run.splits) do
        if not split.completed then
            incompleteSplitCount = incompleteSplitCount + 1
            split.completed = true
            local splitDefinition = splitProfile.splits[index]
            split.quantity = splitDefinition.totalQuantity
            finalSplit = split
        end
    end
    if incompleteSplitCount == 1 then
        finalSplit.duration = run.duration
    end
end

local function OnRunStart(run, worldElapsedTime)
    run.state.active = true
    SetStartTime(run, GetTime() - worldElapsedTime)
    run.state.isStartTimeAccurate = true
    UpdatePendingSplits(run)
    run.startTimestamp = time() - worldElapsedTime
    run.runners = BuildRunners()
    ChangeRunning(run, true)
    addon.RunUI:Show()
end

local function OnTimerCalibrationTick(run)
    local _, worldElapsedTime, timerType = GetWorldElapsedTime(1)
    if timerType ~= LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE then
        CancelTicker()
        return
    end
    if worldElapsedTime > run.state.lastSeenWorldElapsedTime then
        CancelTicker()
        OnRunStart(run, worldElapsedTime)
    end
end

local function StartTimerCalibration(run)
    SetCurrentRun(run)
    local worldElapsedTime = WoWGetWorldElapsedTime()
    if worldElapsedTime == 0 then
        OnRunStart(run, worldElapsedTime)
        return
    end
    CancelTicker()
    run.state.isStartTimeAccurate = false
    run.state.lastSeenWorldElapsedTime = worldElapsedTime
    g_ticker = C_Timer.NewTicker(0.1, (function() OnTimerCalibrationTick(run) end))
end

local function OnRunEnd(run, challengeCompletionInfo)
    run.state.active = false
    local instanceId = run.state.instanceId
    if challengeCompletionInfo then
        run.completed = true
        run.duration = challengeCompletionInfo.time / 1000
        run.medalIndex = addon.Dungeons:GetMedalIndexByDurationOrKeystoneUpgradeLevel(instanceId, run.duration,
            challengeCompletionInfo.keystoneUpgradeLevels)
        run.runners = BuildRunnersFromChallengeCompletionInfo(challengeCompletionInfo)
        CompleteFinalSplit(run)
    end
    local nextRun = addon.RunHistory:PersistCurrentRun(run)
    nextRun = addon.Utility:DeepCopy(nextRun)
    g_runs[instanceId] = nextRun
    SetCurrentIfActiveOrPreviousRun(nextRun)
end

local function MaybeEndRun(run, challengeCompletionInfo)
    ChangeRunning(run, false)
    if run.state.active then
        OnRunEnd(run, challengeCompletionInfo)
    end
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function OnChallengeModeReset()
    -- Also fired when starting a CM.
    local run = g_runs[g_currentInstanceId]
    if not run then
        print("Challenge reset outside of dungeon - please report bug")
        return
    end
    MaybeEndRun(run)
end

local function OnChallengeModeCompleted()
    local challengeCompletionInfo = C_ChallengeMode.GetChallengeCompletionInfo()
    addon.Utility:DebugPrint(challengeCompletionInfo)
    local instanceId = addon.Dungeons:GetInstanceIdByChallengeModeMapId(challengeCompletionInfo.mapChallengeModeID)
    if not instanceId then
        return
    end
    local run = g_runs[instanceId]
    if not run then
        return
    end
    MaybeEndRun(run, challengeCompletionInfo)
end

local function OnPlayerEnteringWorld(isInitialLogin, isReloadUI)
    -- InActiveChallengeMode() will always be false when entering a dungeon.
    -- WORLD_STATE_TIMER_START will always fire after entering world but SCENARIO_CRITERIA_UPDATE may fire before.
    -- difficultyId is always wrong when entering a dungeon.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    local run = g_runs[g_currentInstanceId]
    if not run then
        if g_currentRun and g_currentRun.state.running then
            addon.RunUI:Show()
        else
            addon.RunUI:Hide()
        end
        RestoreBlizzardChallengeModeTimer()
        return
    end
    HideBlizzardChallengeModeTimer()
    ChangeRunning(run, false)
    if isReloadUI and InActiveChallengeMode() then
        StartTimerCalibration(run)
    else
        SetCurrentIfActiveOrPreviousRun(run)
        addon.RunUI:Show()
    end
end

local function OnPlayerLeavingWorld()
    local run = g_runs[g_currentInstanceId]
    if run then
        run.state.isStartTimeAccurate = false
        addon.RunHistory:UpdateCurrentRun(addon.Utility:DeepCopy(run))
    end
end

local function OnScenarioCriteriaUpdate(criteriaId)
    -- InActiveChallengeMode() will always be false when entering a dungeon.
    -- Fired when entering an active CM, usually before PLAYER_ENTERING_WORLD.
    -- difficultyId is always wrong when entering a dungeon.
    -- criteriaId for enemy count cannot be relied upon, just assume that every id that cannot be matched to a boss is for enemy count.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    addon.Utility:DebugPrint("OnScenarioCriteriaUpdate, criteriaId: " .. criteriaId .. " scenario type: " ..
        select(10, C_Scenario.GetInfo()) .. " elapsed: " .. WoWGetWorldElapsedTime())
    if InChallengeMode() and UpdateCriteriaSplit(criteriaId) then
        addon.RunUI:UpdateSplits()
    end
end

local function OnWorldStateTimerStart()
    -- Fired when entering an active CM and after the 5s start countdown, always after PLAYER_ENTERING_WORLD.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    if difficultyId == addon.Dungeons.CHALLENGE_MODE_DIFFICULTY_ID then
        StartTimerCalibration(g_runs[g_currentInstanceId])
    end
end

-- Public API

function addon.Run:Init()
    InitializeRuns()

    local EVENTS = {
        ["CHALLENGE_MODE_RESET"] = OnChallengeModeReset,
        ["CHALLENGE_MODE_COMPLETED"] = OnChallengeModeCompleted,
        ["PLAYER_ENTERING_WORLD"] = OnPlayerEnteringWorld,
        ["PLAYER_LEAVING_WORLD"] = OnPlayerLeavingWorld,
        ["SCENARIO_CRITERIA_UPDATE"] = OnScenarioCriteriaUpdate,
        ["WORLD_STATE_TIMER_START"] = OnWorldStateTimerStart,
    }

    local eventFrame = CreateFrame("Frame")
    for key, _ in pairs(EVENTS) do
        eventFrame:RegisterEvent(key)
    end
    eventFrame:SetScript("OnEvent", function(_, event, ...)
        addon.Utility:DebugPrint(event)
        EVENTS[event](...)
    end)
end

function addon.Run:CreateRun(instanceId)
    local run = {
        state = CreateRunState(instanceId),
        completed = false,
        startTimestamp = 0, -- time()
        duration = 0,       -- GetTime() - startTime
        runners = BuildRunners(),
        splits = {}
    }
    CreateRunSplits(run)
    return run
end

function addon.Run:CreateSampleRun(instanceId, totalTime, completed, secondsAgo)
    local run = self:CreateRun(instanceId)
    local splitProfile = addon.SplitProfile:Get(instanceId)
    local startOffset = secondsAgo or 0

    run.completed = completed and true or false
    run.state.startTime = GetTime() - totalTime
    run.startTimestamp = time() - startOffset - totalTime
    run.duration = addon.Utility:RoundDuration(totalTime)
    if run.completed then
        run.medalIndex = addon.Dungeons:GetMedalIndexByDuration(instanceId, run.duration)
    end

    local splitCount = #run.splits
    local completedSplits = completed and splitCount or math.max(1, math.floor(splitCount / 2))

    for index, split in ipairs(run.splits) do
        local splitDefinition = splitProfile.splits[index]
        local totalQuantity = splitDefinition.totalQuantity or 0
        if index <= completedSplits then
            split.completed = true
            split.duration = addon.Utility:RoundDuration(totalTime * (index / splitCount))
            split.quantity = totalQuantity
        else
            split.completed = false
            split.duration = 0
            split.quantity = math.floor(totalQuantity * 0.4)
        end
    end

    return run
end

function addon.Run:SetSampleRun(runTime)
    local instanceId = 1004
    if not runTime then
        runTime = 390.4
    end
    local sampleRun = addon.Run:CreateSampleRun(instanceId, runTime, true, 86400 * 3)
    sampleRun.previousRun = g_currentRun
    sampleRun.originalGetComparisonRun = addon.RunHistory.GetComparisonRun
    addon.RunHistory.GetComparisonRun = function(_)
        return addon.Run:CreateSampleRun(instanceId, runTime + 20, true, 86400 * 3)
    end
    self.sampleRun = sampleRun
    addon.RunUI:SetRun(self.sampleRun)
end

function addon.Run:UnsetSampleRun()
    if not self.sampleRun then
        return
    end
    addon.RunHistory.GetComparisonRun = self.sampleRun.originalGetComparisonRun
    if self.sampleRun.previousRun then
        addon.RunUI:SetRun(self.sampleRun.previousRun)
    end
    self.sampleRun = nil
end
