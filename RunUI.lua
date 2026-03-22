local addonName, addon = ...

addon.RunUI = addon.RunUI or {}

local RUN_UI_WIDTH = 300
local MEDAL_LABELS = {
    "Title?",
    "Plat",
    "Gold",
    "Silver",
    "Bronze"
}
local MEDAL_COLORS = {
    { 0.3,  0.8,  1 },    -- title
    { 0.9,  0.9,  1 },    -- platinum
    { 1,    0.82, 0 },    -- gold
    { 0.85, 0.85, 0.85 }, -- silver
    { 0.8,  0.55, 0.25 }  -- bronze
}

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
    timerText:SetFont(addon.Constants.FONT, 22, "OUTLINE")
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
    timerText.milliseconds:SetPoint("CENTER", runFrame, "CENTER", 19, -2.5)
    timerText.milliseconds:SetFont(addon.Constants.FONT, 14, "OUTLINE")
    return timerText
end

local function CreateMedalText(runFrame)
    local medalText = runFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    medalText:SetTextColor(1, 1, 1, 1)
    medalText:SetFont(addon.Constants.FONT, 13, "OUTLINE")
    medalText:SetJustifyH("LEFT")
    return medalText
end

local function GetTimerScale()
    return ChallengeModeTimerDB.runUI.timerScale or 1
end

local function SaveTimerScale(scale)
    ChallengeModeTimerDB.runUI.timerScale = scale
end

local function GetSplitsScale()
    return ChallengeModeTimerDB.runUI.splitsScale or 1
end

local function SaveSplitsScale(scale)
    ChallengeModeTimerDB.runUI.splitsScale = scale
end

local function GetSplitLabelXOffset()
    return ChallengeModeTimerDB.runUI.splitLabelXOffset or -60
end

local function SaveSplitLabelXOffset(offset)
    ChallengeModeTimerDB.runUI.splitLabelXOffset = offset
end

local function GetSplitDurationXOffset()
    return ChallengeModeTimerDB.runUI.splitDurationXOffset or 60
end

local function SaveSplitDurationXOffset(offset)
    ChallengeModeTimerDB.runUI.splitDurationXOffset = offset
end

local function GetSplitComparisonXOffset()
    return ChallengeModeTimerDB.runUI.splitComparisonXOffset or 185
end

local function SaveSplitComparisonXOffset(offset)
    ChallengeModeTimerDB.runUI.splitComparisonXOffset = offset
end

local function GetSplitLabelJustifyH()
    return ChallengeModeTimerDB.runUI.splitLabelJustifyH or "LEFT"
end

local function SaveSplitLabelJustifyH(justifyH)
    ChallengeModeTimerDB.runUI.splitLabelJustifyH = justifyH
end

local function GetSplitDurationJustifyH()
    return ChallengeModeTimerDB.runUI.splitDurationJustifyH or "RIGHT"
end

local function SaveSplitDurationJustifyH(justifyH)
    ChallengeModeTimerDB.runUI.splitDurationJustifyH = justifyH
end

local function GetSplitComparisonJustifyH()
    return ChallengeModeTimerDB.runUI.splitComparisonJustifyH or "LEFT"
end

local function SaveSplitComparisonJustifyH(justifyH)
    ChallengeModeTimerDB.runUI.splitComparisonJustifyH = justifyH
end

local function GetShowMedalTime()
    if ChallengeModeTimerDB.runUI.showMedalTime == nil then
        return true
    end
    return ChallengeModeTimerDB.runUI.showMedalTime
end

local function SaveShowMedalTime(enabled)
    ChallengeModeTimerDB.runUI.showMedalTime = enabled
end

local function GetRunUIPosition()
    return ChallengeModeTimerDB.runUI.position
end

local function SaveRunUIPosition(frame)
    local point, relativeTo, relativePoint, xOfs, yOfs = frame:GetPoint(1)
    ChallengeModeTimerDB.runUI.position = {
        point = point,
        relativePoint = relativePoint,
        x = xOfs,
        y = yOfs,
    }
end

local function BuildSplitDifferenceTextAndColor(split, comparisonSplit)
    if split.completed and split.duration ~= 0 and comparisonSplit then
        if comparisonSplit.completed and comparisonSplit.duration ~= 0 then
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

local function BuildNextMedalText(runDuration, instanceId)
    local dungeonData = addon.Constants.CHALLENGE_MODE_DUNGEONS[instanceId]
    for index, medalTime in ipairs(dungeonData.medals) do
        if runDuration < medalTime then
            local label = MEDAL_LABELS[index]
            local timeText = dungeonData.formattedMedalTimes[index]
            local color = MEDAL_COLORS[index]
            return string.format("%s %s", timeText, label), color[1], color[2], color[3], 1
        end
    end
    return "", 1, 1, 1, 1
