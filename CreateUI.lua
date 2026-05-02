local _, addon = ...

addon.CreateUI = addon.CreateUI or {}

local function ParseDuration(text)
    local minutes, seconds = string.split(":", text, 2)
    local minutesNumber = tonumber(minutes)
    if not minutesNumber then
        return nil
    end
    if seconds then
        local secondsNumber = tonumber(seconds)
        if not secondsNumber then
            return nil
        end
        return addon.Utility:RoundDuration(minutesNumber * 60 + secondsNumber)
    end
    return addon.Utility:RoundDuration(minutesNumber)
end

local function UpdateRun(instanceId, run, splitLines, comment)
    local splitProfile = addon.SplitProfile:Get(instanceId)

    local completedCount = 0

    run.duration = 0

    for index, split in ipairs(run.splits) do
        local duration = splitLines[index].duration
        if duration then
            completedCount = completedCount + 1
            split.completed = true
            split.duration = duration
            split.quantity = splitProfile.splits[index].totalQuantity
        else
            split.completed = false
            split.duration = 0
            split.quantity = 0
        end
        if split.duration > run.duration then
            run.duration = duration
        end
    end

    run.completed = (completedCount == #run.splits)
    if run.completed then
        run.medalIndex = addon.Dungeons:GetMedalIndexByDuration(instanceId, run.duration)
    else
        run.medalIndex = nil
    end

    if comment == "" then
        run.comment = nil
    else
        run.comment = comment
    end
end

local function CreateRun(instanceId, splitLines, comment)
    local run = addon.Run:CreateRun(instanceId)
    run.runners = nil
    run.startTimestamp = time()
    UpdateRun(instanceId, run, splitLines, comment)
    return run
end

local function HasValidDuration(splitLines)
    local validDurationCount = 0
    for _, line in ipairs(splitLines) do
        if line.frame:IsShown() then
            if line.duration then
                validDurationCount = validDurationCount + 1
            elseif line.editBox:GetText() ~= "" then
                return false
            end
        end
    end
    return (validDurationCount > 0)
end

local function FocusFirstEmptyEditBox(splitLines)
    for _, line in ipairs(splitLines) do
        if line.editBox:GetText() == "" then
            line.editBox:SetFocus(true)
            return
        end
    end
end

local function InitFrame(frame, instanceId, splitLines, confirmButton)
    local splitProfile = addon.SplitProfile:Get(instanceId)

    local lineHeight = 27
    local distanceFromTop = 20
    local commentBoxHeight = 80

    frame:SetHeight(#splitProfile.splits * lineHeight + 2 * distanceFromTop + commentBoxHeight + 29)

    for index, splitDefinition in ipairs(splitProfile.splits) do
        local line = splitLines[index]
        if not line then
            local lineFrame = CreateFrame("Frame", nil, frame)
            lineFrame:SetPoint("TOPLEFT", frame, "TOPLEFT", 0,
                -(index - 1) * lineHeight - distanceFromTop)
            lineFrame:SetSize(frame:GetWidth(), lineHeight)

            local label = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetWidth(180)
            label:SetJustifyH("RIGHT")
            label:SetTextColor(1, 1, 1)
            label:SetFont(addon.Constants.FONT, 14, "OUTLINE")

            local editBox = CreateFrame("EditBox", nil, lineFrame, "InputBoxTemplate")
            editBox:SetPoint("RIGHT", lineFrame, "RIGHT", -35, 0)
            editBox:SetSize(80, 24)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(9)
            editBox:SetFontObject(addon.Constants.FONT_OBJECT)
            editBox:SetScript("OnEnterPressed", function(eb)
                eb:ClearFocus()
            end)
            editBox:SetScript("OnTabPressed", function(eb)
                eb:ClearFocus()
                if index < #splitLines then
                    splitLines[index + 1].editBox:SetFocus(true)
                else
                    splitLines[1].editBox:SetFocus(true)
                end
            end)

            label:SetPoint("RIGHT", editBox, "LEFT", -10, 0)

            line = {
                frame = lineFrame,
                label = label,
                editBox = editBox
            }

            editBox:HookScript("OnTextChanged", function()
                line.duration = ParseDuration(editBox:GetText())
                if HasValidDuration(splitLines) then
                    confirmButton:Enable()
                else
                    confirmButton:Disable()
                end
            end)

            splitLines[index] = line
        end

        line.label:SetText(splitDefinition.name)
        line.duration = nil
        line.editBox:SetText("")

        line.frame:Show()
    end

    for index = #splitProfile.splits + 1, #splitLines do
        splitLines[index].frame:Hide()
    end

    if not frame.commentBox then
        local commentLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        commentLabel:SetPoint("LEFT", frame, "LEFT", 20, 0)
        commentLabel:SetText("Comment")

        local scrollFrame, editBox = addon.Utility:CreateScrollableEditBox(frame)
        editBox:SetMaxLetters(300)

        scrollFrame:SetPoint("TOP", commentLabel, "BOTTOM", 0, -11)
        scrollFrame:SetPoint("BOTTOM", confirmButton, "TOP", 0, 11)

        frame.commentLabel = commentLabel
        frame.commentBox = editBox
    end

    frame.commentLabel:SetPoint("TOP", splitLines[#splitProfile.splits].frame, "BOTTOM", 0, -12)
    frame.commentBox:SetText("")

    frame:Show()
    FocusFirstEmptyEditBox(splitLines)
end

local function HandleToggleBehavior(frame, splitLines)
    if frame:IsShown() then
        frame:Hide()
    else
        frame:Show()
        FocusFirstEmptyEditBox(splitLines)
    end
end

function addon.CreateUI:Init()
    if self.createFrame then
        return
    end

    -- Create
    local createFrame = addon.PopupUI:CreatePopupFrame(addon.OptionsUI:GetRunsFrame())
    self.createFrame = createFrame

    local createButton = addon.PopupUI:AddButtonsToPopupFrame(createFrame, true)
    self.createButton = createButton

    self.createInstanceId = 0
    self.createSplitLines = {}

    -- Edit
    local editFrame = addon.PopupUI:CreatePopupFrame(addon.OptionsUI:GetRunsFrame())
    self.editFrame = editFrame

    local editButton = addon.PopupUI:AddButtonsToPopupFrame(editFrame, true)
    editButton:SetText("Save")
    self.editButton = editButton

    self.editInstanceId = 0
    self.editRun = {}
    self.editSplitLines = {}
end

function addon.CreateUI:ToggleCreate(instanceId)
    self:Init()
    if self.createInstanceId == instanceId then
        HandleToggleBehavior(self.createFrame, self.createSplitLines)
        return
    end

    local createButton = self.createButton

    InitFrame(self.createFrame, instanceId, self.createSplitLines, createButton)
    self.createInstanceId = instanceId

    createButton:SetScript("OnClick", function()
        local run = CreateRun(instanceId, self.createSplitLines, self.createFrame.commentBox:GetText())
        local runIndex = addon.RunHistory:AddRun(instanceId, run)
        addon.RunHistory:SetComparisonRunIndex(instanceId, runIndex)
        self.createInstanceId = 0
        self.createFrame:Hide()
        addon.RunHistoryUI:Refresh()
    end)
    createButton:SetScript("OnEnter", function()
        local run = CreateRun(instanceId, self.createSplitLines, self.createFrame.commentBox:GetText())
        addon.RunHistoryUI:ShowRunTooltip(self.createButton, instanceId, run)
    end)
    createButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function addon.CreateUI:ToggleEdit(instanceId, runIndex)
    self:Init()
    local run = addon.RunHistory:GetRun(instanceId, runIndex)
    if self.editInstanceId == instanceId and self.editRun == run then
        HandleToggleBehavior(self.editFrame, self.editSplitLines)
        return
    end

    local editButton = self.editButton

    InitFrame(self.editFrame, instanceId, self.editSplitLines, editButton)
    self.editInstanceId = instanceId
    self.editRun = run
    run = addon.Utility:DeepCopy(run)

    for index, split in ipairs(run.splits) do
        if split.completed then
            local line = self.editSplitLines[index]
            line.editBox:SetText(addon.Utility:FormatTime(split.duration, 3))
        end
    end
    FocusFirstEmptyEditBox(self.editSplitLines)

    if run.comment then
        self.editFrame.commentBox:SetText(run.comment)
    end

    editButton:SetScript("OnClick", function()
        UpdateRun(instanceId, run, self.editSplitLines, self.editFrame.commentBox:GetText())
        addon.RunHistory:SetRun(instanceId, run, runIndex)
        addon.RunHistoryUI:Refresh()
        self.editFrame:Hide()
    end)
    editButton:SetScript("OnEnter", function()
        UpdateRun(instanceId, run, self.editSplitLines, self.editFrame.commentBox:GetText())
        addon.RunHistoryUI:ShowRunTooltip(self.editButton, instanceId, run)
    end)
    editButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end
