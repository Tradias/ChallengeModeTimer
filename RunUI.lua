local addonName, addon = ...

addon.RunUI = addon.RunUI or {}

local RUN_UI_WIDTH = 300

local function FormatTimeParts(seconds)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local tenths = math.floor((seconds % 1) * 10)
    local minutesText
    local secondsText
    if minutes == 0 then
        minutesText = ""
        secondsText = string.format("%02d", secs)
    else
        minutesText = string.format("%d:", minutes)
        secondsText = string.format("%02d", secs)
    end
    local secondsTensText = string.sub(secondsText, 1, 1)
    local secondsOnesText = string.sub(secondsText, 2, 2)
    return minutesText, secondsTensText, secondsOnesText, ".", string.format("%01d", tenths)
end

local function CreateTimerTextPart(runFrame)
    local timerText = runFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timerText:SetTextColor(1, 1, 1, 1)
    timerText:SetFont(addon.Constants.FONT, 21, "OUTLINE")
    return timerText
end

local function CreateTimerText(runFrame)
    local timerText = {
        minutes = CreateTimerTextPart(runFrame),
        secondsTens = CreateTimerTextPart(runFrame),
        secondsOnes = CreateTimerTextPart(runFrame),
        dot = CreateTimerTextPart(runFrame),
        milliseconds = CreateTimerTextPart(runFrame),
    }
    timerText.minutes:SetPoint("RIGHT", runFrame, "CENTER", -20, 0)
    timerText.secondsTens:SetPoint("CENTER", runFrame, "CENTER", -15, 0)
    timerText.secondsOnes:SetPoint("CENTER", runFrame, "CENTER", 0, 0)
    timerText.dot:SetPoint("CENTER", runFrame, "CENTER", 9, 0)
    timerText.milliseconds:SetPoint("CENTER", runFrame, "CENTER", 19, -2)
    timerText.milliseconds:SetFont(addon.Constants.FONT, 13, "OUTLINE")
    return timerText
end

local function GetRunUIPosition()
    return ChallengeModeTimerDB.runUIPosition
end

local function SaveRunUIPosition(frame)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    ChallengeModeTimerDB.runUIPosition = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

local function BuildSplitDifferenceTextAndColor(split, comparisonSplit)
    if split.completed and split.duration ~= 0 then
        if comparisonSplit and comparisonSplit.completed and comparisonSplit.duration ~= 0 then
            local difference = split.duration - comparisonSplit.duration
            local differenceText = addon.Utility:FormatTime(math.abs(difference))
            if difference > 0 then
                return "+" .. differenceText, 1, 0.2, 0.2, 1
            else
                return "-" .. differenceText, 0.2, 1, 0.2, 1
            end
        else
            return "-", 1, 1, 1, 1
        end
    end
    return "", 1, 1, 1, 1
end

local function BuildSplitDurationText(split, comparisonSplit)
    if split.completed and split.duration ~= 0 then
        return addon.Utility:FormatTime(split.duration)
    end
    if comparisonSplit and comparisonSplit.completed and comparisonSplit.duration ~= 0 then
        return addon.Utility:FormatTime(comparisonSplit.duration)
    end
    return "-"
end

function addon.RunUI:UpdateTimerText(runDuration)
    local minutesText, secondsTensText, secondsOnesText, dotText, tenthsText = FormatTimeParts(runDuration)
    self.timerText.minutes:SetText(minutesText)
    self.timerText.secondsTens:SetText(secondsTensText)
    self.timerText.secondsOnes:SetText(secondsOnesText)
    self.timerText.dot:SetText(dotText)
    self.timerText.milliseconds:SetText(tenthsText)
end

function addon.RunUI:Init()
    local runFrame = CreateFrame("Frame", "ChallengeModeTimerRunFrame", UIParent)
    runFrame:Hide()
    runFrame:SetSize(RUN_UI_WIDTH, 25)
    runFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 10, -10)
    local savedPosition = GetRunUIPosition()
    if savedPosition then
        runFrame:ClearAllPoints()
        runFrame:SetPoint(
            savedPosition.point,
            UIParent,
            savedPosition.relativePoint,
            savedPosition.x,
            savedPosition.y
        )
    end
    runFrame:SetFrameLevel(5000)
    runFrame:SetClampedToScreen(true)
    runFrame:SetMovable(true)
    runFrame:EnableMouse(false)
    runFrame:RegisterForDrag("LeftButton")

    self.timerText = CreateTimerText(runFrame)
    self:UpdateTimerText(0)

    self.run = addon.Run:CreateRun(1004)

    local splitFrame = CreateFrame("Frame", nil, runFrame)
    splitFrame:SetPoint("TOP", runFrame, "BOTTOM", 0, -6)
    splitFrame:SetSize(runFrame:GetWidth(), 1)
    splitFrame:EnableMouse(false)
    splitFrame:RegisterForDrag("LeftButton")

    for _, frame in ipairs({ runFrame, splitFrame }) do
        frame:SetScript("OnDragStart", function()
            if self.moveModeEnabled then
                runFrame:StartMoving()
            end
        end)

        frame:SetScript("OnDragStop", function()
            runFrame:StopMovingOrSizing()
            SaveRunUIPosition(runFrame)
        end)
    end

    self.splitFrame = splitFrame
    self.splitLines = {}

    self.runFrame = runFrame

    self.moveModeEnabled = false
    self.wasShownBeforeMove = false
