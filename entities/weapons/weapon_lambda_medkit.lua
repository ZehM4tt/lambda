if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("Medkit")
SWEP.PrintName = "Medkit"
SWEP.Author = "Lambda"
SWEP.Instructions = ""
SWEP.Spawnable = true
SWEP.AdminOnly = true
SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = -1
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "lambda_health"
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Ammo = "none"
SWEP.HoldType = "slam"
SWEP.Weight = -1
SWEP.AutoSwitchTo = false
SWEP.AutoSwitchFrom = true
SWEP.UseHands = true
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"

if CLIENT then
    SWEP.Slot = 5
    SWEP.SlotPos = 2
    SWEP.DrawAmmo = true
    SWEP.DrawCrosshair = true
    SWEP.DrawWeaponInfoBox = false
    SWEP.BounceWeaponIcon = false
    SWEP.RenderGroup = RENDERGROUP_OPAQUE
    SWEP.ViewModelFOV = 54
end

game.AddAmmoType({
    name = "lambda_health",
    dmgtype = DMG_DIRECT,
    tracer = TRACER_NONE,
    plydmg = -10,
    npcdmg = -10,
    force = 0,
    minsplash = 0,
    maxsplash = 0
})

local TRACE_LEN = 76
local HEAL_AMOUNT = 10
local REVIVE_AMOUNT = 50

local STATE_IDLE = 0
local STATE_CHARGING = 1
local STATE_RECHARGING = 2

local RECHARGE_DELAY = 0.001
local RECHARGE_AMOUNT = 0.025
local RECHARGE_TARGET = 100

local HEAL_DELAY = 0.5
local PLAYER_HULL_MINS = Vector(-16, -16, 0)
local PLAYER_HULL_MAXS = Vector(16, 16, 72)
local CUSTOM_MAT_NAME = "LambdaMedKitMat" .. math.random(1, 1000)

--
-- ConVars
-- Missing convars.
--
-- Code
function SWEP:Precache()
end

function SWEP:SetupDataTables()
    DbgPrint(self, "SetupDataTables")
    self:NetworkVar("Float", 0, "NextHealTime")
    self:NetworkVar("Float", 1, "Energy")
    self:NetworkVar("Float", 2, "ChargeEnergy")
    self:NetworkVar("Float", 3, "NextRechargeTime")
    self:NetworkVar("Int", 0, "State")
end

function SWEP:Initialize()
    DbgPrint(self, "Initialize")
    self:Precache()
    self:SetHoldType(self.HoldType)
    self.AmmoID = game.GetAmmoID(self.Primary.Ammo)
    if SERVER then
        self:SetEnergy(RECHARGE_TARGET)
        self:SetNextRechargeTime(CurTime() + RECHARGE_DELAY)
    else
        -- For interpolation.
        self.EnergyLevel = RECHARGE_TARGET
        self.ChargeBlink = 0

        hook.Add("PreDrawPlayerHands", self, self.PreDrawPlayerHands)
        hook.Add("PostDrawPlayerHands", self, self.PostDrawPlayerHands)
    end
end

function SWEP:Think()
    local owner = self:GetOwner()

    if IsValid(owner) and owner:KeyDown(IN_ATTACK2) == false and not self:IsCurrentlyIdle() then
        self:StopCharging()
    end
end

function SWEP:Recharge()
    if CurTime() < self:GetNextRechargeTime() then
        return
    end
    self:SetNextRechargeTime(CurTime() + RECHARGE_DELAY)

    local currentEnergy = self:GetEnergy()
    local energy = math.Clamp(currentEnergy + RECHARGE_AMOUNT, 0, RECHARGE_TARGET)
    self:SetEnergy(energy)

    if energy >= RECHARGE_TARGET then
        self:SetState(STATE_IDLE)
        self:EmitSound("buttons/button18.wav", 50, 250, 0.2)
        self.ChargeBlink = 1000
        return
    end
end

function SWEP:StartRecharging()
    if self:GetState() == STATE_RECHARGING then
        return
    end
    self:SetState(STATE_RECHARGING)
    self:SetNextRechargeTime(CurTime() + 1)
    DbgPrint("Starting recharge")
