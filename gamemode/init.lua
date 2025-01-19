AddCSLuaFile("cl_init.lua")
AddCSLuaFile("cl_hud.lua")
AddCSLuaFile("cl_postprocess.lua")
AddCSLuaFile("cl_ragdoll_ext.lua")
AddCSLuaFile("cl_skin_lambda.lua")
AddCSLuaFile("cl_lang.lua")
AddCSLuaFile("huds/hud_numeric.lua")
AddCSLuaFile("huds/hud_suit.lua")
AddCSLuaFile("huds/hud_health.lua")
AddCSLuaFile("huds/hud_armor.lua")
AddCSLuaFile("huds/hud_primary_ammo.lua")
AddCSLuaFile("huds/hud_secondary_ammo.lua")
AddCSLuaFile("huds/hud_ammo.lua")
AddCSLuaFile("huds/hud_aux.lua")
AddCSLuaFile("huds/hud_pickup.lua")
AddCSLuaFile("huds/hud_roundinfo.lua")
AddCSLuaFile("huds/hud_lambda.lua")
AddCSLuaFile("huds/hud_lambda_player.lua")
AddCSLuaFile("huds/hud_lambda_vote.lua")
AddCSLuaFile("huds/hud_lambda_settings.lua")
AddCSLuaFile("huds/hud_lambda_admin.lua")
AddCSLuaFile("huds/hud_lambda_info.lua")
AddCSLuaFile("huds/hud_hint.lua")
AddCSLuaFile("huds/hud_crosshair.lua")
AddCSLuaFile("huds/hud_vote.lua")
AddCSLuaFile("huds/hud_deathnotice.lua")
AddCSLuaFile("huds/hud_scoreboard.lua")
AddCSLuaFile("huds/hud_credits.lua")
DEFINE_BASECLASS("gamemode_base")
include("shared.lua")
include("sv_inputoutput.lua")
include("sv_changelevel.lua")
include("sv_transition.lua")
include("sv_resource.lua")
include("sv_taunts.lua")
include("sv_playerspeech.lua")
include("sv_commands.lua")
include("sv_checkpoints.lua")
include("sv_weapontracking.lua")
include("sv_player_pickup.lua")
include("sv_votefuncs.lua")
include("sv_damage.lua")
include("lambda_mightyfoot_bridge.lua")
util.AddNetworkString("LambdaDeathEvent")
local DbgPrint = GetLogging("Server")
local IsValid = IsValid
local table = table

function GM:GetNextUniqueEntityId()
    self.UniqueEntityId = self.UniqueEntityId or 0
    self.UniqueEntityId = self.UniqueEntityId + 1

    return self.UniqueEntityId
end

function GM:InsertLevelDesignerPlacedObject(obj)
    local objects = self.LevelRelevantObjects or {}

    objects[obj] = {
        class = obj:GetClass(),
        pos = obj:GetPos(),
        ang = obj:GetAngles(),
        name = obj:GetName(),
        spawnflags = obj:GetSpawnFlags(),
        outputs = table.Copy(obj.EntityOutputs or {})
    }

    self.LevelRelevantObjects = objects
end

function GM:IsLevelDesignerPlacedObject(obj)
    local objects = self.LevelRelevantObjects or {}
    if objects == nil then return false end

    return objects[obj] ~= nil
end

function GM:GetLevelDesignerPlacedData(obj)
    local objects = self.LevelRelevantObjects or {}

    return objects[obj]
end

function GM:RemoveLevelDesignerPlacedObject(obj)
    local objects = self.LevelRelevantObjects or {}
    if objects == nil then return end
    objects[obj] = nil
end

function GM:ClearLevelDesignerPlacedObjects()
    self.LevelRelevantObjects = {}
end

function GM:CreateEntityRagdoll(owner, ragdoll)
    DbgPrint("Create Ragdoll:", tostring(owner), tostring(ragdoll))
    ragdoll.IsPhysgunDamage = owner.IsPhysgunDamage
end

function GM:LambdaPreChangelevel(data)
end

function GM:SendDeathNotice(victim, attacker, inflictor, dmgType)
    if IsValid(attacker) and attacker:IsVehicle() == true then
        local driver = attacker:GetDriver()

        if IsValid(driver) and dmgType == 0 then
            inflictor = attacker
            attacker = driver
            dmgType = DMG_CRUSH
        end
    end

    local function GetEntityData(e)
        local data = {}
        data.entIndex = e:EntIndex()
        data.class = e:GetClass()
        data.name = e:GetName()
        data.isNPC = e:IsNPC()
        data.isPlayer = e:IsPlayer()

        if e.Team ~= nil then
            data.team = e:Team()
        end

        return data
    end

    if attacker == nil then
        attacker = inflictor
    end

    local data = {}

    if IsValid(victim) then
        data.victim = GetEntityData(victim)
    end

    if IsValid(attacker) then
        data.attacker = GetEntityData(attacker)
    end

    if bit.band(dmgType, DMG_BULLET) ~= 0 or bit.band(dmgType, DMG_CLUB) ~= 0 or bit.band(dmgType, DMG_BUCKSHOT) ~= 0 then
        -- Player used his weapon in this case.
        if IsValid(inflictor) and inflictor == attacker and attacker.GetActiveWeapon ~= nil then
            local wep = attacker:GetActiveWeapon()

            if IsValid(wep) then
                inflictor = wep
            end
        end
    end

    if IsValid(inflictor) then
        data.inflictor = GetEntityData(inflictor)
    end

    data.selfInflicted = victim == attacker
    data.dmgType = dmgType
    net.Start("LambdaDeathEvent")
    net.WriteTable(data)
    net.Broadcast()
end