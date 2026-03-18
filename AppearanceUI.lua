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
end
