local util = util
if SERVER then
    AddCSLuaFile()
    util.AddNetworkString("LambdaPlayerSettings")
    util.AddNetworkString("LambdaPlayerSettingsChanged")
    util.AddNetworkString("LambdaPlayerDamage")
    util.AddNetworkString("LambdaPlayerMatOverlay")
end

local DbgPrint = GetLogging("Player")
local DbgPrintDmg = GetLogging("Damage")
local CurTime = CurTime
local Vector = Vector
local math = math
local ents = ents
local player = player
local IsValid = IsValid
local table = table
DEFINE_BASECLASS("gamemode_base")
local SUIT_DEVICE_BREATHER = 1
local SUIT_DEVICE_SPRINT = 2
local sv_infinite_aux_power = GetConVar("sv_infinite_aux_power")
-- We use this constant for kickback from the back.
local HITGROUP_HEAD_BACK = 100
local HITGROUP_BACK = 101
if SERVER then
    function GM:IsPlayerEnemy(ply1, ply2)
        local isEnemy = self:CallGameTypeFunc("IsPlayerEnemy", ply1, ply2)
        return isEnemy
    end

    function GM:ShowHelp(ply)
        local posLocked = ply:IsPositionLocked()
        if posLocked == false then self:TogglePlayerSettings(ply, true, 1) end
    end

    function GM:ShowTeam(ply)
        local posLocked = ply:IsPositionLocked()
        if posLocked == false then self:TogglePlayerSettings(ply, true, 2) end
    end

    function GM:ShowSpare1(ply)
        local posLocked = ply:IsPositionLocked()
        if posLocked == false then self:TogglePlayerSettings(ply, true, 3) end
    end

    function GM:ShowSpare2(ply)
        local posLocked = ply:IsPositionLocked()
        if posLocked == false then self:TogglePlayerSettings(ply, true, 4) end
    end

    function GM:TogglePlayerSettings(ply, state, tab)
        if state == true then
            DbgPrint(ply, "Changing to settings")
            ply:LockPosition(true, VIEWLOCK_SETTINGS_ON)
            net.Start("LambdaPlayerSettings")
            net.WriteBool(true)
            net.WriteUInt(tab, 3)
            net.Send(ply)
        else
            DbgPrint(ply, "Leaveing settings")
            ply:LockPosition(true, VIEWLOCK_SETTINGS_RELEASE)
            net.Start("LambdaPlayerSettings")
            net.WriteBool(false)
            net.Send(ply)
        end
    end

    net.Receive("LambdaPlayerSettings", function(len, ply)
        local state = net.ReadBool()
        if state == true then return end
        -- Who cares about state, only sent when closed.
        GAMEMODE:TogglePlayerSettings(ply, false)
    end)

    net.Receive("LambdaPlayerSettingsChanged", function(len, ply)
        GAMEMODE:PlayerSetColors(ply)
        GAMEMODE:PlayerSetModel(ply)
        GAMEMODE:PlayerSetSkin(ply)
        GAMEMODE:PlayerSetBodyGroup(ply)
    end)

    function GM:ResetPlayerRespawnQueue()
        DbgPrint("Reset respawn queue")
        self.PlayerRespawnQueue = {}
    end

    function GM:AddPlayerToRespawnQueue(ply)
        DbgPrint("Adding " .. tostring(ply) .. " to respawn queue")
        self.PlayerRespawnQueue[ply] = true
    end

    function GM:IsPlayerInRespawnQueue(ply)
        if not IsValid(ply) or ply:Alive() == true then return false end
        return self.PlayerRespawnQueue[ply] == true
    end

    function GM:RemovePlayerFromRespawnQueue(ply)
        if not IsValid(ply) then return end
        DbgPrint("Removing " .. tostring(ply) .. " from respawn queue")
        self.PlayerRespawnQueue[ply] = nil
    end

    function GM:CanPlayerSuicide(ply)
        if ply:Alive() == false then return false end
        if ply:IsPositionLocked() then return false end
        return true
    end

    function GM:PlayerDisconnected(ply)
        -- Remove from queue.
        self:RemovePlayerFromRespawnQueue(ply)
        if ply.LambdaPlayerData == nil then DbgPrint("Disconnected without LambdaPlayerData assigned, bug?") end
        if IsValid(ply.TrackerEntity) then ply.TrackerEntity:Remove() end
        return BaseClass.PlayerDisconnected(self, ply)
    end

    function GM:SetupPlayerVisibility(ply, viewEnt)
    end

    function GM:PlayerInitialSpawn(ply)
        DbgPrint("GM:PlayerInitialSpawn")
        self:HandlePlayerConnect(ply:SteamID(), ply:Nick(), ply:EntIndex(), ply:IsBot(), ply:UserID())
        self:IncludePlayerInRound(ply)
        self:SendPlayerModelList(ply)
        local model = "models/player/riot.mdl"
        ply.LambdaLastModel = model
        local transitionData = self:GetPlayerTransitionData(ply)
        if transitionData ~= nil then
            ply:SetFrags(transitionData.Frags)
            ply:SetDeaths(transitionData.Deaths)
        end

        ply:SetTeam(TEAM_SPECTATOR)
        ply:SetName("!player") -- Some thing are triggered between PlayerInitialSpawn and PlayerSpawn
        if ply:IsBot() == false then ply:SetInactive(true) end
        -- If game in progress player needs to wait.
        local elapsed = self:RoundElapsedTime()
        DbgPrint("Round time elapsed:", elapsed)
        -- Also we allow players to directly spawn if the round just started.
        if self:IsRoundRunning() == true then
            if self:WaitForNextCheckpoint(ply) == true and elapsed >= 30 then
                ply.InitialSpawnHandled = false
            else
                ply.InitialSpawnHandled = true
            end
        else
            ply.InitialSpawnHandled = true
        end

        self:AssignPlayerAuthToken(ply)
        self:AddPlayerToRespawnQueue(ply)
    end

    function GM:PlayerSelectSpawn(ply)
        DbgPrint("PlayerSelectSpawn")
        local gameType = self:GetGameType()
        if gameType.UsingCheckpoints == true then
            -- Check if players reached a checkpoint.
            if self.CurrentCheckpoint ~= nil and IsValid(self.CurrentCheckpoint) then
                ply.SelectedSpawnpoint = self.CurrentCheckpoint
                return self.CurrentCheckpoint
            end
        end

        local spawnClass = self:GetGameTypeData("PlayerSpawnClass")
        DbgPrint("Spawn class: " .. spawnClass)
        local spawnpoints = ents.FindByClass(spawnClass)
        if #spawnpoints == 0 then
            -- Always use a fallback.
            spawnpoints = ents.FindByClass("info_player_start")
        end

        local spawnpoint = nil
        local possibleSpawns = {}
        for _, v in pairs(spawnpoints) do
            if self:CallGameTypeFunc("CanPlayerSpawn", ply, v) == true then table.insert(possibleSpawns, v) end
        end

        if spawnpoint == nil and #possibleSpawns > 0 then spawnpoint = self:CallGameTypeFunc("PlayerSelectSpawn", possibleSpawns) end
        DbgPrint("Select spawnpoint for player: " .. tostring(ply) .. ", spawn: " .. tostring(spawnpoint))
        ply.SelectedSpawnpoint = spawnpoint
        return spawnpoint
    end

    function GM:WaitForNextCheckpoint(ply)
        local gameType = self:GetGameType()
        if gameType.UsingCheckpoints == true then return self:CallGameTypeFunc("CheckpointEnablesRespawn") end
        return false
    end

    function GM:CanPlayerSpawn(ply)
        -- If the round has not yet started nobody can spawn.
        if self.WaitingForRoundStart == true then return false end
        local gameType = self:GetGameType()
        if gameType.UsingCheckpoints == true then
            -- Check if the player is waiting for the next checkpoint.
            if self:IsPlayerInRespawnQueue(ply) == true then return false end
            -- Check if players reached a checkpoint.
            if self.CurrentCheckpoint ~= nil and IsValid(self.CurrentCheckpoint) then return true end
        end

        local spawnClass = self:GetGameTypeData("PlayerSpawnClass")
        local spawnpoints = ents.FindByClass(spawnClass)
        if #spawnpoints == 0 then
            -- Always use a fallback.
            spawnpoints = ents.FindByClass("info_player_start")
        end

        for _, v in pairs(spawnpoints) do
            -- If set by us then this is the absolute.
            if v.MasterSpawn == true then return true end
            -- If master flag is set it has priority.
            if v:HasSpawnFlags(1) then return true end
            if self:CallGameTypeFunc("CanPlayerSpawn", ply, v) == true then return true end
        end
        return false
    end

    function GM:PlayerSetModel(ply)
        DbgPrint("GM:PlayerSetModel")
        local playermdl = ply:GetInfo("lambda_playermdl")
        if playermdl == nil or playermdl == "" then playermdl = "male05" end
        local mdls = self:GetAvailablePlayerModels()
        local selection = mdls[playermdl]
        if selection == nil then
            DbgPrint("Player " .. tostring(ply) .. " tried to select unknown model: " .. playermdl)
            selection = mdls["male05"]
        end

        local mdl = selection
        util.PrecacheModel(mdl)
        ply:SetModel(mdl)
        if IsValid(ply.TrackerEntity) then ply.TrackerEntity:AttachToPlayer(ply) end
        ply:SetupHands()
    end

    function GM:PlayerSetSkin(ply)
        local skin = ply:GetInfoNum("lambda_playermdl_skin", 0)
        ply:SetSkin(skin)
    end

    function GM:PlayerSetBodyGroup(ply)
        local bg = ply:GetInfo("lambda_playermdl_bodygroup")
        if bg == nil then bg = "" end
        bg = string.Explode(" ", bg)
        for k = 0, ply:GetNumBodyGroups() - 1 do
            ply:SetBodygroup(k, tonumber(bg[k + 1]) or 0)
        end
    end

    function GM:PlayerSetColors(ply)
        --DbgPrint("PlayerSetColors: " .. tostring(ply))
        local plycolor = ply:GetInfo("lambda_player_color") or "0.3 1 1"
        local wepcolor = ply:GetInfo("lambda_weapon_color") or "0.3 1 1"
        ply:SetPlayerColor(util.StringToType(plycolor, "Vector"))
        ply:SetWeaponColor(util.StringToType(wepcolor, "Vector"))
    end

    function GM:PlayerLoadoutRevive(ply)
        local restoreData = ply.RevivalData
        if restoreData == nil then return end
        for cls, data in pairs(restoreData.Weapons) do
            ply:Give(cls, true)
            local wep = ply:GetWeapon(cls)
            if IsValid(wep) then
                wep:SetClip1(data.Clip1)
                wep:SetClip2(data.Clip2)
            end
        end

        for ammoId, data in pairs(restoreData.Ammo) do
            ply:SetAmmo(data, ammoId)
        end
    end

    function GM:PlayerLoadout(ply)
        DbgPrint("PlayerLoadout: " .. tostring(ply))
        local loadout = self:CallGameTypeFunc("GetPlayerLoadout") or {}
        local transitionData = ply.TransitionData
        if transitionData ~= nil and transitionData.Include == true then
            for _, v in pairs(ply.TransitionData.Weapons) do
                ply:Give(v.Class, true)
                ply:SetAmmo(v.Ammo1.Count, v.Ammo1.Id)
                ply:SetAmmo(v.Ammo2.Count, v.Ammo2.Id)
                local wep = ply:GetWeapon(v.Class)
                if IsValid(wep) then
                    wep:SetClip1(v.Clip1)
                    wep:SetClip2(v.Clip2)
                end

                if v.Active == true then
                    ply.ScheduledActiveWeapon = v.Class
                elseif v.Previous == true then
                    ply.ScheduledLastWeapon = v.Class
                end
            end

            ply:SetHealth(ply.TransitionData.Health)
            ply:SetArmor(ply.TransitionData.Armor)
            if ply.TransitionData.Suit then
                ply:EquipSuit()
            else
                ply:RemoveSuit()
            end
        else
            -- Armor
            ply:SetArmor(loadout.Armor or 0)
            -- HEV
            if loadout.HEV == true then
                DbgPrint("EquipSuit(" .. tostring(ply) .. ")")
                ply:EquipSuit()
            else
                DbgPrint("RemoveSuit(" .. tostring(ply) .. ")")
                ply:RemoveSuit()
            end
        end

        -- Give player the default weapons and ammo.
        local ammoTable = loadout.Ammo or {}
        for k, v in pairs(loadout.Weapons or {}) do
            if ply:HasWeapon(v) == true then continue end
            local weapon = ply:Give(v, true)
            local ammoType1 = weapon:GetPrimaryAmmoType()
            if ammoType1 ~= -1 then
                local ammoName = game.GetAmmoName(ammoType1)
                local ammoNum = ammoTable[ammoName]
                if ammoNum ~= nil then ply:GiveAmmo(ammoNum, ammoName, true) end
            end

            local ammoType2 = weapon:GetSecondaryAmmoType()
            if ammoType2 ~= -1 then
                local ammoName = game.GetAmmoName(ammoType2)
                local ammoNum = ammoTable[ammoName]
                if ammoNum ~= nil then ply:GiveAmmo(ammoNum, ammoName, true) end
            end

            -- We make sure the weapon is loaded.
            local ammo1 = ply:GetAmmoCount(weapon:GetPrimaryAmmoType())
            if ammo1 ~= -1 then
                local maxClip = weapon:GetMaxClip1()
                local newAmmo = maxClip
                if newAmmo > ammo1 then newAmmo = ammo1 end
                weapon:SetClip1(newAmmo)
                ply:SetAmmo(ammo1 - newAmmo, weapon:GetPrimaryAmmoType())
            end
        end
    end

    local function GetDamageValue(dmg)
        if isnumber(dmg) then return dmg end
        local cvar = GetConVar(dmg)
        if cvar == nil then return 0 end
        return cvar:GetFloat()
    end

    local WEAPON_PRIORITY_PENALTY =
    {
        ["weapon_frag"] = 100,
        ["weapon_bugbait"] = 100,
        ["weapon_crowbar"] = 100,
    }

    function GM:GetNextBestWeapon(ply)
        local weps = ply:GetWeapons()
        local defaultAmmoData = {
            npcdmg = 0,
            plydmg = 0,
            dmgtype = 0,
        }

        -- Sort them by damage and ammo count.
        table.sort(weps, function(a, b)
            local ammoDataPrimaryA = game.GetAmmoData(a:GetPrimaryAmmoType()) or defaultAmmoData
            local ammoDataSecondaryA = game.GetAmmoData(a:GetSecondaryAmmoType()) or defaultAmmoData
            local ammoDataPrimaryB = game.GetAmmoData(b:GetPrimaryAmmoType()) or defaultAmmoData
            local ammoDataSecondaryB = game.GetAmmoData(b:GetSecondaryAmmoType()) or defaultAmmoData
            local weightA = a:GetWeight() * 3
            local weightB = b:GetWeight() * 3
            local dmgPrimaryA = GetDamageValue(ammoDataPrimaryA.npcdmg) + GetDamageValue(ammoDataPrimaryA.plydmg)
            if bit.band(ammoDataPrimaryA.dmgtype, DMG_BUCKSHOT) ~= 0 then dmgPrimaryA = dmgPrimaryA * 4 end
            local dmgSecondaryA = GetDamageValue(ammoDataSecondaryA.npcdmg) + GetDamageValue(ammoDataSecondaryA.plydmg)
            local dmgPrimaryB = GetDamageValue(ammoDataPrimaryB.npcdmg) + GetDamageValue(ammoDataPrimaryB.plydmg)
            if bit.band(ammoDataPrimaryB.dmgtype, DMG_BUCKSHOT) ~= 0 then dmgPrimaryB = dmgPrimaryB * 4 end
            local dmgSecondaryB = GetDamageValue(ammoDataSecondaryB.npcdmg) + GetDamageValue(ammoDataSecondaryB.plydmg)
            local ammoCountPrimaryA = ply:GetAmmoCount(a:GetPrimaryAmmoType())
            local ammoCountSecondaryA = ply:GetAmmoCount(a:GetSecondaryAmmoType())
            local ammoCountPrimaryB = ply:GetAmmoCount(b:GetPrimaryAmmoType())
            local ammoCountSecondaryB = ply:GetAmmoCount(b:GetSecondaryAmmoType())
            local bonusDualA = (a:GetPrimaryAmmoType() ~= -1 and a:GetSecondaryAmmoType() ~= -1) and 1 or 0
            local bonusDualB = (b:GetPrimaryAmmoType() ~= -1 and b:GetSecondaryAmmoType() ~= -1) and 1 or 0
            -- Combine all the values to get a weight.
            weightA = weightA + ((ammoCountPrimaryA * dmgPrimaryA) * 0.1) + ((ammoCountSecondaryA * dmgSecondaryA) * 0.5) + bonusDualA
            weightB = weightB + ((ammoCountPrimaryB * dmgPrimaryB) * 0.1) + ((ammoCountSecondaryB * dmgSecondaryB) * 0.5) + bonusDualB
            -- Penalize certain weapons.
            local penaltyA = WEAPON_PRIORITY_PENALTY[a:GetClass()] or 0
            local penaltyB = WEAPON_PRIORITY_PENALTY[b:GetClass()] or 0
            weightA = weightA - penaltyA
            weightB = weightB - penaltyB
            return weightA > weightB
        end)

        if #weps == 0 then return nil end
        return weps[1]
    end

    function GM:SelectBestWeapon(ply)
        local betterWep = self:GetNextBestWeapon(ply)
        if IsValid(betterWep) then
            ply:SelectWeapon(betterWep:GetClass())
            return
        end

        ply:SwitchToDefaultWeapon()
    end

    function GM:RevivePlayer(ply, pos, ang, health)
        pos = pos or ply:GetPos()
        ang = ang or ply:GetAngles()
        ply.Reviving = true
        ply:Spawn()
        ply.Reviving = false
        ply:SetHealth(health or 30)
        ply:TeleportPlayer(pos, ang)
    end

    function GM:PlayerSpawn(ply)
        DbgPrint("GM:PlayerSpawn")
        if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
            ply:KillSilent()
            return
        end

        -- We need this to make sure players end up in the respawn queue.
        if ply.InitialSpawnHandled == false then
            DbgPrint("Initial spawn, using respawn queue")
            ply.InitialSpawnHandled = true
            ply:KillSilent()
            return
        end

        -- Bloody fucking hell.
        ply:SetSaveValue("m_bPreventWeaponPickup", false)
        -- Stop observer mode
        ply:UnSpectate()
        ply:SetupHands()
        ply:EndSpectator()
        ply.SpawnBlocked = false
        ply.LambdaSpawnTime = CurTime()
        ply.IsCurrentlySpawning = true
        ply.DeathAcknowledged = false
        -- If we managed to spawn somehow else.
        self:RemovePlayerFromRespawnQueue(ply)
        self:PlayerSetModel(ply)
        self:PlayerSetSkin(ply)
        self:PlayerSetBodyGroup(ply)
        self:InitializePlayerPickup(ply)
        self:InitializePlayerSpeech(ply)
        self:PlayerSetColors(ply)
        self:NotifyRoundStateChanged(ply, ROUND_INFO_NONE, {})
        -- Update vehicle checkpoints
        self:UpdateQueuedVehicleCheckpoints()
        -- Alive at this point.
        ply:SetTeam(LAMBDA_TEAM_ALIVE)
        -- Either loadout or previous equipment.
        ply:StripAmmo()
        ply:StripWeapons()
        ply:DisablePlayerCollide(true)
        -- Lets remove whatever the player left on vehicles behind before he got killed.
        if ply.Reviving ~= true then
            -- Should we really do this?
            ply.WeaponDuplication = {}
            ply:RemoveSuit()
            hook.Call("PlayerLoadout", GAMEMODE, ply)
            hook.Call("PlayerSetModel", GAMEMODE, ply)
        elseif ply.Reviving == true then
            hook.Call("PlayerLoadoutRevive", GAMEMODE, ply)
        end

        if self.MapScript.PrePlayerSpawn ~= nil then self.MapScript:PrePlayerSpawn(ply) end
        ply:SetLambdaSuitPower(100)
        ply:SetGeigerRange(1000)
        ply:SetLambdaStateSprinting(false)
        ply:SetLambdaSprinting(false)
        ply:SetDuckSpeed(0.4)
        ply:SetUnDuckSpeed(0.2)
        if ply:IsBot() == false then
            ply:SetInactive(true)
            ply:DisablePlayerCollide(true)
        end

        ply:SetRunSpeed(self:GetSetting("sprintspeed")) -- TODO: Put this in a convar.
        ply:SetWalkSpeed(self:GetSetting("normspeed"))
        ply:SetMaxSpeed(self:GetSetting("normspeed"))
        if ply:IsBot() then
            local r = 0.3 + (math.sin(ply:EntIndex()) * 0.7)
            local g = 0.3 + (math.sin(ply:EntIndex() * 33) * 0.7)
            local b = 0.3 + (math.sin(ply:EntIndex() * 17) * 0.7)
            ply:SetWeaponColor(Vector(r, g, b))
        end

        if ply.Reviving ~= true then
            local transitionData = ply.TransitionData
            local useSpawnpoint = true
            if transitionData ~= nil and transitionData.Include == true then
                DbgPrint("Player " .. tostring(ply) .. " has transition data.")
                -- We keep those.
                ply:SetFrags(transitionData.Frags)
                ply:SetDeaths(transitionData.Deaths)
                if transitionData.Vehicle ~= nil then
                    local vehicle = self:FindEntityByTransitionReference(transitionData.Vehicle)
                    if IsValid(vehicle) then
                        DbgPrint("Putting player " .. tostring(ply) .. " back in vehicle: " .. tostring(vehicle))
                        -- Sometimes does crazy things to the view angles, this only helps to a certain amount.
                        local eyeAng = vehicle:WorldToLocalAngles(transitionData.EyeAng)
                        vehicle:SetVehicleEntryAnim(false)
                        vehicle.ResetVehicleEntryAnim = true
                        ply:EnterVehicle(vehicle)
                        ply:SetEyeAngles(eyeAng) -- We call it again because the vehicle sets it to how you entered.
                        useSpawnpoint = false
                    else
                        DbgPrint("Unable to find player " .. tostring(ply) .. " vehicle: " .. tostring(transitionData.Vehicle))
                    end
                elseif transitionData.Ground ~= nil then
                    local groundEnt = self:FindEntityByTransitionReference(transitionData.Ground)
                    if IsValid(groundEnt) then
                        local newPos = groundEnt:LocalToWorld(transitionData.GroundPos)
                        DbgPrint("Using func_tracktrain as spawn position reference.", newPos, groundEnt)
                        ply:TeleportPlayer(newPos, transitionData.Ang)
                        useSpawnpoint = false
                    else
                        DbgPrint("Ground set but not found")
                    end
                else
                    DbgPrint("Player " .. tostring(ply) .. " uses normal position")
                    ply:TeleportPlayer(transitionData.Pos, transitionData.Ang)
                    ply:SetAngles(transitionData.Ang)
                    ply:SetEyeAngles(transitionData.EyeAng)
                    useSpawnpoint = false
                end
            end

            DbgPrint("Selecting best weapon for " .. tostring(ply))
            if ply.ScheduledActiveWeapon ~= nil then
                ply:SelectWeapon(ply.ScheduledActiveWeapon)
                ply.ScheduledActiveWeapon = nil
            else
                self:SelectBestWeapon(ply)
            end

            if ply.ScheduledLastWeapon ~= nil then
                local wep = ply:GetWeapon(ply.ScheduledLastWeapon)
                if IsValid(wep) then ply:SetSaveValue("m_hLastWeapon", wep) end
            end

            if self.MapScript.PostPlayerSpawn ~= nil then self.MapScript:PostPlayerSpawn(ply) end
            -- In case the map script decides to put us in a vehicle lets not do this.
            if useSpawnpoint == true and IsValid(ply:GetVehicle()) == false and IsValid(ply.SelectedSpawnpoint) then
                ply:TeleportPlayer(ply.SelectedSpawnpoint:GetPos(), ply.SelectedSpawnpoint:GetAngles())
                ply.SelectedSpawnpoint = nil
            end

            ply.TransitionData = nil -- Make sure we erase it because this only happens on a new round.
        end

        if SERVER then util.RunNextFrame(function() self:CheckPlayerNotStuck(ply) end) end
        -- Adjust difficulty, we want later some dynamic system that adjusts depending on the players.
        self:AdjustDifficulty()
        if not IsValid(ply.TrackerEntity) then
            ply.TrackerEntity = ents.Create("lambda_player_tracker")
            ply.TrackerEntity:AttachToPlayer(ply)
        end

        local ragdollMgr = ply:GetRagdollManager()
        if IsValid(ragdollMgr) == false then
            local mgr = ents.Create("lambda_ragdollmanager")
            mgr:SetPos(ply:GetPos())
            mgr:SetOwner(ply)
            mgr:SetParent(ply)
            mgr:Spawn()
            ply:SetRagdollManager(mgr)
        else
            -- If we are being revived then we also snatch the model instance.
            ragdollMgr:RemoveRagdoll(ply.Reviving)
        end

        ply.IsCurrentlySpawning = false
        -- Notify the player to start the gamemode in multiplayer to avoid any possible gamemode issues.
        if game.SinglePlayer() == true then
            timer.Create("SPNotify", 2, 10, function() PrintMessage(HUD_PRINTCENTER, "You are in Singleplayer mode. For a better playing experience start Lambda in Multiplayer.") end)
            PrintMessage(HUD_PRINTTALK, "You are in Singleplayer mode. For a better playing experience start Lambda in Multiplayer.")
        end
    end

    function GM:CheckPlayerNotStuck(ply)
        -- Thats all there is to it, hopefully.
        if ply:InVehicle() then return end
        util.PlayerUnstuck(ply)
    end

    local AMMO_TO_ITEM = {
        ["RPG_Round"] = "item_rpg_round",
        ["Grenade"] = "weapon_frag"
    }

    function GM:DoPlayerDeath(ply, attacker, dmgInfo)
        DbgPrint("GM:DoPlayerDeath", ply)
        if ply.LastWeaponsDropped ~= nil then
            for _, v in pairs(ply.LastWeaponsDropped) do
                if IsValid(v) and not IsValid(v:GetOwner()) then v:Remove() end
            end
        end

        local weps = {}
        local dropMode = self:GetSetting("weapondropmode")
        if dropMode >= 1 then
            -- Add active weapon.
            local activeWep = ply:GetActiveWeapon()
            if IsValid(activeWep) then weps[activeWep] = true end
            -- Drop everything.
            if dropMode >= 2 then
                for _, v in pairs(ply:GetWeapons()) do
                    weps[v] = true
                end
            end
        end

        -- Save all the data for when players get revived they have their previous equip.
        local restoreData = {}
        restoreData.Weapons = {}
        for _, v in pairs(ply:GetWeapons()) do
            restoreData.Weapons[v:GetClass()] = {
                Clip1 = v:Clip1(),
                Clip2 = v:Clip2()
            }
        end

        restoreData.Ammo = {}
        for _, v in pairs(ply:GetWeapons()) do
            local primaryAmmo = v:GetPrimaryAmmoType()
            if primaryAmmo ~= -1 then
                local name = game.GetAmmoName(primaryAmmo)
                restoreData.Ammo[name] = ply:GetAmmoCount(primaryAmmo)
            end

            local secondaryAmmo = v:GetSecondaryAmmoType()
            if secondaryAmmo ~= -1 then
                local name = game.GetAmmoName(secondaryAmmo)
                restoreData.Ammo[name] = ply:GetAmmoCount(secondaryAmmo)
            end
        end

        ply.RevivalData = restoreData
        ply.LastWeaponsDropped = {}
        for v, _ in pairs(weps) do
            local ammoType1 = v:GetPrimaryAmmoType()
            local ammoType2 = v:GetSecondaryAmmoType()
            local dropAmmo = false
            local ammo1 = -1
            local ammo2 = -1
            if v:Clip1() == -1 and v:Clip2() == -1 then
                ammo1 = ply:GetAmmoCount(ammoType1)
                if ammo1 > 0 then dropAmmo = true end
                ammo2 = ply:GetAmmoCount(ammoType2)
                if ammo2 > 0 then dropAmmo = true end
            end

            local drop
            if dropAmmo == true and ammo1 > 0 then
                local ammoDropType1 = game.GetAmmoName(ammoType1)
                local dropClass = AMMO_TO_ITEM[ammoDropType1]
                if dropClass ~= nil then
                    for i = 1, ammo1 do
                        drop = ents.Create(dropClass)
                        drop:SetPos(v:GetPos())
                        drop:Spawn()
                        drop.DroppedByPlayer = ply
                    end
                end
            else
                drop = ents.Create(v:GetClass())
                drop:SetClip1(v:Clip1())
                drop:SetClip2(v:Clip2())
                drop:SetPos(v:GetPos())
                drop:SetAngles(v:GetAngles())
                drop:Spawn()
                drop.DroppedByPlayer = ply
                drop.UniqueEntityId = v.UniqueEntityId
                if drop:GetClass() == "weapon_crowbar" then
                    -- Damage players if it gets thrown their way and they already have a crowbar
                    drop:SetSolidFlags(FSOLID_CUSTOMBOXTEST)
                    drop:SetCollisionGroup(COLLISION_GROUP_PLAYER)
                end

                table.insert(ply.LastWeaponsDropped, drop)
            end

            if drop ~= nil and drop:GetClass() == "weapon_physcannon" then
                local color = ply:GetWeaponColor()
                drop:SetLastWeaponColor(color)
            end

            -- Remove the weapon the player holds.
            v:Remove()
        end

        local dmgForce = dmgInfo:GetDamageForce() * 0.1
        -- Apply the velocity to all weapons, when dropped they have zero.
        for _, v in ipairs(ply.LastWeaponsDropped) do
            local phys = v:GetPhysicsObject()
            if IsValid(phys) then phys:SetVelocity(dmgForce * 0.03) end
        end

        ply:SetShouldServerRagdoll(false)
        local damgeDist = dmgInfo:GetDamagePosition():Distance(ply:GetPos())
        local enableGore = true
        local gibPlayer = false
        local didExplode = false
        local vel2D = ply:GetVelocity():Length2D()
        if enableGore == true then
            --print(damageForceLen, dmg)
            if dmgInfo:IsDamageType(DMG_BLAST) and damgeDist < 150 then
                -- Exploded
                gibPlayer = true
                didExplode = true
            elseif dmgInfo:IsDamageType(DMG_CRUSH) and IsValid(attacker) then
                -- Crushed
                local totalMass = 0
                for i = 0, attacker:GetPhysicsObjectCount() - 1 do
                    local physObj = attacker:GetPhysicsObjectNum(i)
                    if IsValid(physObj) then totalMass = totalMass + physObj:GetMass() end
                end

                local forceLen = dmgForce:Length2D()
                if forceLen <= 0 then forceLen = 1 end
                local forceWithMass = totalMass * forceLen
                if forceWithMass >= 150000 or totalMass >= 10000 then gibPlayer = true end
            elseif dmgInfo:IsDamageType(DMG_FALL) and vel2D >= 600 then
                gibPlayer = true
                dmgForce = ply:GetVelocity()
            end
        end

        -- If we gib the player nothing is left.
        if gibPlayer == true then ply.RevivalData = nil end
        local ragdollMgr = ply:GetRagdollManager()
        if IsValid(ragdollMgr) then ragdollMgr:CreateRagdoll(dmgForce, gibPlayer, didExplode) end
        local inflictor = dmgInfo:GetInflictor()
        self:RegisterPlayerDeath(ply, attacker, inflictor, dmgInfo)
    end

    function GM:PlayerDeathSound()
        return true
    end

    function GM:PlayerDeath(ply, attacker, inflictor)
        DbgPrint("GM:PlayerDeath", ply)
        local effectdata = EffectData()
        effectdata:SetOrigin(ply:GetPos())
        effectdata:SetNormal(Vector(0, 0, 1))
        effectdata:SetRadius(50)
        effectdata:SetEntity(ply)
        util.Effect("lambda_death", effectdata, true)
        self:CallGameTypeFunc("PlayerDeath", ply, attacker, inflictor)
    end

    function GM:RegisterPlayerDeath(ply, attacker, inflictor, dmgInfo)
        DbgPrint("RegisterPlayerDeath", ply, attacker, inflictor)
        self:SendDeathNotice(ply, attacker, inflictor, dmgInfo:GetDamageType())
    end

    function GM:PostPlayerDeath(ply)
        DbgPrint("GM:PostPlayerDeath", ply)
        ply.DeathTime = GetSyncedTimestamp()
        ply:SetTeam(LAMBDA_TEAM_DEAD)
        ply:LockPosition(false, false)
        local respawnTime = self:CallGameTypeFunc("GetPlayerRespawnTime")
        ply.RespawnTime = ply.DeathTime + respawnTime
        if self:WaitForNextCheckpoint(ply) then self:AddPlayerToRespawnQueue(ply) end
        if self:IsRoundRestarting() == false and self:CallGameTypeFunc("ShouldRestartRound") == false then
            if self:CanPlayerSpawn(ply) == true then
                DbgPrint("Notifying respawn")
                self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN, {
                    EntIndex = ply:EntIndex(),
                    Respawn = true,
                    StartTime = ply.DeathTime,
                    Timeout = respawnTime
                })
            else
                DbgPrint("Notifying spawn blocked")
                self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN, {
                    EntIndex = ply:EntIndex(),
                    Respawn = true,
                    StartTime = ply.DeathTime,
                    Timeout = 0,
                    SpawnBlocked = true
                })

                ply:SetSpawningBlocked(true)
            end
        end
    end

    function GM:PlayerDeathThink(ply)
        if self.WaitingForRoundStart == true or self:IsRoundRestarting() == true then
            DbgPrint("Can not spawn before players available")
            return false
        end

        local elapsed = GetSyncedTimestamp() - ply.DeathTime
        if elapsed >= 5 and ply:IsSpectator() == false then ply:SetSpectator() end
        if GetSyncedTimestamp() < ply.RespawnTime then return false end
        local timeout = self:CallGameTypeFunc("GetPlayerRespawnTime")
        if timeout >= 0 then if GetSyncedTimestamp() < ply.RespawnTime then return false end end
        if self:CanPlayerSpawn(ply) == false then
            if ply:IsSpawningBlocked() ~= true then
                DbgPrint("Notifying spawn blocked")
                self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN, {
                    EntIndex = ply:EntIndex(),
                    Respawn = true,
                    StartTime = ply.DeathTime,
                    Timeout = 0,
                    SpawnBlocked = true
                })

                ply:SetSpawningBlocked(true)
            end
            -- Can't spawn.
            return false
        end

        -- If the player was previously blocked, notify.
        if ply:IsSpawningBlocked() == true then
            DbgPrint("Notifying spawn free")
            self:NotifyRoundStateChanged(ply, ROUND_INFO_PLAYERRESPAWN, {
                EntIndex = ply:EntIndex(),
                Respawn = true,
                StartTime = ply.DeathTime,
                Timeout = 0,
                SpawnBlocked = false
            })

            ply:SetSpawningBlocked(false)
        end

        if ply:KeyReleased(IN_JUMP) then ply:Spawn() end
        return true
    end

    function GM:PlayerSwitchFlashlight(ply, enabled)
        if not ply:IsSuitEquipped() then return false end
        return true
    end

    function GM:LimitPlayerAmmo(ply)
        if self:GetSetting("limit_default_ammo") == false then return end
        local curTime = CurTime()
        ply.LastAmmoCheck = ply.LastAmmoCheck or curTime
        if curTime - ply.LastAmmoCheck < 0.100 then return end
        ply.LastAmmoCheck = curTime
        for k, v in pairs(self.MAX_AMMO_DEF) do
            local count = ply:GetAmmoCount(k)
            local maxCount = v:GetInt()
            if count > maxCount then ply:SetAmmo(maxCount, k) end
        end
    end

    function GM:AllowPlayerPickup(ply, ent)
        ply.LastPickupTime = ply.LastPickupTime or 0
        local pickupDelay = self:GetSetting("pickup_delay")
        local curTime = CurTime()
        if curTime - ply.LastPickupTime < pickupDelay then return false end
        ply.LastPickupTime = curTime
        return true
    end

    function GM:GetFallDamage(ply, speed)
        speed = speed - 480
        return speed * (100 / (1024 - 480))
    end

    function GM:PlayerUse(ply, ent)
        if self.MapScript ~= nil and self.MapScript.PlayerUse ~= nil then
            local res = self.MapScript:PlayerUse(ply, ent)
            if res == false then return false end
        end
        return true
    end

    function GM:FindUseEntity(ply, engineEnt)
        if engineEnt ~= nil and engineEnt:IsVehicle() then engineEnt = self:FindVehicleSeat(ply, engineEnt) end
        if self.MapScript ~= nil and self.MapScript.FindUseEntity ~= nil then
            local res = self.MapScript:FindUseEntity(ply, engineEnt)
            if res ~= nil then return res end
        end
        return engineEnt
    end

    function GM:StartScreenOverlay(mat, ply)
        net.Start("LambdaPlayerMatOverlay")
        net.WriteBool(true)
        net.WriteString(mat)
        if not ply then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end

    function GM:StopScreenOverlay(ply)
        net.Start("LambdaPlayerMatOverlay")
        net.WriteBool(false)
        if not ply then
            net.Broadcast()
        else
            net.Send(ply)
        end
    end
