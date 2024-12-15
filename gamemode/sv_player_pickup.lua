local DbgPrintPickup = GetLogging("Pickup")
local DbgPrint = DbgPrintPickup
local util = util
local ents = ents
local IsValid = IsValid
local table = table
local CurTime = CurTime

LAMBDA_OBJECT_RESPAWN_QUEUE = LAMBDA_OBJECT_RESPAWN_QUEUE or {}

function GM:InitializeItemRespawn()
    LAMBDA_OBJECT_RESPAWN_QUEUE = {}
end

function GM:InitializePlayerPickup(ply)
    ply.ObjectPickupTable = {}
end

function GM:RegisterPlayerItemPickup(ply, item)
    item.UniqueEntityId = item.UniqueEntityId or self:GetNextUniqueEntityId()
    ply.ObjectPickupTable[item.UniqueEntityId] = true
end

local function respawnItem(gm, data)
    DbgPrintPickup("Respawning object " .. data.class)
    local e = ents.Create(data.class)
    e.UniqueEntityId = data.uniqueId
    e:SetPos(data.pos)
    e:SetAngles(data.ang)
    e:SetName(data.name)
    e:SetSpawnFlags(data.spawnflags or 0)

    for k, outputs in pairs(data.outputs or {}) do
        for _, output in pairs(outputs) do
            local outputStr = k .. " " .. output
            e:Fire("AddOutput", outputStr)
        end
    end

    -- FIXME: This is a bit hacky as calling Entity:Fire will not call our hooks
    -- to populate this.
    e.EntityOutputs = data.outputs
    e:Spawn()
    e:Activate()

    -- Keep it as level designer placed object.
    if data.levelDesignerPlaced == true then
        gm:InsertLevelDesignerPlacedObject(e)
    end

    if data.options.persistent == true then
        e:EnableRespawn(true, data.options.delay)
    end

    if data.options.delay > 0.0 then
        e:EmitSound("AlyxEmp.Charge")
        local effectPos = e:GetPos() + e:OBBCenter()
        local effectdata = EffectData()
        effectdata:SetOrigin(effectPos)
        effectdata:SetScale(1)
        effectdata:SetEntity(e)
        effectdata:SetMagnitude(1)
        effectdata:SetRadius(1)
        util.Effect("cball_explode", effectdata)
    end
end

function GM:UpdateItemRespawn()
    local curTime = CurTime()

    for k, v in pairs(LAMBDA_OBJECT_RESPAWN_QUEUE) do
        if curTime >= v.respawnTime then
            respawnItem(self, v)
            table.remove(LAMBDA_OBJECT_RESPAWN_QUEUE, k)
        end
    end
end

function GM:RespawnObject(obj, options)
    options = options or {}
    options.delay = options.delay or self:CallGameTypeFunc("GetItemRespawnTime")

    if options.persistent == nil then
        options.persistent = false
    end

    DbgPrintPickup("Respawning object " .. tostring(obj) .. " in " .. tostring(options.delay) .. " seconds")

    for _, v in pairs(LAMBDA_OBJECT_RESPAWN_QUEUE) do
        if v.item == obj then
            -- Only update time.
            DbgPrintPickup("Updating respawn of " .. tostring(obj))
            v.respawnTime = CurTime() + options.delay

            return
        end
    end

    -- Create new entry in queue.
    local data = self:GetLevelDesignerPlacedData(obj)

    if data == nil then
        data = {}
        data.class = obj:GetClass()
        data.pos = obj:GetPos()
        data.ang = obj:GetAngles()
        data.name = obj:GetName()
        data.levelDesignerPlaced = false
        data.options = options
        data.outputs = table.Copy(obj.EntityOutputs or {})
    else
        data = table.Copy(data)
        -- Override pos and ang, some weapons are moved or thrown at the player.
        data.pos = obj:GetPos()
        data.ang = obj:GetAngles()
        data.levelDesignerPlaced = true
        data.options = options
    end

    data.uniqueId = obj.UniqueEntityId
    data.respawnTime = CurTime() + options.delay
    data.item = obj
    table.insert(LAMBDA_OBJECT_RESPAWN_QUEUE, data)
end

local AMMO_LIKE_WEAPONS = {
    ["weapon_frag"] = true,
    ["weapon_slam"] = true
}

function GM:PlayerCanPickupAmmo(ply, ent)
    -- Limit the ammo to pickup based on the sk convars.
    if self:GetSetting("limit_default_ammo") == false then return true end
    local class = ent:GetClass()
    local primaryFull = true
    local secondaryFull = true

    local CheckAmmoFull = function(ammoType, clipSize)
        if ammoType ~= -1 then
            local ammoName = game.GetAmmoName(ammoType)
            local cur = ply:GetAmmoCount(ammoType)
            local ammoMax = self.MAX_AMMO_DEF[ammoName]

            if clipSize == -1 then
                clipSize = 0
            end

            if ammoMax ~= nil then
                ammoMax = ammoMax:GetInt()
            else
                ammoMax = 9999
            end

            if cur >= ammoMax then return true end
        end

        return false
    end

    if ent:IsWeapon() then
        local clip1 = ent:Clip1()
        local clip2 = ent:Clip2()

        if clip1 > 0 and clip2 > 0 then
            primaryFull = CheckAmmoFull(ent:GetPrimaryAmmoType(), ent:Clip1())
            secondaryFull = CheckAmmoFull(ent:GetSecondaryAmmoType(), ent:Clip2())

            return primaryFull == false and secondaryFull == false
        elseif clip1 > 0 then
            primaryFull = CheckAmmoFull(ent:GetPrimaryAmmoType(), ent:Clip1())

            return primaryFull == false
        end
    end

    local ammo = self.ITEM_DEF[class]

    if ammo ~= nil then
        local cur = ply:GetAmmoCount(ammo.Type)
        local ammoMax = ammo.Max:GetInt()

        if cur >= ammoMax then
            DbgPrint("Limited ammo pickup: " .. tostring(class) .. ", " .. ammo.Type)

            return false
        end
    end

    return true