end

-- Ugly hack, SWEP.Think is not what it seems.
function SWEP:PredictedThink()
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local state = self:GetState()
    if state == STATE_IDLE then
        return
    elseif state == STATE_RECHARGING then
        self:Recharge()
    end
end

function SWEP:OnRemove()
    DbgPrint(self, "OnRemove")
end

local TRACE_HULL_MINS = Vector(-1, -1, -1)
local TRACE_HULL_MAXS = Vector(1, 1, 1)

function SWEP:GetActorForHealing()
    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos = startPos + (owner:GetAimVector() * TRACE_LEN)

    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = TRACE_HULL_MINS,
        maxs = TRACE_HULL_MAXS,
        mask = MASK_SHOT_HULL,
        filter = owner
    })

    if tr.Hit == true and IsValid(tr.Entity) and (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) then return tr.Entity end

    return nil
end

function SWEP:GetActorForReviving()
    local ragdoll = nil
    local owner = self:GetOwner()
    local startPos = owner:GetShootPos()
    local endPos = startPos + (owner:GetAimVector() * TRACE_LEN)

    local tr = util.TraceHull({
        start = startPos,
        endpos = endPos,
        mins = TRACE_HULL_MINS * 5,
        maxs = TRACE_HULL_MAXS * 5,
        mask = MASK_SHOT_HULL,
        filter = owner
    })

    if IsValid(tr.Entity) and tr.Entity:IsRagdoll() then
        ragdoll = tr.Entity
    end

    return ragdoll
end

function SWEP:IsCurrentlyIdle()
    local currentState = self:GetState()
    return currentState == STATE_IDLE or currentState == STATE_RECHARGING
end

function SWEP:CanPrimaryAttack()
    return self:IsCurrentlyIdle()
end

function SWEP:CanHealActor(actor)
    if actor:Health() >= actor:GetMaxHealth() then return false end
    local healAmount = HEAL_AMOUNT

    if actor:Health() + healAmount > actor:GetMaxHealth() then
        healAmount = actor:GetMaxHealth() - actor:Health()
    end

    local energy = self:GetEnergy()
    if energy - healAmount < 0 then return false end

    return true
end

function SWEP:FindGroundPosition(actor)
    local owner = actor:GetOwner()
    if not IsValid(owner) then return actor:GetPos() end
    local wepOwner = self:GetOwner()
    local startPos = actor:GetPos()

    local filter = function(e)
        if e == actor or e == owner or e == wepOwner or e:IsPlayer() then return false end
    end

    -- Trace line down to find ground first.
    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos - Vector(0, 0, 32),
        filter = filter
    })

    startPos = tr.HitPos
    local mins = Vector(-16, -16, 0)
    local maxs = Vector(16, 16, 1)
    local offsetZ = 0

    while tr.Fraction ~= 1 and offsetZ < 8 do
        tr = util.TraceHull({
            start = startPos + Vector(0, 0, offsetZ),
            endpos = startPos + Vector(0, 0, offsetZ + 1),
            mins = mins,
            maxs = maxs,
            filter = filter
        })

        offsetZ = offsetZ + 1
    end

    local pos

    if offsetZ == 8 then
        -- DbgPrint("No ground found, using reviving player ground")
        pos = wepOwner:GetPos()
        -- Put him as far forward as we can go, begin at the end and work towards the player
        local fwdOffset = TRACE_LEN
        local fwdVector = wepOwner:GetAimVector()

        while fwdOffset >= 0 do
            local fwd = fwdVector * fwdOffset
            local fwd1 = fwdVector * fwdOffset
            startPos = pos + fwd
            startPos.z = pos.z
            local endPos = pos + fwd1
            endPos.z = pos.z

            tr = util.TraceHull({
                start = startPos,
                endpos = endPos,
                mins = PLAYER_HULL_MINS,
                maxs = PLAYER_HULL_MAXS,
                filter = filter
            })

            if tr.Fraction == 1 then
                --DbgPrint("Found suitable spawn position")
                --debugoverlay.Box(tr.HitPos, PLAYER_HULL_MINS, PLAYER_HULL_MAXS, 5, Color( 0, 255, 0 ))
                pos = tr.HitPos
                break
            end

            --debugoverlay.Box(tr.HitPos, PLAYER_HULL_MINS, PLAYER_HULL_MAXS, 5, Color( 255, 0, 0 ))
            fwdOffset = fwdOffset - 4
        end
        -- If we found a spot the loop breaks and pos is assigned to the empty space, otherwise
        -- pos is the player pos at this point.
    else
        pos = startPos + Vector(0, 0, offsetZ)
    end

    debugoverlay.Cross(pos, 20, 10, Color(255, 0, 0), true)

    return pos
