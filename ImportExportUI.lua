local _, addon = ...

addon.ImportExportUI = addon.ImportExportUI or {}

local RUN_TOOLTIP_ANCHOR = "ANCHOR_TOP"

local function CreateImportExportContent(frame, actionButton)
    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", frame, "TOP", 0, -20)

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelInputScrollFrameTemplate")
    if scrollFrame.CharCount then
        scrollFrame.CharCount:Hide()
    end
    scrollFrame:SetPoint("TOP", title, "BOTTOM", 0, -12)
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

    scrollFrame:SetPoint("BOTTOM", actionButton, "TOP", 0, 11)

    return title, editBox
end

function addon.ImportExportUI:Init()
    if self.importFrame then
        return
    end

    -- Import
    local runsFrame = addon.OptionsUI:GetRunsFrame()
    local importFrame = addon.PopupUI:CreatePopupFrame(runsFrame)
    self.importFrame = importFrame

    local importButton = addon.PopupUI:AddButtonsToPopupFrame(importFrame, true)
    importButton:SetText("Import")
    importButton:Hide()

    local importTitle, importEditBox = CreateImportExportContent(importFrame, importButton)
    importTitle:SetText("Paste import string below")

    local importErrorText = importFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importErrorText:SetPoint("CENTER", importButton, "CENTER", 10, 0)
    importErrorText:SetTextColor(1, 0.2, 0.2, 1)
    importErrorText:Hide()

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
    local exportFrame = addon.PopupUI:CreatePopupFrame(runsFrame)
    self.exportFrame = exportFrame

    local exportButton = addon.PopupUI:AddButtonsToPopupFrame(exportFrame)
    exportButton:SetText("OK")
    exportButton:SetScript("OnClick", function()
        exportFrame:Hide()
    end)

    local exportTitle, exportEditBox = CreateImportExportContent(exportFrame, exportButton)
    exportTitle:SetText("Press ctrl-a and ctrl-c to copy")

    self.exportEditBox = exportEditBox
end

function addon.ImportExportUI:ToggleImport()
    self:Init()
    if self.importFrame:IsShown() then
        self.importFrame:Hide()
        return
    end
    self.importFrame:Show()
    self.importFrame:SetScript("OnEnter", nil)
    self.importEditBox:SetText("")
end

function addon.ImportExportUI:ToggleExport(instanceId, run)
    self:Init()
    if self.exportFrame:IsShown() or not instanceId then
        self.exportFrame:Hide()
        return
    end
    self.exportFrame:Show()
    local exportString = addon.ImportExport:ExportRun(instanceId, run)
    self.exportEditBox:SetText(exportString)
    self.exportFrame:SetScript("OnEnter", function()
        addon.RunHistoryUI:ShowRunTooltip(self.exportFrame, instanceId, run, RUN_TOOLTIP_ANCHOR)
    end)
    addon.RunHistoryUI:ShowRunTooltip(self.exportFrame, instanceId, run, RUN_TOOLTIP_ANCHOR)
end
