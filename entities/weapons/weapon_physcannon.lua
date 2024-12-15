-- WIP! Don't touch me
if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("physcannon")
local EyeAngles = EyeAngles
local EyePos = EyePos
local IsValid = IsValid
local game_GetGlobalState = game.GetGlobalState
local bor = bit.bor
local Vector = Vector
local Angle = Angle
local TraceLine = util.TraceLine
local TraceHull = util.TraceHull
local Color = Color
local CurTime = CurTime
local EffectsInvalidated = false
local TraceMask = bor(MASK_SHOT, CONTENTS_GRATE)
local ATTACHMENTS_GAPS_FP = {"fork1t", "fork2t"}
local ATTACHMENTS_GAPS_TP = {"fork1t", "fork2t", "fork3t"}
local ATTACHMENTS_GLOW_FP = {"fork1b", "fork1m", "fork1t", "fork2b", "fork2m", "fork2t"}
local ATTACHMENTS_GLOW_TP = {"fork1m", "fork1t", "fork1b", "fork2m", "fork2t", "fork3m", "fork3t"}
SWEP.PrintName = "#HL2_GravityGun"
SWEP.Author = "Zeh Matt"
SWEP.Instructions = ""
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "none"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "physgun"
SWEP.Weight = 10
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = false
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_superphyscannon.mdl"
SWEP.WorldModel = "models/weapons/w_Physics.mdl"
SWEP.WepSelectFont = "WeaponIconsSelected"
SWEP.WepSelectLetter = "m"
SWEP.IconFont = "WeaponIconsSelected"
SWEP.IconLetter = "m"
if CLIENT then
    SWEP.Slot = 0
    SWEP.SlotPos = 3
    SWEP.DrawAmmo = false
    SWEP.DrawCrosshair = true
    SWEP.DrawWeaponInfoBox = false
    SWEP.BounceWeaponIcon = false
    SWEP.RenderGroup = RENDERGROUP_BOTH
    SWEP.EffectParameters = {}
    SWEP.ViewModelFOV = 54
    surface.CreateFont(
        "LambdaPhyscannonFont",
        {
            font = "HalfLife2",
            size = util.ScreenScaleH(64),
            weight = 0,
            blursize = 0,
            scanlines = 0,
            antialias = true,
            additive = true
        }
    )

    surface.CreateFont(
        "LambdaPhyscannonFont2",
        {
            font = "HalfLife2",
            size = util.ScreenScaleH(64),
            weight = 0,
            blursize = util.ScreenScaleH(4),
            scanlines = 2,
            antialias = true,
            additive = true
        }
    )
end

--
-- ConVars
local physcannon_tracelength = GetConVar("physcannon_tracelength")
local physcannon_maxforce = GetConVar("physcannon_maxforce")
local physcannon_cone = GetConVar("physcannon_cone")
local physcannon_pullforce = GetConVar("physcannon_pullforce")
local physcannon_maxmass = GetConVar("physcannon_maxmass")
-- Missing convars.
local physcannon_dmg_class = CreateConVar("physcannon_dmg_class", "15", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED), "Damage done to glass by punting")
local physcannon_mega_tracelength = CreateConVar("physcannon_mega_tracelength", "850", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
local physcannon_mega_pullforce = CreateConVar("physcannon_mega_pullforce", "8000", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
local physcannon_ball_cone = CreateConVar("physcannon_ball_cone", "0.997", bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED))
local physcannon_glow_mode = 0
if CLIENT then
    local physcannon_glow = CreateConVar("lambda_physcannon_glow", "2", bit.bor(FCVAR_ARCHIVE))
    physcannon_glow_mode = physcannon_glow:GetInt()
    cvars.AddChangeCallback(
        "lambda_physcannon_glow",
        function(convar_name, value_old, value_new)
            physcannon_glow_mode = tonumber(value_new)
            EffectsInvalidated = true
        end
    )
end

-- ConVar physcannon_maxmass( "physcannon_maxmass", "250" );
local SPRITE_SCALE = 12
--
-- States
local ELEMENT_STATE_NONE = -1
local ELEMENT_STATE_OPEN = 0
local ELEMENT_STATE_CLOSED = 1
--
-- Effect State
local EFFECT_NONE = 0
local EFFECT_CLOSED = 1
local EFFECT_READY = 2
local EFFECT_HOLDING = 3
local EFFECT_LAUNCH = 4
local EFFECT_IDLE = 5
local EFFECT_PULLING = 6
--
-- Object Find Result
local OBJECT_FOUND = 0
local OBJECT_NOT_FOUND = 1
local OBJECT_BEING_DETACHED = 2
local OBJECT_BEING_PULLED = 3
--
-- EffectType
local PHYSCANNON_CORE = 0
local PHYSCANNON_BLAST = 1
local PHYSCANNON_GLOW1 = 2
local PHYSCANNON_GLOW2 = 3
local PHYSCANNON_GLOW3 = 4
local PHYSCANNON_GLOW4 = 5
local PHYSCANNON_GLOW5 = 6
local PHYSCANNON_GLOW6 = 7
local PHYSCANNON_ENDCAP1 = 8
local PHYSCANNON_ENDCAP2 = 9
local PHYSCANNON_ENDCAP3 = 10
local PHYSCANNON_CORE_2 = 11
local EFFECT_PARAM_NAME = {
    [PHYSCANNON_CORE] = "PHYSCANNON_CORE",
    [PHYSCANNON_BLAST] = "PHYSCANNON_BLAST",
    [PHYSCANNON_GLOW1] = "PHYSCANNON_GLOW1",
    [PHYSCANNON_GLOW2] = "PHYSCANNON_GLOW2 ",
    [PHYSCANNON_GLOW3] = "PHYSCANNON_GLOW3",
    [PHYSCANNON_GLOW4] = "PHYSCANNON_GLOW4",
    [PHYSCANNON_GLOW5] = "PHYSCANNON_GLOW5",
    [PHYSCANNON_GLOW6] = "PHYSCANNON_GLOW6",
    [PHYSCANNON_ENDCAP1] = "PHYSCANNON_ENDCAP1",
    [PHYSCANNON_ENDCAP2] = "PHYSCANNON_ENDCAP2",
    [PHYSCANNON_ENDCAP3] = "PHYSCANNON_ENDCAP3",
    [PHYSCANNON_CORE_2] = "PHYSCANNON_CORE_2"
}

local PHYSCANNON_ENDCAP_SPRITE = "sprites/physcannon_glow1.vmt"
local PHYSCANNON_GLOW_SPRITE = "sprites/physcannon_glow1.vmt"
local PHYSCANNON_CENTER_GLOW = "sprites/physcannon_core"
local PHYSCANNON_BLAST_SPRITE = "sprites/physcannon_blast"
local PHYSCANNON_CORE_WARP = "particle/warp1_warp"
local MAT_PHYSBEAM = Material("sprites/physbeam.vmt")
local MAT_WORLDMDL = Material("models/weapons/w_physics/w_physics_sheet2")
local GLOW_UPDATE_DT = 1 / 40
--
-- Code
function SWEP:Precache()
    util.PrecacheSound("Weapon_PhysCannon.HoldSound")
end

function SWEP:SetupDataTables()
    DbgPrint(self, "SetupDataTables")
    self:NetworkVar("Int", 0, "EffectState")
    self:NetworkVar("Bool", 0, "ElementOpen")
    self:NetworkVar("Bool", 1, "MegaEnabled")
    self:NetworkVar("Float", 0, "ElementDestination")
    self:NetworkVar("Float", 1, "NextIdleTime")
    self:NetworkVar("Float", 2, "NextDenySoundTime")
    self:NetworkVar("Entity", 0, "MotionController")
    self:NetworkVar("Vector", 0, "TargetOffset")
    self:NetworkVar("Angle", 0, "TargetAngle")
    self:NetworkVar("Vector", 10, "LastWeaponColor")
end

function SWEP:Initialize()
    DbgPrint(self, "Initialize")
    self:Precache()
    self.CalcViewModelView = nil
    self.GetViewModelPosition = nil
    self.LastPuntedObject = nil
    self.NextPuntTime = CurTime()
    self.NextGlowUpdate = CurTime()
    self.NextBeamGlow = CurTime()
    self.OldEffectState = EFFECT_NONE
    self.GlowSprites = {}
    self.BeamSprites = {}
    self:SetElementOpen(false)
    self.OldOpen = false
    self.UpdateName = true
    self:SetNextIdleTime(CurTime())
    self.ObjectAttached = false
    self.PullingObject = false
    if CLIENT then
        self.CurrentElementLen = 0
        self.TargetElementLen = 0
        self.DrawUsingViewModel = false
        self.EffectsSetup = false
        self.CurrentWeaponColor = Color(0, 0, 0, 0)
    end

    self.ChangeState = ELEMENT_STATE_NONE
    self.ElementDebounce = CurTime()
    self.CheckSuppressTime = CurTime()
    self:SetHoldType(self.HoldType)
    self.ElementPosition = InterpValue(0.0, 0.0, 0)
    self.LastElementDestination = 0
    if SERVER then
        if game_GetGlobalState("super_phys_gun") == GLOBAL_ON then
            self:SetMegaEnabled(true)
        else
            self:SetMegaEnabled(false)
        end
    end

    if SERVER then
        local motionController = ents.Create("lambda_motioncontroller")
        motionController:Spawn()
        self:SetMotionController(motionController)
    end

    if CLIENT then
        self:UpdateDrawUsingViewModel()
    end

    self:DoEffect(EFFECT_CLOSED)
    self:CloseElements()
    self:SetElementDestination(0)
    self:SetSkin(1)
    if SERVER then
        self:SetLastWeaponColor(VectorRand(0.0, 1.0))
    end

    local ThinkHook = self.ThinkHook
    hook.Add(
        "Think",
        self,
        function(s)
            ThinkHook(s)
        end
    )
end

function SWEP:WeaponSound(snd)
    DbgPrint(self, "WeaponSound", snd)
    local ent = self
    if CLIENT then
        ent = self:GetOwner()
        if IsValid(ent) ~= true then
            ent = self
        end
    else
        self:EmitSound(snd)
    end

    self:EmitSound(snd)
end

function SWEP:GetMotorSound()
    DbgPrint(self, "GetMotorSound")
    if self.SndMotor == nil or self.SndMotor == NULL then
        local filter
        if SERVER then
            filter = RecipientFilter()
            filter:AddAllPlayers()
        end

        self.SndMotor = CreateSound(self, "Weapon_PhysCannon.HoldSound", filter)
    end

    DbgPrint(self, "SND: " .. tostring(self.SndMotor))

    return self.SndMotor
end

function SWEP:StopLoopingSounds()
    if self.SndMotor ~= nil and self.SndMotor ~= NULL then
        self.SndMotor:Stop()
    end
end

function SWEP:IsObjectAttached()
    local controller = self:GetMotionController()
    if IsValid(controller) ~= true then return false end
    if controller.IsObjectAttached == nil then return false end

    return controller:IsObjectAttached()
end

function SWEP:OnRemove()
    DbgPrint(self, "OnRemove")
    self:StopEffects()
    self:StopLoopingSounds()
    self:DetachObject()
    if SERVER then
        local motionController = self:GetMotionController()
        if IsValid(motionController) == true then
            motionController:Remove()
        end
    end
end

function SWEP:IsMegaPhysCannon()
    return self:GetMegaEnabled(false)
end

function SWEP:Supercharge()
    game.SetGlobalState("super_phys_gun", GLOBAL_ON)
    self:SetSequence(self:SelectWeightedSequence(ACT_PHYSCANNON_UPGRADE))
    self:ResetSequenceInfo()
    self:UseTriggerBounds(true, 32.0)
    for _, v in pairs(ents.FindByName("script_physcannon_upgrade")) do
        v:Input("Trigger", self, self)
    end

    -- Allow pickup again.
    self:AddSolidFlags(FSOLID_TRIGGER)
    self:OpenElements()
end

function SWEP:AcceptInput(inputName, activator, callee, data)
    if inputName:iequals("Supercharge") then
        self:Supercharge()

        return true
    end

    return false
end

function SWEP:LaunchObject(ent, fwd, force)
    if self.LastPuntedObject == ent and CurTime() < self.NextPuntTime then return end
    self:DetachObject(true)
    self.LastPuntedObject = ent
    self.NextPuntTime = CurTime() + 0.5
    self:ApplyVelocityBasedForce(ent, fwd)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
    self.ElementDebounce = CurTime() + 1.0
    self.CheckSuppressTime = CurTime() + 0.25
    self.ChangeState = ELEMENT_STATE_CLOSED
    self.Secondary.Automatic = true
    self:DoEffect(EFFECT_LAUNCH, ent:WorldSpaceCenter())
    local snd = self:GetMotorSound()
    if snd ~= nil and snd ~= NULL then
        snd:ChangeVolume(0, 1.0)
        snd:ChangePitch(50, 1.0)
    end
end

function SWEP:PrimaryAttack()
    DbgPrint(self, "PrimaryAttack")
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return end
    self:SetNextPrimaryFire(CurTime() + 0.5)
    local controller = self:GetMotionController()
    if controller:IsObjectAttached() then
        local ent = controller:GetAttachedObject()
        -- Make sure its in range.
        local dist = (ent:WorldSpaceCenter() - owner:WorldSpaceCenter()):Length()
        if dist > physcannon_tracelength:GetFloat() then return self:DryFire() end
        self:LaunchObject(ent, owner:GetAimVector(), physcannon_maxforce:GetFloat())
        self:PrimaryFireEffect()
        self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
        owner:SetAnimation(PLAYER_ATTACK1)

        return
    end

    -- Punt object.
    local fwd = owner:GetAimVector()
    local start = owner:GetShootPos()
    local puntDist = physcannon_tracelength:GetFloat()
    local endPos = start + (fwd * puntDist)
    local tr = TraceHull(
        {
            start = start,
            endpos = endPos,
            filter = owner,
            mins = Vector(-8, -8, -8),
            maxs = Vector(8, 8, 8),
            mask = TraceMask
        }
    )

    local valid = true
    local ent = tr.Entity
    if tr.Fraction == 1 or IsValid(ent) ~= true or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then
        valid = false
    elseif ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
        if ent:CanTakeDamage() == false then
            valid = false
        end
    end

    if valid == false then
        tr = TraceLine(
            {
                start = start,
                endpos = endPos,
                mask = TraceMask,
                filter = owner
            }
        )

        ent = tr.Entity
        if tr.Fraction == 1 or IsValid(ent) ~= true or ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then return self:DryFire() end -- Nothing valid.
    end

    if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then
        -- FIXME: GetInternalVariable does return nothing for m_takedamage
        if ent:CanTakeDamage() == false then return self:DryFire() end
        -- SDK: // Don't let the player zap any NPC's except regular antlions and headcrabs.
        if owner:IsPlayer() and ent:IsPlayer() then return self:DryFire() end
        if SERVER and self:IsMegaPhysCannon() == true and ent:IsNPC() and ent:IsEFlagSet(EFL_NO_MEGAPHYSCANNON_RAGDOLL) == false and ent:CanBecomeRagdoll() == true then
            local dmgInfo = DamageInfo()
            dmgInfo:SetInflictor(owner)
            dmgInfo:SetAttacker(owner)
            dmgInfo:SetDamage(1)
            dmgInfo:SetDamageType(DMG_GENERIC)
            local ragdoll = ent:CreateServerRagdoll(dmgInfo, COLLISION_GROUP_INTERACTIVE_DEBRIS)
            local phys = ragdoll:GetPhysicsObject()
            if IsValid(phys) == true then
                phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
            end

            ragdoll:SetCollisionBounds(ent:OBBMins(), ent:OBBMaxs())
            ragdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) -- Its ugly if players collide
            ragdoll.IsPhysgunDamage = true
            dmgInfo = DamageInfo()
            dmgInfo:SetInflictor(owner)
            dmgInfo:SetAttacker(owner)
            dmgInfo:SetDamage(10000)
            dmgInfo:SetDamageType(bit.bor(DMG_PHYSGUN, DMG_REMOVENORAGDOLL))
            ent:TakeDamageInfo(dmgInfo)
            self:PuntRagdoll(ragdoll, fwd, tr)
        end

        DbgPrint("Punt: " .. tostring(ent))

        return self:PuntNonVPhysics(ent, fwd, tr)
    end

    if ent:IsRagdoll() and ent:GetCollisionGroup() ~= COLLISION_GROUP_DEBRIS then return self:PuntRagdoll(ent, fwd, tr) end
    if ent:IsWeapon() == true then return self:DryFire() end
    if owner:InVehicle() == true then return self:DryFire() end

    return self:PuntVPhysics(ent, fwd, tr)
