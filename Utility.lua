local _, addon = ...

addon.Utility = addon.Utility or {}

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

function addon.Utility:ToggleDebugMode()
    if not self.isDebugMode then
        self.isDebugMode = true
        print("Debug mode on")
    else
        self.isDebugMode = false
        print("Debug mode off")
    end
end

function addon.Utility:DebugPrint(text)
    if self.isDebugMode then
        DevTools_Dump(text)
    end
end
