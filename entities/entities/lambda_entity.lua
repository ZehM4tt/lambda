if SERVER then
    AddCSLuaFile()
end

local DbgPrint = GetLogging("LambdaEnt")
local util = util
local IsValid = IsValid
ENT.Base = "base_entity"
ENT.Type = "anim"
DEFINE_BASECLASS("base_entity")
local NW2_VARS = true

local DTVAR_TO_TYPE = {
    ["string"] = function(val) return val end,
    ["bool"] = function(val) return tobool(val) end,
    ["float"] = function(val) return util.StringToType(val, "float") end,
    ["int"] = function(val) return util.StringToType(val, "int") end,
    ["angle"] = function(val) return util.StringToType(val, "angle") end,
    ["vector"] = function(val) return util.StringToType(val, "vector") end,
    ["entity"] = function(val)
        error("Can not use entity as key value")
    end
}

local DTVAR_SET

if NW2_VARS == true then
    DTVAR_SET = {
        ["string"] = function(ent, key, index, val)
            ent:SetNW2String(key, val)
        end,
        ["bool"] = function(ent, key, index, val)
            ent:SetNW2Bool(key, val)
        end,
        ["float"] = function(ent, key, index, val)
            ent:SetNW2Float(key, val)
        end,
        ["int"] = function(ent, key, index, val)
            ent:SetNW2Int(key, val)
        end,
        ["angle"] = function(ent, key, index, val)
            ent:SetNW2Angle(key, val)
        end,
        ["entity"] = function(ent, key, index, val)
            ent:SetNW2Entity(key, val)
        end,
        ["vector"] = function(ent, key, index, val)
            ent:SetNW2Vector(key, val)
        end
    }
else
    DTVAR_SET = {
        ["string"] = function(ent, key, index, val)
            ent:SetDTString(index, val)
        end,
        ["bool"] = function(ent, key, index, val)
            ent:SetDTBool(index, val)
        end,
        ["float"] = function(ent, key, index, val)
            ent:SetDTFloat(index, val)
        end,
        ["int"] = function(ent, key, index, val)
            ent:SetDTInt(index, val)
        end,
        ["angle"] = function(ent, key, index, val)
            ent:SetDTAngle(index, val)
        end,
        ["entity"] = function(ent, key, index, val)
            ent:SetDTEntity(index, val)
        end,
        ["vector"] = function(ent, key, index, val)
            ent:SetDTVector(index, val)
        end
    }
end

local DTVAR_GET

if NW2_VARS == true then
    DTVAR_GET = {
        ["string"] = function(ent, key, index, fallback) return ent:GetNW2String(key, fallback) end,
        ["bool"] = function(ent, key, index, fallback) return ent:GetNW2Bool(key, fallback) end,
        ["float"] = function(ent, key, index, fallback) return ent:GetNW2Float(key, fallback) end,
        ["int"] = function(ent, key, index, fallback) return ent:GetNW2Int(key, fallback) end,
        ["angle"] = function(ent, key, index, fallback) return ent:GetNW2Angle(key, fallback) end,
        ["entity"] = function(ent, key, index, fallback) return ent:GetNW2Entity(key, fallback) end,
        ["vector"] = function(ent, key, index, fallback) return ent:GetNW2Vector(key, fallback) end
    }
else
    DTVAR_GET = {
        ["string"] = function(ent, key, index, fallback) return ent:GetDTString(index) or fallback end,
        ["bool"] = function(ent, key, index, fallback) return ent:GetDTBool(index) or fallback end,
        ["float"] = function(ent, key, index, fallback) return ent:GetDTFloat(index) or fallback end,
        ["int"] = function(ent, key, index, fallback) return ent:GetDTInt(index) or fallback end,
        ["angle"] = function(ent, key, index, fallback) return ent:GetDTAngle(index) or fallback end,
        ["entity"] = function(ent, key, index, fallback) return ent:GetDTEntity(index) or fallback end,
        ["vector"] = function(ent, key, index, fallback) return ent:GetDTVector(index) or fallback end
    }
end

function ENT:PreInitialize()
    DbgPrint(self, "PreInitialize")
    self.OutputsTable = self.OutputsTable or {}
    self.InputsTable = self.InputsTable or {}
    self.KeyValueTable = self.KeyValueTable or {}
    self.IsPreInitialized = true

    self.DTVarIndex = self.DTVarIndex or {
        ["string"] = {
            Index = 0,
            Max = 4
        },
        ["bool"] = {
            Index = 0,
            Max = 32
        },
        ["float"] = {
            Index = 0,
            Max = 32
        },
        ["int"] = {
            Index = 0,
            Max = 32
        },
        ["angle"] = {
            Index = 0,
            Max = 32
        },
        ["entity"] = {
            Index = 0,
            Max = 32
        },
        ["vector"] = {
            Index = 0,
            Max = 32
        }
    }

    self.DTVarTable = self.DTVarTable or {}
    self.DTListener = self.DTListener or {}
    self.KeyValueMapping = self.KeyValueMapping or {}

    if NW2_VARS == false then
        self:InstallDataTable()
    end