end

local GEIGER_DELAY = 0.25
local GEIGER_SOUND_DELAY = 0.06
function GM:UpdateGeigerCounter(ply, mv)
    local curTime = CurTime()
    if SERVER then
        ply.GeigerDelay = ply.GeigerDelay or curTime
        if curTime < ply.GeigerDelay then return end
        ply.GeigerDelay = curTime + GEIGER_DELAY
        local range = math.Clamp(math.floor(ply:GetNearestRadiationRange() / 4), 0, 255)
        if ply:InVehicle() then range = math.Clamp(range * 4, 0, 1000) end
        local randChance = math.random(0, 5)
        if randChance == 0 then
            ply:SetGeigerRange(1000)
            ply:SetNearestRadiationRange(1000, true)
        else
            ply:SetGeigerRange(range)
        end
    else
        if ply:Alive() == false or ply ~= LocalPlayer() then return end
        ply.GeigerSoundDelay = ply.GeigerSoundDelay or curTime
        if curTime < ply.GeigerSoundDelay then return end
        ply.GeigerSoundDelay = curTime + GEIGER_SOUND_DELAY
        local range = ply:GetGeigerRange() * 4
        --DbgPrint(range)
        if range == 0 or range >= 1000 then return end
        local pct = 0
        local vol = 0
        local highSnd = false
        if range > 800 then
            pct = 0
        elseif range > 600 then
            pct = 2
            vol = 0.2
        elseif range > 500 then
            pct = 4
            vol = 0.25
        elseif range > 400 then
            pct = 8
            vol = 0.3
            highSnd = true
        elseif range > 300 then
            pct = 8
            vol = 0.35
            highSnd = true
        elseif range > 200 then
            pct = 28
            vol = 0.39
            highSnd = true
        elseif range > 150 then
            pct = 40
            vol = 0.40
            highSnd = true
        elseif range > 100 then
            pct = 60
            vol = 0.45
            highSnd = true
        elseif range > 75 then
            pct = 80
            vol = 0.45
            highSnd = true
        elseif range > 50 then
            pct = 90
            vol = 0.475
        else
            pct = 95
            vol = 0.5
        end

        vol = (vol * (math.random(0, 127) / 255)) + 0.25
        if math.random(0, 127) < pct then
            local snd
            if highSnd then
                snd = "Geiger.BeepHigh"
            else
                snd = "Geiger.BeepLow"
            end

            --DbgPrint("EMITSOUND")
            ply:EmitSound(snd, 75, 100, vol, CHAN_BODY)
        end
    end
