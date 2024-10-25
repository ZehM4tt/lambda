-- Those are the returned collision bounds for the airboat, big enough to work on the jeep.
local DbgPrint = GetLogging("Vehicle")
local util = util
local ents = ents
local IsValid = IsValid
local table = table
local CurTime = CurTime
local VEHICLE_THINK = 1
VEHICLE_SPAWN_MINS = Vector(-85, -132, -40)
VEHICLE_SPAWN_MAXS = Vector(85, 104, 110)
local VEHICLE_JEEP = 1
local VEHICLE_AIRBOAT = 2
local VEHICLE_JALOPY = 3
local VEHICLE_PASSENGER = 4
local NEXT_VEHICLE_SPAWN = CurTime()
local VEHICLE_SPAWN_TIME = 2
local VEHICLE_MIN_DESPAWN_DIST = 5000

if SERVER then
    AddCSLuaFile()

    local function IsSupportedVehicle(entData)
        local className = entData["classname"]
        if className == nil then
            return false
        end
        if className == "prop_vehicle_airboat" then
            return true
        elseif className == "prop_vehicle_jeep" and entData["model"] == "models/buggy.mdl" then
            return true
        elseif className == "prop_vehicle_jeep" and entData["model"] == "models/vehicle.mdl" then
            return true
        end
        return false
    end

    -- Check if the map has logic_auto that would create a vehicle.
    local function IsMapStartCreatingVehicle()
        local mapdata = game.GetMapData()

        local function getTableEntry(tab, key)
            -- We look for the key, case insensitive.
            for k, v in pairs(tab) do
                if string.lower(k) == string.lower(key) then
                    return v
                end
            end
            return nil
        end

        local function isTemplateTargetVehicle(targetName)
            local targetInfo = game.FindEntityInMapData(targetName)
            if targetInfo == nil then
                return false
            end
            return IsSupportedVehicle(targetInfo)
        end

        local function pointTemplateContainsVehicle(entData)
            for i = 1, 16 do
                local templateName = getTableEntry(entData, "template" .. string.format("%02d", i))
                if templateName ~= nil and isTemplateTargetVehicle(templateName) then
                    return true
                end
            end
            return false
        end

        local function isSpawningVehicle(targetName, inputName)
            local targetInfo = game.FindEntityInMapData(targetName)
            if targetInfo == nil then
                return false
            end
            if targetInfo["classname"] ~= nil then
                if targetInfo["classname"] == "point_template" and inputName == "ForceSpawn" then
                    -- Check if one of the templates point to one of the vehicles.
                    if pointTemplateContainsVehicle(targetInfo) then
                        return true
                    end
                elseif targetInfo["classname"] == "env_entity_maker" and inputName == "ForceSpawn" then
                    local templateName = getTableEntry(targetInfo, "EntityTemplate")
                    if templateName ~= nil then
                        local templateInfo = game.FindEntityInMapData(templateName)
                        if templateInfo ~= nil and pointTemplateContainsVehicle(templateInfo) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        for _, entData in pairs(mapdata.Entities) do
            if entData["classname"] == "logic_auto" then
                local onNewGame = getTableEntry(entData, "onnewgame")
                if onNewGame ~= nil then
                    if not istable(onNewGame) then
                        -- Turn to table.
                        onNewGame = {onNewGame}
                    end
                    -- Check the outputs
                    for _, v in pairs(onNewGame) do
                        local outputData = string.Explode(",", v)
                        if isSpawningVehicle(outputData[1], outputData[2]) then
                            return true
                        end
                    end
                end
            end
        end

        return false
    end

    function GM:InitializeMapVehicles()
        DbgPrint("InitializeMapVehicles")

        self.ActiveVehicles = {}
        self.MapVehicles = {}
        self.SpawnPlayerVehicles = true
        self.NextVehicleThink = 0
        self.VehicleCheckpoint = nil

        if IsMapStartCreatingVehicle() then
            self.DeferredVehicleCreation = false
            DbgPrint("First vehicle created at the start of the map.")
        else
            self.DeferredVehicleCreation = true
            DbgPrint("Map does not create vehicles at the start, deferring vehicle creation.")
        end

        -- NOTE: We rely on the first vehicle spawn, this method is unreliable as in ep2_outland_09 
        -- the vehicle is spawned later rather than at the start of the map.
        if self.DeferredVehicleCreation == false then
            local mapdata = game.GetMapData()
            for _, v in pairs(mapdata.Entities) do
                if IsSupportedVehicle(v) then
                    table.insert(self.MapVehicles, v)
                end
            end
        end
    end

    function GM:CleanUpVehicles()
        DbgPrint("Cleaning up vehicles..")
        for vehicle, _ in pairs(self.ActiveVehicles) do
            if IsValid(k) then
                DbgPrint("Removing vehicle: " .. tostring(vehicle))
                vehicle:ClearAllOutputs()
                vehicle:Remove()
            else
                DbgPrint("Vehicle " .. tostring(vehicle) .. " invalid")
            end
        end

        DbgPrint("Clearing vehicle ownership..")
        for _, v in pairs(util.GetAllPlayers()) do
            self:PlayerSetVehicleOwned(v, nil)
        end

        self:ResetVehicleCheck()
        self:InitializeMapVehicles()
    end

    function GM:ResetVehicleCheck()
        self.NextVehicleThink = CurTime() + VEHICLE_THINK
    end

    function GM:VehicleSetPlayerOwner(vehicle, ply)
        DbgPrint("VehicleSetPlayerOwner", vehicle, ply)
        vehicle:SetNWEntity("LambdaVehicleOwner", ply)
    end

    function GM:PlayerSetVehicleOwned(ply, vehicle)
        DbgPrint("PlayerSetVehicleOwned", ply, tostring(vehicle))
        ply:SetNWEntity("LambdaOwnedVehicle", vehicle)
    end

    function GM:SetVehicleType(vehicle, vehicleType)
        DbgPrint("SetVehicleType", vehicle, vehicleType)
        vehicle:SetNWInt("LambdaVehicleType", vehicleType)
    end

    function GM:VehicleSetPassengerSeat(vehicle, seat)
        vehicle:SetNWEntity("PassengerSeat", seat)
    end

    function GM:VehicleSetCanTakeOver(vehicle, canTakeOver)
        vehicle:SetNWBool("LambdaVehicleTakeOver", canTakeOver)
    end

    function GM:HandleVehicleCreation(vehicle)
        DbgPrint("HandleVehicleCreation", tostring(vehicle))
        local class = vehicle:GetClass()
        local vehicleType = nil
        if class ~= "prop_vehicle_airboat" and class ~= "prop_vehicle_jeep" then return end

        -- Akward hack to know if an NPC passenger is inside. We handle this with our AcceptInput hook.
        self.IsCreatingInternalOutputs = true
        vehicle:Input("AddOutput", NULL, NULL, "OnCompanionEnteredVehicle !self,LambdaCompanionEnteredVehicle,,0,-1")
        vehicle:Input("AddOutput", NULL, NULL, "OnCompanionExitedVehicle !self,LambdaCompanionExitedVehicle,,1,-1")
        self.IsCreatingInternalOutputs = false

        -- This has to be set this frame.
        if self.MapScript.VehicleGuns == true then
            DbgPrint("Enabling Gun")
            vehicle:SetKeyValue("EnableGun", "1")
        else
            DbgPrint("No guns enabled")
        end

        -- We only get a model next frame, delay it.
        util.RunNextFrame(function()
            if not IsValid(vehicle) then return end

            local mdl = vehicle:GetModel()
            if class == "prop_vehicle_airboat" and mdl == "models/airboat.mdl" then
                vehicleType = VEHICLE_AIRBOAT
            elseif class == "prop_vehicle_jeep" and mdl == "models/buggy.mdl" then
                vehicleType = VEHICLE_JEEP
            elseif class == "prop_vehicle_jeep" and mdl == "models/vehicle.mdl" then
                vehicleType = VEHICLE_JALOPY
            else
                return
            end

            if self.DeferredVehicleCreation == true then
                if vehicle:GetName() ~= "" and vehicle.VehicleIsCloned ~= true then
                    -- We have a map creation ID, we can use this to determine the vehicle type.
                    local mapdata = game.GetMapData()
                    for _, v in pairs(mapdata.Entities) do
                        if v["targetname"] == vehicle:GetName() then
                            DbgPrint("New vehicle on map: " .. tostring(v["classname"]))
                            table.insert(self.MapVehicles, v)
                        end
                    end
                end
            end

            DbgPrint(vehicle, "Vehicle type: " .. tostring(vehicleType))
            self.ActiveVehicles[vehicle] = true
            --vehicle:SetCustomCollisionCheck(true)
            vehicle:CallOnRemove("LambdaVehicleCleanup", function(ent) self.ActiveVehicles[ent] = nil end)
            vehicle.AllowVehicleCheckpoint = true
            self:SetVehicleType(vehicle, vehicleType)
            local tracker = ents.Create("lambda_vehicle_tracker")
            tracker:AttachToVehicle(vehicle)
            tracker:Spawn()
            if vehicleType == VEHICLE_JEEP then
                self:HandleJeepCreation(vehicle)
            elseif vehicleType == VEHICLE_AIRBOAT then
                self:HandleAirboatCreation(vehicle)
            elseif vehicleType == VEHICLE_JALOPY then
                self:HandleJalopyCreation(vehicle)
            end
        end)
    end

    local function CreatePassengerSeat(parent, localPos, localAng, mdl)
        local seat = ents.Create("prop_vehicle_prisoner_pod")
        seat:SetPos(parent:LocalToWorld(localPos))
        seat:SetAngles(parent:LocalToWorldAngles(localAng))
        seat:SetModel(mdl)
        seat:SetParent(parent)
        seat:Spawn()
        -- TODO: Remove this, legacy.
        seat:SetNWBool("IsPassengerSeat", true)
        GAMEMODE:SetVehicleType(seat, VEHICLE_PASSENGER)
        return seat
    end

    function GM:HandleJeepCreation(jeep)
        DbgPrint("HandleJeepCreation", jeep)

        local seat = jeep:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Already exists.
            return
        end

        seat = CreatePassengerSeat(jeep, Vector(19.369112, -37.018456, 18.896046), Angle(-0.497, -3.368, 0.259), "models/nova/jeep_seat.mdl")
        jeep:SetNWEntity("PassengerSeat", seat)
    end

    function GM:HandleJalopyCreation(jalopy)
        DbgPrint("HandleJalopyCreation", jalopy)

        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Already exists.
            return
        end

        seat = CreatePassengerSeat(jalopy, Vector(21.498613, -27.285204, 18.695107), Angle(-0.211, 0.621, -0.145), "models/nova/jalopy_seat.mdl")
        -- Make it invisible, we just want the functionality.
        seat:SetNoDraw(true)
        jalopy:SetNWEntity("PassengerSeat", seat)

        local mapScript = self.MapScript
        if mapScript ~= nil and mapScript.OnJalopyCreated ~= nil then
            mapScript:OnJalopyCreated(jalopy)
        end
    end

    function GM:OnCompanionEnteredVehicle(jalopy, passenger)
        DbgPrint("Companion entered vehicle")

        jalopy:SetNWEntity("LambdaPassenger", passenger)
        passenger:SetNWEntity("LambdaVehicle", jalopy)
        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Lock this seat as we have the passenger inside the vehicle.
            seat:Fire("Lock")
        else
            DbgPrint("No passenger seat on jalopy: " .. tostring(jalopy))
        end
    end

    function GM:OnCompanionExitedVehicle(jalopy, passenger)
        DbgPrint("Companion exited vehicle")

        jalopy:SetNWEntity("LambdaPassenger", NULL)
        passenger:SetNWEntity("LambdaVehicle", NULL)
        local seat = jalopy:GetNWEntity("PassengerSeat")
        if IsValid(seat) then
            -- Lock this seat as we have the passenger inside the vehicle.
            seat:Fire("Unlock")
        end
    end

    function GM:OnPlayerPassengerEnteredVehicle(ply, vehicle, seat)
        DbgPrint("Player entered passenger seat", ply, vehicle, seat)
        -- Prevent NPC companions from entering as passengers.
        vehicle:Fire("LockEntrance")
    end

    function GM:OnPlayerPassengerExitedVehicle(ply, vehicle, seat)
        DbgPrint("Player exited passenger seat", ply, vehicle, seat)
        -- Allow NPC companions to enter as passengers.
        vehicle:Fire("UnlockEntrance")
    end

    function GM:HandleAirboatCreation(airboat)
    end

    function GM:FindVehicleSeat(ply, vehicle)
        if vehicle:GetDriver() == NULL then return vehicle end
        -- Allow players to enter the passenger seat directly by swapping it.
        local passengerSeat = vehicle:GetNWEntity("PassengerSeat")
        if IsValid(passengerSeat) and passengerSeat:GetDriver() == NULL then return passengerSeat end
        return vehicle
    end

    function GM:PlayerEnteredVehicle(ply, vehicle, role)
        DbgPrint("PlayerEnteredVehicle", ply, vehicle, role)
        if ply:IsSprinting() == true then ply:StopSprinting() end
        local vehicleType = self:VehicleGetType(vehicle)
        if vehicleType == nil then
            -- Nothing to do here.
            DbgPrint("Vehicle type is nil")
            return
        end

        if vehicleType ~= VEHICLE_PASSENGER then
            -- Clear the previous vehicle owner.
            local prevVehicle = self:PlayerGetVehicleOwned(ply)
            if IsValid(prevVehicle) and prevVehicle ~= vehicle then
                DbgPrint("Player owns another vehicle, clearing ownership", prevVehicle)
                self:VehicleSetPlayerOwner(prevVehicle, NULL)
            end

            local owner = self:VehicleGetPlayerOwner(vehicle)
            if IsValid(owner) and owner ~= ply then
                DbgError("Bogus vehicle logic: Player entering vehicle that does not belong to him", owner, ply, vehicle)
            elseif not IsValid(owner) then
                -- Now belongs to the specific player.
                DbgPrint("Player " .. tostring(ply) .. " gets ownership of vehicle: " .. tostring(vehicle))
                self:VehicleSetPlayerOwner(vehicle, ply)
                self:PlayerSetVehicleOwned(ply, vehicle)
            end
        end

        local ang = vehicle:GetForward():Angle()
        ang = vehicle:WorldToLocalAngles(ang)
        ply:SetEyeAngles(ang)
        if self:VehicleIsPassengerSeat(vehicle) then
            local parent = vehicle:GetParent()
            if IsValid(parent) and parent:GetNWEntity("PassengerSeat") == vehicle then self:OnPlayerPassengerEnteredVehicle(ply, parent, vehicle) end
        end

        if self.MapScript ~= nil and self.MapScript.OnEnteredVehicle ~= nil then self.MapScript:OnEnteredVehicle(ply, vehicle, role) end
    end

    function GM:CanExitVehicle(vehicle, ply)
        DbgPrint("CanPlayerExitVehicle", vehicle, ply)
        local locked = vehicle:GetInternalVariable("vehiclelocked")
        if locked ~= nil then return locked == false end
        return true
    end

    function GM:PlayerLeaveVehicle(ply, vehicle)
        -- Reset, we disabled it for transition probably
        DbgPrint("PlayerLeaveVehicle", ply, vehicle)
        if vehicle.ResetVehicleEntryAnim == true then
            vehicle:SetVehicleEntryAnim(true)
        end

        local vehicleType = self:VehicleGetType(vehicle)
        if vehicleType == nil then
            -- Nothing to do here.
            DbgPrint("Vehicle type is nil", vehicle)
            return
        end

        if ply:Alive() == false then
            if vehicleType ~= VEHICLE_PASSENGER then
                self:VehicleSetPlayerOwner(vehicle, NULL)
                self:VehicleDriverKilled(vehicle, ply)
            end
        else
            -- Make sure players won't collide if they exit strangely.
            ply:DisablePlayerCollide(true)
        end

        if ply:Alive() and vehicleType == VEHICLE_PASSENGER then
            local ang = vehicle:GetAngles()
            local pos = vehicle:GetPos()
            local exitpos = pos + (ang:Forward() * 50)
            -- Look towards the seat.
            local exitang = (pos - exitpos):Angle()
            ply:TeleportPlayer(exitpos, exitang)
            vehicle:GetParent().Passenger = nil
            local parent = vehicle:GetParent()
            if IsValid(parent) and self:VehicleGetPassengerSeat(parent) == vehicle then self:OnPlayerPassengerExitedVehicle(ply, parent, vehicle) end
        end
    end

    function GM:CanPlayerEnterVehicle(ply, vehicle, role)
        DbgPrint("CanPlayerEnterVehicle", ply, vehicle)
        -- Disallow by default.
        ply:SetAllowWeaponsInVehicle(false)
        local vehicleType = self:VehicleGetType(vehicle)
        if vehicleType == nil then
            -- Nothing to do here.
            return true
        end

        DbgPrint(vehicle, "Vehicle Type: " .. tostring(vehicleType))

        if vehicleType ~= VEHICLE_PASSENGER then
            local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
            -- Check if the vehicle is owned by someone else.
            if IsValid(vehicleOwner) and vehicleOwner ~= ply then
                DbgPrint("Player not allowed to enter vehicle, owned by: " .. tostring(vehicleOwner))
                -- If this is true it will start the engine and release the handbrake despite
                -- the player not being able to enter the vehicle.
                vehicle:SetVehicleEntryAnim(false)
                return false
            end

            -- Check if the vehicle is already owned by us.
            if vehicleOwner == ply then
                DbgPrint("Player owns the vehicle")
                return true
            end

            -- Check if the player already owns a vehicle other than this one.
            local canTakeOver = self:VehicleCanTakeOver(vehicle, ply)
            if not canTakeOver then
                local playerVehicle = self:PlayerGetVehicleOwned(ply)
                if IsValid(playerVehicle) and playerVehicle ~= vehicle then
                    DbgPrint("Player already owns a vehicle")
                    ply:EmitSound("HL2Player.UseDeny")
                    vehicle:SetVehicleEntryAnim(false)
                    return false
                end
            else
                DbgPrint("Player " .. tostring(ply) .. " can take over vehicle: " .. tostring(vehicle))
            end
        elseif vehicleType == VEHICLE_PASSENGER then
            vehicle:SetKeyValue("limitview", "0")
            ply:SetAllowWeaponsInVehicle(true)
            if vehicle.SetVehicleEntryAnim ~= nil then
                vehicle.ResetVehicleEntryAnim = true
                vehicle:SetVehicleEntryAnim(false)
            else
                vehicle.ResetVehicleEntryAnim = false
            end
        end
        return true
    end

    function GM:RemovePlayerVehicles(ply)
        DbgPrint("GM:RemovePlayerVehicles", ply)
        for vehicle, _ in pairs(self.ActiveVehicles) do
            local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
            local passenger = self:VehicleGetPassenger(vehicle)
            if vehicleOwner == ply and not IsValid(passenger) then
                DbgPrint("Removing player vehicle: " .. tostring(vehicle))
                self:VehicleSetPlayerOwner(vehicle, NULL)
                vehicle:Remove()
            end
        end

        self:PlayerSetVehicleOwned(ply, nil)
    end

    function GM:SetSpawnPlayerVehicles(state)
        self.SpawnPlayerVehicles = state
        if self.SpawnPlayerVehicles == nil then self.SpawnPlayerVehicles = true end
    end

    function GM:GetMaxVehicleCount()
        if self.MapVehicles == nil or #self.MapVehicles == 0 then
            -- No vehicles on this map.
            return 0
        end
        -- TODO: Should we always have one extra in reserve? Its possible that a player
        -- dies far away from the vehicle but has other players around that prevents a despawn.
        local alive = 0
        for _, ply in pairs(util.GetAllPlayers()) do
            if ply:Alive() then alive = alive + 1 end
        end
        return alive
    end

    function GM:CanSpawnVehicle()
        if CurTime() < NEXT_VEHICLE_SPAWN then return false end

        local maxVehicles = self:GetMaxVehicleCount()
        if maxVehicles == 0 then
            -- No vehicles on this map.
            return false
        end

        if self.SpawnPlayerVehicles ~= true then
            -- We are not allowed to spawn vehicles.
            return false
        end

        if table.Count(self.ActiveVehicles) >= maxVehicles then
            -- Exhausted.
            return false
        end

        return true
    end

    function GM:GetVehicleSpawnPos()
        if self.VehicleCheckpoint ~= nil then return self.VehicleCheckpoint.Pos end
        if #self.MapVehicles == 0 then return nil end
        return util.StringToType(self.MapVehicles[1]["origin"], "Vector")
    end

    function GM:SpawnVehicleAtSpot(vehicle)
        local pos = self:GetVehicleSpawnPos()
        -- Check if there is already one.
        local nearbyEnts = ents.FindInBox(pos + VEHICLE_SPAWN_MINS, pos + VEHICLE_SPAWN_MAXS)
        for _, v in pairs(nearbyEnts) do
            if v:GetClass() == vehicle["classname"] then
                -- We normally dont want this, but its possible to spawn two of them at the same spot.
                -- TODO: Create a convar and let the server owner decide.
                return false
            end
            -- The box is somewhat big, we should deal with players standing directly in the way.
        end

        DbgPrint("Spawning vehicle at spot: " .. tostring(pos))
        local newVehicle = ents.CreateFromData(vehicle)
        newVehicle.VehicleIsCloned = true
        if self.VehicleCheckpoint ~= nil then
            newVehicle:SetPos(self.VehicleCheckpoint.Pos)
            newVehicle:SetAngles(self.VehicleCheckpoint.Ang)
        end

        if self.EnableVehicleGuns then newVehicle:SetKeyValue("EnableGun", "1") end
        newVehicle:Spawn()
        newVehicle:Activate()
        DbgPrint("Created new vehicle: " .. tostring(newVehicle))
        NEXT_VEHICLE_SPAWN = CurTime() + VEHICLE_SPAWN_TIME
    end

    function GM:CheckRemoveVehicle(vehicle, ignoreChecks)
        local passenger = self:VehicleGetPassenger(vehicle)
        if IsValid(passenger) then
            -- Never remove vehicles that have a passenger.
            return false
        end

        local vehiclePos = vehicle:GetPos()
        local vehicleOwner = self:VehicleGetPlayerOwner(vehicle)
        if IsValid(vehicleOwner) then
            -- Check how far away the vehicle owner is.
            local ownerDist = vehicleOwner:GetPos():Distance(vehiclePos)
            if ownerDist < VEHICLE_MIN_DESPAWN_DIST then
                -- Owner is close, don't remove.
                return false
            end
        end

        if vehicleOwner ~= NULL and not IsValid(vehicleOwner) then
            -- Probably disconnected client.
            self:VehicleSetPlayerOwner(vehicle, NULL)
        end

        local spawnPos = self:GetVehicleSpawnPos()
        if spawnPos ~= nil then
            -- See if the checkpoint has moved.
            local dist = vehiclePos:Distance(spawnPos)
            if dist < 512 then
                -- Vehicle is close to the spawn point.
                return false
            end
        end

        if ignoreChecks ~= true then
            -- Check if there are players nearby.
            if util.IsPlayerNearby(vehiclePos, VEHICLE_MIN_DESPAWN_DIST) then
                -- Players are nearby, don't remove.
                return
            end
        end

        DbgPrint("Removing vehicle " .. tostring(vehicle) .. " because it is too far away from the owner.")
        vehicle:Remove()

        return true
    end

    function GM:VehiclesThink()
        if self:IsRoundRunning() == false and self:RoundElapsedTime() >= 1 then return end
        if #self.MapVehicles == 0 then
            -- No vehicles on this map.
            return
        end

        local plyCount = player.GetCount()
        local vehicleCount = table.Count(self.ActiveVehicles)

        local curTime = CurTime()
        if curTime < self.NextVehicleThink then return end
        self.NextVehicleThink = curTime + VEHICLE_THINK
        for vehicle, _ in pairs(self.ActiveVehicles) do
            if not IsValid(vehicle) then
                self.ActiveVehicles[vehicle] = nil
            else
                local additionalChecks = vehicleCount > plyCount
                if self:CheckRemoveVehicle(vehicle, additionalChecks) then
                    vehicleCount = vehicleCount - 1
                end
            end
        end

        if self:CanSpawnVehicle() then
            for _, v in pairs(self.MapVehicles) do
                self:SpawnVehicleAtSpot(v)
            end
        end
    end
