local addonName, addon = ...

addon.ImportExport = addon.ImportExport or {}

local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local SCHEMA_VERSION = 1

local function TableToString(inTable, forChat)
    local serialized = LibSerialize:SerializeEx({ errorOnUnserializableType = false }, inTable)
    local compressed = LibDeflate:CompressDeflate(serialized, { level = 9 })
    local encoded = "!CMT:" .. SCHEMA_VERSION .. "!"
    if (forChat) then
        encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
    else
        encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
    end
    return encoded
end

local function StringToTable(inString, fromChat)
    local _, _, schemaVersion, encoded = inString:find("^(!CMT:%d+!)(.+)$")
    if schemaVersion then
        schemaVersion = tonumber(schemaVersion:match("%d+"))
    end
    if not schemaVersion then
        return "Not a " .. addonName .. " export"
    end

    local decoded
    if (fromChat) then
        decoded = LibDeflate:DecodeForPrint(encoded)
    else
        decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
    end
    if not decoded then
        return "Error decoding"
    end

    local decompressed
    decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        return "Error decompressing"
    end

    local success, deserialized
    success, deserialized = LibSerialize:Deserialize(decompressed)
    if not success then
        return "Error deserializing"
    end
    return deserialized, schemaVersion
end

function addon.ImportExport:ImportRun(inString)
    local deserialized, schemaVersion = StringToTable(inString, true)
    if not schemaVersion then
        return false, deserialized
    end
    deserialized.run.importTimestamp = time()
    return true, deserialized
end

function addon.ImportExport:ExportRun(instanceId, run)
    local exported = {
        instanceId = instanceId,
        run = run
    }
    return TableToString(exported, true)
end