end

local SUIT_SPRINT_DRAIN = 20.0
local SUIT_BREATH_DRAIN = 6.7
local SUIT_CHARGE_RATE = 12.5
local SUIT_CHARGE_DELAY = 1.5
local function PlayerHasSuitEnergy(ply)
    return ply:GetLambdaSuitPower() > 0
end

local function PlayerAllowSprinting(ply)
    if ply:IsSuitEquipped() == false then return false end
    if ply:WaterLevel() > 1 then return false end
    if ply:InVehicle() == true then return false end
    if ply:KeyDown(IN_DUCK) then return false end
    return true
end

local function CanPlaySound(ply)
    if not CLIENT and game.MaxPlayers() > 1 then return false end
    if IsFirstTimePredicted() then return true end
    return false
end

function GM:PlayerRejectSprinting(ply, mv)
    if CanPlaySound(ply) then ply:EmitSound("HL2Player.SprintNoPower") end
end

function GM:PlayerStartSprinting(ply, mv)
    --DbgPrint("PlayerStartSprinting: " .. tostring(ply))
    ply:AddSuitDevice(SUIT_DEVICE_SPRINT)
    ply:SetRunSpeed(self:GetSetting("sprintspeed")) -- TODO: Put this in a convar.
    ply:SetWalkSpeed(self:GetSetting("normspeed"))
    ply:SetMaxSpeed(self:GetSetting("sprintspeed"))
    ply:SetLambdaSprinting(true)
    local suitPower = ply:GetLambdaSuitPower()
    if CanPlaySound(ply) and suitPower > 0 then ply:EmitSound("HL2Player.SprintStart") end
    --DbgPrint("Sprint State: " .. tostring(ply:GetLambdaSprinting()))
