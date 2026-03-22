local addonName, addon = ...

addon.RunHistoryUI = addon.RunHistoryUI or {}

local COMPLETED_INDEX = 3
local RUNNER_INDEX = 4

local function SetFont(fontString, desiredSize)
    local _, size, flags = fontString:GetFont()
    if desiredSize then
        size = desiredSize
    end
    fontString:SetFont(addon.Constants.FONT, size, flags)
end

local function FormatRunDate(timestamp)
    return date("%Y/%m/%d %H-%M", timestamp)
end

local function BuildSortedInstanceIds()
    local instanceIds = {}
    for instanceId, _ in pairs(addon.Constants.CHALLENGE_MODE_DUNGEONS) do
        table.insert(instanceIds, instanceId)
    end
    table.sort(instanceIds, function(a, b)
        return addon.Constants.CHALLENGE_MODE_DUNGEONS[a].englishName <
            addon.Constants.CHALLENGE_MODE_DUNGEONS[b].englishName
    end)
    return instanceIds
end

local function BuildSplitDurationText(split)
    if split and split.completed and split.duration ~= 0 then
        return addon.Utility:FormatTime(split.duration)
    end
    return "-"
end

local function BuildRunnerNameText(run)
    if not run.runners or #run.runners < 1 then
        return "-"
    end
    local player = run.runners[1]
    local classColor = addon.Utility:GetClassColorById(player.classId)
    local colorStr = string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    return string.format("|c%s%s|r", colorStr, player.name)
end

local function CompareRowValues(tableFrame, rowa, rowb, sortby, valueGetter)
    local aValue = valueGetter(tableFrame.data[rowa])
    local bValue = valueGetter(tableFrame.data[rowb])
    if aValue == bValue then
        return false
    end
    local column = tableFrame.cols[sortby]
    local direction = column.sort or column.defaultsort
    if direction == addon.LST.SORT_ASC then
        return aValue < bValue
    end
    return aValue > bValue
end

local function RemoveClassColor(name)
    return string.sub(name, 11, -3)
end

local function FilterRow(filterText, rowData)
    if filterText == "" then
        return true
    end
    local text = string.lower(filterText)
    if text == "yes" or text == "no" then
        return string.find(rowData.cols[COMPLETED_INDEX].value, text, 1, true)
    end
    for index, column in ipairs(rowData.cols) do
        if index ~= COMPLETED_INDEX then
            local columnValue = column.value
            if index == RUNNER_INDEX then
                columnValue = string.lower(RemoveClassColor(columnValue))
            end
            if string.find(columnValue, text, 1, true) then
                return true
            end
        end
    end
    return false
end

local function AddRunnerLinesToTooltip(run)
    for _, runner in ipairs(run.runners or {}) do
        local name = runner.name
        local classColor = addon.Utility:GetClassColorById(runner.classId)
        GameTooltip:AddLine(name, classColor.r, classColor.g, classColor.b)
    end
end

local function ShowRunnersTooltip(frame, run)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Runners", 1, 0.82, 0)

    AddRunnerLinesToTooltip(run)

    GameTooltip:Show()
end

local function AddSplitLinesToTooltip(run, instanceId)
    local splitProfile = addon.SplitProfile:Get(instanceId)
    for index, split in ipairs(run.splits or {}) do
        local splitDefinition = splitProfile.splits[index]
        if splitDefinition then
            local label = addon.SplitProfile:FormatSplitLabel(split, splitDefinition)
            local durationText = BuildSplitDurationText(split)
            if split.completed then
                GameTooltip:AddDoubleLine(label, durationText, 0.2, 1, 0.2, 1, 1, 1)
            else
                GameTooltip:AddDoubleLine(label, durationText, 1, 1, 1, 1, 1, 1)
            end
        end
    end
end

local function ShowRunSplitsTooltip(frame, run, instanceId)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Splits", 1, 0.82, 0)

    AddSplitLinesToTooltip(run, instanceId)

    GameTooltip:Show()
end

local function CountCompletedSplits(run)
    local count = 0
    for _, split in ipairs(run.splits) do
        if split.completed then
            count = count + 1
        end
    end
    return count
end