end

function addon.RunUI:SetMoveMode(enabled)
    if enabled == self.moveModeEnabled then
        return
    end

    self.moveModeEnabled = enabled
    self.runFrame:EnableMouse(enabled)
    self.splitFrame:EnableMouse(enabled)

    if enabled then
        self.wasShownBeforeMove = self.runFrame:IsShown()
        addon.Run:SetSampleRun()
        self:Show()
    else
        SaveRunUIPosition(self.runFrame)
        if not self.wasShownBeforeMove then
            self:Hide()
        end
        addon.Run:UnsetSampleRun()
    end
end

function addon.RunUI:IsMoveModeEnabled()
    return self.moveModeEnabled
end

function addon.RunUI:ToggleMoveMode()
    self:SetMoveMode(not self.moveModeEnabled)
end

function addon.RunUI:UpdateSplits()
    local run = self.run
    local comparisonRun = addon.RunHistory:GetComparisonRun(run.state.instanceId)
    local splitProfile = addon.SplitProfile:Get(run.state.instanceId)

    local lineHeight = 20
    for index, split in ipairs(run.splits) do
        local line = self.splitLines[index]
        if not line then
            local lineFrame = CreateFrame("Frame", nil, self.splitFrame)
            lineFrame:SetPoint("TOPLEFT", self.splitFrame, "TOPLEFT", 0, -(index - 1) * lineHeight)
            lineFrame:SetSize(self.splitFrame:GetWidth(), lineHeight)

            local label = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("LEFT", lineFrame, "LEFT", 0, 0)
            label:SetJustifyH("LEFT")
            label:SetFont(addon.Constants.FONT, 14, "OUTLINE")

            local duration = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            duration:SetPoint("RIGHT", lineFrame, "RIGHT", -15, 0)
            duration:SetJustifyH("RIGHT")
            duration:SetFont(addon.Constants.FONT, 14, "OUTLINE")
            duration:SetTextColor(1, 1, 1, 1)

            local comparison = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            comparison:SetPoint("LEFT", duration, "RIGHT", 2, 0)
            comparison:SetJustifyH("LEFT")
            comparison:SetFont(addon.Constants.FONT, 14, "OUTLINE")

            line = {
                frame = lineFrame,
                label = label,
                duration = duration,
                comparison = comparison,
            }
            self.splitLines[index] = line
        end

        local splitDefinition = splitProfile.splits[index]
        local totalQuantity = splitDefinition.totalQuantity
        local currentQuantity = split.quantity
        local comparisonSplit = comparisonRun and comparisonRun.splits[index]

        line.label:SetText(string.format("%s %d/%d", splitDefinition.name, currentQuantity, totalQuantity))
        if split.completed then
            line.label:SetTextColor(0.2, 1, 0.2, 1)
        else
            line.label:SetTextColor(1, 1, 1, 1)
        end

        line.duration:SetText(BuildSplitDurationText(split, comparisonSplit))

        local differenceText, differenceR, differenceG, differenceB, differenceA = BuildSplitDifferenceTextAndColor(
            split, comparisonSplit)
        line.comparison:SetText(differenceText)
        line.comparison:SetTextColor(differenceR, differenceG, differenceB, differenceA)

        line.frame:Show()
    end

    for index = #run.splits + 1, #self.splitLines do
        self.splitLines[index].frame:Hide()
    end

    self.splitFrame:SetHeight(#run.splits * lineHeight)
end

function addon.RunUI:SetRun(run)
    self.run = run
    addon.RunUI:UpdateSplits()
    self:UpdateTimerText(self.run.duration)
end

function addon.RunUI:Show()
    self.runFrame:Show()
end

function addon.RunUI:Hide()
    self.runFrame:Hide()
end