end

function SWEP:CanSecondaryAttack()
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then
        DbgPrint("Invalid owner")

        return false
    end

    return true
end

function SWEP:SecondaryAttack()
    if CLIENT then return end
    if self:CanSecondaryAttack() == false then return end
    if SERVER then
        SuppressHostEvents(NULL)
    end

    local controller = self:GetMotionController()
    local owner = self:GetOwner()
    if controller:IsObjectAttached() == true then
        self:SetNextPrimaryFire(CurTime() + 0.5)
        self:SetNextSecondaryFire(CurTime() + 0.5)
        self.Secondary.Automatic = true
        self:DetachObject(false)
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        owner:SetAnimation(PLAYER_ATTACK1)

        return true
    else
        local res = self:FindObject()
        if res == OBJECT_FOUND then
            self.Secondary.Automatic = false -- No longer automatic, debounce.
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            owner:SetAnimation(PLAYER_ATTACK1)
            self:WeaponSound("Weapon_PhysCannon.Pickup")
            self:SetNextSecondaryFire(CurTime() + 0.5)
            self:SetNextPrimaryFire(CurTime() + 0.5)
            self:DoEffect(EFFECT_HOLDING)
            self:OpenElements()
        elseif res == OBJECT_NOT_FOUND then
            self:SetNextSecondaryFire(CurTime() + 0.4)
            self:SetNextPrimaryFire(CurTime() + 0.4)
            self.Secondary.Automatic = true
            self:CloseElements()
            self:DoEffect(EFFECT_READY)
            self:SetNextIdleTime(CurTime() + 0.2)
        elseif res == OBJECT_BEING_PULLED then
            self:SetNextSecondaryFire(CurTime() + 0.1)
            self:SetNextPrimaryFire(CurTime() + 0.1)
            self.Secondary.Automatic = true
            self:OpenElementsHalf()
            self:DoEffect(EFFECT_PULLING)
            self:SetNextIdleTime(CurTime() + 0.2)
            self.ElementDebounce = CurTime() + 0.2
        elseif res == OBJECT_BEING_DETACHED then
            self:SetNextSecondaryFire(CurTime() + 0.01)
            self:SetNextPrimaryFire(CurTime() + 0.4)
            self.Secondary.Automatic = true
            self:DoEffect(EFFECT_HOLDING)
        end
    end
end

function SWEP:FindObjectInCone(start, fwd, coneSize)
    local nearestDist = physcannon_tracelength:GetFloat() + 1.0
    local mins = start - Vector(nearestDist, nearestDist, nearestDist)
    local maxs = start + Vector(nearestDist, nearestDist, nearestDist)
    local nearest
    for _, v in pairs(ents.FindInBox(mins, maxs)) do
        if IsValid(v:GetPhysicsObject()) ~= true then continue end
        local los = v:WorldSpaceCenter() - start
        local dist = los:Length()
        los:Normalize()
        if dist >= nearestDist or los:Dot(fwd) < coneSize then continue end
        local tr = TraceLine(
            {
                start = start,
                endpos = v:WorldSpaceCenter(),
                mask = TraceMask,
                filter = self:GetOwner()
            }
        )

        if tr.Entity == v then
            nearestDist = dist
            nearest = v
        end
    end

    return nearest
end

