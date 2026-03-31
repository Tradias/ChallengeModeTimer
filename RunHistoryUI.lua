local _, addon = ...

addon.RunHistoryUI = addon.RunHistoryUI or {}

local MEDAL_COLUMN_INDEX = 3
local RUNNER_COLUMN_INDEX = 4
local COMPARISON_RUN_SELECTION_HIGHTLIGHT = { 0.2, 0.6, 1, 0.25 }
local DELETE_MODE_HIGHTLIGHT = { 1, 0.2, 0.2, 0.25 }

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
    for instanceId, _ in pairs(addon.Dungeons:Get()) do
        table.insert(instanceIds, instanceId)
    end
    table.sort(instanceIds, function(a, b)
        return addon.Dungeons:Get(a).name < addon.Dungeons:Get(b).name
    end)
    return instanceIds
end

local function BuildSplitDurationText(split)
    if split.completed and split.duration ~= 0 then
        return addon.Utility:FormatTime(split.duration)
    end
    return "-"
end

local function BuildMedalText(run)
    local medalIndex = run.medalIndex
    if not medalIndex then
        return ""
    end
    local label = addon.Dungeons:GetMedalLabelByIndex(medalIndex)
    local color = addon.Dungeons:GetMedalColorByIndex(medalIndex)
    local colorStr = string.format("ff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
    return string.format("|c%s%s|r", colorStr, label)
end

local function BuildRunnerNameText(run)
    if not run.runners or #run.runners < 1 then
        return "-"
    end
    local player = run.runners[1]
    local classColor = addon.Utility:GetClassColorById(player.classId)
    local colorStr = string.format("ff%02x%02x%02x", classColor.r * 255, classColor.g * 255, classColor.b * 255)
    local importStr = ""
    if run.importTimestamp then
        importStr = "*"
    end
    return string.format("|c%s%s%s|r", colorStr, player.name, importStr)
end

local function RemoveColorCode(text)
    return string.sub(text, 11, -3)
end

local function FilterRow(filterText, rowData)
    if filterText == "" then
        return true
    end
    local text = string.lower(filterText)
    if addon.Dungeons:IsMedalLabel(text) then
        local cellValue = rowData.cols[MEDAL_COLUMN_INDEX].value
        cellValue = string.lower(RemoveColorCode(cellValue))
        return string.find(cellValue, text, 1, true)
    end
    for index, cell in ipairs(rowData.cols) do
        if index ~= MEDAL_COLUMN_INDEX then
            local cellValue = cell.value
            if index == RUNNER_COLUMN_INDEX then
                cellValue = string.lower(RemoveColorCode(cellValue))
            end
            if string.find(cellValue, text, 1, true) then
                return true
            end
        end
    end
    return false
end

local function AddMedalLinesToTooltip(instanceId)
    local dungeon = addon.Dungeons:Get(instanceId)
    for medalIndex, medalTime in ipairs(dungeon.formattedMedalTimes) do
        local label = addon.Dungeons:GetMedalLabelByIndex(medalIndex)
        local color = addon.Dungeons:GetMedalColorByIndex(medalIndex)
        GameTooltip:AddLine(string.format("%s %s", label, medalTime), color[1], color[2], color[3])
    end
end

local function ShowMedalsTooltip(frame, instanceId)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Medals", 1, 0.82, 0)

    AddMedalLinesToTooltip(instanceId)

    GameTooltip:Show()
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

    if run.importTimestamp then
        GameTooltip:AddLine("\n*Imported run", 1, 1, 1)
    end

    GameTooltip:Show()
end

local function AddSplitLinesToTooltip(instanceId, run)
    local splitProfile = addon.SplitProfile:Get(instanceId)
    for index, split in ipairs(run.splits or {}) do
        local splitDefinition = splitProfile.splits[index]
        local label = addon.SplitProfile:FormatSplitLabel(split, splitDefinition)
        local durationText = BuildSplitDurationText(split)
        if split.completed then
            GameTooltip:AddDoubleLine(label, durationText, 0.2, 1, 0.2, 1, 1, 1)
        else
            GameTooltip:AddDoubleLine(label, durationText, 1, 1, 1, 1, 1, 1)
        end
    end
end

local function ShowRunSplitsTooltip(frame, instanceId, run)
    GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
    GameTooltip:SetText("Splits", 1, 0.82, 0)

    AddSplitLinesToTooltip(instanceId, run)

    GameTooltip:AddLine("\nShift-click to share in chat", 1, 1, 1)

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
        if not run.importTimestamp then
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
    addon.RunHistoryUI:ShowRunTooltip(frame, instanceId, run)
end

local function ShowExportTooltip(frame)
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:SetText("Click on a run to export first", 1, 1, 1)
    GameTooltip:Show()
end

local function SendMessageInCurrentChannel(editBox, text)
    local chatType = editBox:GetAttribute("chatType") or "PARTY"
    local target
    if chatType == "WHISPER" then
        target = editBox:GetAttribute("tellTarget")
    elseif chatType == "CHANNEL" then
        return
    end
    C_ChatInfo.SendChatMessage(text, chatType, nil, target)
end

local function SendRunToChat(instanceId, run)
    local editBox = ChatEdit_GetActiveWindow()
    if not editBox then
        print("Press enter and try again")
        return
    end

    local dungeon = addon.Dungeons:Get(instanceId)
    local dungeonName = dungeon.name
    local durationText = addon.Utility:FormatTime(run.duration, 3)
    local header
    if run.medalIndex then
        local medalLabel = addon.Dungeons:GetMedalLabelByIndex(run.medalIndex)
        header = string.format("%s - %s %s", dungeonName, durationText, medalLabel)
    else
        header = string.format("%s - %s", dungeonName, durationText)
    end
    SendMessageInCurrentChannel(editBox, header)

    local splitProfile = addon.SplitProfile:Get(instanceId)
    for index, split in ipairs(run.splits or {}) do
        local splitDefinition = splitProfile.splits[index]
        local label = addon.SplitProfile:FormatSplitLabel(split, splitDefinition)
        local splitDurationText = BuildSplitDurationText(split)
        SendMessageInCurrentChannel(editBox, string.format("%s - %s", label, splitDurationText))
    end

    local runnersText = "Runners: " .. run.runners[1].name
    for i = 2, #run.runners do
        runnersText = runnersText .. ", " .. run.runners[i].name
    end
    SendMessageInCurrentChannel(editBox, runnersText)
end

local function UpdateComparisonRunIndex(table, instanceId, index)
    local isAlreadySelected = (table:GetSelection() == index)
    if isAlreadySelected then
        addon.RunHistory:SetComparisonRunIndex(instanceId, nil)
    else
        addon.RunHistory:SetComparisonRunIndex(instanceId, index)
    end
end

local function GetSortDirection(table, sortby)
    local column = table.cols[sortby]
    return column.sort or column.defaultsort
end

local function CompareRowValues(tableFrame, rowa, rowb, sortby, lessThan)
    local aRow = tableFrame.data[rowa]
    local bRow = tableFrame.data[rowb]
    local direction = GetSortDirection(tableFrame, sortby)
    if direction == addon.LST.SORT_ASC then
        return lessThan(aRow, bRow)
    end
    return lessThan(bRow, aRow)
end

local function BuildColumns()
    return {
        {
            name = "Date",
            width = 150,
            align = "LEFT",
            index = 1,
            sort = addon.LST.SORT_DSC,
            defaultsort = addon.LST.SORT_DSC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(a, b)
                    local aStartTimestamp = a.run.startTimestamp
                    local bStartTimestamp = b.run.startTimestamp
                    return aStartTimestamp < bStartTimestamp or
                        (aStartTimestamp == bStartTimestamp and rowa < rowb)
                end)
            end
        },
        {
            name = "Duration",
            width = 110,
            align = "LEFT",
            index = 2,
            defaultsort = addon.LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(a, b)
                    local aDuration = a.run.duration
                    local bDuration = b.run.duration
                    return aDuration < bDuration or
                        (aDuration == bDuration and (a.run.startTimestamp > b.run.startTimestamp or
                            (a.run.startTimestamp == b.run.startTimestamp and rowa > rowb)))
                end)
            end
        },
        {
            name = "Medal",
            width = 70,
            align = "LEFT",
            index = MEDAL_COLUMN_INDEX,
            defaultsort = addon.LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(a, b)
                    local aMedal = a.run.medalIndex or addon.Dungeons.INCOMPLETE_MEDAL_INDEX
                    local bMedal = b.run.medalIndex or addon.Dungeons.INCOMPLETE_MEDAL_INDEX
                    return aMedal < bMedal or (aMedal == bMedal and (a.run.startTimestamp > b.run.startTimestamp or
                        (a.run.startTimestamp == b.run.startTimestamp and rowa > rowb)))
                end)
            end
        },
        {
            name = "Runner",
            width = 130,
            align = "LEFT",
            index = RUNNER_COLUMN_INDEX,
            defaultsort = addon.LST.SORT_ASC,
            comparesort = function(tableFrame, rowa, rowb, sortby)
                return CompareRowValues(tableFrame, rowa, rowb, sortby, function(a, b)
                    local aRunner = a.run.runners[1].name
                    local bRunner = b.run.runners[1].name
                    return aRunner < bRunner or (aRunner == bRunner and (a.run.startTimestamp > b.run.startTimestamp or
                        (a.run.startTimestamp == b.run.startTimestamp and rowa > rowb)))
                end)
            end
        }
    }
