local _, addon = ...

addon.ImportExportUI = addon.ImportExportUI or {}

local RUN_TOOLTIP_ANCHOR = "ANCHOR_TOP"

local function CreateBaseFrame(name)
    local optionsFrame = addon.OptionsUI:Get()
    local runsFrame = addon.OptionsUI:GetRunsFrame()

    local frame = CreateFrame("Frame", name, runsFrame, "BackdropTemplate")
    frame:SetSize(350, 223)
    frame:SetPoint("CENTER", runsFrame, "CENTER")
    frame:SetFrameStrata(runsFrame:GetFrameStrata())
    frame:SetFrameLevel(runsFrame:GetFrameLevel() + 50)
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
    frame:SetScript("OnHide", function()
        GameTooltip:Hide()
    end)
    frame:Hide()
    return frame
end

local function CreateImportExportContent(frame)
    local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    hint:SetPoint("TOP", frame, "TOP", 0, -20)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelInputScrollFrameTemplate")
    if scrollFrame.CharCount then
        scrollFrame.CharCount:Hide()
    end
    scrollFrame:SetPoint("TOP", hint, "BOTTOM", 0, -12)
    scrollFrame:SetPoint("LEFT", frame, "LEFT", 20, 0)
    scrollFrame:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            frame:Hide()
            return
        end
    end)

    local editBox = scrollFrame.EditBox
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth() - 15)
    editBox:EnableMouse(true)
    editBox:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            editBox:ClearFocus()
            frame:Hide()
        end
    end)

    local actionButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    actionButton:SetSize(80, 22)
    actionButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 17)

    scrollFrame:SetPoint("BOTTOM", actionButton, "TOP", 0, 11)

    return hint, editBox, actionButton
end

function addon.ImportExportUI:Init()
    if self.importFrame then
        return
    end

    -- Import
    local importFrame = CreateBaseFrame("ChallengeModeTimerImport")
    self.importFrame = importFrame

    local importHint, importEditBox, importButton = CreateImportExportContent(importFrame)
    importHint:SetText("Paste import string below")
    importButton:SetText("Import")

    local importErrorText = importFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importErrorText:SetPoint("CENTER", importButton, "CENTER", 0, 0)
    importErrorText:SetTextColor(1, 0.2, 0.2, 1)
    importErrorText:Hide()

    local importAbortButton = CreateFrame("Button", nil, importFrame, "UIPanelButtonTemplate")
    importAbortButton:SetPoint("LEFT", importFrame, "LEFT", 14, 0)
    importAbortButton:SetPoint("TOP", importButton, "TOP", 0, 0)
    importAbortButton:SetText("Abort")
    importAbortButton:SetWidth(50)
    importAbortButton:SetScript("OnClick", function()
        importFrame:Hide()
    end)

    importEditBox:SetScript("OnTextChanged", function()
        GameTooltip:Hide()
        importButton:Hide()
        importErrorText:Hide()
        local text = importEditBox:GetText()
        if text == "" then
            return
        end
        local isSuccess, deserialized = addon.ImportExport:ImportRun(text)
        if not isSuccess then
            importErrorText:SetText(deserialized)
            importErrorText:Show()
            return
        end
        importButton:SetScript("OnClick", function()
            local runIndex = addon.RunHistory:AddRun(deserialized.instanceId, deserialized.run)
            addon.RunHistory:SetComparisonRunIndex(deserialized.instanceId, runIndex)
            importFrame:Hide()
            addon.RunHistoryUI:Refresh()
        end)
        importFrame:SetScript("OnEnter", function()
            addon.RunHistoryUI:ShowRunTooltip(importFrame, deserialized.instanceId, deserialized.run,
                RUN_TOOLTIP_ANCHOR)
        end)
        addon.RunHistoryUI:ShowRunTooltip(importFrame, deserialized.instanceId, deserialized.run, RUN_TOOLTIP_ANCHOR)
        importButton:Show()
    end)

    self.importEditBox = importEditBox

    -- Export
    local exportFrame = CreateBaseFrame("ChallengeModeTimerExport")
    self.exportFrame = exportFrame

    local exportHint, exportEditBox, exportButton = CreateImportExportContent(exportFrame)
    exportHint:SetText("Press ctrl-a and ctrl-c to copy")
    exportButton:SetText("OK")
    exportButton:SetScript("OnClick", function()
        exportFrame:Hide()
    end)
    self.exportEditBox = exportEditBox
    self.exportButton = exportButton
end

function addon.ImportExportUI:ToggleImport()
    self:Init()
    if self.importFrame:IsShown() then
        self.importFrame:Hide()
        return
    end
    self.exportFrame:Hide()

    self.importFrame:SetScript("OnEnter", nil)
    self.importEditBox:SetText("")
    self.importFrame:Show()
end

function addon.ImportExportUI:ToggleExport(instanceId, run)
    self:Init()
    if self.exportFrame:IsShown() or not instanceId then
        self.exportFrame:Hide()
        return
    end
    self.importFrame:Hide()

    local exportString = addon.ImportExport:ExportRun(instanceId, run)
    self.exportEditBox:SetText(exportString)
    self.exportFrame:SetScript("OnEnter", function()
        addon.RunHistoryUI:ShowRunTooltip(self.exportFrame, instanceId, run, RUN_TOOLTIP_ANCHOR)
    end)
    addon.RunHistoryUI:ShowRunTooltip(self.exportFrame, instanceId, run, RUN_TOOLTIP_ANCHOR)
    self.exportFrame:Show()
end