function SWEP:FindObjectInConeMega(start, fwd, coneSize, ballCone, onlyCombineBalls)
    local maxDist = self:TraceLength() + 1.0
    local nearestDist = maxDist
    local nearestIsCombineBall = false
    if onlyCombineBalls == true then
        nearestIsCombineBall = true
    end

    local mins = start - Vector(nearestDist, nearestDist, nearestDist)
    local maxs = start + Vector(nearestDist, nearestDist, nearestDist)
    local nearest
    for _, v in pairs(ents.FindInBox(mins, maxs)) do
        if IsValid(v:GetPhysicsObject()) ~= true then continue end
        local isBall = v:GetClass() == "prop_combine_ball"
        if not isBall and nearestIsCombineBall == true then continue end
        local los = v:WorldSpaceCenter() - start
        local dist = los:Length()
        los:Normalize()
        local dotProduct = los:Dot(fwd)
        if not isBall or nearestIsCombineBall then
            if dist >= nearestDist or dotProduct <= coneSize then continue end
        else
            if dist >= maxDist or dotProduct <= coneSize then continue end
            if dist > nearestDist and dotProduct < ballCone then continue end
        end

        local tr = TraceLine(
            {
                start = start,
                endpos = v:WorldSpaceCenter(),
                mask = TraceMask,
                filter = self:GetOwner()
            }
        )

        if tr.Entity == v then
            nearestDist = dist
            nearest = v
            nearestIsCombineBall = isBall
        end
    end

    return nearest
end

local SF_PHYSPROP_ENABLE_ON_PHYSCANNON = 0x000040
local SF_PHYSBOX_ENABLE_ON_PHYSCANNON = 0x20000
local ALLOWED_PICKUP_CLASS = {
    ["bounce_bomb"] = true,
    ["combine_bouncemine"] = true,
    ["combine_mine"] = true
}

function SWEP:CanPickupObject(ent)
    if IsValid(ent) ~= true then return false end
    local massLimit = 0
    if self:IsMegaPhysCannon() == false then
        massLimit = physcannon_maxmass:GetInt()
    end

    -- TODO: Disolving check
    if ent:IsPlayer() then return false end
    if ent:IsNPC() == true and IsFriendEntityName(ent:GetClass()) == true then return false end
    if ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then return false end
    if ent:HasSpawnFlags(SF_PHYSBOX_NEVER_PICK_UP) == true then return false end
    local owner = self:GetOwner()
    if IsValid(owner) == true and owner:GetGroundEntity() == ent then return false end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) and phys:HasGameFlag(FVPHYSICS_PLAYER_HELD) == true then return false end
    -- Hooks
    local pickupAllowed = hook.Call("GravGunPickupAllowed", GAMEMODE, owner, ent)
    if pickupAllowed == false then return false end
    if ent:IsVehicle() then return false end
    if self:IsMegaPhysCannon() == false then
        if ent:IsVPhysicsFlesh() == true then return false end
        if ent:GetMoveType() ~= MOVETYPE_VPHYSICS then return false end
        -- NOTE: This is from CBasePlayer::CanPickupObject
        do
            local physCount = ent:GetPhysicsObjectCount()
            if physCount == 0 then return false end -- Must have physics.
            local checkEnable = false
            local objectMass = 0
            for i = 0, physCount - 1 do
                local subphys = ent:GetPhysicsObjectNum(i)
                if IsValid(subphys) ~= true then continue end
                if subphys:IsMoveable() == false then
                    checkEnable = true
                end

                if subphys:HasGameFlag(FVPHYSICS_NO_PLAYER_PICKUP) == True then return false end
                objectMass = objectMass + subphys:GetMass()
                -- TODO: if subphys:IsHinged() == true then return false end
            end

            if massLimit > 0 and objectMass > massLimit then return false end
            if checkEnable == true then
                -- Allow things that have no motion but can be picked up.
                local class = ent:GetClass()
                if ALLOWED_PICKUP_CLASS[class] == true then return true end
                if ent:HasSpawnFlags(SF_PHYSPROP_ENABLE_ON_PHYSCANNON) == false and ent:HasSpawnFlags(SF_PHYSBOX_ENABLE_ON_PHYSCANNON) == false then return false end
            end
        end
    else
        if ent:GetMoveType() ~= MOVETYPE_VPHYSICS and ent:GetMoveType() ~= MOVETYPE_STEP then return false end
    end

    return true
end

function SWEP:TraceLength()
    if self:IsMegaPhysCannon() then return physcannon_mega_tracelength:GetFloat() end

    return physcannon_tracelength:GetFloat()
end

function SWEP:FindObjectTrace(owner)
    local fwd = owner:GetAimVector()
    local start = owner:GetShootPos()
    local testLength = self:TraceLength() * 4.0
    local endPos = start + (fwd * testLength)
    local tr = TraceLine(
        {
            start = start,
            endpos = endPos,
            mask = TraceMask,
            filter = owner
        }
    )

    if tr.Fraction == 1 or IsValid(tr.Entity) ~= true or tr.HitWorld == true then
        tr = TraceHull(
            {
                start = start,
                endpos = endPos,
                mask = TraceMask,
                filter = owner,
                mins = Vector(-4, -4, -4),
                maxs = Vector(4, 4, 4)
            }
        )
    end

    return tr
end

function SWEP:GetPullForce()
    if self:IsMegaPhysCannon() then return physcannon_mega_pullforce:GetFloat() end

    return physcannon_pullforce:GetFloat()
end

function SWEP:FindObject()
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return end
    local tr = self:FindObjectTrace(owner)
    local ent
    if IsValid(tr.Entity) == true then
        ent = tr.Entity:GetRootMoveParent()
    end

    local attach = false
    local pull = false
    if tr.Fraction ~= 1.0 and IsValid(tr.Entity) == true and tr.HitWorld == false then
        if tr.Fraction <= 0.25 then
            attach = true
        elseif tr.Fraction > 0.25 then
            pull = true
        end
    end

    local fwd = owner:GetAimVector()
    local start = owner:GetShootPos()
    local testLength = physcannon_tracelength:GetFloat() * 4.0
    local coneEnt
    if self:IsMegaPhysCannon() == false then
        if attach == false and pull == false then
            coneEnt = self:FindObjectInCone(start, fwd, physcannon_cone:GetFloat())
        end
    else
        coneEnt = self:FindObjectInConeMega(start, fwd, physcannon_cone:GetFloat(), physcannon_ball_cone:GetFloat(), attach or pull)
    end

    if IsValid(coneEnt) == true then
        ent = coneEnt
        if ent:WorldSpaceCenter():DistToSqr(start) <= (testLength * testLength) then
            attach = true
        else
            pull = true
        end
    end

    if self:CanPickupObject(ent) == false then
        if CurTime() > self:GetNextDenySoundTime() then
            self:WeaponSound("Weapon_PhysCannon.TooHeavy")
            self:SetNextDenySoundTime(CurTime() + 0.9)
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            owner:SetAnimation(PLAYER_ATTACK1)
        end

        return OBJECT_NOT_FOUND
    end

    if attach == true then
        if self:AttachObject(ent, tr) == true then return OBJECT_FOUND end

        return OBJECT_NOT_FOUND
    end

    if pull == false then return OBJECT_NOT_FOUND end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) ~= true then return OBJECT_NOT_FOUND end
    local pullDir = start - ent:WorldSpaceCenter()
    pullDir = pullDir:GetNormal() * self:GetPullForce()
    local mass = ent:GetPhysMass()
    if mass < 50 then
        pullDir = pullDir * ((mass + 0.5) * (1 / 50.0))
    end

    phys:ApplyForceCenter(pullDir)

    return OBJECT_BEING_PULLED
end

function SWEP:GetAttachedObject()
    local controller = self:GetMotionController()
    if controller:IsObjectAttached() == false then return end

    return controller:GetAttachedObject()
end

function SWEP:UpdateObject()
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return false end
    local controller = self:GetMotionController()
    if controller:IsObjectAttached() == false then return end
    local err = controller:ComputeError()
    --DbgPrint(err)
    if err >= 12 then return false end
    local attachedObject = controller:GetAttachedObject()
    if attachedObject:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == true then return false end
    if owner:GetGroundEntity() == attachedObject then return false end
    local fwd = owner:GetAimVector()
    fwd.x = math.Clamp(fwd.x, -75, 75)
    local start = owner:GetShootPos()
    local minDist = 24
    local playerLen = owner:OBBMaxs():Length2D()
    local objLen = attachedObject:OBBMaxs():Length2D()
    local distance = minDist + playerLen + objLen
    local targetAng = self:GetTargetAngle() --self:GetNW2Angle("TargetAng")
    local targetAttachment = self:GetTargetOffset() --self:GetNW2Vector("AttachmentPoint")
    local ang = owner:LocalToWorldAngles(targetAng)
    local endPos = start + (fwd * distance)
    local attachmentPoint = Vector(targetAttachment)
    attachmentPoint:Rotate(ang)
    local finalPos = endPos - attachmentPoint
    controller:SetTargetTransform(finalPos, ang)

    return true
end

function SWEP:OpenElements()
    --DbgPrint(self, "OpenElements")
    if self:GetElementDestination() == 1.0 then return end
    if SERVER then
        SuppressHostEvents(NULL)
    end

    if self:GetElementDestination() == 0 then
        self:WeaponSound("Weapon_PhysCannon.OpenClaws")
    end

    self:SetElementDestination(1)
    self:SetElementOpen(true)
    if self:IsMegaPhysCannon() == true then
        self:SendWeaponAnim(ACT_VM_IDLE)
    end

    self:DoEffect(EFFECT_READY)
end

function SWEP:OpenElementsHalf()
    --DbgPrint(self, "OpenElements")
    if self:GetElementDestination() == 0.5 then return end
    if SERVER then
        SuppressHostEvents(NULL)
    end

    if self:GetElementDestination() == 0 then
        self:WeaponSound("Weapon_PhysCannon.OpenClaws")
    end

    self:SetElementDestination(0.5)
    self:SetElementOpen(true)
    if self:IsMegaPhysCannon() == true then
        self:SendWeaponAnim(ACT_VM_IDLE)
    end

    self:DoEffect(EFFECT_READY)
