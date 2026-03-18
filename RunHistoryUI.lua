local addonName, addon = ...

addon.RunHistoryUI     = addon.RunHistoryUI or {}

local LST              = LibStub and LibStub("ScrollingTable")
local LSM              = LibStub and LibStub("LibSharedMedia-3.0", true)
local FONT_2002        = (LSM and LSM:Fetch("font", "2002")) or "Fonts\\2002.TTF"
local COMPLETED_INDEX  = 3
local RUNNER_INDEX     = 4

local function SetFont(fontString, desiredSize)
    local _, size, flags = fontString:GetFont()
    if desiredSize then
        size = desiredSize
    end
    fontString:SetFont(FONT_2002, size, flags)
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
    if not run or not run.runner then
        return "-"
    end

    local name = run.runner.name
    local classId = run.runner.classId
    local _, classToken = GetClassInfo(classId)
    local classColor = classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local colorStr = string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    return string.format("|c%s%s|r", colorStr, name)
end

local function CompareRowValues(tableFrame, rowa, rowb, sortby, valueGetter)
    local aValue = valueGetter(tableFrame.data[rowa])
    local bValue = valueGetter(tableFrame.data[rowb])
    if aValue == bValue then
        return false
    end
    local column = tableFrame.cols[sortby]
    local direction = column.sort or column.defaultsort
    if direction == LST.SORT_ASC then
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

local function ShowRunSplitsTooltip(cellFrame, run, instanceId)
    if not run or not instanceId then
        return
    end

    local splitProfile = addon.SplitProfile:Get(instanceId)
    if not splitProfile then
        return
    end

    GameTooltip:SetOwner(cellFrame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Splits", 1, 0.82, 0)

    for index, split in ipairs(run.splits or {}) do
        local splitDefinition = splitProfile.splits[index]
        if splitDefinition then
            local totalQuantity = splitDefinition.totalQuantity
            local currentQuantity = split.quantity
            local label = string.format("%s %d/%d", splitDefinition.name, currentQuantity, totalQuantity)
            local durationText = BuildSplitDurationText(split)
            if split.completed then
                GameTooltip:AddDoubleLine(label, durationText, 0.2, 1, 0.2, 1, 1, 1)
            else
                GameTooltip:AddDoubleLine(label, durationText, 1, 1, 1, 1, 1, 1)
            end
        end
    end

    GameTooltip:Show()
end

local function BuildColumns()
    return {
        {
            name = "Date",
            width = 180,
            align = "LEFT",
            index = 1,
            sort = LST.SORT_DSC,
            defaultsort = LST.SORT_DSC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.startTimestamp or 0
                end)
            end
        },
        {
            name = "Duration",
            width = 120,
            align = "RIGHT",
            index = 2,
            defaultsort = LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.duration or 0
                end)
            end
        },
        {
            name = "Completed",
            width = 120,
            align = "RIGHT",
            index = COMPLETED_INDEX,
            defaultsort = LST.SORT_DSC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(row)
                    return row.run.completed and 1 or 0
                end)
            end
        },
        {
            name = "Runner",
            width = 140,
            align = "RIGHT",
            index = RUNNER_INDEX,
            defaultsort = LST.SORT_ASC,
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

    local dropdown = CreateFrame("Frame", "ChallengeModeTimerRunHistoryDropdown", runsFrame, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", runsFrame, "TOPLEFT", 0, 0)
    UIDropDownMenu_SetWidth(dropdown, 165)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")
    SetFont(_G[dropdown:GetName() .. "Text"], 12)
    self.dropdown = dropdown

    local filterLabel = runsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    filterLabel:SetPoint("LEFT", dropdown, "RIGHT", 10, 0)
    filterLabel:SetText("Filter")
    SetFont(filterLabel, 12)

    local filterBox = CreateFrame("EditBox", nil, runsFrame, "InputBoxTemplate")
    filterBox:SetSize(190, 20)
    filterBox:SetPoint("LEFT", filterLabel, "RIGHT", 8, 0)
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

    self.instanceIds = BuildSortedInstanceIds()
    self.selectedInstanceId = self.instanceIds[1]

    self.table = self:CreateTable()

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        local fontObject = CreateFont("ChallengeModeTimerDropdownFontObject")
        fontObject:SetFont(FONT_2002, 12, "")
        for _, instanceId in ipairs(self.instanceIds) do
            local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
            local info        = UIDropDownMenu_CreateInfo()
            info.text         = dungeonData.englishName
            info.fontObject   = fontObject
            info.noClickSound = true
            info.func         = function() self:SetSelectedInstance(instanceId) end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    runsFrame:HookScript("OnShow", function()
        self:SetSelectedInstance(self.selectedInstanceId)
    end)
end

function addon.RunHistoryUI:CreateTable()
    local columns = BuildColumns()

    local rowHeight = 20
    local tableFrame = LST:CreateST(columns, 10, rowHeight, nil, self.runsFrame, false)
    tableFrame.frame:SetPoint("TOPLEFT", self.dropdown, "BOTTOMLEFT", 0, -20)
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
                addon.RunHistory:SetComparisonRunIndex(self.selectedInstanceId, realrow)
            end
            return false
        end,
        OnEnter = function(rowFrame, cellFrame, data, cols, row, realrow, column, tableFrame)
            if not realrow then
                return false
            end
            local rowData = tableFrame:GetRow(realrow)
            if rowData then
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
    for index, run in ipairs(runs) do
        rows[index] = {
            run = run,
            cols = BuildRowValues(run)
        }
        if index == runCount then
            break
        end
    end
    return rows
end

function addon.RunHistoryUI:SyncSelectionAndComparisonRun()
    local comparisonRunIndex = addon.RunHistory:GetComparisonRunIndex(self.selectedInstanceId)
    if comparisonRunIndex then
        self.table:SetSelection(comparisonRunIndex)
        return
    end
    self.table:ClearSelection()
end

function addon.RunHistoryUI:Refresh()
    if not self.table or not self.runsFrame or not self.runsFrame:IsShown() then
        return
    end

    local rows = self:BuildRows(self.selectedInstanceId)
    self.table:SetData(rows)
    self:SyncSelectionAndComparisonRun()
end

function addon.RunHistoryUI:SetSelectedInstance(instanceId)
    local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
    if not dungeonData then
        return
    end
    self.selectedInstanceId = instanceId
    local name = dungeonData.englishName
    UIDropDownMenu_SetText(self.dropdown, name)
    self:Refresh()
end
