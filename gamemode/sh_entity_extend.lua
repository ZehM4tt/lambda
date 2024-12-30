if SERVER then
    AddCSLuaFile()
end

local CurTime = CurTime
local Vector = Vector
local util = util
local ents = ents
local IsValid = IsValid
local table = table
--local DbgPrint = GetLogging("EntityExt")
local ENTITY_META = FindMetaTable("Entity")

-- Credits to CapsAdmin
local function EstimateModelCategory(ent)
    local mdl = ent:GetModel()
    if not mdl then return end
    local headcrabAttachment = ent:LookupAttachment("headcrab")
    if headcrabAttachment ~= 0 then return "zombie" end
    local ziplineAttachment = ent:LookupAttachment("zipline")
    if ziplineAttachment ~= 0 then return "combine" end
    local seq
    seq = ent:LookupSequence("d3_c17_07_Kidnap")
    if seq ~= nil and seq > 0 then return "combine" end
    
    local mdlLower = mdl:lower()
    
    if mdlLower:find("monk.mdl", 1, true) then return "monk" end
    if mdlLower:find("barney.mdl", 1, true) then return "barney" end
    if mdlLower:find("alyx.mdl", 1, true) then return "alyx" end
    if mdlLower:find("gman", 1, true) then return "gman" end
    if mdlLower:find("kleiner", 1, true) then return "kleiner" end
    if mdlLower:find("magnusson", 1, true) then return "magnusson" end
    if mdlLower:find("mossman", 1, true) then return "mossman" end
    if mdlLower:find("odessa", 1, true) then return "odessa" end
    if mdlLower:find("breen", 1, true) then return "breen" end
    if mdlLower:find("eli", 1, true) then return "eli" end
    if mdlLower:find("female", 1, true) or ent:LookupBone("ValveBiped.Bip01_R_Pectoral") or ent:LookupBone("ValveBiped.Bip01_L_Pectoral") then return "female" end

    return "male"
end

function ENTITY_META:GetActivator()
    -- Scripted entities don't have this field so we have to do it ourselves.
    if self.LambdaLastActivator ~= nil then return self.LambdaLastActivator end
    -- Native entities.

    return self:GetInternalVariable("m_hActivator")
end

function ENTITY_META:GetModelCategory()
    if self:IsPlayer() then
        local voiceGroup = self:GetInfo("lambda_voice_group", "auto")
        if voiceGroup ~= "auto" then
            return voiceGroup
        end
    end

    local oldCache = false
    local mdl = self:GetModel()

    if self.CachedModelCategoryModel == nil or self.CachedModelCategoryModel ~= mdl then
        self.CachedModelCategoryModel = mdl
        oldCache = true
    end

    if oldCache == true then
        self.CachedModelCategory = EstimateModelCategory(self)
    end

    return self.CachedModelCategory
end

function ENTITY_META:AddSpawnFlags(flags)
    local newFlags = bit.bor(self:GetSpawnFlags(), flags)
    self:SetKeyValue("spawnflags", newFlags)
end

function ENTITY_META:RemoveSpawnFlags(flags)
    local newFlags = bit.band(self:GetSpawnFlags(), bit.bnot(flags))
    self:SetKeyValue("spawnflags", newFlags)
end

function ENTITY_META:SetSpawnFlags(flags)
    self:SetKeyValue("spawnflags", flags)
end

function ENTITY_META:IsDoor()
    local class = self:GetClass()

    return class == "prop_door_rotating" or class == "func_door" or class == "func_door_rotating"
end

function ENTITY_META:GetModelInfo()
    local mdl = self:GetModel()
    if self.CachedModelDataInfo ~= nil and self.CachedModelDataFile == mdl then return self.CachedModelDataInfo end
    local mdlInfo = util.GetModelInfo(mdl)

    if mdlInfo ~= nil and mdlInfo.KeyValues ~= nil then
        self.CachedModelDataInfo = util.KeyValuesToTable(mdlInfo.KeyValues)
        self.CachedModelDataFile = mdl
    end

    return self.CachedModelDataInfo
end

function ENTITY_META:ShouldShootMissTarget(attacker)
    if self:IsPlayer() == false then return false end
    local curTime = CurTime()

    if self.TargetFindTime == nil then
        self.TargetFindTime = curTime + util.RandomFloat(3, 5)

        return false
    end

    if curTime > self.TargetFindTime then
        self.TargetFindTime = curTime + util.RandomFloat(3, 5)

        return true
    end

    return false
end

local MISS_TARGET_RADIUS = Vector(150, 150, 100)

