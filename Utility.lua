local _, addon = ...

addon.Utility = addon.Utility or {}

local CHARACTER_WIDTH = {
    [string.byte(" ")] = 2,
    [string.byte("(")] = 2,
    [string.byte(")")] = 2,
    [string.byte("-")] = 2,
    [string.byte(".")] = 1,
    [string.byte("'")] = 1,
    [string.byte("0")] = 2,
    [string.byte("1")] = 2,
    [string.byte("2")] = 2,
    [string.byte("3")] = 2,
    [string.byte("4")] = 2,
    [string.byte("5")] = 2,
    [string.byte("6")] = 2,
    [string.byte("7")] = 2,
    [string.byte("8")] = 2,
    [string.byte("9")] = 2,
    [string.byte("a")] = 2,
    [string.byte("b")] = 2,
    [string.byte("c")] = 2,
    [string.byte("d")] = 2,
    [string.byte("e")] = 2,
    [string.byte("f")] = 1,
    [string.byte("g")] = 2,
    [string.byte("h")] = 2,
    [string.byte("i")] = 1,
    [string.byte("j")] = 1,
    [string.byte("k")] = 2,
    [string.byte("l")] = 1,
    [string.byte("m")] = 3,
    [string.byte("n")] = 2,
    [string.byte("o")] = 2,
    [string.byte("p")] = 2,
    [string.byte("q")] = 2,
    [string.byte("r")] = 2,
    [string.byte("s")] = 2,
    [string.byte("t")] = 1,
    [string.byte("u")] = 2,
    [string.byte("v")] = 2,
    [string.byte("w")] = 3,
    [string.byte("x")] = 2,
    [string.byte("y")] = 2,
    [string.byte("z")] = 2,
    [string.byte("A")] = 2,
    [string.byte("B")] = 2,
    [string.byte("C")] = 2,
    [string.byte("D")] = 2,
    [string.byte("E")] = 2,
    [string.byte("F")] = 2,
    [string.byte("G")] = 2,
    [string.byte("H")] = 2,
    [string.byte("I")] = 1,
    [string.byte("J")] = 2,
    [string.byte("K")] = 2,
    [string.byte("L")] = 2,
    [string.byte("M")] = 3,
    [string.byte("N")] = 2,
    [string.byte("O")] = 2,
    [string.byte("P")] = 2,
    [string.byte("Q")] = 2,
    [string.byte("R")] = 2,
    [string.byte("S")] = 2,
    [string.byte("T")] = 2,
    [string.byte("U")] = 2,
    [string.byte("V")] = 2,
    [string.byte("W")] = 3,
    [string.byte("X")] = 2,
    [string.byte("Y")] = 2,
    [string.byte("Z")] = 2,
}

local function GetCharacterWidthAt(text, i)
    return CHARACTER_WIDTH[string.byte(text, i)]
end

function addon.Utility:FormatTime(seconds, precision)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local tenths = math.floor((seconds % 1) * 10)
    local tenthsFormatString = "%01d"
    if precision then
        local thousands = math.pow(10, precision)
        tenths = math.floor((seconds % 1) * thousands + 0.5 / thousands)
        tenthsFormatString = string.format("%%0%dd", precision)
    end
    if minutes == 0 then
        return string.format("%d." .. tenthsFormatString, secs, tenths)
    end
    return string.format("%d:%02d." .. tenthsFormatString, minutes, secs, tenths)
end

function addon.Utility:RoundDuration(seconds)
    return math.floor(seconds * 1000 + 0.5) / 1000
end

function addon.Utility:DeepCopy(obj)
    if type(obj) ~= 'table' then return obj end
    local res = {}
    for k, v in pairs(obj) do
        res[self:DeepCopy(k)] = self:DeepCopy(v)
    end
    return res
end

function addon.Utility:GetClassColorById(classId)
    local _, classToken = GetClassInfo(classId)
    return classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
end

function addon.Utility:CreateScrollableEditBox(frame)
    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelInputScrollFrameTemplate")
    if scrollFrame.CharCount then
        scrollFrame.CharCount:Hide()
    end
    scrollFrame:SetPoint("TOP", frame, "BOTTOM", 0, -12)
    scrollFrame:SetPoint("LEFT", frame, "LEFT", 20, 0)
    scrollFrame:SetPoint("RIGHT", frame, "RIGHT", -20, 0)
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function(_, button)
        if button == "RightButton" then
            frame:Hide()
            return
        else
            scrollFrame.EditBox:SetFocus(true)
        end
    end)

    local editBox = scrollFrame.EditBox
    editBox:SetMultiLine(true)
    editBox:SetFontObject("ChatFontNormal")
    editBox:SetWidth(scrollFrame:GetWidth() - 15)
    editBox:EnableMouse(true)
    editBox:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then
            editBox:ClearFocus()
            frame:Hide()
        end
    end)

    return scrollFrame, editBox
end

function addon.Utility:GetTextWidth(text)
    local width = 0
    for i = 1, #text do
        width = width + GetCharacterWidthAt(text, i)
    end
    return width
end

function addon.Utility:ShortenTextToWidth(text, targetWidth)
    local textWidth = addon.Utility:GetTextWidth(text)
    for i = #text, 0, -1 do
        textWidth = textWidth - GetCharacterWidthAt(text, i)
        if textWidth <= targetWidth then
            return string.sub(text, 1, i)
        end
    end
    return ""
end