end

function ENT:DTVarNotify(dtVar, val, default)
    if val == nil and default ~= nil then
        error("Investigate", default)
    end

    if dtVar.LastVal == val then return end
    DbgPrint(self, "DTVar Changed: " .. tostring(dtVar.Key) .. " New: " .. tostring(val) .. ", Old: " .. tostring(dtVar.LastVal))

    if dtVar.OnChange ~= nil then
        dtVar.OnChange(self, dtVar.Key, dtVar.LastVal, val)
    end

    -- Keep keyvalues up to date.
    if dtVar.KeyValue ~= nil then
        self.KeyValueTable[dtVar.KeyValue] = val
    end

    dtVar.LastVal = val
end

function ENT:NotifyDTChange()
    for _, dtVar in pairs(self.DTListener) do
        local curVal = dtVar.Get(self, dtVar.Key, dtVar.Index, dtVar.LastVal or dtVar.Default)
        self:DTVarNotify(dtVar, curVal, dtVar.Default)
    end
end

function ENT:Initialize()
    if self.IsPreInitialized ~= true then
        self:PreInitialize()
    end

    BaseClass.Initialize(self)
end

function ENT:SetupNWVar(key, dtType, data)
    dtType = dtType:lower()
    local dtVarIndex = self.DTVarIndex[dtType]

    if dtVarIndex == nil then
        DbgError("Invalid DTVar type")

        return
    end

    if NW2_VARS == false then
        if dtVarIndex.Index >= dtVarIndex.Max then
            DbgError("Reached maximum DTVar type index")

            return
        end
    end

    local dtVar = self.DTVarTable[key] or {}
    dtVar.Key = key

    if dtVar.Index == nil then
        dtVar.Index = dtVarIndex.Index
        dtVarIndex.Index = dtVarIndex.Index + 1
    end

    dtVar.Type = dtType
    dtVar.ToType = DTVAR_TO_TYPE[dtType]
    dtVar.Get = DTVAR_GET[dtType]
    dtVar.Set = DTVAR_SET[dtType]
    dtVar.LastVal = nil
    self.DTVarTable[key] = dtVar

    --DbgPrint(self, "Setup new DTVar: " .. key .. ", index: " .. tostring(dtvar.Index))
    if data.KeyValue ~= nil then
        self.KeyValueMapping[data.KeyValue:lower()] = dtVar
    end

    if data.OnChange ~= nil then
        dtVar.OnChange = data.OnChange
        self.DTListener[key] = dtVar
    end

    if SERVER and data.Default ~= nil then
        self:SetNWVar(key, data.Default, true)
    end
end

function ENT:OnRestore()
    -- Adjust the Get/Set functions, functions can not be serialized.
    for k, v in pairs(self.DTVarTable) do
        v.Get = DTVAR_GET[v.Type]
        v.Set = DTVAR_SET[v.Type]
    end
end

function ENT:GetNWVar(key, fallback)
    if self.DTVarTable == nil then return fallback end
    local dtVar = self.DTVarTable[key]

    if dtVar == nil and fallback == nil then
        DbgError("DTVar not setup, no fallback specified")

        return
    end

    return dtVar.Get(self, dtVar.Key, dtVar.Index, fallback)
end

function ENT:SetNWVar(key, val, forceNotify)
    if self.DTVarTable == nil then return end
    local dtVar = self.DTVarTable[key]

    if dtVar == nil then
        DbgError("DTVar not setup: " .. key)

        return
    end

    local cur = dtVar.Get(self, dtVar.Key, dtVar.Index, nil)
    if cur == val and forceNotify ~= true then return end
    dtVar.Set(self, dtVar.Key, dtVar.Index, val) -- Refactored, remove this comment if working
    self:DTVarNotify(dtVar, val)
end

function ENT:GetNWVars()
    local vars = {}

    for k, v in pairs(self.DTVarTable) do
        vars[k] = self:GetNWVar(k)
    end

    return vars
end

function ENT:SetNWVars(vars)
    for k, v in pairs(vars) do
        self:SetNWVar(k, v)
    end
end

--if SERVER then
function ENT:AddSpawnFlags(flags)
    if flags == nil then
        error("Can not add nil as spawn flag")
    end

    local newFlags = bit.bor(self:GetSpawnFlags(), flags)
    self:SetKeyValue("spawnflags", tostring(newFlags))
end

function ENT:SetupOutput(name)
    self.OutputsTable = self.OutputsTable or {}
    self.OutputsTable[name] = self.OutputsTable[name] or {}
    --DbgPrint(self, "Setup output: " .. name)
end

