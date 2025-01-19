if SERVER then
    AddCSLuaFile()
end

--local DbgPrint = print
local DbgPrint = GetLogging("EnvCredits")
ENT.Base = "lambda_entity"
ENT.Type = "anim"
DEFINE_BASECLASS("lambda_entity")
CREDITS_TYPE_NONE = 0
CREDITS_TYPE_INTRO = 1
CREDITS_TYPE_OUTRO = 2
CREDITS_TYPE_PARAMS = 3
CREDITS_TYPE_LOGO = 4

local CREDITS_SECTION_NAME = {
    [CREDITS_TYPE_INTRO] = "IntroCreditsNames",
    [CREDITS_TYPE_OUTRO] = "OutroCreditsNames",
    [CREDITS_TYPE_PARAMS] = "CreditsParams",
    [CREDITS_TYPE_LOGO] = "CreditsParams"
}

local function GetCreditsSection(tab, key)
    local name = CREDITS_SECTION_NAME[key]

    for k, v in pairs(tab) do
        if v.Key == name then return v.Value end
    end
end

function ENT:PreInitialize()
    BaseClass.PreInitialize(self)
    DbgPrint(self, "PreInitialize")

    local gametype_name = GAMEMODE:GetGameTypeData("InternalName") or "hl2"
    local path = ""

    if GAMEMODE.WorkshopBuild == false then
        DbgPrint("Path set for non workshop copy")
        path = "gamemodes/Lambda/data/"
    else
        DbgPrint("Path set for workshop build")
        path = "data_static/"
    end

    self:SetupNWVar("CreditsFile", "string", {
        Default = path .. gametype_name .. "/credits.txt",
        KeyValue = "CreditsFile",
        OnChange = self.CreditsFileChanged
    })

    self:SetupNWVar("CreditsFinishTime", "float", {
        Default = 0
    })

    self:SetupNWVar("CreditsStartTime", "float", {
        Default = 0
    })

    self:SetupNWVar("CreditsType", "int", {
        Default = CREDITS_TYPE_NONE,
        OnChange = self.CreditsTypeChanged
    })

    self:SetInputFunction("RollCredits", self.RollCredits)
    self:SetInputFunction("RollOutroCredits", self.RollOutroCredits)
    self:SetInputFunction("ShowLogo", self.ShowLogo)
    self:SetInputFunction("SetLogoLength", self.SetLogoLength)
    self:SetInputFunction("StopCredits", self.StopCredits)

    if CLIENT then
        self.LastCreditsType = nil
        self.LastCreditsFile = nil
    end

    self:SetupOutput("OnCreditsDone")
end

function ENT:Initialize()
    BaseClass.Initialize(self)
    DbgPrint(self, "Initialize")
    self:NextThink(CurTime())
end

function ENT:LoadCreditsFile(filePath, gamePath)
    local fileData = file.Read(filePath, gamePath)
    if fileData == nil then return false end
    local credits = util.KeyValuesToTablePreserveOrder(fileData, false, true)

    if credits == nil then
        print(self, "Unable to parse credits file")

        return false
    end

    self.Credits = credits
    self.Params = {}

    for _, v in pairs(GetCreditsSection(self.Credits, CREDITS_TYPE_PARAMS) or {}) do
        self.Params[v.Key] = v.Value
    end

    if self.Params["color"] ~= nil then
        self.Params["color"] = Color(unpack(string.Split(self.Params["color"], " ")))
    end

    DbgPrint("Loaded credits file: " .. filePath)
    self.LastCreditsFile = filePath

    return true
end

function ENT:ReloadCreditsFile(f)
    local failsafePath = "scripts/credits.txt"

    if string.len(f) < 2 then
        f = failsafePath
    end

    return self:LoadCreditsFile(f, "GAME")
end

function ENT:CreditsFileChanged(key, oldVal, newVal)
    return self:ReloadCreditsFile(newVal)
end

function ENT:GetCreditsLength(creditsType)
    if self.Credits == nil then return 0 end
    local creditsLength = 0

    if creditsType == CREDITS_TYPE_INTRO then
        local section = GetCreditsSection(self.Credits, creditsType)
        local i = 0
        local creditsSize = #section
        local fadeInTime = self.Params["fadeintime"] or 1.0
        local fadeOutTime = self.Params["fadeouttime"] or 1.0
        local fadeHoldTime = self.Params["fadeholdtime"] or 1.0
        local nextFadeTime = self.Params["nextfadetime"] or 1.0
        local pauseBetweenWaves = self.Params["pausebetweenwaves"] or 1.0
        local entryLength = fadeInTime + fadeOutTime + fadeHoldTime

        while i < creditsSize do
            local len = 3

            if i + len > creditsSize then
                len = creditsSize - i
            end

            creditsLength = creditsLength + (len * nextFadeTime) + pauseBetweenWaves
            i = i + len
        end

        creditsLength = creditsLength + entryLength
    elseif creditsType == CREDITS_TYPE_OUTRO then
        creditsLength = self.Params["scrolltime"] or 158
    elseif creditsType == CREDITS_TYPE_LOGO then
        local fadeInTime = self.Params["fadeintime"] or 1.0
        local fadeOutTime = self.Params["fadeouttime"] or 1.0
        local logoTime = self.Params["logotime"] or 1.0

        creditsLength = fadeInTime + logoTime + fadeOutTime
    end

    return creditsLength
