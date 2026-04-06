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

local function CreateRun(splitLines, instanceId)
    local run = addon.Run:CreateRun(instanceId)
    run.runners = nil
    local splitProfile = addon.SplitProfile:Get(instanceId)

    local completedCount = 0

    run.startTimestamp = time()
    run.duration = 0

    for index, split in ipairs(run.splits) do
        local duration = splitLines[index].duration
        if duration then
            completedCount = completedCount + 1
            split.completed = true
            split.duration = duration
            if duration > run.duration then
                run.duration = duration
            end
            split.quantity = splitProfile.splits[index].totalQuantity
        end
    end

    run.completed = (completedCount == #run.splits)
    if run.completed then
        run.medalIndex = addon.Dungeons:GetMedalIndexByDuration(instanceId, run.duration)
    end

    return run
end

local function HasValidDuration(splitLines)
    local validDurationCount = 0
    for _, line in ipairs(splitLines) do
        if line.duration then
            validDurationCount = validDurationCount + 1
        elseif line.editBox:GetText() ~= "" then
            return false
        end
    end
    return (validDurationCount > 0)
end

function addon.CreateUI:Init()
    if self.createFrame then
        return
    end

    local createFrame = addon.PopupUI:CreatePopupFrame(addon.OptionsUI:GetRunsFrame())
    self.createFrame = createFrame

    local createButton = addon.PopupUI:AddButtonsToPopupFrame(createFrame, true)
    self.createButton = createButton

    self.instanceId = 0
    self.splitLines = {}
end

function addon.CreateUI:ToggleCreate(instanceId)
    self:Init()
    if self.instanceId == instanceId then
        if self.createFrame:IsShown() then
            self.createFrame:Hide()
        else
            self.createFrame:Show()
            for _, line in ipairs(self.splitLines) do
                if line.editBox:GetText() == "" then
                    line.editBox:SetFocus(true)
                    return
                end
            end
        end
        return
    end

    local splitProfile = addon.SplitProfile:Get(instanceId)

    local lineHeight = 27
    local distanceFromTop = 20

    self.createFrame:SetHeight(#splitProfile.splits * lineHeight + 2 * distanceFromTop + 29)

    for index, splitDefinition in ipairs(splitProfile.splits) do
        local line = self.splitLines[index]
        if not line then
            local lineFrame = CreateFrame("Frame", nil, self.createFrame)
            lineFrame:SetPoint("TOPLEFT", self.createFrame, "TOPLEFT", 0,
                -(index - 1) * lineHeight - distanceFromTop)
            lineFrame:SetSize(self.createFrame:GetWidth(), lineHeight)

            local label = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetWidth(180)
            label:SetJustifyH("RIGHT")
            label:SetTextColor(1, 1, 1)
            label:SetFont(addon.Constants.FONT, 14, "OUTLINE")

            local editBox = CreateFrame("EditBox", nil, lineFrame, "InputBoxTemplate")
            editBox:SetPoint("RIGHT", lineFrame, "RIGHT", -45, 0)
            editBox:SetSize(70, 24)
            editBox:SetAutoFocus(false)
            editBox:SetMaxLetters(8)
            editBox:SetFontObject(addon.Constants.FONT_OBJECT)
            editBox:SetScript("OnEnterPressed", function(eb)
                eb:ClearFocus()
            end)
            editBox:SetScript("OnTabPressed", function(eb)
                eb:ClearFocus()
                if index < #self.splitLines then
                    self.splitLines[index + 1].editBox:SetFocus(true)
                else
                    self.splitLines[1].editBox:SetFocus(true)
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
                if HasValidDuration(self.splitLines) then
                    self.createButton:Enable()
                else
                    self.createButton:Disable()
                end
            end)

            self.splitLines[index] = line
        end

        line.label:SetText(splitDefinition.name)
        line.duration = nil
        line.editBox:SetText("")

        line.frame:Show()
    end

    for index = #splitProfile.splits + 1, #self.splitLines do
        self.splitLines[index].frame:Hide()
    end

    self.createButton:SetScript("OnClick", function()
        local run = CreateRun(self.splitLines, instanceId)
        addon.RunHistory:AddRun(instanceId, run)
        addon.RunHistoryUI:Refresh()
        self.createFrame:Hide()
    end)
    self.createButton:SetScript("OnEnter", function()
        local run = CreateRun(self.splitLines, instanceId)
        addon.RunHistoryUI:ShowRunTooltip(self.createButton, instanceId, run)
    end)
    self.createButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    self.instanceId = instanceId
    self.createFrame:Show()

    self.splitLines[1].editBox:SetFocus(true)
end