end

function GM:PlayerEndSprinting(ply, mv)
    --DbgPrint("PlayerEndSprinting: " .. tostring(ply) )
    ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)
    ply:SetRunSpeed(self:GetSetting("normspeed")) -- TODO: Put this in a convar.
    ply:SetWalkSpeed(self:GetSetting("normspeed"))
    ply:SetMaxSpeed(self:GetSetting("normspeed"))
    ply:SetLambdaSprinting(false)
end

function GM:StartCommand(ply, cmd)
    self:CalculateMovementAccuracy(ply)
    -- TODO: Make this a new setting so bots do random things.
    if false and ply:IsBot() then
        local rnd = math.random(0, 200)
        if rnd < 1 then cmd:AddKey(IN_JUMP) end
        rnd = math.random(0, 100)
        if rnd < 1 then cmd:AddKey(IN_USE) end
        rnd = math.random(0, 200)
        if rnd < 1 then cmd:AddKey(IN_ATTACK) end
        rnd = math.random(0, 10)
        if rnd < 1 then cmd:AddKey(IN_DUCK) end
    end

    if ply:IsPositionLocked() == true then
        local vel = ply:GetVelocity()
        vel.x = 0
        vel.y = 0
        vel.z = math.Clamp(vel.z, -2, 0)
        ply:SetVelocity(vel)
        cmd:ClearButtons()
        cmd:ClearMovement()
        local viewlock = ply:GetViewLock()
        if viewlock == VIEWLOCK_SETTINGS_ON or viewlock == VIEWLOCK_SETTINGS_RELEASE then
            cmd:SetMouseX(0)
            cmd:SetMouseY(0)
            cmd:SetViewAngles(ply:GetAngles())
        end

        ply.LastUserCmdButtons = cmd:GetButtons()
        return
    end

    -- Fixes a prediction error when starting noclip in water and flying out.
    if ply:GetMoveType() == MOVETYPE_NOCLIP and ply:WaterLevel() == 0 then ply:RemoveFlags(FL_INWATER) end
    if CLIENT then
        if cmd:KeyDown(IN_SCORE) then
            cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK)))
            cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_ATTACK2)))
        end

        if self:GetSetting("allow_auto_jump") == true and lambda_auto_jump:GetBool() == true then if ply:GetMoveType() == MOVETYPE_WALK and not ply:IsOnGround() and ply:WaterLevel() < 2 then cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_JUMP))) end end
    end

    if cmd:KeyDown(IN_SPEED) == true and (ply:IsSuitEquipped() ~= true or ply:WaterLevel() > 1) and ply:InVehicle() == false then cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_SPEED))) end
    -- HACKHACK: When the player is crouched and releases IN_DUCK but can't stand up it would
    -- offset the player for a short moment when pressing IN_DUCK again. We suppress this.
    if ply:Crouching() == true and ply:KeyDown(IN_DUCK) == false and cmd:KeyDown(IN_DUCK) == true then cmd:SetButtons(bit.band(cmd:GetButtons(), bit.bnot(IN_DUCK))) end
    ply.LastUserCmdButtons = cmd:GetButtons()

    -- Handle the vehicle take-over mechanic.
    local vehicle = ply:GetVehicle()
    if IsValid(vehicle) then
        self:VehicleStartCommand(ply, vehicle, cmd)
    end