else -- CLIENT
    function GM:CalcVehicleView(vehicle, ply, view)
        --print("CalcVehicleView")
        if ply.VehicleSteeringView == true then
            local viewPos = view.origin
            local headBone = ply:LookupBone("ValveBiped.Bip01_Head1")
            if headBone ~= nil then viewPos = ply:GetBonePosition(headBone) end
            view.origin = viewPos + (view.angles:Forward() * 3)
        end

        -- Don't roll the camera
        view.angles.z = 0
        if vehicle.GetThirdPersonMode == nil or ply:GetViewEntity() ~= ply then -- This should never happen.
            return
        end

        if vehicle:GetThirdPersonMode() == false then return view end
        local mn, mx = vehicle:GetRenderBounds()
        local radius = (mn - mx):Length()
        radius = radius + radius * vehicle:GetCameraDistance()
        -- Trace back from the original eye position, so we don't clip through walls/objects
        local TargetOrigin = view.origin + (view.angles:Forward() * -radius)
        local WallOffset = 4
        local tr = util.TraceHull({
            start = view.origin,
            endpos = TargetOrigin,
            filter = function(e)
                local c = e:GetClass() -- Avoid contact with entities that can potentially be attached to the vehicle. Ideally, we should check if "e" is constrained to "Vehicle".
                return not c:StartWith("prop_physics") and not c:StartWith("prop_dynamic") and not c:StartWith("prop_ragdoll") and not e:IsVehicle() and not c:StartWith("gmod_")
            end,
            mins = Vector(-WallOffset, -WallOffset, -WallOffset),
            maxs = Vector(WallOffset, WallOffset, WallOffset)
        })

        view.origin = tr.HitPos
        view.drawviewer = true
        --
        -- If the trace hit something, put the camera there.
        --
        if tr.Hit and not tr.StartSolid then view.origin = view.origin + tr.HitNormal * WallOffset end
        return view
    end