end

function SWEP:CloseElements()
    --DbgPrint(self, "CloseElements")
    if self:GetElementDestination() == 0.0 then return end
    -- Never close on mega
    if self:IsMegaPhysCannon() == true then return end
    if SERVER then
        SuppressHostEvents(NULL)
    end

    local snd = self:GetMotorSound()
    if snd ~= nil and snd ~= NULL then
        snd:ChangeVolume(0, 1.0)
        snd:ChangePitch(50, 1.0)
    end

    self:SetElementDestination(0)
    self:WeaponSound("Weapon_PhysCannon.CloseClaws")
    self:SetElementOpen(false)
    if self:IsMegaPhysCannon() == true then
        self:SendWeaponAnim(ACT_VM_IDLE)
    end

    self:DoEffect(EFFECT_CLOSED)
end

function SWEP:WeaponIdle()
    local owner = self:GetOwner()
    if owner == nil or owner == NULL then return end
    if owner:GetActiveWeapon() ~= self then return end
    --DbgPrint(self, self:GetOwner(), "WeaponIdle")
    local controller = self:GetMotionController()
    if self:IsMegaPhysCannon() == true then
        self:OpenElements()
    end

    if self:GetNextIdleTime() == -1 then return end
    if CurTime() < self:GetNextIdleTime() then return end
    self:SetNextIdleTime(-1)
    if controller:IsObjectAttached() == true then
        self:SendWeaponAnim(ACT_VM_RELOAD)
    else
        if self:IsMegaPhysCannon() == true then
            self:SendWeaponAnim(ACT_VM_RELOAD)
        else
            self:SendWeaponAnim(ACT_VM_IDLE)
        end

        self:DoEffect(EFFECT_READY)
    end
end

function SWEP:UpdateElementPosition()
    local dest = self:GetElementDestination()
    if dest ~= self.LastElementDestination then
        self.LastElementDestination = dest
        self.ElementPosition:InitFromCurrent(dest, 0.2)
    end

    local elemPos = self.ElementPosition:Interp(CurTime())
    if self:ShouldDrawUsingViewModel() == true then
        local owner = self:GetOwner()
        if IsValid(owner) ~= true then return end
        local vm = owner:GetViewModel()
        if vm ~= nil then
            vm:SetPoseParameter("active", elemPos)
        end
    else
        if self:IsMegaPhysCannon() == true then
            elemPos = 1
        end

        self:SetPoseParameter("active", elemPos)
        if CLIENT then
            self:InvalidateBoneCache()
        end
    end
end

function SWEP:CheckForTarget()
    -- Elements are always open so we can leave all of this.
    if self:IsMegaPhysCannon() == true then return end
    local curTime = CurTime()
    if self.CheckSuppressTime > curTime then return end
    if self:IsEffectActive(EF_NODRAW) then return end
    local owner = self:GetOwner()
    if owner == nil then return end
    local controller = self:GetMotionController()
    if controller:IsObjectAttached() then return end
    local tr = self:FindObjectTrace(owner)
    if tr.Fraction ~= 1.0 and IsValid(tr.Entity) == true then
        local dist = (tr.StartPos - tr.HitPos):Length()
        if dist <= self:TraceLength() and self:CanPickupObject(tr.Entity) then
            self.ChangeState = ELEMENT_STATE_NONE
            self:OpenElementsHalf()

            return
        end
    end

    if self.ElementDebounce < curTime and self.ChangeState == ELEMENT_STATE_NONE then
        self.ChangeState = ELEMENT_STATE_CLOSED
        self.ElementDebounce = curTime + 0.5
    end
end

function SWEP:EmitLight(glowMode, pos, brightness, color)
    local projectedTextureEnabled = glowMode == 1 or glowMode == 2
    local dynamicLightEnabled = glowMode == 1 or glowMode == 3
    local owner = self:GetOwner()
    if not IsValid(owner) then
        -- Disable the light effects without a owner, save a bit of performance.
        projectedTextureEnabled = false
        dynamicLightEnabled = false
    end

    if projectedTextureEnabled then
        local pt = self.ProjectedTexture
        if pt == nil then
            pt = ProjectedTexture()
            pt:SetTexture("effects/flashlight/soft")
            pt:SetEnableShadows(true)
            pt:SetVerticalFOV(120)
            pt:SetHorizontalFOV(120)
            self.ProjectedTexture = pt
        end

        if IsValid(owner) then
            pt:SetAngles(owner:GetAimVector():Angle())
        else
            pt:SetAngles(self:GetAngles())
        end

        pt:SetFarZ(150)
        pt:SetBrightness(brightness)
        pt:SetColor(color)
        pt:SetPos(pos)
        pt:Update()
    else
        if self.ProjectedTexture ~= nil and IsValid(self.ProjectedTexture) then
            self.ProjectedTexture:Remove()
            self.ProjectedTexture = nil
        end
    end

    if dynamicLightEnabled then
        local dlight = DynamicLight(self:EntIndex(), false)
        if dlight then
            dlight.pos = pos
            dlight.r = color.r
            dlight.g = color.g
            dlight.b = color.b
            dlight.brightness = brightness
            dlight.decay = 1
            dlight.size = 82
            dlight.minlight = 0.1
            dlight.nomodel = false
            dlight.dietime = CurTime() + 0.1
        end
    end
end

function SWEP:GetLightPosition()
    local owner = self:GetOwner()
    local pos
    if self:ShouldDrawUsingViewModel() == true and IsValid(owner) == true then
        local vm = owner:GetViewModel()
        local attachmentData = vm:GetAttachment(1)
        if attachmentData == nil then return end
        local fwd = attachmentData.Ang:Forward()
        pos = self:FormatViewModelAttachment(attachmentData.Pos, true) - (fwd * 60)
        pos = pos + (attachmentData.Ang:Up() * 5)
    else
        local attachment = self:GetAttachment(1)
        if attachment == nil then return end
        pos = attachment.Pos + (attachment.Ang:Forward() * 4.5)
    end

    return pos
end

function SWEP:GetLightBrightness()
    local brightness
    if self:IsMegaPhysCannon() == true then
        brightness = 1.3
    else
        brightness = 0.5
    end

    local efState = self:GetEffectState()
    if efState == EFFECT_HOLDING then
        brightness = brightness * (2.5 + (math.sin(CurTime() * 100) * 0.12))
    elseif efState == EFFECT_LAUNCH then
        brightness = brightness * 2.5
    end

    return brightness
end

function SWEP:StopLights()
    if self.ProjectedTexture ~= nil and IsValid(self.ProjectedTexture) then
        self.ProjectedTexture:Remove()
        self.ProjectedTexture = nil
    end
end

function SWEP:UpdateGlow()
    if self:IsEffectActive(EF_NODRAW) == true then return end
    local glowMode = physcannon_glow_mode
    if glowMode == 0 then
        self:StopLights()

        return
    end

    local curTime = CurTime()
    if curTime < self.NextGlowUpdate then return end
    local lightPos = self:GetLightPosition()
    local wepColor = self:GetWeaponColor()
    local brightness = self:GetLightBrightness()
    self:EmitLight(glowMode, lightPos, brightness, wepColor)
    self.NextGlowUpdate = curTime + GLOW_UPDATE_DT
end

function SWEP:ThinkHook()
    if SERVER then
        if game_GetGlobalState("super_phys_gun") == GLOBAL_ON then
            self:SetMegaEnabled(true)
        else
            self:SetMegaEnabled(false)
        end
    else
        self:UpdateEffects()
    end
end

function SWEP:Think()
    local controller = self:GetMotionController()
    if CLIENT then
        -- Only predict for local player.
        local ply = LocalPlayer()
        if IsValid(ply) == true and ply:GetObserverMode() == OBS_MODE_NONE and ply == self:GetOwner() then
            controller:ManagePredictedObject()
        end

        local effectState = self:GetEffectState()
        if effectState ~= self.OldEffectState then
            self:DoEffect(effectState)
        end

        self:UpdateElementPosition()
        self:StartEffects()
    end

    if controller:IsObjectAttached() == true and self:UpdateObject() == false then
        self:DetachObject()

        return
    elseif controller:IsObjectAttached() == false and self.ObjectAttached == true then
        self:DetachObject()

        return
    end

    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return true end
    -- In mega its always open, no need for traces.
    if self:IsMegaPhysCannon() == false and controller:IsObjectAttached() == false then
        self:CheckForTarget()
        if self.ElementDebounce < CurTime() and self.ChangeState ~= ELEMENT_STATE_NONE then
            if self.ChangeState == ELEMENT_STATE_OPEN then
                if SERVER then
                    self:OpenElements()
                end
            elseif self.ChangeState == ELEMENT_STATE_CLOSED then
                if SERVER then
                    self:CloseElements()
                end
            end

            self.ChangeState = ELEMENT_STATE_NONE
        end
    end

    self:WeaponIdle()

    return true
end

