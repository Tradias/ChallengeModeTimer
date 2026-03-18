local addonName, addon = ...

LoadAddOn("Blizzard_DebugTools")
--  DevTools_Dump()

addon.Run = addon.Run or {}

local g_eventFrame = nil
local g_sampleRun = nil
local g_currentRun = nil
local g_currentInstanceId = nil
local g_timerCalibrationTicker = nil

local function CreateRunSplits(run)
    run.splits = {}
    local splitProfile = addon.SplitProfile:Get(run.state.instanceId)
    for _, _ in ipairs(splitProfile.splits) do
        table.insert(run.splits, addon.SplitProfile:CreateSplit())
    end
end

local function InActiveChallengeMode()
    local _, _, timerType = GetWorldElapsedTime(1)
    return timerType == LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE
end

local function WoWGetWorldElapsedTime()
    local _, worldElapsedTime = GetWorldElapsedTime(1)
    return worldElapsedTime
end

local function RoundDuration(duration)
    return math.floor(duration * 1000 + 0.5) / 1000
end

local function SetStartTime(run, startTime)
    run.state.startTime = startTime
    addon.Run:SetDurationFromNow(run)
end

local function UpdateCriteriaSplits()
    local run = addon.RunHistory:GetActiveRun(g_currentInstanceId)
    local splitProfile = addon.SplitProfile:Get(g_currentInstanceId)
    for index, split in ipairs(run.splits) do
        local splitDefinition = splitProfile.splits[index]
        local criteriaInfo = C_ScenarioInfo.GetCriteriaInfo(splitDefinition.criteriaIndex)
        if split.quantity < criteriaInfo.quantity then
            split.quantity = criteriaInfo.quantity
        end
        if criteriaInfo.completed then
            split.quantity = splitDefinition.totalQuantity
        end
        if not split.completed and criteriaInfo.completed then
            split.completed = true
            if run.state.startTime == 0 then
                split.duration = WoWGetWorldElapsedTime() - criteriaInfo.elapsed
            else
                split.duration = RoundDuration(GetTime() - run.state.startTime - criteriaInfo.elapsed)
            end
        end
    end
    addon.RunUI:UpdateSplits()
end

local function BuildRunner()
    local _, _, classId = UnitClass("player")
    local name = UnitName("player")
    return {
        name = name,
        classId = classId
    }
end

local function OnRunStart(run, worldElapsedTime)
    run.state.active = true
    run.startTimestamp = time() - worldElapsedTime
    run.runner = BuildRunner()
    UpdateCriteriaSplits()
    addon.RunUI:Show()
end

local function MaybeStartNewRun(run, worldElapsedTime)
    run.state.running = true
    if not run.state.active then
        OnRunStart(run, worldElapsedTime)
    end
end

local function CancelTimerCalibration()
    if g_timerCalibrationTicker then
        g_timerCalibrationTicker:Cancel()
        g_timerCalibrationTicker = nil
    end
end

local function OnTimerCalibrationTick(run)
    local _, worldElapsedTime, timerType = GetWorldElapsedTime(1)
    if timerType ~= LE_WORLD_ELAPSED_TIMER_TYPE_CHALLENGE_MODE then
        CancelTimerCalibration()
        return
    end
    if worldElapsedTime > run.state.lastSeenWorldElapsedTime then
        SetStartTime(run, GetTime() - worldElapsedTime)
        MaybeStartNewRun(run, worldElapsedTime)
        CancelTimerCalibration()
    end
end

local function StartTimerCalibration(run)
    local worldElapsedTime = WoWGetWorldElapsedTime()
    if worldElapsedTime == 0 then
        SetStartTime(run, GetTime())
        MaybeStartNewRun(run, worldElapsedTime)
        return
    end
    SetStartTime(run, 0)
    run.state.lastSeenWorldElapsedTime = worldElapsedTime
    if g_timerCalibrationTicker then
        CancelTimerCalibration()
    end
    g_timerCalibrationTicker = C_Timer.NewTicker(0.1, (function() OnTimerCalibrationTick(run) end))
end

local function OnRunEnd(run, challengeCompletionInfo)
    CancelTimerCalibration()
    local instanceId = run.state.instanceId
    if challengeCompletionInfo then
        run.completed = true
        run.duration = challengeCompletionInfo.time / 1000
    end
    addon.RunHistory:PersistActiveRun(instanceId)
    g_currentRun = nil
end

-- ============================================================================
-- EVENT HANDLING
-- ============================================================================

local function OnChallengeModeReset()
    -- Also fired when starting a CM.
    local run = addon.RunHistory:GetActiveRun(g_currentInstanceId)
    if not run then
        print("Challenge reset outside of dungeon - please report bug")
        return
    end
    if run.state.active then
        OnRunEnd(run)
    end
end

