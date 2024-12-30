if SERVER then AddCSLuaFile() end
GM.ConVars = {}
function GM:RegisterConVar(name, value, flags, helptext, fn)
    if CLIENT and bit.band(flags, FCVAR_REPLICATED) ~= 0 and bit.band(flags, FCVAR_ARCHIVE) ~= 0 then
        DbgPrint("Removing FCVAR_ARCHIVE from " .. name)
        flags = bit.band(flags, bit.bnot(FCVAR_ARCHIVE))
    end

    local prefix = "lambda_"
    local actualName = prefix .. name
    local actualValue = ""
    if isbool(value) then
        actualValue = tostring(tonumber(value))
    elseif isstring(value) then
        actualValue = value
    else
        actualValue = tostring(value)
    end

    local convar = CreateConVar(actualName, actualValue, flags, helptext)
    self.ConVars[name] = convar
    if fn ~= nil and isfunction(fn) then cvars.AddChangeCallback(actualName, fn) end
    return convar
end

function GM:GetRegisteredConVar(name)
    return self.ConVars[name]
end

if CLIENT then
    lambda_crosshair = GM:RegisterConVar("crosshair", 1, bit.bor(0, FCVAR_ARCHIVE), "Lambda Crosshair")
    lambda_crosshair_dynamic = GM:RegisterConVar("crosshair_dynamic", 1, bit.bor(0, FCVAR_ARCHIVE), "Dynamic crosshair")
    lambda_crosshair_size = GM:RegisterConVar("crosshair_size", 8, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_width = GM:RegisterConVar("crosshair_width", 2, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_space = GM:RegisterConVar("crosshair_space", 4, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_outline = GM:RegisterConVar("crosshair_outline", 1, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_adaptive = GM:RegisterConVar("crosshair_adaptive", 1, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_color = GM:RegisterConVar("crosshair_color", "0 128 0", bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_crosshair_alpha = GM:RegisterConVar("crosshair_alpha", 255, bit.bor(0, FCVAR_ARCHIVE), "")
    lambda_postprocess = GM:RegisterConVar("postprocess", 1, bit.bor(0, FCVAR_ARCHIVE), "Postprocessing")
    lambda_hud_text_color = GM:RegisterConVar("hud_text_color", "255 208 64", bit.bor(0, FCVAR_ARCHIVE), "HUD Text Color R(0-255), G(0-255), B(0-255)")
    lambda_hud_bg_color = GM:RegisterConVar("hud_bg_color", "0 0 0", bit.bor(0, FCVAR_ARCHIVE), "HUD BG Color R(0-255), G(0-255), B(0-255)")
    lambda_player_color = GM:RegisterConVar("player_color", "0.3 1 1", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player color")
    lambda_weapon_color = GM:RegisterConVar("weapon_color", "0.3 1 1", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Weapon color")
    lambda_playermdl = GM:RegisterConVar("playermdl", "male_01", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player model")
    lambda_playermdl_skin = GM:RegisterConVar("playermdl_skin", "0", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player model skin")
    lambda_playermdl_bodygroup = GM:RegisterConVar("playermdl_bodygroup", "0", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Player model bodygroup")
    lambda_deathnotice_time = GM:RegisterConVar("deathnotice_time", "6", bit.bor(0, FCVAR_ARCHIVE), "Deathnotice time")
    lambda_auto_jump = GM:RegisterConVar("auto_jump", "0", bit.bor(0, FCVAR_ARCHIVE), "Automatically jump if on ground")
    lambda_gore = GM:RegisterConVar("gore", "1", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Enable gore")
    lambda_language = GM:RegisterConVar("language", "english", bit.bor(0, FCVAR_ARCHIVE), "Gamemode language")
    lambda_voice_group = GM:RegisterConVar("voice_group", "auto", bit.bor(0, FCVAR_ARCHIVE, FCVAR_USERINFO), "Voice group")
end

-- Server --
lambda_gametype = GM:RegisterConVar("gametype", "auto", bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Current gametype")
lambda_instance_id = GM:RegisterConVar("instance_id", 1, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY), "Allows to assign a unique instance id to support multiple srcds instances at once from the same directory.")
-- Deathmatch specific convars
lambda_dm_fraglimit = GM:RegisterConVar("dm_fraglimit", 50, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "When frags are reached the round ends")
lambda_dm_timelimit = GM:RegisterConVar("dm_timelimit", 10, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "When time runs out the round ends(min)")
lambda_dm_teamonly = GM:RegisterConVar("dm_teamonly", 0, bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED), "Team based deathmatch")
