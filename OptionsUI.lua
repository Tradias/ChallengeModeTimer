local _, addon = ...

addon.OptionsUI = addon.OptionsUI or {}

function addon.OptionsUI:Init()
    local optionsFrame = CreateFrame("Frame", "ChallengeModeTimerOptions", UIParent, "BackdropTemplate")
    optionsFrame:SetSize(515, 572)
    optionsFrame:SetPoint("CENTER")
    optionsFrame:SetFrameStrata("DIALOG")
    optionsFrame:SetFrameLevel(100)
    optionsFrame:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    optionsFrame:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
    optionsFrame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
    optionsFrame:EnableMouse(true)
    optionsFrame:SetMovable(true)
    optionsFrame:SetClampedToScreen(true)
    optionsFrame:RegisterForDrag("LeftButton")
    optionsFrame:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            addon.OptionsUI:Hide()
        end
    end)
    optionsFrame:SetScript("OnDragStart", function()
        optionsFrame:StartMoving()
    end)
    optionsFrame:SetScript("OnDragStop", function()
        optionsFrame:StopMovingOrSizing()
    end)
    optionsFrame:Hide()

    local closeHint = optionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeHint:SetPoint("TOPRIGHT", optionsFrame, "TOPRIGHT", -18, -12)
    closeHint:SetText("right-click to close")
    closeHint:SetTextColor(0.7, 0.7, 0.7, 1)

    self.optionsFrame = optionsFrame

    local function CreateTab(index, text)
        local tab = CreateFrame("Button", optionsFrame:GetName() .. "Tab" .. index, optionsFrame,
            "CharacterFrameTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(text)
        PanelTemplates_TabResize(tab, 0)
        return tab
    end

    local runsTab = CreateTab(1, "Runs")
    runsTab:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 12, -8)

    local appearanceTab = CreateTab(2, "Appearance")
    appearanceTab:SetPoint("LEFT", runsTab, "RIGHT", -16, 0)

    PanelTemplates_SetNumTabs(optionsFrame, 2)

    local runsFrame = CreateFrame("Frame", nil, optionsFrame)
    runsFrame:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -runsTab:GetHeight() - 20)
    runsFrame:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -10, 10)

    local appearanceFrame = CreateFrame("Frame", nil, optionsFrame)
    appearanceFrame:SetPoint("TOPLEFT", optionsFrame, "TOPLEFT", 10, -runsTab:GetHeight() - 20)
    appearanceFrame:SetPoint("BOTTOMRIGHT", optionsFrame, "BOTTOMRIGHT", -10, 10)

    local function SetSampleRun(enabled)
        if enabled == self.isSampleRunSet then
            return
        end

        self.isSampleRunSet = enabled

        if enabled then
            self.wasRunUIShownBefore = addon.RunUI:IsShown()
            addon.Run:SetSampleRun()
            addon.RunUI:Show()
        else
            addon.Run:UnsetSampleRun()
            if not self.wasRunUIShownBefore then
                addon.RunUI:Hide()
            end
        end
    end

    local function SelectTab(tabId)
        PanelTemplates_SetTab(optionsFrame, tabId)
        runsFrame:SetShown(tabId == 1)
        appearanceFrame:SetShown(tabId == 2)
        SetSampleRun(tabId == 2)
    end

    runsTab:SetScript("OnClick", function()
        SelectTab(1)
    end)

    appearanceTab:SetScript("OnClick", function()
        SelectTab(2)
    end)

    optionsFrame:SetScript("OnShow", function()
        local selectedTab = PanelTemplates_GetSelectedTab(optionsFrame) or 1
        SetSampleRun(selectedTab == 2)
    end)

    optionsFrame:SetScript("OnHide", function()
        SetSampleRun(false)
    end)

    self.runsFrame = runsFrame
    self.appearanceFrame = appearanceFrame
    self.tabs = { runsTab, appearanceTab }
    self.isSampleRunSet = false
    self.wasRunUIShownBefore = false

    SelectTab(1)
end

function addon.OptionsUI:Show()
    self.optionsFrame:Show()
end

function addon.OptionsUI:Hide()
    self.optionsFrame:Hide()
end

function addon.OptionsUI:Get()
    return self.optionsFrame
end

function addon.OptionsUI:GetRunsFrame()
    return self.runsFrame
end

function addon.OptionsUI:GetAppearanceFrame()
    return self.appearanceFrame
end