end

function ENT:CreditsTypeChanged(key, oldVal, newVal)
    DbgPrint(self, "CreditsTypeChanged: " .. key .. ", " .. tostring(oldVal) .. "," .. newVal)
    if self.Credits == nil and self:ReloadCreditsFile(self:GetNWVar("CreditsFile")) == false then return end

    if newVal == CREDITS_TYPE_NONE then
        self.Section = nil
    else
        self.Section = GetCreditsSection(self.Credits, newVal)
    end

    if CLIENT then
        self.LastCreditsType = newVal

        if IsValid(self.Panel) then
            self.Panel:Remove()
        end

        local startTime = self:GetNWVar("CreditsStartTime")
        local finishTime = self:GetNWVar("CreditsFinishTime")

        if newVal ~= CREDITS_TYPE_NONE then
            self.Panel = vgui.Create("HudCredits", GetHUDPanel())
            self.Panel:ShowCredits(self.Credits, self.Params, newVal, startTime, finishTime)
        end
    end
end

function ENT:Think()
    local creditsFile = self:GetNWVar("CreditsFile")

    if CLIENT and self.LastCreditsFile ~= creditsFile then
        self:CreditsFileChanged("CreditsFile", self.LastCreditsFile, creditsFile)
    end

    local creditsType = self:GetNWVar("CreditsType", CREDITS_TYPE_NONE)

    if CLIENT and self.LastCreditsType ~= creditsType then
        self:CreditsTypeChanged("CreditsType", self.LastCreditsType, creditsType)
    end

    if creditsType == CREDITS_TYPE_NONE then return end

    if SERVER then
        local finishTime = self:GetNWVar("CreditsFinishTime")
        local curTime = CurTime()

        if finishTime ~= 0 and curTime >= finishTime then
            DbgPrint("Credits completed")
            self:StopCredits()
        end
    end
end

function ENT:AcceptInput(fn, data, activator, caller)
    DbgPrint(self, "AcceptInput", fn, data, activator, caller)
    BaseClass.AcceptInput(self, fn, data, activator, caller)
end

function ENT:ShowLogo()
    if CLIENT then return end
    local length = self:GetCreditsLength(CREDITS_TYPE_LOGO)
    self:SetNWVar("CreditsStartTime", CurTime())
    self:SetNWVar("CreditsFinishTime", CurTime() + length)
    self:SetNWVar("CreditsType", CREDITS_TYPE_LOGO)
end

function ENT:RollCredits()
    if CLIENT then return end
    local length = self:GetCreditsLength(CREDITS_TYPE_INTRO)
    self:SetNWVar("CreditsStartTime", CurTime())
    self:SetNWVar("CreditsFinishTime", CurTime() + length)
    self:SetNWVar("CreditsType", CREDITS_TYPE_INTRO)
end

function ENT:RollOutroCredits()
    if CLIENT then return end
    local length = self:GetCreditsLength(CREDITS_TYPE_OUTRO)
    self:SetNWVar("CreditsStartTime", CurTime())
    self:SetNWVar("CreditsFinishTime", CurTime() + length)
    self:SetNWVar("CreditsType", CREDITS_TYPE_OUTRO)
end

function ENT:StopCredits()
    DbgPrint("StopCredits")
    local prevType = self:GetNWVar("CreditsType")
    self:SetNWVar("CreditsStartTime", 0)
    self:SetNWVar("CreditsFinishTime", 0)
    self:SetNWVar("CreditsType", CREDITS_TYPE_NONE)

    if prevType ~= CREDITS_TYPE_NONE then
        self:FireOutputs("OnCreditsDone", self, self)
    end
end

function ENT:KeyValue(key, val)
    DbgPrint(self, "KeyValue", key, val)

    return BaseClass.KeyValue(self, key, val)
end

function ENT:OnRemove()
    if CLIENT and IsValid(self.Panel) then
        self.Panel:Remove()
    end
end

function ENT:UpdateTransmitState()
    return TRANSMIT_ALWAYS
end

function TriggerLogo()
    for k, v in pairs(ents.FindByClass("env_credits")) do
        v:Fire("ShowLogo")
        break
    end
end

function TriggerCredits()
    for k, v in pairs(ents.FindByClass("env_credits")) do
        v:Fire("RollOutroCredits")
        break
    end
end

function FinishCredits()
    for k, v in pairs(ents.FindByClass("env_credits")) do
        v:Fire("StopCredits")
        break
    end
end

function RollCredits()
    for k, v in pairs(ents.FindByClass("env_credits")) do
        v:Fire("RollCredits")
        break
    end
end