function SWEP:AttachObject(ent, tr)
    DbgPrint(self, "AttachObject", ent)
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return end
    local useGrabPos = false
    local grabPos = tr.HitPos
    local attachmentPoint
    if self:IsMegaPhysCannon() == true and ent:IsNPC() and ent:IsEFlagSet(EFL_NO_PHYSCANNON_INTERACTION) == false and ent:IsEFlagSet(EFL_NO_MEGAPHYSCANNON_RAGDOLL) == false and ent:CanBecomeRagdoll() == true and ent:GetMoveType() == MOVETYPE_STEP then
        local dmgInfo = DamageInfo()
        dmgInfo:SetInflictor(owner)
        dmgInfo:SetAttacker(owner)
        dmgInfo:SetDamage(1)
        dmgInfo:SetDamageType(DMG_GENERIC)
        local ragdoll = ent:CreateServerRagdoll(dmgInfo)
        local phys = ragdoll:GetPhysicsObject()
        if IsValid(phys) == true then
            phys:AddGameFlag(FVPHYSICS_NO_SELF_COLLISIONS)
        end

        ragdoll:SetCollisionBounds(ent:OBBMins(), ent:OBBMaxs())
        ragdoll:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) -- Its ugly if players collide
        ragdoll.IsPhysgunDamage = true
        dmgInfo = DamageInfo()
        dmgInfo:SetInflictor(owner)
        dmgInfo:SetAttacker(owner)
        dmgInfo:SetDamage(10000)
        dmgInfo:SetDamageType(bor(DMG_PHYSGUN, DMG_REMOVENORAGDOLL))
        ent:TakeDamageInfo(dmgInfo)
        ent = ragdoll
    end

    local motionController = self:GetMotionController()
    if ent:IsRagdoll() then
        -- NOTE: This is off by default, the original implementation used the closest physics object
        -- It makes the game play a lot better using the center for ragdolls.
        useGrabPos = false
        attachmentPoint = Vector(0, 0, 0)
    else
        attachmentPoint = ent:OBBCenter()
    end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) ~= true then
        DbgPrint("Physics invalid!")

        return
    end

    if SERVER then
        owner:SimulateGravGunPickup(ent, false)
    end

    motionController:AttachObject(ent, grabPos, useGrabPos)
    self.ObjectAttached = true
    phys:AddGameFlag(FVPHYSICS_PLAYER_HELD)
    --if SERVER then
    if IsValid(ent:GetOwner()) ~= true then
        ent:SetOwner(owner)
        self.ResetOwner = true
    end

    --end
    if SERVER then
        local targetAng = nil
        local preferredCarryAng = owner:GetPreferredCarryAngles(ent)
        if preferredCarryAng ~= nil and targetAng == nil then
            targetAng = preferredCarryAng
        end

        if targetAng == nil then
            targetAng = ent:GetAngles()
        end

        targetAng = owner:WorldToLocalAngles(targetAng)
        self:SetTargetAngle(targetAng)
        self:SetTargetOffset(attachmentPoint)
        ent:PhysicsImpactSound()
    end

    -- We call it once so it resets the positions.
    if self:UpdateObject() == false then
        self:DetachObject()

        return false
    end

    self:DoEffect(EFFECT_HOLDING)
    self:OpenElements()
    self:SetNextIdleTime(CurTime() + 0.2)
    local snd = self:GetMotorSound()
    if snd ~= nil and snd ~= NULL then
        if CLIENT then
            snd:Stop()
        end

        --snd:Play()
        snd:PlayEx(100, 50)
        snd:ChangePitch(100, 0.5)
        snd:ChangeVolume(0.8, 0.5)
        DbgPrint(self, "Playing sound")
    end

    return true
end

function SWEP:DetachObject(launched)
    --assert(false)
    local owner = self:GetOwner()
    DbgPrint(self, "DetachObject")
    if self.ObjectAttached == true then
        self:WeaponSound("Weapon_PhysCannon.Drop")
        self.ObjectAttached = false
    end

    local snd = self:GetMotorSound()
    if snd ~= nil and snd ~= NULL then
        snd:ChangeVolume(0, 1.0)
        snd:ChangePitch(50, 1.0)
    end

    local controller = self:GetMotionController()
    if IsValid(controller) ~= true then
        DbgPrint(self, "No valid controller")

        return
    end

    if controller:IsObjectAttached() == false then
        DbgPrint(self, "No object attached")

        return
    end

    local ent = controller:GetAttachedObject()
    if IsValid(ent) ~= true then
        DbgPrint(self, "Invalid attached object")

        return
    end

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) ~= true then
        DbgPrint("No physics object")

        return
    end

    phys:ClearGameFlag(FVPHYSICS_PLAYER_HELD)
    if self.ResetOwner == true then
        ent:SetOwner(nil)
    end

    if SERVER and IsValid(owner) == true then
        owner:SimulateGravGunDrop(ent, launched)
    end

    local motionController = self:GetMotionController()
    motionController:DetachObject()
    if self:IsMegaPhysCannon() == false then
        self:SendWeaponAnim(ACT_VM_DRYFIRE)
    end

    self:DoEffect(EFFECT_READY)
    self:SetNextIdleTime(CurTime() + 0.2)
    if launched ~= true and ent:GetClass() == "prop_combine_ball" and IsValid(phys) == true then
        -- If we just release it then it will be simply stuck mid air.
        phys:Wake()
        phys:SetVelocity((owner:GetAimVector() + (VectorRand() * 0.8)) * 4000)
    end
end

function SWEP:DryFire()
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:EmitSound("Weapon_PhysCannon.DryFire")
    self:DoEffect(EFFECT_READY)
    self:SetNextIdleTime(CurTime() + 0.2)
end

function SWEP:PrimaryFireEffect()
    local owner = self:GetOwner()
    if IsValid(owner) ~= true then return end
    owner:ViewPunch(Angle(-6, util.SharedRandom("physcannonfire", -2, 2), 0))
    self:EmitSound("Weapon_PhysCannon.Launch")
end

function SWEP:PuntNonVPhysics(ent, fwd, tr)
    DbgPrint("PuntNonVPhysics")
    if hook.Call("GravGunPunt", GAMEMODE, self:GetOwner(), ent) == false then return end
    if ent:IsNPC() == true and IsFriendEntityName(ent:GetClass()) == true then return end
    if SERVER then
        local dmgAmount = 1.0
        if ent:GetClass() == "func_breakable" and ent:GetMaterialType() == MAT_GLASS then
            dmgAmount = physcannon_dmg_class:GetFloat()
        end

        local dmgInfo = DamageInfo()
        dmgInfo:SetAttacker(self:GetOwner())
        dmgInfo:SetInflictor(self)
        dmgInfo:SetDamage(dmgAmount)
        dmgInfo:SetDamageType(bor(DMG_CRUSH, DMG_PHYSGUN))
        dmgInfo:SetDamageForce(fwd)
        dmgInfo:SetDamagePosition(tr.HitPos)
        ent:DispatchTraceAttack(dmgInfo, tr, fwd)
        self:DoEffect(EFFECT_LAUNCH, tr.HitPos, tr.MatType, tr.HitNormal)
        self:SetNextIdleTime(CurTime() + 0.2)
        ent:SetPhysicsAttacker(self:GetOwner())
    end

    self:PrimaryFireEffect()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)
    self.ElementDebounce = CurTime() + 0.5
    self.CheckSuppressTime = CurTime() + 0.25
    self.ChangeState = ELEMENT_STATE_CLOSED
end

function SWEP:ApplyVelocityBasedForce(ent, fwd)
    if not SERVER then return end
    local phys = ent:GetPhysicsObject()
    if IsValid(phys) ~= true then return end
    local maxForce = physcannon_maxforce:GetFloat()
    local force = maxForce
    local vVel = fwd * force
    --local aVel = tr.HitPos
    if ent:IsRagdoll() then
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local phys2 = ent:GetPhysicsObjectNum(i)
            if IsValid(phys2) ~= true then continue end -- Yes this can actually happen
            phys2:AddVelocity(vVel)
        end
    else
        phys:AddVelocity(vVel)
    end
    --phys:AddAngleVelocity(aVel * 1)
end

function SWEP:PuntVPhysics(ent, fwd, tr)
    local curTime = CurTime()
    if self.LastPuntedObject == ent and curTime < self.NextPuntTime then return end
    if self:IsMegaPhysCannon() == false and ent:IsVPhysicsFlesh() == true then return end
    DbgPrint("PuntVPhysics")
    self.LastPuntedObject = ent
    self.NextPuntTime = curTime + 0.5
    local owner = self:GetOwner()
    if SERVER then
        local dmgInfo = DamageInfo()
        dmgInfo:SetAttacker(self:GetOwner())
        dmgInfo:SetInflictor(self)
        dmgInfo:SetDamage(0)
        dmgInfo:SetDamageType(DMG_PHYSGUN)
        ent:DispatchTraceAttack(dmgInfo, tr, fwd)
        if fwd.z < 0 then
            fwd.z = fwd.z * -0.65
        end

        owner:SimulateGravGunPickup(ent, true)
        local phys = ent:GetPhysicsObjectNum(0)
        if IsValid(phys) then
            if phys:HasGameFlag(FVPHYSICS_CONSTRAINT_STATIC) and ent:IsVehicle() then
                fwd.x = 0
                fwd.y = 0
                fwd.z = 0
            end
        end

        -- if ( !Pickup_ShouldPuntUseLaunchForces( pEntity, PHYSGUN_FORCE_PUNTED ) )
        if self:IsMegaPhysCannon() == false then
            local totalMass = 0
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                local subphys = ent:GetPhysicsObjectNum(i)
                totalMass = totalMass + subphys:GetMass()
            end

            local maxMass = 250
            local actualMass = math.min(totalMass, maxMass)
            local mainPhys = ent:GetPhysicsObject()
            for i = 0, ent:GetPhysicsObjectCount() - 1 do
                local subphys = ent:GetPhysicsObjectNum(i)
                local ratio = phys:GetMass() / totalMass
                if subphys == mainPhys then
                    ratio = ratio + 0.5
                    ratio = math.min(ratio, 1.0)
                else
                    ratio = ratio * 0.5
                end

                subphys:ApplyForceCenter(fwd * 15000 * ratio)
                subphys:ApplyForceOffset(fwd * actualMass * 600 * ratio, tr.HitPos)
            end
        else
            self:ApplyVelocityBasedForce(ent, fwd, tr)
        end
    end

    self:PrimaryFireEffect()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    owner:SetAnimation(PLAYER_ATTACK1)
    self.ChangeState = ELEMENT_STATE_CLOSED
    self.ElementDebounce = CurTime() + 0.5
    self.CheckSuppressTime = CurTime() + 0.25
    self:DoEffect(EFFECT_LAUNCH, tr.HitPos, tr.MatType, tr.HitNormal)
    self:SetNextIdleTime(CurTime() + 0.2)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:PuntRagdoll(ent, fwd, tr)
    local curTime = CurTime()
    local owner = self:GetOwner()
    if self.LastPuntedObject == ent and curTime < self.NextPuntTime then return end
    self.LastPuntedObject = ent
    self.NextPuntTime = curTime + 0.5
    if SERVER then
        local dmgInfo = DamageInfo()
        dmgInfo:SetAttacker(self:GetOwner())
        dmgInfo:SetInflictor(self)
        dmgInfo:SetDamage(0)
        dmgInfo:SetDamageType(DMG_PHYSGUN)
        ent:DispatchTraceAttack(dmgInfo, tr, fwd)
        if fwd.z < 0 then
            fwd.z = fwd.z * -0.65
        end

        owner:SimulateGravGunPickup(ent, true)
        local vel = fwd * 1500
        for i = 0, ent:GetPhysicsObjectCount() - 1 do
            local phys = ent:GetPhysicsObject()
            phys:AddVelocity(vel)
        end
    end

    self:PrimaryFireEffect()
    self:SendWeaponAnim(ACT_VM_SECONDARYATTACK)
    owner:SetAnimation(PLAYER_ATTACK1)
    self.ChangeState = ELEMENT_STATE_CLOSED
    self.ElementDebounce = CurTime() + 0.5
    self.CheckSuppressTime = CurTime() + 0.25
    self:DoEffect(EFFECT_LAUNCH, tr.HitPos, tr.MatType, tr.HitNormal)
    self:SetNextIdleTime(CurTime() + 0.2)
    self:SetNextPrimaryFire(CurTime() + 0.5)
    self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:DoEffectNone(pos)
    if SERVER then return end
    DbgPrint("DoEffectNone")
    self.EffectParameters[PHYSCANNON_CORE].Visible = false
    self.EffectParameters[PHYSCANNON_BLAST].Visible = false
    for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
        self.EffectParameters[i].Visible = true
    end

    for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
        local beamdata = self.BeamParameters[i]
        if beamdata == nil then continue end
        beamdata.Visible = true
        beamdata.Scale:InitFromCurrent(0.0, 0.1)
    end

    local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
    core2.Scale:InitFromCurrent(24.0, 0.1)
    core2.Alpha:InitFromCurrent(255, 0.2)