local function FindBestFilteredRun(table)
    if not table.filtered then
        return
    end
    local index
    local bestDuration
    local bestCompletedSplitCount = 0
    for _, realrow in ipairs(table.filtered) do
        local rowData = table:GetRow(realrow)
        local run = rowData.run
        local duration = run.duration
        local completedSplitCount = CountCompletedSplits(run)
        if completedSplitCount > bestCompletedSplitCount then
            bestDuration = duration
            bestCompletedSplitCount = completedSplitCount
            index = realrow
        elseif completedSplitCount == bestCompletedSplitCount and (bestDuration == nil or duration < bestDuration) then
            bestDuration = duration
            index = realrow
        end
    end
    return index
end

local function ShowBestRunTooltip(frame, table, instanceId)
    local bestIndex = FindBestFilteredRun(table)
    if not bestIndex then
        return
    end
    local rowData = table:GetRow(bestIndex)
    local run = rowData.run
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText(addon.Utility:FormatTime(run.duration, 3), 1, 0.82, 0)
    GameTooltip:AddLine(FormatRunDate(run.startTimestamp), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Splits", 1, 0.82, 0)
    AddSplitLinesToTooltip(run, instanceId)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Runners", 1, 0.82, 0)
    AddRunnerLinesToTooltip(run)
    GameTooltip:Show()
end

local function BuildColumns()
    return {
        {
            name = "Date",
            width = 160,
            align = "LEFT",
            index = 1,
            sort = addon.LST.SORT_DSC,
            defaultsort = addon.LST.SORT_DSC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.startTimestamp or 0
                end)
            end
        },
        {
            name = "Duration",
            width = 120,
            align = "LEFT",
            index = 2,
            defaultsort = addon.LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.duration or 0
                end)
            end
        },
        {
            name = "Completed",
            width = 120,
            align = "LEFT",
            index = COMPLETED_INDEX,
            defaultsort = addon.LST.SORT_DSC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.completed and 1 or 0
                end)
            end
        },
        {
            name = "Runner",
            width = 140,
            align = "LEFT",
            index = RUNNER_INDEX,
            defaultsort = addon.LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    local runnerName = row.run.runner and row.run.runner.name or ""
                    return string.lower(RemoveClassColor(runnerName))
                end)
            end
        }
    }
end

local function BuildRowValues(run)
    return {
        { value = FormatRunDate(run.startTimestamp) },
        { value = addon.Utility:FormatTime(run.duration, 3) },
        { value = run.completed and "yes" or "no" },
        { value = BuildRunnerNameText(run) },
    }
end

function addon.RunHistoryUI:Init()
    local runsFrame = addon.OptionsUI:GetRunsFrame()
    self.runsFrame = runsFrame

    local dropdown = CreateFrame("DropdownButton", "ChallengeModeTimerRunHistoryDropdown", runsFrame,
        "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", runsFrame, "TOPLEFT", 10, 0)
    dropdown:SetWidth(180)
    self.dropdown = dropdown

    local filterLabel = runsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    filterLabel:SetPoint("LEFT", dropdown, "RIGHT", 15, 0)
    filterLabel:SetText("Filter")
    SetFont(filterLabel, 12)

    local filterBox = CreateFrame("EditBox", nil, runsFrame, "InputBoxTemplate")
    filterBox:SetSize(170, 20)
    filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 6, 0)
    filterBox:SetAutoFocus(false)
    SetFont(filterBox, 12)
    filterBox:SetScript("OnEnterPressed", function()
        filterBox:ClearFocus()
    end)
    self.filterText = ""
    filterBox:SetScript("OnTextChanged", function()
        self.filterText = filterBox:GetText()
        self.table:SortData()
    end)

    local bestRunButton = CreateFrame("Button", nil, runsFrame, "UIPanelButtonTemplate")
    bestRunButton:SetSize(80, filterBox:GetHeight())
    bestRunButton:SetPoint("LEFT", filterBox, "RIGHT", 23, -1)
    bestRunButton:SetText("Best run")
    bestRunButton:SetScript("OnClick", function()
        self:SelectBestFilteredRun()
    end)
    bestRunButton:SetScript("OnEnter", function()
        ShowBestRunTooltip(bestRunButton, self.table, self.selectedInstanceId)
    end)
    bestRunButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.instanceIds = BuildSortedInstanceIds()
    self.selectedInstanceId = self.instanceIds[1]

    self.table = self:CreateTable()

    dropdown:SetupMenu(function(_, rootDescription)
        for _, instanceId in ipairs(self.instanceIds) do
            local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
            local button = rootDescription:CreateButton(dungeonData.englishName,
                function(v) self:SetSelectedInstance(v) end, instanceId)
            button:SetIsSelected(function(v) return v == self.selectedInstanceId end)
        end
    end)

    runsFrame:HookScript("OnShow", function()
        self:SetSelectedInstance(self.selectedInstanceId)
    end)
