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
    splitsScaleSlider:SetPoint("TOPLEFT", timerScaleSlider, "BOTTOMLEFT", 0, -30)
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
end