end

function GM:SetupMove(ply, mv, cmd)
    --if not IsFirstTimePredicted() then return end
    if ply:Alive() == false then return end
    local isSprinting = false
    if ply.GetLambdaSprinting ~= nil then isSprinting = ply:GetLambdaSprinting() end
    if bit.band(mv:GetButtons(), IN_JUMP) ~= 0 and bit.band(mv:GetOldButtons(), IN_JUMP) == 0 and ply:OnGround() then ply:SetIsJumping(true) end
    if mv:KeyDown(IN_DUCK) and ply:IsOnGround() and isSprinting == true then
        self:PlayerEndSprinting(ply, mv)
        ply:SetLambdaStateSprinting(false)
    end

    if mv:KeyDown(IN_SPEED) == true then
        --DbgPrint("Is Sprinting: " .. tostring(isSprinting))
        local canSprint = PlayerAllowSprinting(ply)
        local hasEnergy = PlayerHasSuitEnergy(ply)
        local sprintState = ply:GetLambdaStateSprinting()
        if canSprint == true and isSprinting == false and sprintState == false and hasEnergy == true then
            self:PlayerStartSprinting(ply, mv)
        elseif sprintState == false and hasEnergy == false then
            self:PlayerRejectSprinting(ply, mv)
        end

        ply:SetLambdaStateSprinting(true)
    else
        if isSprinting == true then
            --DbgPrint("IN_SPEED missing, stopped sprinting " .. tostring(isSprinting))
            self:PlayerEndSprinting(ply, mv, cmd)
        end

        ply:SetLambdaStateSprinting(false)
    end
