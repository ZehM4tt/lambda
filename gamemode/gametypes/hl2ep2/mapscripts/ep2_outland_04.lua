if SERVER then
    AddCSLuaFile()
end

local MAPSCRIPT = {}
MAPSCRIPT.DefaultLoadout = {
    Weapons = {
        "weapon_lambda_medkit",
        "weapon_physcannon",
        "weapon_357",
        "weapon_smg1",
        "weapon_crowbar",
        "weapon_pistol",
        "weapon_shotgun",
    },
    Ammo = {
    },
    Armor = 30,
    HEV = true
}

MAPSCRIPT.InputFilters = {
    ["plank_2_break"] = {"Break"},
    ["plank_2_rotating"] = {"Open"},
}
MAPSCRIPT.EntityFilterByClass = {}
MAPSCRIPT.EntityFilterByName = {
    ["loaditems"] = true,
    ["player_death_fall_trigger"] = true,
    ["vort_shaft_blocker_1"] = true,
    ["plank_2_kill_trigger"] = true,
    ["plank_2_break_trigger"] = true,
}

MAPSCRIPT.GlobalStates = {
}

MAPSCRIPT.Checkpoints = {
    {
        Pos = Vector(4923.1, -1864.1, 176.1),
        Ang = Angle(0, 0, 0),
        Trigger = {
            Pos = Vector(4991.264648, -1872.797729, 176.031250),
            Mins = Vector(-100, -95, 0),
            Maxs = Vector(100, 95, 140)
        }
    },
    {
        Pos = Vector(6576, -3378.766846, -69),
        Ang = Angle(0, -90, 0),
        Trigger = {
            Pos = Vector(6576, -3378.766846, -69),
            Mins = Vector(-20, -20, 0),
            Maxs = Vector(20, 20, 40)
        }
    },
    {
        Pos = Vector(6074.604980, -2448.431641, -1129),
        Ang = Angle(0, 173, 0),
        Trigger = {
            Pos = Vector(6074.604980, -2448.431641, -1129),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 70)
        }
    },
    {
        Pos = Vector(3248.099609, 454.039337, -1518.137817),
        Ang = Angle(0, 90, 0),
        Trigger = {
            Pos = Vector(3248.099609, 454.039337, -1518.137817),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 70)
        }
    },
    {
        Pos = Vector(2141.473145, -1152.235474, -1843.205811),
        Ang = Angle(0, 20, 0),
        Trigger = {
            Pos = Vector(2141.473145, -1152.235474, -1843.205811),
            Mins = Vector(-25, -25, 0),
            Maxs = Vector(25, 25, 70)
        }
    },
    {
        Pos = Vector(5316.966797, -4152.538086, -2296.5),
        Ang = Angle(0, 20, 0),
        Trigger = {
            Pos = Vector(5316.966797, -4152.538086, -2296.5),
            Mins = Vector(-75, -75, 0),
            Maxs = Vector(75, 75, 70)
        }
    },
}

function MAPSCRIPT:PostInit()
    print("-- Incomplete mapscript --")

    -- Slightly reposition the vort to allow players to get by easier.
    ents.WaitForEntityByName("mark_elevator_jump_wait", function(ent)
        ent:SetPos(Vector(5076, -1576, 396))
    end)

    ents.WaitForEntityByName("elevator_exit_trigger", function(ent)
        ent:ResizeTriggerBox(Vector(-10, -40, -40), Vector(40, 40, 40))
        ent:SetKeyValue("teamwait", "1")
    end)

end

return MAPSCRIPT