if SERVER then AddCSLuaFile() end
local DbgPrint = GetLogging("GameType")
local GAMETYPE = {}
GAMETYPE.Name = "Lambda Base"
GAMETYPE.MapScript = {}
GAMETYPE.PlayerSpawnClass = "info_player_start"
GAMETYPE.UsingCheckpoints = true
GAMETYPE.MapList = {}
GAMETYPE.ClassesEnemyNPC = {}
GAMETYPE.ImportantPlayerNPCNames = {}
GAMETYPE.ImportantPlayerNPCClasses = {}
GAMETYPE.PlayerTiming = false
GAMETYPE.WaitForPlayers = false
GAMETYPE.Localisation = include("base/cl_localisation.lua")
function GAMETYPE:GetData(name)
    local base = self
    while base ~= nil do
        local var = base[name]
        if var ~= nil and isfunction(var) == false then return var end
        base = base.Base
    end
    return nil
end

function GAMETYPE:GetPlayerRespawnTime()
    return 0
end

function GAMETYPE:CheckpointEnablesRespawn()
    return false
end

function GAMETYPE:ShouldRestartRound()
    return false
end

function GAMETYPE:PlayerCanPickupWeapon(ply, wep)
    return true
end

function GAMETYPE:PlayerCanPickupItem(ply, item)
    return true
end

function GAMETYPE:GetWeaponRespawnTime()
    return 1
end

function GAMETYPE:GetItemRespawnTime()
    return -1
end

function GAMETYPE:ShouldRespawnWeapon(ent)
    return false
end

function GAMETYPE:PlayerDeath(ply, inflictor, attacker)
    ply:AddDeaths(1)
    -- Suicide?
    if inflictor == ply or attacker == ply then
        attacker:AddFrags(-1)
        return
    end

    -- Friendly kill?
    if IsValid(attacker) and attacker:IsPlayer() then
        attacker:AddFrags(-1)
    elseif IsValid(inflictor) and inflictor:IsPlayer() then
        inflictor:AddFrags(-1)
    end
end

function GAMETYPE:PlayerShouldTakeDamage(ply, attacker, inflictor)
    return true
end

function GAMETYPE:CanPlayerSpawn(ply, spawn)
    return true
end

function GAMETYPE:ShouldRespawnItem(ent)
    return false
end

function GAMETYPE:GetPlayerLoadout()
    return self.MapScript.DefaultLoadout or {}
end

function GAMETYPE:LoadMapScript(path, name)
    local MAPSCRIPT_FILE = path .. "/mapscripts/" .. name .. ".lua"
    self.MapScript = nil
    if file.Exists(MAPSCRIPT_FILE, "LUA") == true then
        self.MapScript = include(MAPSCRIPT_FILE)
        if self.MapScript ~= nil then
            DbgPrint("Loaded mapscript: " .. MAPSCRIPT_FILE)
        else
            self.MapScript = {}
        end
    else
        print("No map script was loaded for: " .. name)
        self.MapScript = {}
    end
end

function GAMETYPE:LoadLocalisation(lang)
end

function GAMETYPE:AllowPlayerTracking()
    return true
end

function GAMETYPE:IsPlayerEnemy(ply1, ply2)
    return false
end