end

function GM:Move(ply, mv)
    -- Whoever stumbles upon this code might ask what this is all about.
    --
    -- Its best shown by going to d1_town_01 to the part where you have to lift up the
    -- vehicles, you have to walk on them and them and jump off which is close to impossible
    -- without the code below, feel free to comment it in order to see the difference.
    local groundEnt = ply:GetGroundEntity()
    if mv:KeyDown(IN_JUMP) and groundEnt ~= NULL and IsValid(groundEnt) then
        local class = groundEnt:GetClass()
        if class == "prop_physics" or class == "func_physbox" then
            local phys = groundEnt:GetPhysicsObject()
            if IsValid(phys) and phys:IsMotionEnabled() == true then ply:SetPos(ply:GetPos() + Vector(0, 0, 1)) end
        end
    end
end

function GM:FinishMove(ply, mv)
    if SERVER then
        -- Network velocity to every client to properly sync animations.
        --ply:SetNetworkAbsVelocity(mv:GetVelocity())
        -- Teleport queue.
        local modifiedPlayer = false
        if ply.TeleportQueue ~= nil and #ply.TeleportQueue > 0 then
            local data = ply.TeleportQueue[1]
            ply:SetPos(data.pos)
            ply:SetAngles(data.ang)
            ply:SetVelocity(data.vel)
            ply:SetEyeAngles(data.ang)
            table.remove(ply.TeleportQueue, 1)
            modifiedPlayer = true
            DbgPrint("Teleported player: " .. tostring(ply) .. " to " .. tostring(data.pos))
        end

        if (mv:GetButtons() ~= 0 or ply:IsBot()) and ply:GetLifeTime() > 0.1 and ply:IsInactive() == true then
            DbgPrint(ply, "Player now active")
            ply:SetInactive(false)
        end

        local curPos = mv:GetOrigin()
        if ply.LastPlayerPos ~= nil then
            local distance = ply.LastPlayerPos:Distance(curPos)
            if distance >= 100 then
                -- Player probably teleported
                DbgPrint("Teleport detected, disabling player collisions temporarily.")
                ply:DisablePlayerCollide(true)
            end
        end

        ply.LastPlayerPos = curPos
        if modifiedPlayer == true then return modifiedPlayer end
    end

    if self:GetSetting("abh") == true then
        if ply:GetIsJumping() then
            local forward = ply:EyeAngles()
            forward.y, forward.r = math.Round(forward.y), math.Round(forward.r) -- Prediction is better if math.Round is used on angles
            forward.p = 0
            forward = forward:Forward()
            local speedBoostPerc = ((not ply:Crouching()) and 0.5) or 0.1
            local speedAddition = math.abs(mv:GetForwardSpeed() * speedBoostPerc)
            local maxSpeed = mv:GetMaxSpeed() * (1 + speedBoostPerc)
            local newSpeed = speedAddition + mv:GetVelocity():Length2D()
            if newSpeed > maxSpeed then speedAddition = speedAddition - (newSpeed - maxSpeed) end
            if mv:GetForwardSpeed() < 0 then speedAddition = -speedAddition end
            mv:SetVelocity(forward * speedAddition + mv:GetVelocity())
        end

        ply:SetIsJumping(false)
    end
end

function GM:DrainSuit(ply, amount)
    local current = ply:GetLambdaSuitPower()
    local res = true
    if ply:GetMoveType() == MOVETYPE_NOCLIP then -- Dont do anything in this case
        return true
    end

    if sv_infinite_aux_power:GetBool() == true then amount = 0 end
    current = current - amount
    if current < 0 then
        current = 0
        res = false
    end

    ply:SetLambdaSuitPower(current)
    return res
end

function GM:ChargeSuitPower(ply, amount)
    local current = ply:GetLambdaSuitPower() + amount
    if current > 100.0 then current = 100.0 end
    ply:SetLambdaSuitPower(current)
    ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
    ply:RemoveSuitDevice(SUIT_DEVICE_SPRINT)
end