end

local function SetSplitTextXOffset(splitLines, textKey, offset)
    for _, line in ipairs(splitLines) do
        local text = line[textKey]
        text:ClearAllPoints()
        text:SetPoint("CENTER", line.frame, "CENTER", offset, 0)
    end
end

local function SetSplitTextJustifyH(splitLines, textKey, justifyH)
    for _, line in ipairs(splitLines) do
        local text = line[textKey]
        text:SetJustifyH(justifyH)
    end
end

function addon.RunUI:UpdateTimerText(runDuration)
    local minutesText, secondsTensText, secondsOnesText, dotText, tenthsText = FormatTimeParts(runDuration)
    self.timerText.minutes:SetText(minutesText)
    self.timerText.secondsTens:SetText(secondsTensText)
    self.timerText.secondsOnes:SetText(secondsOnesText)
    self.timerText.dot:SetText(dotText)
    self.timerText.milliseconds:SetText(tenthsText)

    if self.showMedalTime then
        local medalText, medalR, medalG, medalB, medalA = BuildNextMedalText(
            runDuration,
            self.run.state.instanceId
        )
        self.medalText:SetText(medalText)
        self.medalText:SetTextColor(medalR, medalG, medalB, medalA)
    end
end

function addon.RunUI:Init()
    if not ChallengeModeTimerDB.runUI then
        ChallengeModeTimerDB.runUI = {}
    end

    self.run = addon.Run:CreateRun(1004)

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

    local timerFrame = CreateFrame("Frame", nil, runFrame)
    timerFrame:SetPoint("TOPLEFT", runFrame, "TOPLEFT", 0, 0)
    timerFrame:SetPoint("TOPRIGHT", runFrame, "TOPRIGHT", 0, 0)
    timerFrame:SetScale(GetTimerScale())
    self.timerFrame = timerFrame

    self.timerText = CreateTimerText(timerFrame)

    self.medalText = CreateMedalText(runFrame)
    self.medalText:SetPoint("LEFT", timerFrame, "RIGHT", -90, 0)
    self:SetShowMedalTime(GetShowMedalTime())
    self:UpdateTimerText(0)

    timerFrame:SetHeight(self.timerText.secondsOnes:GetHeight())

    local splitsFrame = CreateFrame("Frame", nil, runFrame)
    splitsFrame:SetPoint("TOP", timerFrame, "BOTTOM", 0, 0)
    splitsFrame:SetSize(runFrame:GetWidth(), 1)
    splitsFrame:EnableMouse(false)
    splitsFrame:RegisterForDrag("LeftButton")
    splitsFrame:SetScale(GetSplitsScale())

    for _, frame in ipairs({ runFrame, splitsFrame }) do
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

    self.runFrame = runFrame

    self.splitsFrame = splitsFrame
    self.splitLines = {}

    self.moveModeEnabled = false
end

function addon.RunUI:SetMoveMode(enabled)
    if enabled == self.moveModeEnabled then
        return
    end

    self.moveModeEnabled = enabled
    self.runFrame:EnableMouse(enabled)
    self.splitsFrame:EnableMouse(enabled)

    if not enabled then
        SaveRunUIPosition(self.runFrame)
    end
end

function addon.RunUI:IsMoveModeEnabled()
    return self.moveModeEnabled
end

function addon.RunUI:ToggleMoveMode()
    self:SetMoveMode(not self.moveModeEnabled)
end

function addon.RunUI:SetTimerScale(scale)
    self.timerFrame:SetScale(scale)
    SaveTimerScale(scale)
end

function addon.RunUI:GetTimerScale()
    return GetTimerScale()
end

function addon.RunUI:SetSplitsScale(scale)
    self.splitsFrame:SetScale(scale)
    SaveSplitsScale(scale)
end

function addon.RunUI:GetSplitsScale()
    return GetSplitsScale()
end

function addon.RunUI:SetSplitLabelXOffset(offset)
    SaveSplitLabelXOffset(offset)
    SetSplitTextXOffset(self.splitLines, "label", offset)
end

function addon.RunUI:GetSplitLabelXOffset()
    return GetSplitLabelXOffset()
end

function addon.RunUI:SetSplitDurationXOffset(offset)
    SaveSplitDurationXOffset(offset)
    SetSplitTextXOffset(self.splitLines, "duration", offset)