end

local function BuildRowValues(run)
    return {
        { value = FormatRunDate(run.startTimestamp) },
        { value = addon.Utility:FormatTime(run.duration, 3) },
        { value = BuildMedalText(run) },
        { value = BuildRunnerNameText(run) },
    }
end

local function BuildRows(instanceId)
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

local function UpdateTableData(self)
    self.table:SetData(BuildRows(self.selectedInstanceId))
end

local function UpdateComparisonHintAndExportButton(self, hasSelection)
    if hasSelection == nil then
        hasSelection = self.table:GetSelection()
    end
    if hasSelection or #self.table.filtered == 0 or #self.table.filtered >= self.table.displayRows then
        self.comparisonHint:Hide()
    else
        self.comparisonHint:Show()
    end
    if hasSelection then
        self.exportButton:Enable()
    else
        self.exportButton:Disable()
    end
end

local function SyncSelectionAndComparisonRun(self)
    local comparisonRunIndex = addon.RunHistory:GetComparisonRunIndex(self.selectedInstanceId)
    if comparisonRunIndex then
        self.table:SetSelection(comparisonRunIndex)
    else
        self.table:ClearSelection()
    end
    UpdateComparisonHintAndExportButton(self)
end

local function SelectBestFilteredRun(self)
    local index = FindBestFilteredRun(self.table)
    if index then
        self.table:SetSelection(index)
        addon.RunHistory:SetComparisonRunIndex(self.selectedInstanceId, index)
    end
    UpdateComparisonHintAndExportButton(self)
