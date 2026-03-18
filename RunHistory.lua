local addonName, addon = ...

addon.RunHistory = addon.RunHistory or {}

local function GetRunHistory(instanceId)
    return ChallengeModeTimerDB.runHistory[instanceId]
end

local function HasAtLeastOneCompletedSplit(run)
    if run.duration == 0 then
        return false
    end
    for _, split in ipairs(run.splits) do
        if split.completed then
            return true
        end
    end
    return false
end

function addon.RunHistory:Init()
    if not ChallengeModeTimerDB.runHistory then
        ChallengeModeTimerDB.runHistory = {}
        for instanceId, _ in pairs(addon.Constants.CHALLENGE_MODE_DUNGEONS) do
            ChallengeModeTimerDB.runHistory[instanceId] = { runs = { addon.Run:CreateRun(instanceId) } }
        end
    end
end

function addon.RunHistory:GetCurrentRun(instanceId)
    local runHistory = GetRunHistory(instanceId)
    if not runHistory then
        return nil
    end
    local runs = runHistory.runs
    return runs[#runs]
end

function addon.RunHistory:GetPreviousRun(instanceId)
    local runHistory = GetRunHistory(instanceId)
    if not runHistory then
        return nil
    end
    local runs = runHistory.runs
    if #runs > 1 then
        return runs[#runs - 1]
    end
end

function addon.RunHistory:PersistCurrentRun(instanceId)
    local runs = GetRunHistory(instanceId).runs
    local activeRun = runs[#runs]
    local nextRun = addon.Run:CreateRun(instanceId)
    if HasAtLeastOneCompletedSplit(activeRun) then
        activeRun.state = nil
        table.insert(runs, nextRun)
        addon.RunHistoryUI:Refresh()
    else
        runs[#runs] = nextRun
    end
    return nextRun
end

function addon.RunHistory:GetHistoricalRuns(instanceId)
    local runs = GetRunHistory(instanceId).runs
    if HasAtLeastOneCompletedSplit(runs[#runs]) then
        return runs, #runs
    end
    return runs, #runs - 1
end

function addon.RunHistory:GetComparisonRun(instanceId)
    local runHistory = GetRunHistory(instanceId)
    local index = runHistory.comparisonRunIndex
    if index then
        return runHistory.runs[index]
    end
end

function addon.RunHistory:GetComparisonRunIndex(instanceId)
    return GetRunHistory(instanceId).comparisonRunIndex
end

function addon.RunHistory:SetComparisonRunIndex(instanceId, index)
    local runHistory = GetRunHistory(instanceId)
    runHistory.comparisonRunIndex = index
    addon.RunUI:UpdateSplits()
end

function addon.RunHistory:InsertSampleRuns()
    for instanceId, dungeonData in pairs(addon.Constants.CHALLENGE_MODE_DUNGEONS) do
        local baseTime = dungeonData.medals.gold
        local slowerTime = baseTime + 45
        local fasterTime = math.max(60, baseTime - 30)
        local partialTime = math.max(60, math.floor(baseTime * 0.4))

        function SaltRunTime(runTime)
            return runTime + math.random()
        end

        local runs = GetRunHistory(instanceId).runs
        table.insert(runs, 1, addon.Run:CreateSampleRun(instanceId, SaltRunTime(partialTime), false, 3600))
        table.insert(runs, 1, addon.Run:CreateSampleRun(instanceId, SaltRunTime(fasterTime), true, 3600 * 12))
        table.insert(runs, 1, addon.Run:CreateSampleRun(instanceId, SaltRunTime(slowerTime), true, 86400 * 3))

        self:SetComparisonRunIndex(instanceId, 1)
    end

    addon.RunHistoryUI:Refresh()
end
