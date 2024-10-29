AddCSLuaFile()

local badAddonIds = {
    -- "Episode animation fixes"
    ["3022183926"] = true,
    ["1879556056"] = true,
    ["2576796480"] = true,
    ["3263204957"] = true,
    ["1881393042"] = true,
    ["1095903501"] = true,
    ["1890049841"] = true,
    -- Reserved.
}

local function IsBadAddon(id)
    return badAddonIds[id] ~= nil
end

local function CheckAddonCompatibility()
    local addons = engine.GetAddons()
    local badAddons = {}
    for _, addon in pairs(addons) do
        if addon.mounted and IsBadAddon(addon.wsid) then
            table.insert(badAddons, addon)
        end
    end
    if #badAddons == 0 then
        return
    end
    local errorInfo = "WARNING: Following addons are obsolete or cause issues:\n"
    for _, addon in pairs(badAddons) do
        errorInfo = errorInfo .. " - " .. addon.title .. " (" .. addon.wsid .. ")\n"
    end
    errorInfo = errorInfo .. "Disable them and restart the game for the best experience.\n"
    ErrorNoHalt(errorInfo)
end

CheckAddonCompatibility()