end

function SWEP:DoEffectClosed(pos)
    if SERVER then return end
    DbgPrint("DoEffectClosed")
    for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
        local data = self.EffectParameters[i]
        data.Scale:InitFromCurrent(0.4 * SPRITE_SCALE, 0.2)
        data.Alpha:InitFromCurrent(64.0, 0.2)
        data.Visible = true
    end

    for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
        local data = self.EffectParameters[i]
        if data == nil then continue end
        --data.Visible = false
        local beamdata = self.BeamParameters[i]
        beamdata.Visible = true
        beamdata.Scale:InitFromCurrent(0.0, 0.1)
    end

    local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
    core2.Scale:InitFromCurrent(14.0, 0.1)
    core2.Alpha:InitFromCurrent(64, 0.2)
end

function SWEP:DoEffectReady(pos)
    if SERVER then return end
    DbgPrint("DoEffectReady")
    local core = self.EffectParameters[PHYSCANNON_CORE]
    if self:ShouldDrawUsingViewModel() == true then
        core.Scale:InitFromCurrent(20.0, 0.2)
    else
        core.Scale:InitFromCurrent(12.0, 0.2)
    end

    core.Alpha:InitFromCurrent(128.0, 0.2)
    core.Visible = true
    self.EffectParameters[PHYSCANNON_CORE_2].Scale:InitFromCurrent(0.0, 0.2)
    for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
        local data = self.EffectParameters[i]
        data.Scale:InitFromCurrent(10 * SPRITE_SCALE, 0.2)
        data.Alpha:InitFromCurrent(256.0, 0.2)
        data.Visible = true
    end

    for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
        local data = self.EffectParameters[i]
        if data ~= nil then
            data.Visible = true
        end

        local beamdata = self.BeamParameters[i]
        if beamdata ~= nil then
            beamdata.Visible = true
            beamdata.Scale:InitFromCurrent(0.0, 0.1)
        end
    end

    local core2 = self.EffectParameters[PHYSCANNON_CORE_2]
    core2.Scale:InitFromCurrent(5.0, 0.1)
    core2.Alpha:InitFromCurrent(255, 0.2)
end

function SWEP:DoEffectHolding(pos)
    DbgPrint("DoEffectHolding")
    if SERVER then return end
    local effectParameters = self.EffectParameters
    local beamParameters = self.BeamParameters
    if self:ShouldDrawUsingViewModel() == true then
        local core = effectParameters[PHYSCANNON_CORE]
        core.Scale:InitFromCurrent(20.0, 0.2)
        core.Alpha:InitFromCurrent(255.0, 0.1)
        local blast = effectParameters[PHYSCANNON_BLAST]
        blast.Visible = false
        for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
            local data = effectParameters[i]
            data.Scale:InitFromCurrent(0.5 * SPRITE_SCALE, 0.2)
            data.Alpha:InitFromCurrent(64.0, 0.2)
            data.Visible = true
        end

        for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
            local data = effectParameters[i]
            if data ~= nil then
                data.Visible = true
            end

            local beamdata = beamParameters[i]
            if beamdata ~= nil then
                beamdata.Lifetime = -1
                beamdata.Scale:InitFromCurrent(0.5, 0.1)
            end
        end
    else
        local core = effectParameters[PHYSCANNON_CORE]
        core.Scale:InitFromCurrent(16.0, 0.2)
        core.Alpha:InitFromCurrent(255.0, 0.1)
        local blast = effectParameters[PHYSCANNON_BLAST]
        blast.Visible = false
        for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
            local data = effectParameters[i]
            data.Scale:InitFromCurrent(0.5 * SPRITE_SCALE, 0.2)
            data.Alpha:InitFromCurrent(64.0, 0.2)
            data.Visible = true
        end

        for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
            local data = effectParameters[i]
            if data == nil then continue end
            data.Visible = true
            local beamdata = beamParameters[i]
            if beamdata ~= nil then
                beamdata.Scale:InitFromCurrent(0.6, 0.1)
                beamdata.Lifetime = -1
            end
        end
    end

    local core2 = effectParameters[PHYSCANNON_CORE_2]
    core2.Scale:InitFromCurrent(38.0, 0.1)
    core2.Alpha:InitFromCurrent(150, 0.2)
end

function SWEP:DoEffectLaunch(pos, matType, normal)
    DbgPrint("DoEffectLaunch")
    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos
    local shotDir
    local controller = self:GetMotionController()
    local attachedEnt = controller:GetAttachedObject()

    if pos == nil then

        if attachedEnt ~= nil then
            endPos = attachedEnt:WorldSpaceCenter()
            startPos = endPos
            shotDir = endPos - startPos
        else
            shotDir = owner:GetAimVector()
            local tr = TraceLine(
                {
                    start = startPos,
                    endpos = startPos + (shotDir * 1900),
                    mask = TraceMask,
                    filter = owner
                }
            )
            endPos = tr.HitPos
            matType = tr.MatType
            normal = tr.HitNormal
            shotDir = endPos - startPos
            -- Override material type for zombies, it reports MAT_FLESH
            if IsValid(tr.Entity) and tr.Entity:IsNPC() then
                local hitClass = tr.Entity:GetClass()
                if hitClass == "npc_zombie" or hitClass == "npc_fastzombie" or hitClass == "npc_poisonzombie" then
                    matType = MAT_ALIENFLESH
                end
            end
        end
    else
        endPos = pos
        shotDir = endPos - startPos
    end

    if normal == nil then
        normal = shotDir:GetNormalized()
    end

    if matType == nil then
        matType = 0
    end

    shotDir:Normalize()
    local ef = EffectData()
    ef:SetOrigin(endPos)
    ef:SetEntity(self)
    ef:SetMaterialIndex(matType)
    ef:SetNormal(normal)
    if CLIENT and IsFirstTimePredicted() then
        util.Effect("lambda_physcannon_impact", ef)
    elseif SERVER then
        util.Effect("lambda_physcannon_impact", ef)
    end

    if CLIENT then
        local blast = self.EffectParameters[PHYSCANNON_BLAST]
        blast.Scale:Init(8.0, 128, 0.3)
        blast.Alpha:Init(255, 0, 0.2)
        blast.Visible = true
    end
end

function SWEP:DoEffectIdle()
end

function SWEP:DoEffectPulling()
end

local EFFECT_NAME = {
    [EFFECT_NONE] = "EFFECT_NONE",
    [EFFECT_CLOSED] = "EFFECT_CLOSED",
    [EFFECT_READY] = "EFFECT_READY",
    [EFFECT_HOLDING] = "EFFECT_HOLDING",
    [EFFECT_LAUNCH] = "EFFECT_LAUNCH",
    [EFFECT_IDLE] = "EFFECT_IDLE",
    [EFFECT_PULLING] = "EFFECT_PULLING"
}

local EFFECT_TABLE = {
    [EFFECT_NONE] = SWEP.DoEffectNone,
    [EFFECT_CLOSED] = SWEP.DoEffectClosed,
    [EFFECT_READY] = SWEP.DoEffectReady,
    [EFFECT_HOLDING] = SWEP.DoEffectHolding,
    [EFFECT_LAUNCH] = SWEP.DoEffectLaunch,
    [EFFECT_IDLE] = SWEP.DoEffectIdle,
    [EFFECT_PULLING] = SWEP.DoEffectPulling
}

function SWEP:DoEffect(effect, pos, matType, normal)
    if self.CurrentEffect == effect then return end
    if CLIENT then
        self:StartEffects()
        self.OldEffectState = effect
    end

    self.CurrentEffect = effect
    if SERVER then
        self:SetEffectState(effect)
    end

    DbgPrint("Assigned Current Effect: " .. (EFFECT_NAME[effect] or "Unknown!") .. " (" .. effect .. ")")
    EFFECT_TABLE[effect](self, pos, matType, normal)
end