end

function GM:VehicleShouldCollide(veh1, veh2)
    -- FIXME: When vehicles initially intersect they shouldn't collide as long they do.
    do
        return
    end
end

function GM:VehicleDriverKilled(vehicle, ply)
    DbgPrint("Vehicle driver dead", ply, vehicle)
    local vehicleType = self:VehicleGetType(vehicle)
    if vehicleType == VEHICLE_PASSENGER then
        -- Do nothing for passenger seats.
        return
    end
    -- Check if we have a passenger, notify him that he can take over.
    local passenger = self:VehicleGetPassenger(vehicle)
    if IsValid(passenger) then
        DbgPrint("Notifying passenger")
        -- Send a hint that the passenger can take over.
        self:AddHint("#LAMBDA_VEHICLE_TAKE_OVER", 7, passenger)
    end
    -- Allow vehicle to be taken over.
    self:VehicleSetCanTakeOver(vehicle, true)
end

function GM:VehiclePromotePassenger(ply, vehicle)
    local parent = vehicle:GetParent()
    if not IsValid(parent) then
        DbgError("VehiclePromotePassenger: Invalid parent")
        return
    end
    if IsValid(parent:GetDriver()) then
        DbgError("VehiclePromotePassenger: Parent already has a driver")
        return
    end
    local owner = self:VehicleGetPlayerOwner(vehicle)
    if IsValid(owner) then
        DbgError("VehiclePromotePassenger: Vehicle has an owner")
        return
    end
    util.RunNextFrame(function()
        -- Enter the driver side.
        ply:EnterVehicle(parent)
    end)
