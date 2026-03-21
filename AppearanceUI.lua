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

local function CreateEditBox(parentFrame)
    local editBox = CreateFrame("EditBox", nil, parentFrame, "InputBoxTemplate")
    editBox:SetSize(80, 24)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject(addon.Constants.FONT_OBJECT)
    editBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)

    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", editBox, "TOPLEFT", 0, 4)

    return editBox, label
end

local function CreateDropdown(parentFrame)
    local dropdown = CreateFrame("Frame", nil, parentFrame, "UIDropDownMenuTemplate")
    local label = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", dropdown, "TOPLEFT", 16, 4)

    UIDropDownMenu_SetWidth(dropdown, 120)
    UIDropDownMenu_JustifyText(dropdown, "LEFT")

    return dropdown, label
end

local function InitializeJustifyDropdown(dropdown, currentValue, onSelect)
    local options = {
        { text = "Left", value = "LEFT" },
        { text = "Center", value = "CENTER" },
        { text = "Right", value = "RIGHT" },
    }

    UIDropDownMenu_Initialize(dropdown, function(_, level)
        for _, option in ipairs(options) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function()
                UIDropDownMenu_SetSelectedValue(dropdown, option.value)
                UIDropDownMenu_SetText(dropdown, option.text)
                onSelect(option.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetSelectedValue(dropdown, currentValue)
    for _, option in ipairs(options) do
        if option.value == currentValue then
            UIDropDownMenu_SetText(dropdown, option.text)
            break
        end
    end
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

    -- Timer scale
    local timerScaleSlider, timerScaleLabel, timerScaleText = CreateSlider(appearanceFrame)
    timerScaleSlider:SetPoint("TOPLEFT", moveButton, "BOTTOMLEFT", 0, -30)
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

    -- Split label X offset
    local splitLabelOffsetInput, splitLabelOffsetLabel = CreateEditBox(appearanceFrame)
    splitLabelOffsetInput:SetPoint("TOPLEFT", splitsScaleSlider, "BOTTOMLEFT", 0, -40)
    splitLabelOffsetInput:SetText(tostring(addon.RunUI:GetSplitLabelXOffset()))
    splitLabelOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitLabelXOffset(value)
        end
    end)
    splitLabelOffsetLabel:SetText("Split label X offset")

    -- Split duration X offset
    local splitDurationOffsetInput, splitDurationOffsetLabel = CreateEditBox(appearanceFrame)
    splitDurationOffsetInput:SetPoint("TOPLEFT", splitLabelOffsetInput, "BOTTOMLEFT", 0, -30)
    splitDurationOffsetInput:SetText(tostring(addon.RunUI:GetSplitDurationXOffset()))
    splitDurationOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitDurationXOffset(value)
        end
    end)
    splitDurationOffsetLabel:SetText("Split duration X offset")

    -- Split comparison X offset
    local splitComparisonOffsetInput, splitComparisonOffsetLabel = CreateEditBox(appearanceFrame)
    splitComparisonOffsetInput:SetPoint("TOPLEFT", splitDurationOffsetInput, "BOTTOMLEFT", 0, -30)
    splitComparisonOffsetInput:SetText(tostring(addon.RunUI:GetSplitComparisonXOffset()))
    splitComparisonOffsetInput:SetScript("OnTextChanged", function(editBox)
        local value = tonumber(editBox:GetText())
        if value then
            addon.RunUI:SetSplitComparisonXOffset(value)
        end
    end)
    splitComparisonOffsetLabel:SetText("Split comparison X offset")

    -- Split label justification
    local splitLabelJustifyDropdown, splitLabelJustifyLabel = CreateDropdown(appearanceFrame)
    splitLabelJustifyDropdown:SetPoint("TOPLEFT", splitComparisonOffsetInput, "BOTTOMLEFT", -16, -30)
    InitializeJustifyDropdown(splitLabelJustifyDropdown, addon.RunUI:GetSplitLabelJustifyH(), function(value)
        addon.RunUI:SetSplitLabelJustifyH(value)
    end)
    splitLabelJustifyLabel:SetText("Split label justification")

    -- Split duration justification
    local splitDurationJustifyDropdown, splitDurationJustifyLabel = CreateDropdown(appearanceFrame)
    splitDurationJustifyDropdown:SetPoint("TOPLEFT", splitLabelJustifyDropdown, "BOTTOMLEFT", 0, -24)
    InitializeJustifyDropdown(splitDurationJustifyDropdown, addon.RunUI:GetSplitDurationJustifyH(), function(value)
        addon.RunUI:SetSplitDurationJustifyH(value)
    end)
    splitDurationJustifyLabel:SetText("Split duration justification")

    -- Split comparison justification
    local splitComparisonJustifyDropdown, splitComparisonJustifyLabel = CreateDropdown(appearanceFrame)
    splitComparisonJustifyDropdown:SetPoint("TOPLEFT", splitDurationJustifyDropdown, "BOTTOMLEFT", 0, -24)
    InitializeJustifyDropdown(splitComparisonJustifyDropdown, addon.RunUI:GetSplitComparisonJustifyH(), function(value)
        addon.RunUI:SetSplitComparisonJustifyH(value)
    end)
    splitComparisonJustifyLabel:SetText("Split comparison justification")
end
