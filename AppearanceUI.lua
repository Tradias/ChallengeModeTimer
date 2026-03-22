local addonName, addon = ...

addon.AppearanceUI = addon.AppearanceUI or {}

local function CreateSlider(parentFrame)
    local slider = CreateFrame("Slider", nil, parentFrame, "OptionsSliderTemplate")
    slider:SetWidth(200)
    slider:SetObeyStepOnDrag(true)

    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)

    local text = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("LEFT", slider, "RIGHT", 8, 0)

    return slider, label, text
end

local function CreateEditBox(parentFrame, labelText)
    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, parentFrame, "InputBoxTemplate")
    editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
    editBox:SetSize(70, 24)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(addon.Constants.FONT_OBJECT)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    return editBox, label
end

local function CreateDropdown(parentFrame, labelText)
    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetText(labelText)

    local dropdown = CreateFrame("DropdownButton", nil, parentFrame, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("LEFT", label, "RIGHT", 8, 0)
    dropdown:SetWidth(80)

    return dropdown, label
end

local function CreateCheckbox(parentFrame, labelText)
    local checkButton = CreateFrame("CheckButton", nil, parentFrame, "UICheckButtonTemplate")
    checkButton.Text:SetText(labelText)
    checkButton.Text:SetFontObject("GameFontNormal")
    return checkButton
end

local function InitializeJustifyDropdown(dropdown, isSelected, onSelect)
    MenuUtil.CreateRadioMenu(dropdown,
        isSelected,
        onSelect,
        { "Left",   "LEFT" },
        { "Center", "CENTER" },
        { "Right",  "RIGHT" }
    )
end

function addon.AppearanceUI:Init()
    local appearanceFrame = addon.OptionsUI:GetAppearanceFrame()

    -- Timer position
    local moveButton = CreateFrame("Button", nil, appearanceFrame, "UIPanelButtonTemplate")
    moveButton:SetSize(110, 24)
    moveButton:SetPoint("TOPLEFT", appearanceFrame, "TOPLEFT", 10, 0)

    local function UpdateMoveButtonText()
        if addon.RunUI:IsMoveModeEnabled() then
            moveButton:SetText("Lock")
        else
            moveButton:SetText("Unlock")
        end
    end

    moveButton:SetScript("OnClick", function()
        addon.RunUI:ToggleMoveMode()
        UpdateMoveButtonText()
    end)

    UpdateMoveButtonText()

    -- Medal time visibility
    local showMedalTimeCheckbox = CreateCheckbox(appearanceFrame, "Show medal time")
    showMedalTimeCheckbox:SetPoint("TOPLEFT", moveButton, "BOTTOMLEFT", -4, -8)
    showMedalTimeCheckbox:SetChecked(addon.RunUI:GetShowMedalTime())
    showMedalTimeCheckbox:SetScript("OnClick", function(button)
        addon.RunUI:SetShowMedalTime(button:GetChecked())
    end)

    -- Timer scale
    local timerScaleSlider, timerScaleLabel, timerScaleText = CreateSlider(appearanceFrame)
    timerScaleSlider:SetPoint("TOPLEFT", showMedalTimeCheckbox, "BOTTOMLEFT", 4, -25)
    timerScaleSlider:SetMinMaxValues(0.5, 2)
    timerScaleSlider:SetValueStep(0.05)
    timerScaleLabel:SetText("Timer scale")

    local function UpdateTimerScaleText(value)
        timerScaleText:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
    end

    timerScaleSlider:SetScript("OnValueChanged", function(_, value)
        UpdateTimerScaleText(value)
        addon.RunUI:SetTimerScale(value)
    end)

    timerScaleSlider:SetValue(addon.RunUI:GetTimerScale())
    UpdateTimerScaleText(timerScaleSlider:GetValue())

    -- Splits scale
    local splitsScaleSlider, splitsScaleLabel, splitsScaleText = CreateSlider(appearanceFrame)
    splitsScaleSlider:SetPoint("TOPLEFT", timerScaleSlider, "BOTTOMLEFT", 0, -40)
    splitsScaleSlider:SetMinMaxValues(0.5, 2)
    splitsScaleSlider:SetValueStep(0.05)
    splitsScaleLabel:SetText("Splits scale")

    local function UpdateSplitsScaleText(value)
        splitsScaleText:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
    end

    splitsScaleSlider:SetScript("OnValueChanged", function(_, value)
        UpdateSplitsScaleText(value)
        addon.RunUI:SetSplitsScale(value)
    end)

    splitsScaleSlider:SetValue(addon.RunUI:GetSplitsScale())
    UpdateSplitsScaleText(splitsScaleSlider:GetValue())

    -- Split label
    local splitLabelOffsetLabel = appearanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    splitLabelOffsetLabel:SetPoint("TOPLEFT", splitsScaleSlider, "BOTTOMLEFT", 0, -25)
    splitLabelOffsetLabel:SetText("Split label")

    local splitLabelOffsetInput, splitLabelOffsetInputLabel = CreateEditBox(appearanceFrame, "X")
    splitLabelOffsetInputLabel:SetPoint("TOPLEFT", splitLabelOffsetLabel, "BOTTOMLEFT", 0, -10)
    splitLabelOffsetInput:SetText(tostring(addon.RunUI:GetSplitLabelXOffset()))
    splitLabelOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitLabelXOffset(value)
        end
    end)

    local splitLabelJustifyDropdown, splitLabelJustifyLabel = CreateDropdown(appearanceFrame, "Align")
    splitLabelJustifyLabel:SetPoint("LEFT", splitLabelOffsetInput, "RIGHT", 25, 0)
    InitializeJustifyDropdown(splitLabelJustifyDropdown,
        function(value)
            return value == addon.RunUI:GetSplitLabelJustifyH()
        end,
        function(value)
            addon.RunUI:SetSplitLabelJustifyH(value)
        end)

    -- Split duration
    local splitDurationLabel = appearanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    splitDurationLabel:SetPoint("TOPLEFT", splitLabelOffsetInputLabel, "BOTTOMLEFT", 0, -25)
    splitDurationLabel:SetText("Split duration")

    local splitDurationOffsetInput, splitDurationOffsetInputLabel = CreateEditBox(appearanceFrame, "X")
    splitDurationOffsetInputLabel:SetPoint("TOPLEFT", splitDurationLabel, "BOTTOMLEFT", 0, -10)
    splitDurationOffsetInput:SetText(tostring(addon.RunUI:GetSplitDurationXOffset()))
    splitDurationOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitDurationXOffset(value)
        end
    end)

    local splitDurationJustifyDropdown, splitDurationJustifyLabel = CreateDropdown(appearanceFrame, "Align")
    splitDurationJustifyLabel:SetPoint("LEFT", splitDurationOffsetInput, "RIGHT", 25, 0)
    InitializeJustifyDropdown(splitDurationJustifyDropdown,
        function(value)
            return value == addon.RunUI:GetSplitDurationJustifyH()
        end,
        function(value)
            addon.RunUI:SetSplitDurationJustifyH(value)
        end)

    -- Split comparison
    local splitComparisonLabel = appearanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    splitComparisonLabel:SetPoint("TOPLEFT", splitDurationOffsetInputLabel, "BOTTOMLEFT", 0, -25)
    splitComparisonLabel:SetText("Split comparison")

    local splitComparisonOffsetInput, splitComparisonOffsetInputLabel = CreateEditBox(appearanceFrame, "X")
    splitComparisonOffsetInputLabel:SetPoint("TOPLEFT", splitComparisonLabel, "BOTTOMLEFT", 0, -10)
    splitComparisonOffsetInput:SetText(tostring(addon.RunUI:GetSplitComparisonXOffset()))
    splitComparisonOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitComparisonXOffset(value)
        end
    end)

    local splitComparisonJustifyDropdown, splitComparisonJustifyLabel = CreateDropdown(appearanceFrame, "Align")
    splitComparisonJustifyLabel:SetPoint("LEFT", splitComparisonOffsetInput, "RIGHT", 25, 0)
    InitializeJustifyDropdown(splitComparisonJustifyDropdown,
        function(value)
            return value == addon.RunUI:GetSplitComparisonJustifyH()
        end,
        function(value)
            addon.RunUI:SetSplitComparisonJustifyH(value)
        end)
end