function ENTITY_META:FindMissTarget()
    local pos = self:GetPos()
    local nearby = ents.FindInBox(pos - MISS_TARGET_RADIUS, pos + MISS_TARGET_RADIUS)
    local candidates = {}
    local isPlayer = self:IsPlayer()

    for _, v in pairs(nearby) do
        local class = v:GetClass()

        if isPlayer then
            if self:InsideViewCone(v) == false then continue end
        end

        if class == "prop_dynamic" or class == "prop_physics" or class == "physics_prop" then
            table.insert(candidates, v)
        end

        if #candidates >= 16 then break end
    end

    if #candidates == 0 then return nil end

    return table.Random(candidates)
end

local ITEM_CLASSES = {
    ["item_ammo_357"] = true,
    ["item_ammo_357_large"] = true,
    ["item_ammo_ar2"] = true,
    ["item_ammo_ar2_altfire"] = true,
    ["item_ammo_ar2_large"] = true,
    ["item_ammo_crate"] = true,
    ["item_ammo_crossbow"] = true,
    ["item_ammo_pistol"] = true,
    ["item_ammo_pistol_large"] = true,
    ["item_ammo_smg1"] = true,
    ["item_ammo_smg1_grenade"] = true,
    ["item_ammo_smg1_large"] = true,
    ["item_battery"] = true,
    ["item_box_buckshot"] = true,
    ["item_dynamic resupply"] = true,
    ["item_healthcharger"] = true,
    ["item_healthkit"] = true,
    ["item_healthvial"] = true,
    ["item_item_crate"] = true,
    ["item_rpg_round"] = true,
    ["item_suit"] = true,
    ["item_suitcharger"] = true,
    ["weapon_frag"] = true,
    ["weapon_slam"] = true
}

function ENTITY_META:IsItem()
    local class = self:GetClass()

    return ITEM_CLASSES[class] == true
end

function ENTITY_META:PhysicsImpactSound(chan, vol, speed)
    local mdlInfo = self:GetModelInfo()
    if mdlInfo == nil then return end
    local solid = mdlInfo["solid"]
    if solid == nil then return end
    local surfaceprop = solid["surfaceprop"]
    if surfaceprop == nil then return end
    local data = surfacedata.GetByName(surfaceprop)
    if data == nil then return end
    local snd = data["impactsoft"]

    if snd ~= nil then
        self:EmitSound(snd)
    end
end

DOOR_STATE_CLOSED = 0
DOOR_STATE_OPENING = 1
DOOR_STATE_OPEN = 2
DOOR_STATE_CLOSING = 3

function ENTITY_META:GetDoorState()
    return self:GetInternalVariable("m_eDoorState")
end

function ENTITY_META:IsDoorClosing()
    return self:GetDoorState() == DOOR_STATE_CLOSING
end

function ENTITY_META:IsDoorClosed()
    return self:GetDoorState() == DOOR_STATE_CLOSED
end

function ENTITY_META:IsDoorOpening()
    return self:GetDoorState() == DOOR_STATE_OPENING
end

function ENTITY_META:IsDoorOpen()
    return self:GetDoorState() == DOOR_STATE_OPEN
end

function ENTITY_META:IsDoorLocked()
    return self:GetInternalVariable("m_bLocked") or false
end

OVERLAY_TEXT_BIT = 0x00000001 -- show text debug overlay for this entity
OVERLAY_NAME_BIT = 0x00000002 -- show name debug overlay for this entity
OVERLAY_BBOX_BIT = 0x00000004 -- show bounding box overlay for this entity
OVERLAY_PIVOT_BIT = 0x00000008 -- show pivot for this entity
OVERLAY_MESSAGE_BIT = 0x00000010 -- show messages for this entity
OVERLAY_ABSBOX_BIT = 0x00000020 -- show abs bounding box overlay
OVERLAY_RBOX_BIT = 0x00000040 -- show the rbox overlay
OVERLAY_SHOW_BLOCKSLOS = 0x00000080 -- show entities that block NPC LOS
OVERLAY_ATTACHMENTS_BIT = 0x00000100 -- show attachment points
OVERLAY_AUTOAIM_BIT = 0x00000200 -- Display autoaim radius
OVERLAY_NPC_SELECTED_BIT = 0x00001000 -- the npc is current selected
OVERLAY_NPC_NEAREST_BIT = 0x00002000 -- show the nearest node of this npc
OVERLAY_NPC_ROUTE_BIT = 0x00004000 -- draw the route for this npc
OVERLAY_NPC_TRIANGULATE_BIT = 0x00008000 -- draw the triangulation for this npc
OVERLAY_NPC_ZAP_BIT = 0x00010000 -- destroy the NPC
OVERLAY_NPC_ENEMIES_BIT = 0x00020000 -- show npc's enemies
OVERLAY_NPC_CONDITIONS_BIT = 0x00040000 -- show NPC's current conditions
OVERLAY_NPC_SQUAD_BIT = 0x00080000 -- show npc squads
OVERLAY_NPC_TASK_BIT = 0x00100000 -- show npc task details
OVERLAY_NPC_FOCUS_BIT = 0x00200000 -- show line to npc's enemy and target
OVERLAY_NPC_VIEWCONE_BIT = 0x00400000 -- show npc's viewcone
OVERLAY_NPC_KILL_BIT = 0x00800000 -- kill the NPC running all appropriate AI.
OVERLAY_WC_CHANGE_ENTITY = 0x01000000 -- object changed during WC edit
OVERLAY_BUDDHA_MODE = 0x02000000 -- take damage but don't die
OVERLAY_NPC_STEERING_REGULATIONS = 0x04000000 -- Show the steering regulations associated with the NPC
OVERLAY_TASK_TEXT_BIT = 0x08000000 -- show task and schedule names when they start
OVERLAY_PROP_DEBUG = 0x10000000
OVERLAY_NPC_RELATION_BIT = 0x20000000 -- show relationships between target and all children
OVERLAY_VIEWOFFSET = 0x40000000 -- show view offset

