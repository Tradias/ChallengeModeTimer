local addonName, addon = ...

addon.Migrations = addon.Migrations or {}

function addon.Migrations:Run()
    local runHistory = ChallengeModeTimerDB.runHistory
    if runHistory then
        for instanceId, history in pairs(runHistory) do
            history.comparisonRun = nil
            local runs = history.runs
            for _, run in ipairs(runs) do
                if run.splits then
                    for _, split in ipairs(run.splits) do
                        if split.splitData then
                            split = split.splitData
                        end
                    end
                end
            end

            if #runs == 0 or not runs[#runs].state then
                table.insert(runs, addon.Run:CreateRun(instanceId))
            end
        end
    end
end
