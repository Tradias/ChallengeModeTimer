local _, addon = ...

addon.PopupUI = addon.PopupUI or {}

local g_popupFrames = {}

function addon.PopupUI:CreatePopupFrame(parentFrame)
    local optionsFrame = addon.OptionsUI:Get()

    local frame = CreateFrame("Frame", nil, parentFrame, "BackdropTemplate")
    frame:SetSize(325, 223)
    frame:SetPoint("CENTER", parentFrame, "CENTER")
    frame:SetFrameStrata(parentFrame:GetFrameStrata())
    frame:SetFrameLevel(parentFrame:GetFrameLevel() + 50)
    frame:SetBackdrop(optionsFrame:GetBackdrop())
    frame:SetBackdropColor(0.1, 0.1, 0.1, 1)
    frame:SetBackdropBorderColor(optionsFrame:GetBackdropBorderColor())
    frame:EnableMouse(true)
    frame:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            frame:Hide()
            return
        end
    end)
    frame:SetScript("OnShow", function()
        for _, popupFrame in ipairs(g_popupFrames) do
            if popupFrame ~= frame then
                popupFrame:Hide()
            end
        end
    end)
    frame:SetScript("OnHide", function()
        GameTooltip:Hide()
    end)
    frame:Hide()
    table.insert(g_popupFrames, frame)
    return frame
end

function addon.PopupUI:AddButtonsToPopupFrame(frame, hasAbortButton)
    local actionButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    actionButton:SetSize(80, 22)
    actionButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 14)
    actionButton:SetText("Create")

    local abortButton
    if hasAbortButton then
        abortButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
        abortButton:SetPoint("LEFT", frame, "LEFT", 14, 0)
        abortButton:SetPoint("TOP", actionButton, "TOP", 0, 0)
        abortButton:SetText("Abort")
        abortButton:SetWidth(50)
        abortButton:SetScript("OnClick", function()
            frame:Hide()
        end)
    end

    return actionButton, abortButton
end