function ENTITY_META:AddDebugOverlays(f)
    local flags = self:GetDebugOverlays()
    flags = bit.bor(flags, tonumber(f or 0))
    self:SetSaveValue("m_debugOverlays", flags)
end

function ENTITY_META:RemoveDebugOverlays(f)
    local flags = self:GetDebugOverlays()
    flags = bit.band(flags, bit.bnot(f))
    self:SetSaveValue("m_debugOverlays", flags)
end

function ENTITY_META:GetDebugOverlays()
    return tonumber(self:GetInternalVariable("m_debugOverlays", 0))
end

-- Vehicles
function ENTITY_META:IsGunEnabled()
    return self:GetInternalVariable("EnableGun", false)
end

-- Damage
function ENTITY_META:GetLastDamageType()
    return self.LastReceivedDamageType or 0
end

function ENTITY_META:SetLastDamageType(dmgType)
    self.LastReceivedDamageType = dmgType
end

-- caps
FCAP_MUST_SPAWN = 0x00000001 -- Spawn after restore
FCAP_ACROSS_TRANSITION = 0x00000002 -- should transfer between transitions
-- UNDONE: This will ignore transition volumes (trigger_transition), but not the PVS!!!
FCAP_FORCE_TRANSITION = 0x00000004 -- ALWAYS goes across transitions
FCAP_NOTIFY_ON_TRANSITION = 0x00000008 -- Entity will receive Inside/Outside transition inputs when a transition occurs
FCAP_IMPULSE_USE = 0x00000010 -- can be used by the player
FCAP_CONTINUOUS_USE = 0x00000020 -- can be used by the player
FCAP_ONOFF_USE = 0x00000040 -- can be used by the player
FCAP_DIRECTIONAL_USE = 0x00000080 -- Player sends +/- 1 when using (currently only tracktrains)
-- NOTE: Normally +USE only works in direct line of sight.  Add these caps for additional searches
FCAP_USE_ONGROUND = 0x00000100
FCAP_USE_IN_RADIUS = 0x00000200
FCAP_SAVE_NON_NETWORKABLE = 0x00000400
FCAP_MASTER = 0x10000000 -- Can be used to "master" other entities (like multisource)
FCAP_WCEDIT_POSITION = 0x40000000 -- Can change position and update Hammer in edit mode
FCAP_DONT_SAVE = 0x80000000 -- Don't save this

function ENTITY_META:HasObjectCaps(caps)
    return bit.band(self:ObjectCaps(), caps) ~= 0
end

function ENTITY_META:GetObjectCaps()
    return self:ObjectCaps()
end

function ENTITY_META:EnableRespawn(state, delay)
    -- On shutdown this actually errors thats why this check exists.
    if not IsValid(self) then return end

    if state == true then
        self:CallOnRemove("LambdaRespawn", function(ent)
            GAMEMODE:RespawnObject(ent, {
                delay = delay,
                persistent = true
            })
        end)
    else
        self:RemoveCallOnRemove("LambdaRespawn")
    end
end

function ENTITY_META:GetKeyValueTable()
    return table.Copy(self.LambdaKeyValues or {})
end