end

function GM:VehicleStartCommand(ply, vehicle, cmd)
    -- Handle the vehicle take-over mechanic.
    local mainVehicle = vehicle:GetParent()
    if not IsValid(mainVehicle) then
        return
    end

    if not (cmd:KeyDown(IN_USE) and cmd:KeyDown(IN_SPEED)) then
        return
    end

    if self:VehicleIsPassengerSeat(vehicle) then
        if self:VehicleCanTakeOver(mainVehicle, ply) then
            if SERVER then
                self:VehiclePromotePassenger(ply, vehicle)
            end
        else
            DbgPrint("Not allowed to take-over vehicle")
            -- Remove the keys from the player.
            cmd:RemoveKey(IN_USE)
            cmd:RemoveKey(IN_SPEED)
        end
    end
end

function GM:VehicleMove(ply, vehicle, mv)
    local modified = false
    -- We have to call it here because PlayerTick wont be called if we are inside a vehicle.
    self:UpdateSuit(ply, mv)
    self:PlayerWeaponTick(ply, mv)
    --
    -- On duck toggle third person view
    --
    if mv:KeyPressed(IN_DUCK) and vehicle.SetThirdPersonMode then vehicle:SetThirdPersonMode(not vehicle:GetThirdPersonMode()) end
    --
    -- Adjust the camera distance with the mouse wheel
    --
    local iWheel = ply:GetCurrentCommand():GetMouseWheel()
    if iWheel ~= 0 and vehicle.SetCameraDistance then
        -- The distance is a multiplier
        -- Actual camera distance = ( renderradius + renderradius * dist )
        -- so -1 will be zero.. clamp it there.
        local newdist = math.Clamp(vehicle:GetCameraDistance() - iWheel * 0.03 * (1.1 + vehicle:GetCameraDistance()), -1, 10)
        vehicle:SetCameraDistance(newdist)
    end

    if ply:IsPositionLocked() ~= true then return end
    mv:SetButtons(0)
    local phys = vehicle:GetPhysicsObject()
    if IsValid(phys) then
        local vel = phys:GetVelocity()
        local len = vel:Length()
        if vel:Length() >= 1 then
            vel = vel - (vel * 0.015)
            phys:SetVelocity(vel)
        end

        if len < 50 and (vehicle:GetClass() == "prop_vehicle_jeep" or vehicle:GetClass() == "prop_vehicle_jalopy") then vehicle:Fire("HandBrakeOn") end
    end
    return modified
