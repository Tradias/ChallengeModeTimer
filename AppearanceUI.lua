local addonName, addon = ...

addon.AppearanceUI = addon.AppearanceUI or {}

function addon.AppearanceUI:Init()
    local appearanceFrame = addon.OptionsUI:GetAppearanceFrame()

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
    self.moveButton = moveButton

    local scaleSlider = CreateFrame("Slider", nil, appearanceFrame, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", moveButton, "BOTTOMLEFT", 0, -30)
    scaleSlider:SetWidth(200)
    scaleSlider:SetMinMaxValues(0.5, 2)
    scaleSlider:SetValueStep(0.05)
    scaleSlider:SetObeyStepOnDrag(true)

    local scaleLabel = appearanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    scaleLabel:SetPoint("BOTTOMLEFT", scaleSlider, "TOPLEFT", 0, 4)
    scaleLabel:SetText("Scale")

    local scaleValue = appearanceFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    scaleValue:SetPoint("LEFT", scaleSlider, "RIGHT", 8, 0)

    local function UpdateScaleValueText(value)
        scaleValue:SetText(string.format("%d%%", math.floor(value * 100 + 0.5)))
    end

    scaleSlider:SetScript("OnValueChanged", function(_, value)
        UpdateScaleValueText(value)
        addon.RunUI:SetScale(value)
    end)

    scaleSlider:SetValue(addon.RunUI:GetScale())
    UpdateScaleValueText(scaleSlider:GetValue())

    self.scaleSlider = scaleSlider
end