function SWEP:DrawWorldModel()
    local effectState = self:GetEffectState(EFFECT_READY)
    if effectState ~= self.OldEffectState then
        self:DoEffect(effectState)
    end

    local wepColor = self:GetWeaponColor(true)
    MAT_WORLDMDL:SetVector("$selfillumtint", wepColor)
    self:UpdateElementPosition()
    self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
    self:UpdateDrawUsingViewModel()
    self:DrawModel()
    self:DrawEffects()
end

function SWEP:Holster(ent)
    DbgPrint(self, "Holster")
    if not IsFirstTimePredicted() then return end
    local controller = self:GetMotionController()
    if controller:IsObjectAttached() == true then return false end
    self:StopLoopingSounds()
    self:StopEffects()
    self:DetachObject()
    self.ShouldDrawGlow = false
    self:SendWeaponAnim(ACT_VM_HOLSTER)

    return true
end

function SWEP:Startup()
    self.ShouldDrawGlow = true
    self:SendWeaponAnim(ACT_VM_DEPLOY)
    self:SetNextIdleTime(CurTime() + 0.1)
    if self:IsMegaPhysCannon() == true then
        self:OpenElements()
    else
        self:CloseElements()
    end

    if CLIENT then
        self:StartEffects()
        self:UpdateEffects()
    end

    self:DoEffect(EFFECT_READY)
end

function SWEP:Equip(newOwner)
    DbgPrint("Equip")
    self:Startup()
    if IsValid(newOwner) and newOwner:IsPlayer() == true then
        self:SetLastWeaponColor(newOwner:GetWeaponColor())
    end
end

function SWEP:Deploy()
    DbgPrint("Deploy")
    self:Startup()

    return true
end

function SWEP:OnDrop()
    self:DetachObject()
end

function SWEP:OwnerChanged()
    self:DetachObject()
end

function SWEP:FormatViewModelAttachment(vOrigin, bFrom)
    local nFOV = self.ViewModelFOV
    local vEyePos = EyePos()
    local aEyesRot = EyeAngles()
    local vOffset = vOrigin - vEyePos
    local vForward = aEyesRot:Forward()
    local nViewX = math.tan(nFOV * math.pi / 360)
    if nViewX == 0 then
        vForward:Mul(vForward:Dot(vOffset))
        vEyePos:Add(vForward)

        return vEyePos
    end

    -- FIXME: LocalPlayer():GetFOV() should be replaced with EyeFOV() when it's binded
    local nWorldX = math.tan(LocalPlayer():GetFOV() * math.pi / 360)
    if nWorldX == 0 then
        vForward:Mul(vForward:Dot(vOffset))
        vEyePos:Add(vForward)

        return vEyePos
    end

    local vRight = aEyesRot:Right()
    local vUp = aEyesRot:Up()
    if not bFrom then
        local nFactor = nWorldX / nViewX
        vRight:Mul(vRight:Dot(vOffset) * nFactor)
        vUp:Mul(vUp:Dot(vOffset) * nFactor)
    else
        local nFactor = nViewX / nWorldX
        vRight:Mul(vRight:Dot(vOffset) * nFactor)
        vUp:Mul(vUp:Dot(vOffset) * nFactor)
    end

    vForward:Mul(vForward:Dot(vOffset))
    vEyePos:Add(vRight)
    vEyePos:Add(vUp)
    vEyePos:Add(vForward)

    return vEyePos
end

function SWEP:UpdateDrawUsingViewModel()
    if EffectsInvalidated == true then
        self:InvalidateEffects()
        EffectsInvalidated = false
    end

    local newValue = self:IsCarriedByLocalPlayer() and LocalPlayer():ShouldDrawLocalPlayer() == false
    local owner = self:GetOwner()
    if IsValid(owner) == false then
        newValue = false
    else
        if owner:Alive() == false then
            newValue = false
        end
    end

    -- Mark for next frame otherwise positions are incorrect.
    EffectsInvalidated = newValue ~= self.DrawUsingViewModel
    self.DrawUsingViewModel = newValue
end

function SWEP:ShouldDrawUsingViewModel()
    if not IsValid(self:GetOwner()) then return false end

    return self.DrawUsingViewModel
end

function SWEP:DrawEffects(vm)
    local owner = self:GetOwner()
    self:DrawCoreBeams(owner, vm)
    local DrawEffectType = self.DrawEffectType
    for k, data in pairs(self.EffectParameters) do
        if data.Visible == false then continue end
        DrawEffectType(self, k, data, owner, vm)
    end
end

function SWEP:DrawEffectType(id, data, owner, vm)
    local curTime = CurTime()
    local alpha = data.Alpha:Interp(curTime)
    if alpha < 0 then return end
    local pos
    if self:ShouldDrawUsingViewModel() == true then
        if IsValid(owner) == true then
            if vm == nil then
                vm = owner:GetViewModel()
            end

            local attachmentData = vm:GetAttachment(data.Attachment)
            if attachmentData == nil then return end
            pos = self:FormatViewModelAttachment(attachmentData.Pos, true)
        end
    else
        local attachmentData = self:GetAttachment(data.Attachment)
        if attachmentData == nil then return end --print("Missing attachment: " .. attachmentId)
        pos = attachmentData.Pos
    end

    render.SetMaterial(data.Mat)
    local color = data.Col
    color.a = alpha
    local scale = data.Scale:Interp(curTime)
    render.DrawSprite(pos, scale, scale, color)
end

local BEAM_GROUPS = 4
local BEAM_SEGMENTS = 4
local render_StartBeam = render and render.StartBeam or nil
local render_EndBeam = render and render.EndBeam or nil
function SWEP:DrawBeam(startPos, endPos, width, color)
    color = color or Color(255, 255, 255, 255)
    local frequency = 5
    local curTime = CurTime()
    local range = 1
    for n = 0, BEAM_GROUPS - 1 do
        local seed = n
        render_StartBeam(BEAM_SEGMENTS)
        for i = 0, BEAM_SEGMENTS - 1 do
            local p = i / (BEAM_SEGMENTS - 1)
            local pos = LerpVector(p, startPos, endPos)
            local randVec = Vector(1, 1, 1)
            randVec.x = randVec.x * util.SharedRandom("beam_posx" .. tostring(i), -0.1, 0.1)
            randVec.y = randVec.y * util.SharedRandom("beam_posy" .. tostring(i), -0.1, 0.1)
            randVec.z = randVec.z * util.SharedRandom("beam_posz" .. tostring(i), -0.1, 0.1)
            if i > 0 then
                local yOffset = math.sin(i + (seed * 10) + curTime * frequency) * range
                local xOffset = math.cos(i + (seed * 20) + seed + curTime * frequency) * range
                local zOffset = math.sin(i + (seed * 30) + seed + curTime * frequency * 0.5) * range
                pos.x = pos.x + xOffset
                pos.y = pos.y + yOffset
                pos.z = pos.z + zOffset
                pos = pos + VectorRand() * 0.2
            end

            local texcoord = util.SharedRandom("beam_tex" .. tostring(i), 0.5, 1)
            render.AddBeam(pos, width, texcoord, color)
        end

        render_EndBeam()
    end
end

function SWEP:GetCorePos(owner, vm)
    local corePos
    local maxEndCap = PHYSCANNON_ENDCAP3
    local shouldDrawUsingViewModel = self:ShouldDrawUsingViewModel()
    if shouldDrawUsingViewModel == true then
        if owner ~= nil then
            if IsValid(vm) == false then
                vm = owner:GetViewModel()
            end

            local attachmentData = vm:GetAttachment(1)
            if attachmentData == nil then return end
            corePos = self:FormatViewModelAttachment(attachmentData.Pos, true)
        end

        maxEndCap = PHYSCANNON_ENDCAP2
    else
        local attachmentData = self:GetAttachment(1)
        if attachmentData == nil then return end --print("Missing attachment: " .. attachmentId)
        corePos = attachmentData.Pos
    end

    return corePos, maxEndCap
end

function SWEP:DrawCoreBeams(owner, vm)
    local shouldDrawUsingViewModel = self:ShouldDrawUsingViewModel()
    if vm == nil and IsValid(owner) == true then
        vm = owner:GetViewModel()
    elseif vm == nil then
        vm = self
    end

    local curTime = CurTime()
    local corePos, maxEndCap = self:GetCorePos(owner, vm)
    local wepColor = self:GetWeaponColor()
    local beamDrawn = false
    local endPos
    local beamParameters = self.BeamParameters
    local effectParameters = self.EffectParameters
    -- Swirl around the core.
    local coreDist = 1.0
    local corePosX = math.sin(curTime) * coreDist
    local corePosY = math.cos(curTime + corePosX) * coreDist
    local corePosZ = math.cos(curTime + corePosY) * coreDist
    render.SetMaterial(MAT_PHYSBEAM)
    for i = PHYSCANNON_ENDCAP1, maxEndCap do
        local beamdata = beamParameters[i]
        if beamdata == nil then continue end
        if beamdata.Lifetime ~= -1 then
            if beamdata.Lifetime <= 0 then continue end
            beamdata.Lifetime = beamdata.Lifetime - FrameTime()
        end

        local params = effectParameters[i]
        if params == nil then continue end
        local attachmentData = self:GetAttachment(params.Attachment)
        if attachmentData == nil then continue end
        if shouldDrawUsingViewModel == true then
            if owner ~= nil then
                attachmentData = vm:GetAttachment(params.Attachment)
                if attachmentData == nil then continue end
                endPos = self:FormatViewModelAttachment(attachmentData.Pos, true)
            end
        else
            attachmentData = self:GetAttachment(params.Attachment)
            if attachmentData == nil then continue end
            endPos = attachmentData.Pos
        end

        local width = (5 + util.SharedRandom("beam" .. tostring(i), 1, 15)) * beamdata.Scale:Interp(curTime)
        if width <= 0.0 then continue end
        self:DrawBeam(endPos, corePos + Vector(corePosX, corePosY, corePosZ), width, wepColor)
        beamDrawn = true
    end

    if beamDrawn == true and physcannon_glow_mode > 0 and curTime >= self.NextBeamGlow then
        local brightness = self:GetLightBrightness()
        local lightPos = self:GetLightPosition()
        self:EmitLight(physcannon_glow_mode, lightPos, brightness, wepColor)
        self.NextBeamGlow = curTime + GLOW_UPDATE_DT
    end