end

function GM:VehicleGetPassenger(vehicle)
    local npcPassenger = vehicle:GetNWEntity("LambdaPassenger")
    if IsValid(npcPassenger) then
        -- There is an NPC sitting in the vehicle.
        return npcPassenger
    end

    local seat = vehicle:GetNWEntity("PassengerSeat")
    if IsValid(seat) then return seat:GetDriver() end
    return nil
end

function GM:VehicleGetPlayerOwner(vehicle)
    if not IsValid(vehicle) then
        DbgError("VehicleGetPlayerOwner: Invalid vehicle")
        return nil
    end
    return vehicle:GetNWEntity("LambdaVehicleOwner", nil)
end

function GM:PlayerGetVehicleOwned(ply)
    if not IsValid(ply) then
        DbgError("PlayerGetVehicleOwned: Invalid player")
        return nil
    end
    return ply:GetNWEntity("LambdaOwnedVehicle", nil)
end

function GM:VehicleGetType(vehicle)
    if not IsValid(vehicle) then
        DbgError("VehicleGetType: Invalid vehicle")
        return nil
    end

    if vehicle:GetNWBool("IsPassengerSeat", false) then return VEHICLE_PASSENGER end
    local res = vehicle:GetNWInt("LambdaVehicleType", -1)
    if res == -1 then
        return nil
    end
    return res
end

function GM:VehicleIsPassengerSeat(vehicle)
    return self:VehicleGetType(vehicle) == VEHICLE_PASSENGER
end

function GM:VehicleGetPassengerSeat(vehicle)
    return vehicle:GetNWEntity("PassengerSeat")
end

function GM:VehicleCanTakeOver(vehicle, ply)
    local owner = self:VehicleGetPlayerOwner(vehicle)
    if not IsValid(owner) and not IsValid(self:PlayerGetVehicleOwned(ply)) then
        -- If there is no owner we can always take it.
        return true
    end
    if owner == ply then
        -- If we are the owner we can always take it.
        return true
    end
    -- If the driver died in a vehicle we can take it over.
    return vehicle:GetNWBool("LambdaVehicleTakeOver", false)
end