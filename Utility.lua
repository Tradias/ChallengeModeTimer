local addonName, addon = ...

addon.Utility = addon.Utility or {}

function addon.Utility:FormatTime(seconds, precision)
    local minutes = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    local tenths = math.floor((seconds % 1) * 10)
    local tenthsFormatString = "%01d"
    if precision then
        tenths = math.floor((seconds % 1) * math.pow(10, precision))
        tenthsFormatString = string.format("%%0%dd", precision)
    end
    if minutes == 0 then
        return string.format("%d." .. tenthsFormatString, secs, tenths)
    end
    return string.format("%d:%02d." .. tenthsFormatString, minutes, secs, tenths)
end

function addon.Utility:ShallowClone(t)
    local t2 = {}
    for k, v in pairs(t) do
        t2[k] = v
    end
    return t2
end

function addon.Utility:GetClassColorById(classId)
    local _, classToken = GetClassInfo(classId)
    return classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
end
