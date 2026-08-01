---@type string, ChallengeModeTimerAddon
local _, addon = ...

---@class AppearanceUIModule
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
    editBox:SetSize(50, 24)
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

local function CreateOffsetInputs(parentFrame, frameAbove, name, getOffset, setOffset, getJustify, setJustify)
    local offsetLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    offsetLabel:SetPoint("TOPLEFT", frameAbove, "BOTTOMLEFT", 0, -25)
    offsetLabel:SetText(name)

    local slider = CreateFrame("Slider", nil, parentFrame, "OptionsSliderTemplate")

    local offsetInput, offsetInputLabel = CreateEditBox(parentFrame, "X")
    offsetInputLabel:SetPoint("TOPLEFT", offsetLabel, "BOTTOMLEFT", 0, -10)
    offsetInput:SetText(tostring(getOffset(addon.RunUI)))
    offsetInput:SetScript("OnTextChanged", function(editBox, userInput)
        local value = tonumber(editBox:GetText())
        if value then
            setOffset(addon.RunUI, value)
            if userInput then
                slider:SetValue(value)
            end
        end
    end)

    -- Slider
    slider:SetWidth(200)
    slider:SetObeyStepOnDrag(true)
    slider:SetPoint("LEFT", offsetInputLabel, "RIGHT", 10, 0)
    slider:SetMinMaxValues(-200, 200)
    slider:SetValueStep(5)
    slider:SetScript("OnValueChanged", function(_, value, userInput)
        if userInput then
            offsetInput:SetText(tostring(value))
        end
    end)
    slider:SetValue(getOffset(addon.RunUI))

    offsetInput:SetPoint("TOPLEFT", slider, "TOPRIGHT", 18, 0)

    -- Dropdown
    local alignDropdown, alignLabel = CreateDropdown(parentFrame, "Align")
    alignLabel:SetPoint("LEFT", offsetInput, "RIGHT", 15, 0)
    MenuUtil.CreateRadioMenu(alignDropdown,
        function(value)
            return value == getJustify(addon.RunUI)
        end,
        function(value)
            setJustify(addon.RunUI, value)
        end,
        { "Left", "LEFT" },
        { "Center", "CENTER" },
        { "Right", "RIGHT" }
    )

    return offsetInputLabel
end

function addon.AppearanceUI:Init()
    local appearanceFrame = addon.OptionsUI:GetAppearanceFrame()

    appearanceFrame:HookScript("OnShow", function()
        addon.RunUI:SetMoveMode(true)
    end)

    appearanceFrame:HookScript("OnHide", function()
        addon.RunUI:SetMoveMode(false)
    end)

    -- Reset position
    local resetPositionButton = CreateFrame("Button", nil, appearanceFrame, "UIPanelButtonTemplate")
    resetPositionButton:SetSize(110, 24)
    resetPositionButton:SetPoint("TOPLEFT", appearanceFrame, "TOPLEFT", 10, 0)
    resetPositionButton:SetText("Reset Position")
    resetPositionButton:SetScript("OnClick", function()
        addon.RunUI:ResetPosition()
    end)

    -- Medal time visibility
    local showMedalTimeCheckbox = CreateCheckbox(appearanceFrame, "Show medal time")
    showMedalTimeCheckbox:SetPoint("TOPLEFT", resetPositionButton, "BOTTOMLEFT", -4, -8)
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
    local splitLabelOffsetSliderLabel = CreateOffsetInputs(appearanceFrame, splitsScaleSlider, "Split label",
        addon.RunUI.GetSplitLabelXOffset,
        addon.RunUI.SetSplitLabelXOffset, addon.RunUI.GetSplitLabelJustifyH,
        addon.RunUI.SetSplitLabelJustifyH)

    -- Split duration
    local splitDurationOffsetSliderLabel = CreateOffsetInputs(appearanceFrame, splitLabelOffsetSliderLabel, "Split label",
        addon.RunUI.GetSplitDurationXOffset,
        addon.RunUI.SetSplitDurationXOffset, addon.RunUI.GetSplitDurationJustifyH,
        addon.RunUI.SetSplitDurationJustifyH)

    -- Split comparison
    local splitComparsionOffsetSliderLabel = CreateOffsetInputs(appearanceFrame, splitDurationOffsetSliderLabel,
        "Split label",
        addon.RunUI.GetSplitComparisonXOffset,
        addon.RunUI.SetSplitComparisonXOffset, addon.RunUI.GetSplitComparisonJustifyH,
        addon.RunUI.SetSplitComparisonJustifyH)

    -- Font
    local fontDropdown, fontLabel = CreateDropdown(appearanceFrame, "Font")
    fontLabel:SetPoint("TOPLEFT", splitComparsionOffsetSliderLabel, "BOTTOMLEFT", 0, -25)
    fontDropdown:SetPoint("TOPLEFT", fontLabel, "BOTTOMLEFT", 0, -8)
    fontDropdown:SetWidth(237)

    local function InitializeFontDropdown()
        local fonts = addon.LSM:List("font")

        local function isSelected(fontName)
            return fontName == addon.RunUI:GetFont()
        end

        local function onSelect(fontName)
            addon.RunUI:SetFont(fontName)
        end

        fontDropdown:SetupMenu(function(_, rootDescription)
            rootDescription:SetScrollMode(220)

            for _, fontName in ipairs(fonts) do
                rootDescription:CreateRadio(fontName, isSelected, onSelect, fontName)
            end
        end)
    end
    InitializeFontDropdown()
end