end

function SWEP:CanReviveActor(actor)
    local owner = actor:GetOwner()
    if not IsValid(owner) then return false end
    if actor:GetNWBool("IsReviving", false) == true then return false end
    local startPos = self:FindGroundPosition(actor)
    local offsetZ = PLAYER_HULL_MAXS.z -- Only standing works.

    local tr = util.TraceLine({
        start = startPos,
        endpos = startPos + Vector(0, 0, offsetZ),
        filter = {actor, owner, self:GetOwner()}
    })

    if tr.Fraction ~= 1 then return false end

    return true
end

function SWEP:ConsumeEnergy(amount)
    local energy = self:GetEnergy()
    energy = math.Clamp(energy - amount, 0, 100)
    self:SetEnergy(energy)
end

function SWEP:DryFire()
    if (CLIENT and IsFirstTimePredicted() == true) or game.SinglePlayer() == true then
        self:EmitSound("items/medshotno1.wav")
    end
end

function SWEP:PrimaryAttack()
    DbgPrint(self, "PrimaryAttack")
    if self:CanPrimaryAttack() == false then return end
    local actor = self:GetActorForHealing()

    if not IsValid(actor) or self:CanHealActor(actor) == false then
        self:SetNextPrimaryFire(CurTime() + HEAL_DELAY)
        self:SetNextSecondaryFire(CurTime() + HEAL_DELAY)
        self:DryFire()

        return
    end

    local healAmount = HEAL_AMOUNT

    if actor:Health() + healAmount > actor:GetMaxHealth() then
        healAmount = actor:GetMaxHealth() - actor:Health()
    end

    actor:SetHealth(actor:Health() + healAmount)
    self:EmitSound("items/medshot4.wav")
    self:ConsumeEnergy(healAmount)
    self:SetNextPrimaryFire(CurTime() + HEAL_DELAY)
    self:SetNextSecondaryFire(CurTime() + HEAL_DELAY)
    self:SetNextRechargeTime(CurTime() + 2)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:StartRecharging()
    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)
end

function SWEP:CanSecondaryAttack()
    return true
end

local CHARGE_TIME = 2.0
local STEP_TIME = 0.1
local TOTAL_STEPS = CHARGE_TIME / STEP_TIME
local CHARGE_AMOUNT = REVIVE_AMOUNT / TOTAL_STEPS

function SWEP:CreateChargeSound()
    if self.SndCharge == nil or self.SndCharge == NULL then
        local filter

        if SERVER then
            filter = RecipientFilter()
            filter:AddAllPlayers()
        end

        self.SndCharge = CreateSound(self, "lambda/defibrillator_charge.wav", filter)
    end

    DbgPrint(self, "SND: " .. tostring(self.SndCharge))

    return self.SndCharge
end

function SWEP:EmitChargingSound()
    local snd = self:CreateChargeSound()

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
end

function SWEP:StopChargeSound()
    if self.SndCharge ~= nil and self.SndCharge ~= NULL then
        self.SndCharge:ChangeVolume(0.0, 0.0)
        self.SndCharge:Stop()
    end
end

function SWEP:StartCharging()
    if not self:IsCurrentlyIdle() then return end
    self:SetChargeEnergy(0.0)
    self:EmitChargingSound()
    self:SetState(STATE_CHARGING)
    self:SetNextSecondaryFire(CurTime() + STEP_TIME)
end

function SWEP:StopCharging()
    self:StopChargeSound()
    self:StartRecharging()
    self:SetChargeEnergy(0.0)
    self:SetNextSecondaryFire(CurTime() + 0.5)