local function OnChallengeModeCompleted()
    local run = addon.RunHistory:GetActiveRun(g_currentInstanceId)
    if not run then
        print("Challenge completed outside of dungeon - please report bug")
        DevTools_Dump(C_ChallengeMode.GetChallengeCompletionInfo())
        return
    end
    OnRunEnd(run, C_ChallengeMode.GetChallengeCompletionInfo())
end

local function OnPlayerEnteringWorld(isInitialLogin, isReloadUI)
    -- InActiveChallengeMode() will always be false when entering a dungeon.
    -- WORLD_STATE_TIMER_START will always fire after entering world but SCENARIO_CRITERIA_UPDATE may fire before.
    -- difficultyId is always wrong when entering a dungeon.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    local run = addon.RunHistory:GetActiveRun(instanceId)
    if not run then
        if g_currentRun and g_currentRun.state.running then
            addon.RunUI:Show()
        else
            addon.RunUI:Hide()
        end
        return
    end
    g_currentRun = run
    run.state.running = false
    if isReloadUI and InActiveChallengeMode() then
        StartTimerCalibration(run)
    else
        addon.RunUI:Show()
    end
end

local function OnScenarioCriteriaUpdate(criteriaId)
    -- InActiveChallengeMode() will always be false when entering a dungeon.
    -- Fired when entering an active CM, usually before PLAYER_ENTERING_WORLD.
    -- difficultyId is always wrong when entering a dungeon.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    if InActiveChallengeMode() then
        UpdateCriteriaSplits()
    end
end

local function OnWorldStateTimerStart()
    -- Fired when entering an active CM and after the 5s start countdown, always after PLAYER_ENTERING_WORLD.
    local dungeonName, instanceType, difficultyId, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceId =
        GetInstanceInfo()
    g_currentInstanceId = instanceId
    if difficultyId == addon.Constants.CHALLENGE_MODE_DIFFICULTY_ID then
        StartTimerCalibration(addon.RunHistory:GetActiveRun(instanceId))
    end
end

-- Public API

function addon.Run:Init()
    local EVENTS = {
        ["CHALLENGE_MODE_RESET"] = OnChallengeModeReset,
        ["CHALLENGE_MODE_COMPLETED"] = OnChallengeModeCompleted,
        ["PLAYER_ENTERING_WORLD"] = OnPlayerEnteringWorld,
        ["SCENARIO_CRITERIA_UPDATE"] = OnScenarioCriteriaUpdate,
        ["WORLD_STATE_TIMER_START"] = OnWorldStateTimerStart,
    }

    g_eventFrame = CreateFrame("Frame")
    for key, _ in pairs(EVENTS) do
        g_eventFrame:RegisterEvent(key)
    end
    g_eventFrame:SetScript("OnEvent", function(_, event, ...)
        EVENTS[event](...)
    end)
end

function addon.Run:Get()
    if g_currentRun then
        return g_currentRun
    end
    if not g_currentInstanceId then
        return nil
    end
    return addon.RunHistory:GetActiveRun(g_currentInstanceId)
end

function addon.Run:SetDurationFromNow(run)
    run.duration = RoundDuration(GetTime() - run.state.startTime)
end

function addon.Run:CreateRun(instanceId)
    local run = {
        state = {
            instanceId = instanceId,
            active = false,
            running = false,
            startTime = 0,                -- GetTime()
            lastSeenWorldElapsedTime = 0, -- GetWorldElapsedTime(1)
        },
        completed = false,
        startTimestamp = 0, -- time()
        duration = 0,       -- GetTime() - startTime
        runner = BuildRunner(),
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
    run.duration = RoundDuration(totalTime)

    local splitCount = #run.splits
    local completedSplits = completed and splitCount or math.max(1, math.floor(splitCount / 2))

    for index, split in ipairs(run.splits) do
        local splitDefinition = splitProfile.splits[index]
        local totalQuantity = splitDefinition.totalQuantity or 0
        if index <= completedSplits then
            split.completed = true
            split.duration = RoundDuration(totalTime * (index / splitCount))
            split.quantity = totalQuantity
        else
            split.completed = false
            split.duration = 0
            split.quantity = math.floor(totalQuantity * 0.4)
        end
    end

    return run
end

function addon.Run:SetSampleRun()
    local instanceId = 1004
    local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
    local runTime = (dungeonData.medals and dungeonData.medals.gold) or 900
    runTime = runTime + math.random()
    local previousRun = g_currentRun
    g_currentRun = addon.Run:CreateSampleRun(instanceId, runTime, true, 86400 * 3)
    g_currentRun.previousRun = previousRun
    g_sampleRun = g_currentRun
end

function addon.Run:UnsetSampleRun()
    if g_sampleRun then
        g_currentRun = g_sampleRun.previousRun
        g_sampleRun = nil
    end
end