CHAR_TEX_ANTLION = 'A'
CHAR_TEX_BLOODYFLESH = 'B'
CHAR_TEX_CONCRETE = 'C'
CHAR_TEX_DIRT = 'D'
CHAR_TEX_EGGSHELL = 'E' -- the egg sacs in the tunnels in ep2.
CHAR_TEX_FLESH = 'F'
CHAR_TEX_GRATE = 'G'
CHAR_TEX_ALIENFLESH = 'H'
CHAR_TEX_CLIP = 'I'
CHAR_TEX_SNOW = 'J'

function ENTITY_META:IsVPhysicsFlesh()
    if CLIENT then
        -- Since they dont have physics this is our best bet.
        local class = self:GetClass()
        if class == "prop_ragdoll" then return true end
    end

    for i = 0, self:GetPhysicsObjectCount() - 1 do
        local phys = self:GetPhysicsObjectNum(i)
        local mat = phys:GetMaterial()
        --DbgPrint("MAT:" .. tostring(mat))
        local surfdata = surfacedata.GetByName(mat)

        if surfdata ~= nil then
            local matType = surfdata["gamematerial"]
            if matType == CHAR_TEX_ANTLION or matType == CHAR_TEX_FLESH or matType == CHAR_TEX_BLOODYFLESH or matType == CHAR_TEX_ALIENFLESH then return true end
        end
    end

    return false
end

function ENTITY_META:GetRootMoveParent()
    local ent = self
    local parent = ent:GetMoveParent()

    while IsValid(parent) do
        ent = parent
        parent = ent:GetMoveParent()
    end

    return ent
end

function ENTITY_META:GetPhysMass()
    local mass = 0.0

    for i = 0, self:GetPhysicsObjectCount() - 1 do
        local phys = self:GetPhysicsObjectNum(i)

        if IsValid(phys) then
            mass = mass + phys:GetMass()
        end
    end

    return mass
end

function ENTITY_META:CanBecomeRagdoll()
    local seq = self:SelectWeightedSequence(ACT_DIERAGDOLL)
    if seq == ACT_INVALID then return false end
    if self:IsFlagSet(FL_TRANSRAGDOLL) then return false end

    return true
end

function ENTITY_META:CopyAnimationDataFrom(other)
    self:SetModel(other:GetModel() or "")
    self:SetCycle(other:GetCycle())
    self:RemoveEffects(self:GetEffects()) -- Clear, no set available.
    self:AddEffects(other:GetEffects())
    self:SetSequence(other:GetSequence())
    local animTime = other:GetInternalVariable("m_flAnimTime")
    self:SetSaveValue("m_flAnimTime", animTime)
    self:SetSkin(other:GetSkin())
end

function ENTITY_META:CanTakeDamage()
    local data = self:GetInternalVariable("m_takedamage")
    if data ~= nil then
        -- DAMAGE_NO
        return data ~= 0
    end

    return true
end

function ENTITY_META:SetBlocksLOS(bBlocksLOS)
    if bBlocksLOS == true then
        self:RemoveEFlags(EFL_DONTBLOCKLOS)
    else
        self:AddEFlags(EFL_DONTBLOCKLOS)
    end
end

function ENTITY_META:BlocksLOS()
    return self:IsEFlagSet(EFL_DONTBLOCKLOS) == false
end

function ENTITY_META:DispatchResponse(response)
    self:Input("DispatchResponse", self, self, response)
end

ENTITY_DISSOLVE_NORMAL = 0
ENTITY_DISSOLVE_ELECTRICAL = 1
ENTITY_DISSOLVE_ELECTRICAL_LIGHT = 2
ENTITY_DISSOLVE_CORE = 3

function ENTITY_META:Dissolve(dissolveType)
    if dissolveType == nil then
        dissolveType = ENTITY_DISSOLVE_NORMAL
    end

    self:SetOwner(NULL)
    local name = self:GetName()

    if name == nil or name == "" then
        name = "dissolve_" .. tostring(self:EntIndex())
        self:SetName(name)
    end

    local dissolver = ents.Create("env_entity_dissolver")
    dissolver:SetKeyValue("target", name)
    dissolver:SetKeyValue("dissolvetype", tostring(dissolveType))
    -- Ensure all clients receive this.
    dissolver:AddEFlags(EFL_FORCE_CHECK_TRANSMIT)
    dissolver:Spawn()
    dissolver:Activate()
    dissolver:Fire("Dissolve", name, 0)
    dissolver:Fire("Kill", "", 0.1)

    if self:IsNPC() then
        -- Play any appropriate noises when we start to dissolve
        if dissolveType == ENTITY_DISSOLVE_ELECTRICAL or dissolveType == ENTITY_DISSOLVE_ELECTRICAL_LIGHT then
            self:DispatchResponse("TLK_ELECTROCUTESCREAM")
        else
            self:DispatchResponse("TLK_DISSOLVESCREAM")
        end
    end
end