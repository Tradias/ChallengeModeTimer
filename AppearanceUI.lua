local addonName, addon = ...

addon.AppearanceUI = addon.AppearanceUI or {}

local MINIMAP_BUTTON_SIZE = 31
local MINIMAP_RADIUS = 80
local DEFAULT_MINIMAP_ANGLE = 225

local function GetMinimapButtonAngle()
    if type(ChallengeModeTimerDB.minimapButtonAngle) ~= "number" then
        ChallengeModeTimerDB.minimapButtonAngle = DEFAULT_MINIMAP_ANGLE
    end

    return ChallengeModeTimerDB.minimapButtonAngle
end

local function SaveMinimapButtonAngle(angle)
    ChallengeModeTimerDB.minimapButtonAngle = angle
end

local function PositionMinimapButton(button, angle)
    local radians = math.rad(angle)
    local xOffset = math.cos(radians) * MINIMAP_RADIUS
    local yOffset = math.sin(radians) * MINIMAP_RADIUS

    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", xOffset, yOffset)
end

local function UpdateMinimapButtonPositionFromCursor(button)
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local deltaX = cursorX / scale - centerX
    local deltaY = cursorY / scale - centerY
    local angle

    if math.atan2 then
        angle = math.deg(math.atan2(deltaY, deltaX))
    elseif deltaX == 0 then
        if deltaY >= 0 then
            angle = 90
        else
            angle = 270
        end
    else
        angle = math.deg(math.atan(deltaY / deltaX))
        if deltaX < 0 then
            angle = angle + 180
        end
    end

    if angle < 0 then
        angle = angle + 360
    end

    SaveMinimapButtonAngle(angle)
    PositionMinimapButton(button, angle)
end

local function ToggleOptionsFrame()
    if addon.OptionsUI:Get():IsShown() then
        addon.OptionsUI:Hide()
    else
        addon.OptionsUI:Show()
    end
end

local function CreateMinimapButton()
    local minimapButton = CreateFrame("Button", "ChallengeModeTimerMinimapButton", Minimap)
    minimapButton:SetSize(MINIMAP_BUTTON_SIZE, MINIMAP_BUTTON_SIZE)
    minimapButton:SetFrameStrata("MEDIUM")
    minimapButton:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    minimapButton:RegisterForClicks("LeftButtonUp")
    minimapButton:RegisterForDrag("LeftButton")

    local icon = minimapButton:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Challenges\\ChallengeMode_Medal_Gold")
    minimapButton.icon = icon

    local overlay = minimapButton:CreateTexture(nil, "OVERLAY")
    overlay:SetSize(53, 53)
    overlay:SetPoint("TOPLEFT")
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    minimapButton:GetHighlightTexture():SetBlendMode("ADD")

    minimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(addonName)
        GameTooltip:AddLine("Linksklick: Optionen oeffnen/schliessen", 1, 1, 1)
        GameTooltip:AddLine("Ziehen: Position an der Minimap aendern", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    minimapButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    minimapButton:SetScript("OnClick", function(self)
        if self.wasDragged then
            self.wasDragged = false
            return
        end

        ToggleOptionsFrame()
    end)

    minimapButton:SetScript("OnDragStart", function(self)
        self.isDragging = true
        self:SetScript("OnUpdate", function(frame)
            UpdateMinimapButtonPositionFromCursor(frame)
        end)
    end)

    minimapButton:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        UpdateMinimapButtonPositionFromCursor(self)
        self.isDragging = false
        self.wasDragged = true
    end)

    PositionMinimapButton(minimapButton, GetMinimapButtonAngle())
    return minimapButton
end

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

    if not self.minimapButton then
        self.minimapButton = CreateMinimapButton()
    end
end