end

function addon.RunUI:GetSplitDurationXOffset()
    return GetSplitDurationXOffset()
end

function addon.RunUI:SetSplitComparisonXOffset(offset)
    SaveSplitComparisonXOffset(offset)
    SetSplitTextXOffset(self.splitLines, "comparison", offset)
end

function addon.RunUI:GetSplitComparisonXOffset()
    return GetSplitComparisonXOffset()
end

function addon.RunUI:SetSplitLabelJustifyH(justifyH)
    SaveSplitLabelJustifyH(justifyH)
    SetSplitTextJustifyH(self.splitLines, "label", justifyH)
end

function addon.RunUI:GetSplitLabelJustifyH()
    return GetSplitLabelJustifyH()
end

function addon.RunUI:SetSplitDurationJustifyH(justifyH)
    SaveSplitDurationJustifyH(justifyH)
    SetSplitTextJustifyH(self.splitLines, "duration", justifyH)
end

function addon.RunUI:GetSplitDurationJustifyH()
    return GetSplitDurationJustifyH()
end

function addon.RunUI:SetSplitComparisonJustifyH(justifyH)
    SaveSplitComparisonJustifyH(justifyH)
    SetSplitTextJustifyH(self.splitLines, "comparison", justifyH)
end

function addon.RunUI:GetSplitComparisonJustifyH()
    return GetSplitComparisonJustifyH()
end

function addon.RunUI:SetShowMedalTime(isEnabled)
    SaveShowMedalTime(isEnabled)
    self.showMedalTime = isEnabled

    if isEnabled then
        self.medalText:Show()
        self:UpdateTimerText(self.run.duration)
    else
        self.medalText:Hide()
    end
end

function addon.RunUI:GetShowMedalTime()
    return GetShowMedalTime()
end

function addon.RunUI:UpdateSplits()
    local run = self.run
    local comparisonRun = addon.RunHistory:GetComparisonRun(run.state.instanceId)
    local splitProfile = addon.SplitProfile:Get(run.state.instanceId)

    local lineHeight = 20
    local distanceFromTimer = 6
    local labelXOffset = GetSplitLabelXOffset()
    local durationXOffset = GetSplitDurationXOffset()
    local comparisonXOffset = GetSplitComparisonXOffset()
    local labelJustifyH = GetSplitLabelJustifyH()
    local durationJustifyH = GetSplitDurationJustifyH()
    local comparisonJustifyH = GetSplitComparisonJustifyH()
    for index, split in ipairs(run.splits) do
        local line = self.splitLines[index]
        if not line then
            local lineFrame = CreateFrame("Frame", nil, self.splitsFrame)
            lineFrame:SetPoint("TOPLEFT", self.splitsFrame, "TOPLEFT", 0, -(index - 1) * lineHeight - distanceFromTimer)
            lineFrame:SetSize(self.splitsFrame:GetWidth(), lineHeight)

            local label = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            label:SetPoint("CENTER", lineFrame, "CENTER", labelXOffset, 0)
            label:SetWidth(220)
            label:SetJustifyH(labelJustifyH)
            label:SetFont(addon.Constants.FONT, 14, "OUTLINE")

            local duration = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            duration:SetPoint("CENTER", lineFrame, "CENTER", durationXOffset, 0)
            duration:SetWidth(120)
            duration:SetJustifyH(durationJustifyH)
            duration:SetFont(addon.Constants.FONT, 14, "OUTLINE")
            duration:SetTextColor(1, 1, 1, 1)

            local comparison = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            comparison:SetPoint("CENTER", lineFrame, "CENTER", comparisonXOffset, 0)
            comparison:SetWidth(120)
            comparison:SetJustifyH(comparisonJustifyH)
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
        line.label:SetText(addon.SplitProfile:FormatSplitLabel(split, splitDefinition))
        if split.completed then
            line.label:SetTextColor(0.2, 1, 0.2, 1)
        else
            line.label:SetTextColor(1, 1, 1, 1)
        end

        local comparisonSplit = comparisonRun and comparisonRun.splits[index]
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

    self.splitsFrame:SetHeight(#run.splits * lineHeight)
end

function addon.RunUI:SetRun(run)
    self.run = run
    self:UpdateSplits()
    self:UpdateTimerText(self.run.duration)
end

function addon.RunUI:Show()
    self.runFrame:Show()
end

function addon.RunUI:IsShown()
    return self.runFrame:IsShown()
end

function addon.RunUI:Hide()
    self.runFrame:Hide()
end