end

function SWEP:SetupEffects()
    local effects = {}
    local beams = {}
    local shouldUseViewModel = self:ShouldDrawUsingViewModel()
    local vm = self
    if shouldUseViewModel then
        local owner = self:GetOwner()
        if IsValid(owner) == true then
            local ownerVm = owner:GetViewModel()
            if IsValid(ownerVm) then
                vm = ownerVm
            end
        end
    end

    -- Core
    do
        local data = {
            Scale = InterpValue(0.0, 1.0, 0.1),
            Alpha = InterpValue(255, 255, 0.1),
            Attachment = 1,
            Mat = Material(PHYSCANNON_CENTER_GLOW),
            Visible = false,
            Col = Color(255, 255, 255)
        }

        effects[PHYSCANNON_CORE] = data
    end

    -- Blast
    do
        local data = {
            Scale = InterpValue(0.0, 1.0, 0.1),
            Alpha = InterpValue(255, 255, 0.1),
            Attachment = 1,
            Mat = Material(PHYSCANNON_BLAST_SPRITE),
            Visible = false,
            Col = Color(255, 255, 255)
        }

        effects[PHYSCANNON_BLAST] = data
    end

    -- Glow sprites
    local n = 1
    for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
        local data = {
            Scale = InterpValue(0.05 * SPRITE_SCALE, 0.05 * SPRITE_SCALE, 0.0),
            Alpha = InterpValue(64, 64, 0),
            Mat = Material(PHYSCANNON_GLOW_SPRITE),
            Visible = true,
            Col = Color(255, 128, 0)
        }

        local attachmentName
        if shouldUseViewModel == true then
            attachmentName = ATTACHMENTS_GLOW_FP[n]
        else
            attachmentName = ATTACHMENTS_GLOW_TP[n]
        end

        data.Attachment = vm:LookupAttachment(attachmentName)
        if data.Attachment == 0 then
            DbgPrint("Missing attachment: " .. tostring(attachmentName))
        end

        effects[i] = data
        n = n + 1
        init = true
    end

    if shouldUseViewModel == true then
        attachmentGaps = ATTACHMENTS_GAPS_FP
    else
        attachmentGaps = ATTACHMENTS_GAPS_TP
    end

    -- Endcap Sprites
    n = 1
    for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
        local beamdata = {
            Scale = InterpValue(0, 0, 0),
            Alpha = InterpValue(255, 255, 0),
            Visible = false,
            Col = Color(255, 128, 0, 255),
            Lifetime = -1
        }

        beams[i] = beamdata
        local attachmentName = attachmentGaps[n]
        if attachmentName == nil then continue end
        local data = {
            Scale = InterpValue(0.15 * SPRITE_SCALE, 0.15 * SPRITE_SCALE, 0.0),
            Alpha = InterpValue(255, 255, 0),
            Attachment = vm:LookupAttachment(attachmentName),
            Visible = false,
            Mat = Material(PHYSCANNON_ENDCAP_SPRITE),
            Col = Color(255, 128, 0, 255)
        }

        effects[i] = data
        n = n + 1
    end

    do
        local data = {
            Scale = InterpValue(0.0, 0.0, 1.1),
            Alpha = InterpValue(255, 255, 0.1),
            Attachment = 1,
            Mat = Material(PHYSCANNON_CORE_WARP),
            Visible = true,
            Col = Color(255, 0, 0)
        }

        effects[PHYSCANNON_CORE_2] = data
    end

    if init == true then
        for k, v in pairs(effects) do
            v.Name = EFFECT_PARAM_NAME[k]
        end
    end

    return effects, beams
end

function SWEP:InvalidateEffects()
    DbgPrint("InvalidateEffects", self:ShouldDrawUsingViewModel())
    local effectParameters = self.EffectParameters
    local beamParameters = self.BeamParameters
    self.EffectParameters = nil
    self.BeamParameters = nil
    self.EffectsSetup = false
    self:StartEffects()
    self:UpdateEffects()
    if effectParameters ~= nil then
        for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
            if self.EffectParameters[i] == nil or effectParameters[i] == nil then continue end
            self.EffectParameters[i].Scale = effectParameters[i].Scale
            self.EffectParameters[i].Alpha = effectParameters[i].Alpha
            self.EffectParameters[i].Visible = effectParameters[i].Visible
            self.EffectParameters[i].Col = effectParameters[i].Col
        end

        for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
            if self.EffectParameters[i] == nil or effectParameters[i] == nil then continue end
            self.EffectParameters[i].Scale = effectParameters[i].Scale
            self.EffectParameters[i].Alpha = effectParameters[i].Alpha
            self.EffectParameters[i].Visible = effectParameters[i].Visible
            self.EffectParameters[i].Col = effectParameters[i].Col
        end
    end

    if beamParameters ~= nil then
        for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
            if self.BeamParameters[i] == nil or beamParameters[i] == nil then continue end
            self.BeamParameters[i].Scale = beamParameters[i].Scale
            self.BeamParameters[i].Alpha = beamParameters[i].Alpha
            self.BeamParameters[i].Col = beamParameters[i].Col
            self.BeamParameters[i].Lifetime = beamParameters[i].Lifetime
        end
    end
end

function SWEP:StartEffects()
    --DbgPrint("StartEffects")
    if SERVER then
        error("Dont call me server side")

        return
    end

    if self.EffectsSetup == true then return end
    local effect = self.CurrentEffect
    local effectParams, beamParams = self:SetupEffects()
    self.EffectParameters = effectParams
    self.BeamParameters = beamParams
    if effect ~= nil then
        self:DoEffect(effect)
    end

    self.EffectsSetup = true
end

function SWEP:StopEffects(stopSound)
    self:DoEffect(EFFECT_NONE)
    if SERVER then
        if stopSound == nil then
            stopSound = true
        end

        local snd = self:GetMotorSound()
        if stopSound == true and snd ~= nil and snd ~= NULL then
            snd:ChangeVolume(0, 1.0)
            snd:ChangePitch(50, 1.0)
        end
    else
        if self.ProjectedTexture ~= nil then
            self.ProjectedTexture:Remove()
            self.ProjectedTexture = nil
        end
    end
end

function SWEP:GetWeaponColor(asVector)
    local owner = self:GetOwner()
    local wepColor
    if IsValid(owner) == true and owner:IsPlayer() == true then
        wepColor = owner:GetWeaponColor()
    else
        wepColor = self:GetLastWeaponColor()
    end

    if asVector then return wepColor end

    return Color(wepColor.x * 255, wepColor.y * 255, wepColor.z * 255)
end

function SWEP:UpdateEffects()
    local owner = self:GetOwner()
    local usingViewModel = self:ShouldDrawUsingViewModel()
    if IsValid(owner) and owner:GetActiveWeapon() ~= self then
        if self.ProjectedTexture ~= nil then
            self.ProjectedTexture:Remove()
            self.ProjectedTexture = nil
        end

        return
    end

    self:StartEffects()
    self:UpdateGlow()
    local isMegaPhysCannon = self:IsMegaPhysCannon()
    local wepColor = self:GetWeaponColor()
    local pulseScale = 2
    if self:GetEffectState() == EFFECT_READY then
        pulseScale = 7
    elseif self:GetEffectState() == EFFECT_HOLDING then
        pulseScale = 30
    end

    local pulseTime = CurTime() * pulseScale
    local pulse = 0.5 + (math.sin(pulseTime) * math.cos(pulseTime))
    local effectParameters = self.EffectParameters
    for i = PHYSCANNON_GLOW1, PHYSCANNON_GLOW6 do
        local data = effectParameters[i]
        data.Scale:SetAbsolute(util.RandomFloat(0.075, 0.05) * (30 + (30 * pulse)))
        data.Alpha:SetAbsolute(100 + (util.RandomFloat(75, 128) * pulse))
    end

    for i = PHYSCANNON_ENDCAP1, PHYSCANNON_ENDCAP3 do
        local data = effectParameters[i]
        if data == nil then continue end
        data.Scale:SetAbsolute(util.RandomFloat(3, 10))
        data.Alpha:SetAbsolute(util.RandomFloat(200, 255))
    end

    for i, data in pairs(effectParameters) do
        data.Col = wepColor
    end

    if CLIENT and (isMegaPhysCannon == true or self.CurrentEffect == EFFECT_PULLING) then
        local endCapMax = PHYSCANNON_ENDCAP3
        if usingViewModel == true then
            endCapMax = PHYSCANNON_ENDCAP2
        end

        local i = math.random(PHYSCANNON_ENDCAP1, endCapMax)
        local beamdata = self.BeamParameters[i]
        if self.CurrentEffect ~= EFFECT_HOLDING and self:IsObjectAttached() ~= true and math.random(0, 200) == 0 then
            self:EmitSound("Weapon_MegaPhysCannon.ChargeZap")
            beamdata.Scale:InitFromCurrent(0.5, 0.1)
            beamdata.Lifetime = 0.05 + (math.random() * 0.1)
            if physcannon_glow_mode > 0 then
                local params = self.EffectParameters[i]
                if params == nil then return end
                local lightPos = self:GetLightPosition()
                local brightness = self:GetLightBrightness() + 1.5
                self:EmitLight(physcannon_glow_mode, lightPos, brightness, wepColor)
                self.NextBeamGlow = CurTime() + GLOW_UPDATE_DT
            end
        end
    end
end

function SWEP:ViewModelDrawn(vm)
    self:UpdateDrawUsingViewModel()
    self:DrawEffects(vm)
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    surface.SetTextColor(255, 220, 0, alpha)
    surface.SetFont("LambdaPhyscannonFont")
    local w, h = surface.GetTextSize("m")
    surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
    surface.SetFont("LambdaPhyscannonFont2")
    surface.DrawText("m")
    surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
    surface.SetFont("LambdaPhyscannonFont")
    surface.DrawText("m")
end