end

local function EnableDeleteMode(self, isEnabled)
    if self.deleteModeActive == isEnabled then
        return
    end

    self.deleteModeActive = isEnabled
    if isEnabled then
        self.table:SetDefaultHighlight(unpack(DELETE_MODE_HIGHTLIGHT))
        self.table:ClearSelection()
        self.comparisonHint:Hide()
    else
        self.table:SetDefaultHighlight(unpack(COMPARISON_RUN_SELECTION_HIGHTLIGHT))
        SyncSelectionAndComparisonRun(self)
    end
end

local function CreateTable(self)
    local rowHeight = 20
    local tableFrame = addon.LST:CreateST(BuildColumns(), 10, rowHeight, nil, self.runsFrame, false)

    local comparisonHint = tableFrame.frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    comparisonHint:SetPoint("BOTTOM", tableFrame.frame, "BOTTOM", 0, 8)
    comparisonHint:SetText("↑ click on a run to compare against ↑")
    comparisonHint:SetTextColor(0.7, 0.7, 0.7)
    SetFont(comparisonHint, 11)
    comparisonHint:Hide()
    self.comparisonHint = comparisonHint

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
    tableFrame:SetDefaultHighlight(unpack(COMPARISON_RUN_SELECTION_HIGHTLIGHT))

    tableFrame:RegisterEvents({
        OnClick = function(rowFrame, cellFrame, data, cols, row, realrow, column, table, button)
            if button == "RightButton" then
                addon.OptionsUI:Hide()
                return true
            end
            if button == "LeftButton" and realrow then
                if IsShiftKeyDown() then
                    local rowData = table:GetRow(realrow)
                    SendRunToChat(self.selectedInstanceId, rowData.run)
                elseif self.deleteModeActive then
                    addon.RunHistory:DeleteRun(self.selectedInstanceId, realrow)
                    UpdateTableData(self)
                else
                    UpdateComparisonRunIndex(table, self.selectedInstanceId, realrow)
                    SyncSelectionAndComparisonRun(self)
                end
                return true
            end
            return false
        end,
        OnEnter = function(rowFrame, cellFrame, data, cols, row, realrow, column, table)
            if not realrow then
                if column and column == MEDAL_COLUMN_INDEX then
                    ShowMedalsTooltip(cellFrame, self.selectedInstanceId)
                end
                return false
            end
            local rowData = table:GetRow(realrow)
            if column == RUNNER_COLUMN_INDEX then
                ShowRunnersTooltip(cellFrame, rowData.run)
            elseif column == MEDAL_COLUMN_INDEX then
                ShowMedalsTooltip(cellFrame, self.selectedInstanceId)
            else
                ShowRunSplitsTooltip(cellFrame, self.selectedInstanceId, rowData.run)
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

function addon.RunHistoryUI:Init()
    local runsFrame = addon.OptionsUI:GetRunsFrame()
    self.runsFrame = runsFrame

    self.instanceIds = BuildSortedInstanceIds()
    self.selectedInstanceId = self.instanceIds[1]

    -- Instance dropdown
    local dropdown = CreateFrame("DropdownButton", "ChallengeModeTimerRunHistoryDropdown", runsFrame,
        "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", runsFrame, "TOPLEFT", 10, 0)
    dropdown:SetWidth(200)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, instanceId in ipairs(self.instanceIds) do
            local dungeon = addon.Dungeons:Get(instanceId)
            local button = rootDescription:CreateButton(dungeon.name,
                function(v) self:SetSelectedInstance(v) end, instanceId)
            button:SetIsSelected(function(v) return v == self.selectedInstanceId end)
        end
    end)
    self.dropdown = dropdown

    -- Filter
    local filterBox = CreateFrame("EditBox", nil, runsFrame, "InputBoxTemplate")
    filterBox:SetSize(150, 20)
    filterBox:SetPoint("LEFT", dropdown, "RIGHT", 25, 0)
    filterBox:SetAutoFocus(false)
    SetFont(filterBox, 12)

    local filterPlaceholder = "Filter"
    local isPlaceholder = false
    local normalTextColor = { 1, 1, 1 }
    local placeholderTextColor = { 0.6, 0.6, 0.6 }

    local function SetPlaceholder()
        isPlaceholder = true
        filterBox:SetText(filterPlaceholder)
        filterBox:SetTextColor(unpack(placeholderTextColor))
        self.filterText = ""
    end

    local function ClearPlaceholder()
        isPlaceholder = false
        filterBox:SetText("")
        filterBox:SetTextColor(unpack(normalTextColor))
    end

    SetPlaceholder()
    filterBox:SetScript("OnTextChanged", function()
        if isPlaceholder then
            return
        end
        self.filterText = filterBox:GetText()
        self.table:SortData()
        UpdateComparisonHintAndExportButton(self)
    end)
    filterBox:SetScript("OnEditFocusGained", function()
        if isPlaceholder then
            ClearPlaceholder()
        end
    end)
    filterBox:SetScript("OnEditFocusLost", function()
        if filterBox:GetText() == "" then
            SetPlaceholder()
        end
    end)
    filterBox:SetScript("OnEnterPressed", function()
        filterBox:ClearFocus()
    end)

    -- Best run
    local bestRunButton = CreateFrame("Button", nil, runsFrame, "UIPanelButtonTemplate")
    bestRunButton:SetSize(80, filterBox:GetHeight())
    bestRunButton:SetPoint("LEFT", filterBox, "RIGHT", 20, -1)
    bestRunButton:SetText("Best Run")
    bestRunButton:SetScript("OnClick", function()
        SelectBestFilteredRun(self)
    end)
    bestRunButton:SetScript("OnEnter", function()
        ShowBestRunTooltip(bestRunButton, self.table, self.selectedInstanceId)
    end)
    bestRunButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Bottom bar
    local bottomBarFrame = CreateFrame("Frame", nil, runsFrame)
    bottomBarFrame:SetPoint("BOTTOMLEFT", self.runsFrame, "BOTTOMLEFT", 0, 0)
    bottomBarFrame:SetPoint("BOTTOMRIGHT", self.runsFrame, "BOTTOMRIGHT", 0, 0)
    bottomBarFrame:SetHeight(25)
    self.bottomBarFrame = bottomBarFrame

    -- Table
    self.table = CreateTable(self)
    self.table.frame:SetPoint("TOPLEFT", self.dropdown, "BOTTOMLEFT", -10, -30)
    self.table.frame:SetPoint("BOTTOMRIGHT", bottomBarFrame, "TOPRIGHT", 0, 0)

    -- Bottom bar buttons
    local bottomBarButtonFrame = CreateFrame("Frame", nil, bottomBarFrame)
    bottomBarButtonFrame:SetPoint("TOPLEFT", bottomBarFrame, "TOPLEFT", 0, 0)
    bottomBarButtonFrame:SetPoint("BOTTOMRIGHT", bottomBarFrame, "BOTTOMRIGHT", 0, 0)

    local importButton = CreateFrame("Button", nil, bottomBarButtonFrame, "UIPanelButtonTemplate")
    importButton:SetPoint("LEFT", bottomBarButtonFrame, "LEFT", 10, 2)
    importButton:SetSize(bestRunButton:GetWidth(), bestRunButton:GetHeight())
    importButton:SetText("Import")
    importButton:SetScript("OnClick", function()
        addon.ImportExportUI:ToggleImport()
    end)

    local exportButton = CreateFrame("Button", nil, bottomBarButtonFrame, "UIPanelButtonTemplate")
    exportButton:SetPoint("LEFT", importButton, "RIGHT", 10, 0)
    exportButton:SetSize(importButton:GetWidth(), importButton:GetHeight())
    exportButton:SetText("Export")
    exportButton:SetScript("OnClick", function()
        local run = addon.RunHistory:GetComparisonRun(self.selectedInstanceId)
        if run then
            addon.ImportExportUI:ToggleExport(self.selectedInstanceId, run)
        else
            addon.ImportExportUI:ToggleExport()
        end
    end)
    self.exportButton = exportButton

    local exportTooltipFrame = CreateFrame("Frame", nil, exportButton)
    exportTooltipFrame:SetPoint("TOPLEFT", exportButton, "TOPLEFT", 0, 0)
    exportTooltipFrame:SetPoint("BOTTOMRIGHT", exportButton, "BOTTOMRIGHT", 0, 0)
    exportTooltipFrame:SetPropagateMouseClicks(true)
    exportTooltipFrame:SetPropagateMouseMotion(true)
    exportTooltipFrame:SetScript("OnEnter", function()
        if not exportButton:IsEnabled() then
            ShowExportTooltip(exportButton)
        end
    end)
    exportTooltipFrame:SetScript("OnLeave", function()
        if not exportButton:IsEnabled() then
            GameTooltip:Hide()
        end
    end)

    local deleteModeButton = CreateFrame("Button", nil, bottomBarButtonFrame, "UIPanelButtonTemplate")
    deleteModeButton:SetPoint("RIGHT", bottomBarButtonFrame, "RIGHT", -10, 2)
    deleteModeButton:SetSize(100, bestRunButton:GetHeight())
    deleteModeButton:SetText("Delete Mode")

    -- Bottom bar delete mode
    self.deleteModeActive = false

    local bottomBarDeleteModeFrame = CreateFrame("Frame", nil, bottomBarFrame)
    bottomBarDeleteModeFrame:SetPoint("TOPLEFT", bottomBarFrame, "TOPLEFT", 0, 0)
    bottomBarDeleteModeFrame:SetPoint("BOTTOMRIGHT", bottomBarFrame, "BOTTOMRIGHT", 0, 0)
    bottomBarDeleteModeFrame:SetScript("OnShow", function()
        bottomBarButtonFrame:Hide()
    end)
    bottomBarDeleteModeFrame:SetScript("OnHide", function()
        EnableDeleteMode(self, false)
        bottomBarButtonFrame:Show()
    end)
    bottomBarDeleteModeFrame:Hide()

    deleteModeButton:SetScript("OnClick", function()
        bottomBarDeleteModeFrame:Show()
        EnableDeleteMode(self, true)
    end)

    local deleteModeText = bottomBarDeleteModeFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    deleteModeText:SetPoint("LEFT", bottomBarDeleteModeFrame, "LEFT", 10, 2)
    deleteModeText:SetText("Click on a run to delete")
    deleteModeText:SetTextColor(unpack(DELETE_MODE_HIGHTLIGHT))
    deleteModeText:SetAlpha(1)
    SetFont(deleteModeText, 12)

    local deleteModeDoneButton = CreateFrame("Button", nil, bottomBarDeleteModeFrame, "UIPanelButtonTemplate")
    deleteModeDoneButton:SetPoint("RIGHT", bottomBarButtonFrame, "RIGHT", -10, 2)
    deleteModeDoneButton:SetSize(100, bestRunButton:GetHeight())
    deleteModeDoneButton:SetText("Done")
    deleteModeDoneButton:SetScript("OnClick", function()
        bottomBarDeleteModeFrame:Hide()
    end)

    runsFrame:HookScript("OnShow", function()
        self:SetSelectedInstance(self.selectedInstanceId)
        bottomBarDeleteModeFrame:Hide()
    end)
end

function addon.RunHistoryUI:Refresh()
    if not self.table or not self.runsFrame or not self.runsFrame:IsShown() then
        return
    end

    UpdateTableData(self)
    SyncSelectionAndComparisonRun(self)
end

function addon.RunHistoryUI:SetSelectedInstance(instanceId)
    local dungeon = addon.Dungeons:Get(instanceId)
    if not dungeon then
        return
    end
    self.selectedInstanceId = instanceId
    self:Refresh()
end

function addon.RunHistoryUI:ShowRunTooltip(frame, instanceId, run, anchor)
    if not anchor then
        anchor = "ANCHOR_RIGHT"
    end
    GameTooltip:SetOwner(frame, anchor)
    local header = addon.Utility:FormatTime(run.duration, 3)
    if run.medalIndex then
        local medalLabel = addon.Dungeons:GetMedalLabelByIndex(run.medalIndex)
        header = string.format("%s %s", header, medalLabel)
    end
    GameTooltip:SetText(header, 1, 0.82, 0)
    GameTooltip:AddLine(FormatRunDate(run.startTimestamp), 1, 1, 1)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Splits", 1, 0.82, 0)
    AddSplitLinesToTooltip(instanceId, run)
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Runners", 1, 0.82, 0)
    AddRunnerLinesToTooltip(run)
    GameTooltip:Show()
end