function GM:ShouldChargeSuitPower(ply)
    local sprinting = ply:GetLambdaSprinting()
    local inWater = ply:WaterLevel() >= 3
    local powerDrain = sprinting or inWater --[[ or flashlightOn ]]
    if powerDrain == true then -- Something is draning power.
        return false
    end

    local power = ply:GetLambdaSuitPower()
    if power >= 100.0 then -- Full
        return false
    end

    local curTime = CurTime()
    ply.NextSuitCharge = ply.NextSuitCharge or curTime
    if curTime < ply.NextSuitCharge then return false end
    --DbgPrint("Should Charge")
    return true
end

function GM:UpdateSuit(ply, mv)
    if ply:IsSuitEquipped() == false then return end
    local frameTime = FrameTime()
    -- Check if we should recharge.
    if self:ShouldChargeSuitPower(ply) == true then
        local amount = SUIT_CHARGE_RATE * frameTime
        self:ChargeSuitPower(ply, amount)
    else
        local powerLoad = 0
        if ply:GetLambdaSprinting() then
            local pos = ply:GetAbsVelocity()
            if math.abs(pos.x) > 0 or math.abs(pos.y) > 0 then powerLoad = powerLoad + SUIT_SPRINT_DRAIN end
        end

        if ply:WaterLevel() >= 3 then
            powerLoad = powerLoad + SUIT_BREATH_DRAIN
            ply:AddSuitDevice(SUIT_DEVICE_BREATHER)
        else
            ply:RemoveSuitDevice(SUIT_DEVICE_BREATHER)
        end

        if powerLoad > 0 then
            ply.NextSuitCharge = CurTime() + SUIT_CHARGE_DELAY
            if self:DrainSuit(ply, powerLoad * frameTime) == false then
                ply.NextSuitCharge = CurTime() + SUIT_CHARGE_DELAY
                if ply:GetLambdaSprinting() == true then self:PlayerEndSprinting(ply, mv) end
            end
        end
    end

    self:UpdateGeigerCounter(ply, mv)
end

local CHOKE_TIME = 1
local WATER_HEALTH_RECHARGE_TIME = 3
function GM:PlayerCheckDrowning(ply)
    if not ply:Alive() or not ply:IsSuitEquipped() then return end
    ply.WaterDamage = ply.WaterDamage or 0
    local curTime = CurTime()
    if ply:WaterLevel() ~= 3 then
        if ply.IsDrowning == true then ply.IsDrowning = false end
        if ply.WaterDamage > 0 then
            ply.NextWaterHealthTime = ply.NextWaterHealthTime or curTime + WATER_HEALTH_RECHARGE_TIME
            if ply:Health() >= 100 then
                ply.WaterDamage = 0
            else
                if ply.NextWaterHealthTime < curTime then
                    ply.WaterDamage = ply.WaterDamage - 10
                    if ply:Health() + 10 > 100 then
                        ply:SetHealth(100)
                    else
                        ply:SetHealth(ply:Health() + 10)
                    end

                    ply.NextWaterHealthTime = curTime + WATER_HEALTH_RECHARGE_TIME
                end
            end
        end
    else
        ply.NextChokeTime = ply.NextChokeTime or curTime + CHOKE_TIME
        if ply:GetLambdaSuitPower() == 0 and curTime > ply.NextChokeTime then
            if ply.IsDrowning ~= true then
                ply.IsDrowning = true
                ply.DrowningStartTime = CurTime()
                ply.WaterDamage = 0
            end

            local dmgInfo = DamageInfo()
            dmgInfo:SetDamage(10)
            dmgInfo:SetDamageType(DMG_DROWN)
            dmgInfo:SetInflictor(game.GetWorld())
            dmgInfo:SetAttacker(game.GetWorld())
            ply:TakeDamageInfo(dmgInfo)
            ply.WaterDamage = ply.WaterDamage + 10
            ply.NextChokeTime = curTime + CHOKE_TIME
        end
    end
end

function GM:PlayerWeaponTick(ply, mv, ucmd)
    -- HACKHACK: Because Think is broken on SWEPS and only called when
    --           the weapon is active we do this for the medkit.
    for _, wep in pairs(ply:GetWeapons()) do
        if wep.PredictedThink ~= nil then wep:PredictedThink() end
    end
end

function GM:PlayerTick(ply, mv)
    self:UpdateSuit(ply, mv)
    self:PlayerWeaponTick(ply, mv)
    if SERVER then
        self:LimitPlayerAmmo(ply)
        self:PlayerCheckDrowning(ply)
        if ply:GetNWBool("LambdaHEVSuit", false) ~= ply:IsSuitEquipped() then ply:SetNWBool("LambdaHEVSuit", ply:IsSuitEquipped()) end
    end
end

function GM:CalculateMovementAccuracy(ent)
    local movementRecoil = ent.MovementRecoil or 0
    ent.MovementRecoil = ent.MovementRecoil or 0
    local vel = ent:GetVelocity()
    local len = vel:Length()
    local target = len / ent:GetWalkSpeed()
    local scale = 100
    if len > 0 then scale = 20 end
    movementRecoil = Lerp(FrameTime() * scale, movementRecoil, target)
    movementRecoil = math.Clamp(movementRecoil, 0, 2)
    ent.MovementRecoil = movementRecoil
end

function GM:PlayerUpdateSettings(ply)
end

function GM:CheckPlayerCollision(ply)
    local curTime = CurTime()
    if ply.NextPlayerCollideTest == nil or curTime < ply.NextPlayerCollideTest then return end
    if ply:IsPositionLocked() ~= false then return end
    -- If server set collisions off don't bother reverting.
    local playersCollide = self:GetSetting("playercollision", true)
    if playersCollide == false then return end
    if ply:IsPlayerCollisionEnabled() == true then return end
    local hullMin, hullMax = ply:GetHull()
    -- Extend the hull so we keep collisions off in tight spaces.
    hullMin.x = hullMin.x * 2
    hullMin.y = hullMin.y * 2
    hullMax.x = hullMax.x * 2
    hullMax.y = hullMax.y * 2
    local tr = util.TraceHull({
        start = ply:GetPos(),
        endpos = ply:GetPos(),
        filter = ply,
        mins = hullMin,
        maxs = hullMax,
        mask = MASK_SHOT_HULL,
        ignoreworld = true,
        collisiongroup = COLLISION_GROUP_PLAYER,
    })

    if tr.Hit == false and tr.Fraction == 1 then
        ply:DisablePlayerCollide(false)
        ply:SetNoCollideWithTeammates(false)
        DbgPrint(ply, "Reset player collision.")
    else
        DbgPrint(ply, "Colliding with " .. tostring(tr.Entity))
        ply.NextPlayerCollideTest = curTime + 1
    end
end

function GM:PlayerThink(ply)
    if SERVER then
        -- Make sure we reset the view lock if we are in release mode.
        local viewlock = ply:GetViewLock()
        if viewlock == VIEWLOCK_SETTINGS_RELEASE then
            local viewlockTime = ply:GetNWFloat("ViewLockTime")
            if viewlockTime + VIEWLOCK_RELEASE_TIME < CurTime() then ply:LockPosition(false) end
        end

        self:CheckPlayerCollision(ply)
    end
end

function GM:GravGunPickupAllowed(ply, ent)
    if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then return false end
    do
        return true
    end
    --return BaseClass.GravGunPickupAllowed(ply, ent)
end

function GM:GravGunPunt(ply, ent)
    if ent:IsWeapon() and ent:GetClass() ~= "weapon_crowbar" then return false end
    local playerVehicle = ply:GetVehicle()
    if playerVehicle ~= NULL and IsValid(playerVehicle) == true and ent:IsVehicle() == true and ent:GetNWEntity("PassengerSeat") == playerVehicle then return false end
    if ent:IsVehicle() then
        util.RunNextFrame(function()
            if not IsValid(ent) then return end
            local phys = ent:GetPhysicsObject()
            if not IsValid(phys) then return end
            local force = phys:GetVelocity()
            force = force * 0.000001
            phys:SetVelocity(force)
        end)
    end

    if ent:IsNPC() and IsFriendEntityName(ent:GetClass()) then return false end
    return BaseClass.GravGunPickupAllowed(ply, ent)
end

function GM:PlayerFootstep(ply, pos, foot, sound, volume, filter)
    if ply:KeyDown(IN_WALK) then return true end
    if SERVER then self:NotifyNPCFootsteps(ply, pos, foot, sound, volume) end
end

function GM:PlayerSwitchWeapon(ply, old, new)
    DbgPrint("PlayerSwitchWeapon", ply, old, new)
end