end

function GM:PlayerDroppedWeapon(ply, wep)
    --wep.DroppedByPlayer = ply
end

function GM:PlayerCanPickupItem(ply, item)
    DbgPrintPickup("PlayerCanPickupItem", ply, item)

    if item.CreatedForPlayer ~= nil then
        if item.CreatedForPlayer == ply then
            DbgPrintPickup("Simple pickup, created for player: " .. tostring(ply))

            return true
        else
            -- Deny this weapon for whoever wants to touch it.
            return false
        end
    end

    item.UniqueEntityId = item.UniqueEntityId or self:GetNextUniqueEntityId()

    if self:CallGameTypeFunc("PlayerCanPickupItem", ply, item) == false then
        DbgPrintPickup("GameType prevented pickup")

        return false
    end

    local class = item:GetClass()

    -- Dont pickup stuff if we dont need it.
    if class == "item_health" or class == "item_healthvial" or class == "item_healthkit" then
        if ply:Health() >= ply:GetMaxHealth() then return false end
    elseif class == "item_battery" then
        if ply:Armor() >= 100 then return false end
    elseif class == "item_suit" then
        if ply:IsSuitEquipped() == true then return false end
    end

    if self:PlayerCanPickupAmmo(ply, item) == false then return false end

    if self:CallGameTypeFunc("ShouldRespawnItem", item) == true then
        self:RespawnObject(item)
    else
        return true
    end

    return true
end

function GM:PlayerCanPickupWeapon(ply, wep)
    if ply.InsideGive == true then
        -- Workaround for PLAYER_META:Give fallback
        DbgPrintPickup(ply, "Simple pickup, using PLAYER:Give")

        return true
    end

    if wep.DroppedByPlayer ~= nil then
        DbgPrintPickup(ply, "Simple pickup, dropped by other player")

        return true
    end

    if wep.CreatedForPlayer ~= nil then
        if wep.CreatedForPlayer == ply then
            DbgPrintPickup(ply, "Simple pickup, created for player")

            return true
        else
            -- Deny this weapon for whoever wants to touch it.
            return false
        end
    end

    if AMMO_LIKE_WEAPONS[wep:GetClass()] == true then return self:PlayerCanPickupItem(ply, wep) end
    --DbgPrintPickup("PlayerCanPickupWeapon", ply, wep)
    wep.UniqueEntityId = wep.UniqueEntityId or self:GetNextUniqueEntityId()
    if self:CallGameTypeFunc("PlayerCanPickupWeapon", ply, wep) == false then return false end --DbgPrint("GameType prevented pickup")

    if ply:HasWeapon(wep:GetClass()) == true then
        if self:PlayerCanPickupAmmo(ply, wep) == false then return false end
        local clip1 = wep:Clip1()

        if clip1 > 0 then
            ply:GiveAmmo(clip1, wep:GetPrimaryAmmoType(), false)
            wep:SetClip1(0)
        end

        local clip2 = wep:Clip2()

        if clip2 > 0 then
            ply:GiveAmmo(clip2, wep:GetSecondaryAmmoType(), false)
            wep:SetClip2(0)
        end

        self:RegisterPlayerItemPickup(ply, wep)

        return false
    end

    return true
end

function GM:WeaponEquip(wep, owner)
    DbgPrintPickup("WeaponEquip", wep, owner, wep.CreatedForPlayer)
    local ply = owner
    if not IsValid(ply) then return end
    wep.UniqueEntityId = wep.UniqueEntityId or self:GetNextUniqueEntityId()
    self:RegisterPlayerItemPickup(ply, wep)

    if owner.IsCurrentlySpawning == false then
        local class = wep:GetClass()

        util.RunNextFrame(function()
            if not IsValid(ply) then return end
            ply:SelectWeapon(class)
        end)

        if wep.ShouldHidePickupInfo == nil or wep.ShouldHidePickupInfo() ~= true then
            ply:EmitSound("Player.PickupWeapon")
        end
    end

    if wep.CreatedForPlayer ~= owner and wep.DroppedByPlayer == nil then
        if AMMO_LIKE_WEAPONS[wep:GetClass()] ~= true and self:CallGameTypeFunc("ShouldRespawnWeapon", wep) == true then
            local respawnTime = self:CallGameTypeFunc("GetWeaponRespawnTime") or 0.5

            self:RespawnObject(wep, {
                delay = respawnTime
            })
        end
    end

    wep.CreatedForPlayer = nil
end