end

function SWEP:UpdateCharging()
    local current = self:GetChargeEnergy()
    current = current + CHARGE_AMOUNT
    self:SetChargeEnergy(current)
    if current >= REVIVE_AMOUNT then
        return self:ReleaseCharge()
    end
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:SetNextSecondaryFire(CurTime() + STEP_TIME)
end

sound.Add({
    name = "lambda_player_revive",
    channel = CHAN_STATIC,
    volume = 1,
    level = 80,
    pitch = {95, 110},
    sound = "ambient/energy/electric_loop.wav"
})

function SWEP:ReleaseCharge()
    local ragdoll = self:GetActorForReviving()

    if not IsValid(ragdoll) or ragdoll:GetNWBool("IsReviving", false) == true then
        self:SetNextPrimaryFire(CurTime() + 1)
        self:SetNextSecondaryFire(CurTime() + 1)
        self:StopCharging()
        self:StartRecharging()
        return
    end

    ragdoll:SetNWBool("IsReviving", true)
    self:ConsumeEnergy(self:GetChargeEnergy())
    self:StopCharging()
    self:EmitSound("lambda/defibrillator_release.wav")
    self:SetNextPrimaryFire(CurTime() + 1)
    self:SetNextSecondaryFire(CurTime() + 1)
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:StartRecharging()

    local owner = self:GetOwner()
    owner:SetAnimation(PLAYER_ATTACK1)
    local ragdollOwner = ragdoll:GetOwner()

    if SERVER then
        local respawnTime = 2.0
        ragdoll.RespawnTime = CurTime() + respawnTime
        local respawnPos = self:FindGroundPosition(ragdoll)
        local respawnAng = ragdoll:GetAngles()
        -- We set the position of the player to the current ragdoll position.
        ragdollOwner:SetPos(respawnPos)
        ragdollOwner:SetAngles(respawnAng)
        -- NOTE: The reason we do this is to make the player emit a hurt sound.
        --       If the health is <= 0 it wouldn't do anything.
        ragdollOwner:SetHealth(2)
        ragdollOwner:TakeDamage(1, self, self)
        ragdoll:EmitSound("lambda_player_revive")

        for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
            local bone = ragdoll:GetPhysicsObjectNum(i)

            if IsValid(bone) then
                bone:EnableCollisions(false)
            end
        end

        -- Now we interpolate the ragdoll towards the player.
        hook.Add("Think", ragdoll, function(rag)
            local ply = rag:GetOwner()

            if not IsValid(ply) then
                hook.Remove("Think", rag)

                return
            end

            ply:SetPos(respawnPos)
            ply:SetAngles(respawnAng)
            ply:SetAnimation(PLAYER_WALK)
            ply:AnimRestartMainSequence()
            local curTime = CurTime()
            local left = ragdoll.RespawnTime - curTime

            if left < 0 then
                left = 0
            end

            for i = 0, rag:GetPhysicsObjectCount() - 1 do
                local bone = rag:GetPhysicsObjectNum(i)

                if IsValid(bone) then
                    local boneId = rag:TranslatePhysBoneToBone(i)
                    local bp, ba = ply:GetBonePosition(boneId)

                    if bp and ba then
                        local deltaPos = bp - bone:GetPos()
                        local ang = LerpAngle(FrameTime(), bone:GetAngles(), ba)
                        bone:SetAngles(ang)
                        bone:SetVelocity(deltaPos * 3)
                    end
                end
            end

            if CurTime() < rag.RespawnTime then return end
            rag:StopSound("lambda_player_revive")
            -- No longer need this hook.
            hook.Remove("Think", rag)
            ply:Revive(respawnPos, respawnAng, 30)
        end)
    end
end

function SWEP:SecondaryAttack()
    if self:CanSecondaryAttack() == false then return end
    local ragdoll = self:GetActorForReviving()

    if ragdoll == nil or self:GetEnergy() < REVIVE_AMOUNT or self:CanReviveActor(ragdoll) == false then
        self:SetNextPrimaryFire(CurTime() + HEAL_DELAY)
        self:SetNextSecondaryFire(CurTime() + HEAL_DELAY)
        self:DryFire()
        self:StopCharging()
        self:StartRecharging()
        return
    end

    local currentState = self:GetState()

    if self:IsCurrentlyIdle() then
        self:StartCharging()
    elseif currentState == STATE_CHARGING then
        self:UpdateCharging()
    end
