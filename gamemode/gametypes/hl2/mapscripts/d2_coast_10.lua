if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.PlayersLocked = false

MAPSCRIPT.DefaultLoadout = {
    Weapons = {"weapon_lambda_medkit", "weapon_crowbar", "weapon_pistol", "weapon_smg1", "weapon_357", "weapon_physcannon", "weapon_frag", "weapon_shotgun", "weapon_ar2", "weapon_rpg", "weapon_crossbow"},
    Ammo = {
        ["Pistol"] = 20,
        ["SMG1"] = 45,
        ["357"] = 6,
        ["Grenade"] = 3,
        ["Buckshot"] = 12,
        ["AR2"] = 50,
        ["RPG_Round"] = 8,
        ["SMG1_Grenade"] = 3,
        ["XBowBolt"] = 4
    },
    Armor = 60,
    HEV = true
}

MAPSCRIPT.EntityFilterByName = {
    ["player_spawn_items"] = true,
    ["fall_trigger"] = true,
    ["fade_fall"] = true,
}

MAPSCRIPT.ImportantPlayerNPCNames = {
    ["citizen_greeter"] = true
}

MAPSCRIPT.VehicleGuns = true

function MAPSCRIPT:PostInit()
    -- -6397.890625 4632.765625 512.031250
    if SERVER then
        local citizen_greeter

        ents.WaitForEntityByName("citizen_greeter", function(ent)
            ent:SetHealth(100)
            citizen_greeter = ent
        end)

        GAMEMODE:WaitForInput("greeter_dropships", "Start", function(ent)
            if IsValid(citizen_greeter) then
                GAMEMODE:UnregisterMissionCriticalNPC(citizen_greeter)
            end
        end)

        -- In case of map reset.
        GAMEMODE:SetSpawnPlayerVehicles(true)
        -- This is ugly but it solves a strange issue where the whole script falls apart.
        local timer1 = ents.Create("logic_timer")
        timer1:SetKeyValue("RefireTime", "1")
        timer1:Fire("AddOutput", "OnTimer dropship_container,SetDamageFilter,lambda_null_filter,0,-1")
        timer1:Spawn()
        local nullFilter = ents.Create("filter_activator_class")
        nullFilter:SetName("lambda_null_filter")
        nullFilter:SetKeyValue("filterclass", "null")
        nullFilter:Spawn()
        local checkpoint1 = GAMEMODE:CreateCheckpoint(Vector(4805.765625, -401.630463, 916.031250), Angle(0, 0, 0))
        local checkpointTrigger1 = ents.Create("trigger_once")
        checkpointTrigger1:SetupTrigger(Vector(4891.401855, -227.542877, 916.031250), Angle(0, 0, 0), Vector(-100, -100, 0), Vector(100, 100, 200))
        checkpointTrigger1:SetKeyValue("teamwait", "1")
        checkpointTrigger1:SetKeyValue("disableendtouch", "1")

        checkpointTrigger1.OnStartTouch = function(_, ent)
            if ent:IsPlayer() then
                local car = ent:GetVehicle()

                if IsValid(car) then
                    car:Remove()
                end
            end
        end

        checkpointTrigger1.OnTrigger = function(_, activator)
            GAMEMODE:SetSpawnPlayerVehicles(false)
            GAMEMODE:SetPlayerCheckpoint(checkpoint1, activator)
            TriggerOutputs({{"garage_exit_trigger", "Enable", 0, ""}, {"greeter_conditions", "Disable", 0, ""}, {"greeter_car_nag_timer", "Kill", 0, ""}, {"garage_door", "Close", 0, ""}, {"greeter_briefing_conditions", "Enable", 0, ""}, {"greeter_wave_timer", "Disable", 0, ""}, {"look_at_player", "Resume", 0, ""}})

            ents.RemoveByClass("prop_vehicle_jeep")
        end

        -- 8222.646484 1799.084961 960.000000
        local checkpoint2 = GAMEMODE:CreateCheckpoint(Vector(8222.646484, 1799.084961, 960.000000), Angle(0, 90, 0))
        local checkpointTrigger2 = ents.Create("trigger_once")
        checkpointTrigger2:SetupTrigger(Vector(8220.174805, 1837.689819, 960.000000), Angle(0, 0, 0), Vector(-100, -100, 0), Vector(100, 100, 200))

        checkpointTrigger2.OnTrigger = function(_, activator)
            GAMEMODE:SetPlayerCheckpoint(checkpoint2, activator)
        end

        local triggerCar = ents.FindByPos(Vector(4773, -228, 976), "trigger_once")

        for _, v in pairs(triggerCar) do
            v:Remove()
        end

        local triggerRaid = ents.FindByPos(Vector(8088, 1920, 896), "trigger_once")

        for _, v in pairs(triggerRaid) do
            v:SetKeyValue("teamwait", "1")
            v:SetKeyValue("showwait", "0") -- Don't let the players know, this is subtile.
            v:SetKeyValue("disableendtouch", "1")
        end
    end
end

function MAPSCRIPT:PostPlayerSpawn(ply)
    --DbgPrint("PostPlayerSpawn")
end

return MAPSCRIPT