function GM:OnPlayerAmmoDepleted(ply, wep)
    DbgPrint("Ammo Depleted: " .. tostring(ply) .. " - " .. tostring(wep))
    if SERVER then
        util.RunDelayed(function()
            -- Only switch if we are still holding the empty weapon.
            if ply:GetActiveWeapon() == wep then self:SelectBestWeapon(ply) end
        end, CurTime() + 1.5)
    end

    if CLIENT then ply:EmitSound("hl1/fvox/ammo_depleted.wav", 75, 100, 0.5) end
end

function GM:PlayerNoClip(ply, desiredState)
    local sv_cheats = GetConVar("sv_cheats")
    if desiredState == false then
        return true
    elseif sv_cheats:GetBool() == true then
        return true
    end
end

function GM:AllowPlayerTracking()
    return self:CallGameTypeFunc("AllowPlayerTracking")
end

local FLINCH_SEQUENCE = {
    [HITGROUP_GENERIC] = {"flinch_head_01", "flinch_head_02"},
    [HITGROUP_HEAD] = {"flinch_head_01", "flinch_head_02"},
    [HITGROUP_HEAD_BACK] = {"flinch_back_01"},
    [HITGROUP_BACK] = {"flinch_back_01"},
    [HITGROUP_CHEST] = {"flinch_01", "flinch_02"},
    [HITGROUP_STOMACH] = {"flinch_stomach_01", "flinch_stomach_02"},
    [HITGROUP_LEFTARM] = {"flinch_shoulder_l"},
    [HITGROUP_RIGHTARM] = {"flinch_shoulder_r"}
}

local FLESH_IMPACT_SOUNDS = {"lambda/physics/flesh/flesh_impact_bullet1.wav", "lambda/physics/flesh/flesh_impact_bullet2.wav", "lambda/physics/flesh/flesh_impact_bullet3.wav", "lambda/physics/flesh/flesh_impact_bullet4.wav", "lambda/physics/flesh/flesh_impact_bullet5.wav"}
function GM:ScalePlayerDamage(ply, hitgroup, dmginfo)
    DbgPrintDmg("ScalePlayerDamage", ply, hitgroup)
    -- Must be called here not in EntityTakeDamage as that runs after so scaling wouldn't work.
    self:ApplyCorrectedDamage(dmginfo)
    local attacker = dmginfo:GetAttacker()
    if SERVER and dmginfo:IsDamageType(DMG_BULLET) == true then self:MetricsRegisterBulletHit(attacker, ply, hitgroup) end
    -- First scale hitgroups.
    local scale = self:GetDifficultyPlayerHitgroupDamageScale(hitgroup)
    DbgPrintDmg("Hitgroup Scale", npc, scale)
    dmginfo:ScaleDamage(scale)
    -- Scale by difficulty.
    local scaleType = 0
    if attacker:IsPlayer() == true then
        scaleType = DMG_SCALE_PVP
    elseif attacker:IsNPC() == true then
        scaleType = DMG_SCALE_NVP
    end

    if scaleType ~= 0 then
        scale = self:GetDifficultyDamageScale(scaleType)
        if scale ~= nil then
            DbgPrintDmg("Scaling difficulty damage: " .. tostring(scale))
            dmginfo:ScaleDamage(scale)
        end
    end

    if SERVER and dmginfo:GetDamage() > 0 then
        --DbgPrintDmg("ScalePlayerDamage: " .. tostring(ply))
        self:EmitPlayerHurt(dmginfo:GetDamage(), ply, hitgroup)
    end

    -- Reset water damage
    if ply.IsDrowning ~= true then ply.WaterDamage = 0 end
    if ply:IsPositionLocked() == true then dmginfo:ScaleDamage(0) end
    -- Determine if the bullet came from the back or front.
    local eyePos = ply:EyePos()
    local dmgDelta = (attacker:EyePos() - eyePos):GetNormalized()
    local eyeAng = ply:EyeAngles()
    eyeAng.x = 0
    local eyeFwd = eyeAng:Forward()
    local dot = eyeFwd:Dot(dmgDelta)
    local isBackside = false
    if dot < -0.4 then isBackside = true end
    if isBackside == true then
        if hitgroup == HITGROUP_HEAD then
            hitgroup = HITGROUP_HEAD_BACK
        elseif hitgroup == HITGROUP_CHEST or hitgroup == HITGROUP_STOMACH then
            hitgroup = HITGROUP_BACK
        end
    end

    if SERVER then
        local plys = player.GetAll()
        table.RemoveByValue(plys, attacker)
        net.Start("LambdaPlayerDamage")
        net.WriteEntity(attacker)
        net.WriteEntity(ply)
        net.WriteUInt(hitgroup, 10)
        net.WriteVector(dmginfo:GetDamagePosition())
        net.Send(plys)
    else
        -- Local player runs this shared, no need to network this.
        if attacker == LocalPlayer() then self:OnPlayerDamage(attacker, ply, hitgroup, dmginfo:GetDamagePosition()) end
    end

    local dmgForceLen = math.Clamp(dmginfo:GetDamageForce():Length2D() / 1000, 0, 1)
    local punchForce = dmgForceLen * 10
    local viewPunch = Angle(0, 0, 0)
    if hitgroup == HITGROUP_HEAD then
        viewPunch = viewPunch + Angle(-punchForce, 0, 0)
    elseif hitgroup == HITGROUP_HEAD_BACK then
        viewPunch = viewPunch + Angle(punchForce, 0, 0)
    end

    self:PlayerApplyViewPunch(ply, viewPunch)
end

local VIEWPUNCH_DECAY_TIME = 1.0
function GM:PlayerApplyViewPunch(ply, viewPunch)
    local alpha = 1.0
    if ply.NextViewPunchTime ~= nil then
        alpha = ply.NextViewPunchTime - CurTime()
        if alpha < 0 then alpha = 0 end
        alpha = 1.0 - (alpha / VIEWPUNCH_DECAY_TIME)
        alpha = alpha
    end

    viewPunch.x = math.Clamp(viewPunch.x, -60, 60)
    ply:ViewPunch(viewPunch * alpha)
    -- Prevent player view drifting way too far with fast impacts.
    ply.NextViewPunchTime = CurTime() + VIEWPUNCH_DECAY_TIME
end

function GM:OnPlayerDamage(attacker, victim, hitgroup, hitpos)
    if attacker ~= LocalPlayer() then
        local vol = 0.7
        if hitgroup == HITGROUP_HEAD or hitgroup == HITGROUP_HEAD_BACK then
            vol = 0.7
        elseif hitgroup == HITGROUP_LEFTARM or hitgroup == HITGROUP_RIGHTARM then
            vol = 0.25
        elseif hitgroup == HITGROUP_STOMACH or hitgroup == HITGROUP_CHEST then
            vol = 0.12
        else
            vol = 0.1
        end

        local snd = table.Random(FLESH_IMPACT_SOUNDS)
        victim:EmitSound(snd, 75, 100, vol)
    end

    -- Play kickback.
    local flinchSeqs = FLINCH_SEQUENCE[hitgroup]
    if flinchSeqs ~= nil then
        local randFlinch = table.Random(flinchSeqs)
        local id = victim:LookupSequence(randFlinch)
        if id ~= -1 then
            local actId = victim:GetSequenceActivity(id)
            victim:AnimSetGestureWeight(GESTURE_SLOT_FLINCH, 1)
            victim:AnimRestartGesture(GESTURE_SLOT_FLINCH, actId, true)
        end
    end
end

net.Receive("LambdaPlayerDamage", function(len)
    local attacker = net.ReadEntity()
    local victim = net.ReadEntity()
    local hitgroup = net.ReadUInt(10)
    local hitpos = net.ReadVector()
    GAMEMODE:OnPlayerDamage(attacker, victim, hitgroup, hitpos)
end)

if SERVER then
    concommand.Add("lambda_show_loadout", function(ply, cmd, args)
        -- Build the weapon table
        local weps = {}
        for _,v in pairs(ply:GetWeapons()) do
            table.insert(weps, v:GetClass())
        end

        -- Build ammo table
        local ammo = {}
        for ammoId, count in pairs(ply:GetAmmo()) do
            local ammoName = game.GetAmmoName(ammoId)
            ammo[ammoName] = count
        end

        local armor = ply:Armor()
        local hev = ply:IsSuitEquipped()

        -- Print the DefaultLoadout table
        print("DefaultLoadout = {")
        print("    Weapons = {")
        for _,v in pairs(weps) do
            print("        \"" .. v .. "\",")
        end
        print("    },")
        print("    Ammo = {")
        for k,v in pairs(ammo) do
            print("        [\"" .. k .. "\"] = " .. v .. ",")
        end
        print("    },")
        print("    Armor = " .. armor .. ",")
        print("    HEV = " .. tostring(hev))
        print("}")
    end)
end