end

function SWEP:Equip()
    DbgPrint("Equip")
end

function SWEP:Deploy()
    DbgPrint("Deploy")
    self:SendWeaponAnim(ACT_VM_DEPLOY)

    return true
end

function SWEP:Holster(ent)
    DbgPrint(self, "Holster")

    if IsFirstTimePredicted() then
        self:SendWeaponAnim(ACT_VM_HOLSTER)
    end

    return true
end

function SWEP:DrawWorldModel()
    self:DrawModel()
end

function SWEP:DrawWorldModelTranslucent()
    self:DrawModel()
end

function SWEP:PreDrawViewModel(vm, wep, ply)
    -- Update the glow based on energy.
    local energy = self:GetEnergy() - self:GetChargeEnergy()
    self.EnergyLevel = math.Approach(self.EnergyLevel or 0, energy, FrameTime() * 100)

    self.ChargeBlink = math.Approach(self.ChargeBlink, 0, FrameTime() * 350)
    local glow = math.Clamp(self.EnergyLevel / 100, 0, 1)
    local c = Color(0, 255, 0, 255)
    c.r = (255 * (1 - glow)) * 1
    c.g = ((1000 * glow) - (c.r * 0.8))
    c.b = self.ChargeBlink

    -- Pulse the glow.
    local pulse = math.abs(math.sin(CurTime() * 2) * 255) / 500
    pulse = pulse + 0.2
    c.r = c.r * pulse
    c.g = c.g * pulse

    if self.Mat == nil then
        local oldMat = vm:GetMaterials()
        if oldMat == nil or #oldMat == 0 then
            self.Mat = false
            return
        end
        local oldMatFile = oldMat[1]

        local fileData = file.Read("materials/" .. oldMatFile .. ".vmt", "GAME")
        if fileData == nil then
            self.Mat = false
            return
        end

        local matData = util.KeyValuesToTable(fileData, false, true)
        if matData == nil then
            self.Mat = false
            return
        end

        -- Copy the material.
        self.Mat = CreateMaterial(CUSTOM_MAT_NAME, "VertexLitGeneric", matData)
    end

    if self.Mat then
        self.Mat:SetVector("$selfillumtint", Vector(c.r / 255, c.g / 255, c.b / 255))
    end

    render.MaterialOverride(self.Mat)
end

function SWEP:PostDrawViewModel(vm, wep, ply)
    render.MaterialOverride(nil)
end

function SWEP:PreDrawPlayerHands(hands, vm, ply, wep)
    render.MaterialOverride(nil)
end

function SWEP:PostDrawPlayerHands(hands, vm, ply, wep)
    render.MaterialOverride(nil)
end

function SWEP:Ammo1()
    local energy = math.Clamp(self:GetEnergy() - self:GetChargeEnergy(), 0, 100)

    return energy
end

function SWEP:Ammo2()
    return 0
end

if CLIENT then
    surface.CreateFont("LambdaMedkitFont", {
        font = "HalfLife2",
        size = util.ScreenScaleH(64),
        weight = 0,
        blursize = 0,
        scanlines = 0,
        antialias = true,
        additive = true
    })

    surface.CreateFont("LambdaMedkitFont2", {
        font = "HalfLife2",
        size = util.ScreenScaleH(64),
        weight = 0,
        blursize = util.ScreenScaleH(4),
        scanlines = 2,
        antialias = true,
        additive = true
    })
end

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
    surface.SetTextColor(255, 220, 0, alpha)
    surface.SetFont("LambdaMedkitFont")
    local w, h = surface.GetTextSize("+")
    surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
    surface.SetFont("LambdaMedkitFont2")
    surface.DrawText("+")
    surface.SetTextPos(x + (wide / 2) - (w / 2), y + (tall / 2) - (h / 2))
    surface.SetFont("LambdaMedkitFont")
    surface.DrawText("+")
end
