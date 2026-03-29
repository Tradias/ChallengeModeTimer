local _, addon = ...

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
        for instanceId, _ in pairs(addon.Dungeons:Get()) do
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

function addon.RunHistory:UpdateCurrentRun(run)
    local instanceId = run.state.instanceId
    local runs = GetRunHistory(instanceId).runs
    runs[#runs] = run
end

function addon.RunHistory:PersistCurrentRun(run)
    -- Keep the most recently failed run, otherwise store only runs with at least one completed split
    local instanceId = run.state.instanceId
    local runs = GetRunHistory(instanceId).runs
    local nextRun = addon.Run:CreateRun(instanceId)
    run.state = nil
    if #runs < 2 then
        runs[1] = run
        table.insert(runs, nextRun)
    else
        if not HasAtLeastOneCompletedSplit(runs[#runs - 1]) then
            runs[#runs - 1] = run
            runs[#runs] = nextRun
        else
            runs[#runs] = run
            table.insert(runs, nextRun)
        end
    end
    return nextRun
end

function addon.RunHistory:GetHistoricalRuns(instanceId)
    local runs = GetRunHistory(instanceId).runs
    if HasAtLeastOneCompletedSplit(runs[#runs]) then
        return runs, #runs
    end
    if #runs > 1 and HasAtLeastOneCompletedSplit(runs[#runs - 1]) then
        return runs, #runs - 1
    end
    return runs, #runs - 2
end

function addon.RunHistory:AddRun(instanceId, run)
    local runs = GetRunHistory(instanceId).runs
    table.insert(runs, 1, run)
    return 1
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
    for instanceId, dungeon in pairs(addon.Dungeons:Get()) do
        local baseTime = dungeon.medals[3] -- gold
        local slowerTime = baseTime + 45
        local fasterTime = math.max(60, baseTime - 30)
        local partialTime = math.max(60, math.floor(baseTime * 0.4))

        function SaltRunTime(runTime)
            return runTime + math.random()
        end

        function CreateSampleRun(runTime, completed, secondsAgo)
            local run = addon.Run:CreateSampleRun(instanceId, SaltRunTime(runTime), completed, secondsAgo)
            run.state = nil
            return run
        end

        local runs = GetRunHistory(instanceId).runs
        table.insert(runs, 1, CreateSampleRun(SaltRunTime(partialTime), false, 3600))
        table.insert(runs, 1, CreateSampleRun(SaltRunTime(fasterTime), true, 3600 * 12))
        table.insert(runs, 1, CreateSampleRun(SaltRunTime(slowerTime), true, 86400 * 3))

        self:SetComparisonRunIndex(instanceId, 1)
    end

    addon.RunHistoryUI:Refresh()
end