end

function addon.RunHistoryUI:CreateTable()
    local columns = BuildColumns()

    local rowHeight = 20
    local tableFrame = addon.LST:CreateST(columns, 10, rowHeight, nil, self.runsFrame, false)
    tableFrame.frame:SetPoint("TOPLEFT", self.dropdown, "BOTTOMLEFT", -10, -30)
    tableFrame.frame:SetPoint("BOTTOMRIGHT", self.runsFrame, "BOTTOMRIGHT", 0, 0)

    local function SetTableFonts()
        for _, col in ipairs(tableFrame.head.cols) do
            SetFont(col:GetFontString(), 13)
        end
        for _, row in ipairs(tableFrame.rows) do
            for _, col in ipairs(row.cols) do
                SetFont(col.text, 12)
            end
        end
    end

    local function UpdateDisplayRows()
        local frameHeight = tableFrame.frame:GetHeight()
        if not frameHeight or frameHeight <= 0 then
            return
        end
        local displayRows = math.max(1, math.floor((frameHeight - 10) / rowHeight))
        if displayRows ~= tableFrame.displayRows then
            tableFrame:SetDisplayRows(displayRows, rowHeight)
            SetTableFonts()
        end
    end

    tableFrame.frame:SetScript("OnSizeChanged", UpdateDisplayRows)
    self.runsFrame:HookScript("OnSizeChanged", UpdateDisplayRows)
    UpdateDisplayRows()

    tableFrame:EnableSelection(true)
    tableFrame:SetDefaultHighlight(0.2, 0.6, 1, 0.25)

    tableFrame:RegisterEvents({
        OnClick = function(rowFrame, cellFrame, data, cols, row, realrow, column, tableFrame, button)
            if button == "LeftButton" and realrow then
                local isAlreadySelected = (tableFrame:GetSelection() == realrow)
                if isAlreadySelected then
                    addon.RunHistory:SetComparisonRunIndex(self.selectedInstanceId, nil)
                else
                    addon.RunHistory:SetComparisonRunIndex(self.selectedInstanceId, realrow)
                end
            end
            return false
        end,
        OnEnter = function(rowFrame, cellFrame, data, cols, row, realrow, column, tableFrame)
            if not realrow then
                return false
            end
            local rowData = tableFrame:GetRow(realrow)
            if column == RUNNER_INDEX then
                ShowRunnersTooltip(cellFrame, rowData.run)
            else
                ShowRunSplitsTooltip(cellFrame, rowData.run, self.selectedInstanceId)
            end
            return false
        end,
        OnLeave = function()
            GameTooltip:Hide()
            return false
        end
    }, true)

    tableFrame:SetFilter(function(_, rowData)
        return FilterRow(self.filterText, rowData)
    end)

    return tableFrame
end

function addon.RunHistoryUI:BuildRows(instanceId)
    local runs, runCount = addon.RunHistory:GetHistoricalRuns(instanceId)
    local rows = {}
    if runCount > 0 then
        for index, run in ipairs(runs) do
            rows[index] = {
                run = run,
                cols = BuildRowValues(run)
            }
            if index == runCount then
                break
            end
        end
    end
    return rows
end

function addon.RunHistoryUI:SyncSelectionAndComparisonRun()
    local comparisonRunIndex = addon.RunHistory:GetComparisonRunIndex(self.selectedInstanceId)
    if comparisonRunIndex then
        self.table:SetSelection(comparisonRunIndex)
    else
        self.table:ClearSelection()
    end
end

function addon.RunHistoryUI:Refresh()
    if not self.table or not self.runsFrame or not self.runsFrame:IsShown() then
        return
    end

    local rows = self:BuildRows(self.selectedInstanceId)
    self.table:SetData(rows)
    self:SyncSelectionAndComparisonRun()
end

function addon.RunHistoryUI:SelectBestFilteredRun()
    local index = FindBestFilteredRun(self.table)
    if index then
        self.table:SetSelection(index)
        addon.RunHistory:SetComparisonRunIndex(self.selectedInstanceId, index)
    end
end

function addon.RunHistoryUI:SetSelectedInstance(instanceId)
    local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
    if not dungeonData then
        return
    end
    self.selectedInstanceId = instanceId
    self:Refresh()
end