function GAMETYPE:GetDifficultyData()
    return {
        [0] = {
            Name = "Very Easy",
            Proficiency = WEAPON_PROFICIENCY_POOR,
            Skill = 1,
            NPCSpawningScale = 0.0,
            DamageScale = {
                [DMG_SCALE_PVN] = 1.6,
                [DMG_SCALE_NVP] = 0.7,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 2.5,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 2.5,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        },
        [1] = {
            Name = "Easy",
            Proficiency = WEAPON_PROFICIENCY_AVERAGE,
            Skill = 1,
            NPCSpawningScale = 0.2,
            DamageScale = {
                [DMG_SCALE_PVN] = 1.2,
                [DMG_SCALE_NVP] = 0.8,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 3.4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 3.4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        },
        [2] = {
            Name = "Normal",
            Proficiency = WEAPON_PROFICIENCY_GOOD,
            Skill = 2,
            NPCSpawningScale = 0.4,
            DamageScale = {
                [DMG_SCALE_PVN] = 1,
                [DMG_SCALE_NVP] = 1,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        },
        [3] = {
            Name = "Hard",
            Proficiency = WEAPON_PROFICIENCY_VERY_GOOD,
            Skill = 2,
            NPCSpawningScale = 0.7,
            DamageScale = {
                [DMG_SCALE_PVN] = 1,
                [DMG_SCALE_NVP] = 1,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        },
        [4] = {
            Name = "Very Hard",
            Proficiency = WEAPON_PROFICIENCY_PERFECT,
            Skill = 3,
            NPCSpawningScale = 1,
            DamageScale = {
                [DMG_SCALE_PVN] = 1,
                [DMG_SCALE_NVP] = 1,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 1,
                [HITGROUP_HEAD] = 4,
                [HITGROUP_CHEST] = 1,
                [HITGROUP_STOMACH] = 1,
                [HITGROUP_LEFTARM] = 1,
                [HITGROUP_RIGHTARM] = 1,
                [HITGROUP_LEFTLEG] = 1,
                [HITGROUP_RIGHTLEG] = 1
            }
        },
        [5] = {
            Name = "Realism",
            Proficiency = WEAPON_PROFICIENCY_PERFECT,
            Skill = 3,
            NPCSpawningScale = 1,
            DamageScale = {
                [DMG_SCALE_PVN] = 1,
                [DMG_SCALE_NVP] = 1,
                [DMG_SCALE_PVP] = 1,
                [DMG_SCALE_NVN] = 1
            },
            HitgroupPlayerDamageScale = {
                [HITGROUP_GENERIC] = 2,
                [HITGROUP_HEAD] = 8,
                [HITGROUP_CHEST] = 3.5,
                [HITGROUP_STOMACH] = 3,
                [HITGROUP_LEFTARM] = 0.8,
                [HITGROUP_RIGHTARM] = 0.8,
                [HITGROUP_LEFTLEG] = 0.8,
                [HITGROUP_RIGHTLEG] = 0.8
            },
            HitgroupNPCDamageScale = {
                [HITGROUP_GENERIC] = 2,
                [HITGROUP_HEAD] = 8,
                [HITGROUP_CHEST] = 3.5,
                [HITGROUP_STOMACH] = 3,
                [HITGROUP_LEFTARM] = 0.8,
                [HITGROUP_RIGHTARM] = 0.8,
                [HITGROUP_LEFTLEG] = 0.8,
                [HITGROUP_RIGHTLEG] = 0.8
            }
        }
    }
end

function GAMETYPE:InitSettings()
    --SERVER
    GAMEMODE:AddSetting("walkspeed", {
        Category = "SERVER",
        NiceName = "#GM_WALKSPEED",
        Description = "#GM_WALKSPEED_DESC",
        Type = "int",
        Default = 150,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 1,
            Max = 1000
        }
    })

    GAMEMODE:AddSetting("normspeed", {
        Category = "SERVER",
        NiceName = "#GM_NORMSPEED",
        Description = "#GM_NORMSPEED_DESC",
        Type = "int",
        Default = 190,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 1,
            Max = 1000
        }
    })

    GAMEMODE:AddSetting("sprintspeed", {
        Category = "SERVER",
        NiceName = "#GM_SPRINTSPEED",
        Description = "#GM_SPRINTSPEED_DESC",
        Type = "int",
        Default = 320,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 1,
            Max = 1000
        }
    })

    GAMEMODE:AddSetting("connect_timeout", {
        Category = "SERVER",
        NiceName = "#GM_CONNECTTIMEOUT",
        Description = "#GM_CONNECTTIMEOUT_DESC",
        Type = "int",
        Default = 120,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Max = 60 * 3
        }
    })

    GAMEMODE:AddSetting("playercollision", {
        Category = "SERVER",
        NiceName = "#GM_PLAYERCOLLISION",
        Description = "#GM_PLAYERCOLLISION_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("friendlyfire", {
        Category = "SERVER",
        NiceName = "#GM_FRIENDLYFIRE",
        Description = "#GM_FRIENDLYFIRE_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("prevent_item_move", {
        Category = "SERVER",
        NiceName = "#GM_PREVENTITEMMOVE",
        Description = "#GM_PREVENTITEMMOVE_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("limit_default_ammo", {
        Category = "SERVER",
        NiceName = "#GM_DEFAMMO",
        Description = "#GM_DEFAMMO_DESC",
        Type = "bool",
        Default = true,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("allow_auto_jump", {
        Category = "SERVER",
        NiceName = "#GM_AUTOJUMP",
        Description = "#GM_AUTOJUMP_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("max_respawn_timeout", {
        Category = "SERVER",
        NiceName = "#GM_RESPAWNTIME",
        Description = "#GM_RESPAWNTIME_DESC",
        Type = "int",
        Default = 20,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 600
        }
    })

    GAMEMODE:AddSetting("checkpoint_respawn", {
        Category = "SERVER",
        NiceName = "#GM_CHECKPOINT_RESPAWN",
        Description = "#GM_CHECKPOINT_RESPAWN_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
    })

    GAMEMODE:AddSetting("map_restart_timeout", {
        Category = "SERVER",
        NiceName = "#GM_RESTARTTIME",
        Description = "#GM_RESTARTTIME_DESC",
        Type = "int",
        Default = 10,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 600
        }
    })

    GAMEMODE:AddSetting("map_change_timeout", {
        Category = "SERVER",
        NiceName = "#GM_MAPCHANGETIME",
        Description = "#GM_MAPCHANGETIME_DESC",
        Type = "int",
        Default = 60,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 600
        }
    })

    GAMEMODE:AddSetting("checkpoint_timeout", {
        Category = "SERVER",
        NiceName = "#GM_CHECKPOINTTIMEOUT",
        Description = "#GM_CHECKPOINTTIMEOUT_DESC",
        HelpText = "Set to 0 to disable timeout",
        Type = "int",
        Default = 60,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 600
        }
    })

    GAMEMODE:AddSetting("player_god", {
        Category = "SERVER",
        NiceName = "#GM_GODMODE",
        Description = "#GM_GODMODE_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("pickup_delay", {
        Category = "SERVER",
        NiceName = "#GM_PICKUPDELAY",
        Description = "#GM_PICKUPDELAY_DESC",
        Type = "float",
        Default = 0.5,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        maxv = 10
    })

    GAMEMODE:AddSetting("difficulty_metrics", {
        Category = "DEVELOPER",
        NiceName = "#GM_DIFFMETRICS",
        Description = "#GM_DIFFMETRICS_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_REPLICATED),
        maxv = 1
    })

    GAMEMODE:AddSetting("weapondropmode", {
        Category = "SERVER",
        NiceName = "#GM_WEAPONDROP",
        Description = "#GM_WEAPONDROP_DESC",
        Type = "int",
        Default = 1,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Extra = {
            Type = "combo",
            Choices = {
                [0] = "Nothing",
                [1] = "Active",
                [2] = "Everything"
            }
        }
    })

    GAMEMODE:AddSetting("abh", {
        Category = "SERVER",
        NiceName = "#GM_ABH",
        Description = "#GM_ABH_DESC",
        Type = "bool",
        Default = false,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED)
    })

    GAMEMODE:AddSetting("changelevel_delay", {
        Category = "SERVER",
        NiceName = "#GM_CHANGELVLDELAY",
        Description = "#GM_CHANGELVLDELAY_DESC",
        Type = "int",
        Default = 6,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 600
        }
    })

    GAMEMODE:AddSetting("max_cockroaches", {
        Category = "SERVER",
        NiceName = "#GM_COCKROACHES",
        Description = "#GM_COCKROACHES_DESC",
        Type = "int",
        Default = 30,
        Flags = bit.bor(0, FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED),
        Clamp = {
            Min = 0,
            Max = 100,
        }
    })

end

function GAMETYPE:GetScoreboardInfo()
    return {}
end

hook.Add("LambdaLoadGameTypes", "LambdaBaseGameType", function(gametypes)
    --
    gametypes:Add("lambda_base", GAMETYPE)
end)