function ENT:SetInputFunction(input, fnc)
    self.InputsTable = self.InputsTable or {}
    self.InputsTable[input] = fnc
end

local function NormalizeOutputParams(params)
    local normalized = params
    -- Old style and also Hammer disallows comma.
    normalized = string.Replace(normalized, ":", ",")
    -- Newer source games according to Rubat use this instead of comma.
    normalized = string.Replace(normalized, "\x1B", ",")
    return normalized
end

function ENT:KeyValue(name, val)
    DbgPrint(self, "KeyValue", name, val)

    if self.IsPreInitialized ~= true and self.PreInitialize ~= nil then
        self.IsPreInitialized = true
        self:PreInitialize()
    end

    if self.OutputsTable[name] ~= nil then
        local normalized = NormalizeOutputParams(val)
        local params = string.Explode(",", string.Trim(normalized), false)
        local target = params[1]
        local input = params[2]
        local param = params[3]
        local delay = params[4]
        local times = params[5]
        self:AddOutput(name, target, input, param, delay, times)
    else
        self.KeyValueTable = self.KeyValueTable or {}
        self.KeyValueTable[name] = val
    end

    local mapping = self.KeyValueMapping[name:lower()]

    if mapping ~= nil then
        local data = mapping.ToType(val)

        if data == nil then
            DbgError("Unable to convert value data on key: " .. name .. " -> " .. tostring(val))
        end

        --DbgPrint(self, "KeyValue to DTVar: " .. name .. " -> " .. val)
        --PrintTable(mapping)
        --mapping.Set(self, mapping.Key, mapping.Index, data)
        self:SetNWVar(mapping.Key, data)
    end

    return BaseClass.KeyValue(self, name, val)
end

function ENT:GetLambdaKeyValueTable()
    return table.Copy(self.KeyValueTable)
end

function ENT:CloneOutputs(ent)
    if ent.OutputsTable ~= nil then
        self.OutputsTable = table.Copy(ent.OutputsTable)
    end
end

function ENT:GetOutputsTable()
    return self.OutputsTable
end

function ENT:SetOutputsTable(outputs)
    self.OutputsTable = outputs
end

function ENT:FireOutputs(name, param, activator, caller)
    local actualCaller = caller or self
    local actualActivator = activator or self
    local outputs = self.OutputsTable[name] or {}
    if #outputs == 0 then return end

    util.EnqueueOutput(function()
        DbgPrint(self, "FireOutputs: " .. name .. " " .. table.Count(outputs) .. " outputs")
        util.TriggerOutputs(outputs, actualActivator, actualCaller, param, self)
    end)
end

function ENT:AddOutput(output, target, input, param, delay, times)
    param = param or ""
    delay = delay or "0"
    times = times or "-1"
    param = string.Trim(param)
    delay = string.Trim(delay)
    times = string.Trim(times)
    local outputData = target .. "," .. input .. "," .. param .. "," .. delay .. "," .. times
    self.OutputsTable[output] = self.OutputsTable[output] or {}
    table.insert(self.OutputsTable[output], {outputData, 0})
    DbgPrint(self, "Registered output: ", output, outputData)

    return true
end

function ENT:ClearOutputs()
    self.OutputsTable = {}
end

function ENT:AcceptInput(name, activator, caller, data)
    -- Scripted entities dont set this for some reason.
    DbgPrint(self, "AcceptInput", name, activator, caller, data)
    self.LambdaLastActivator = activator

    if GAMEMODE ~= nil and GAMEMODE.AcceptInput ~= nil and GAMEMODE:AcceptInput(self, name, activator, caller, data) == true then
        DbgPrint(self, "Suppressed Input via GAMEMODE:AcceptInput")

        return true
    end

    DbgPrint(self, "Name: " .. tostring(name))

    if name:iequals("Kill") then
        self:Remove()

        return
    elseif name:iequals("AddOutput") then
        local outputname = string.match(data, "(%w+)(.+)")
        -- We do not add the output, just ensure it exists in the table
        self.OutputsTable[outputname] = self.OutputsTable[outputname] or {}

        return
    end

    if self.InputsTable ~= nil then
        local fn = self.InputsTable[name]

        if fn then
            DbgPrint(self, "Handling Input (" .. name .. ")")
            local res = fn(self, data, activator, caller)
            if res ~= nil then return res end
        else
            DbgPrint(self, "Unhandled input: " .. name)
        end
    else
        DbgPrint("No InputsTable")
    end

    return BaseClass.AcceptInput(name, activator, caller, data)
end

function ENT:PropagateActivator(e)
    local lastActivator

    while IsValid(e) do
        lastActivator = e
        e = e:GetActivator()
    end

    return lastActivator
end

function ENT:PropagatePlayerActivator(e)
    while IsValid(e) do
        if e:IsPlayer() then return e end
        e = e:GetActivator()
    end

    return nil
end
--end