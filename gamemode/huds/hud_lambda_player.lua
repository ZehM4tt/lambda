local border = 4
local border_w = 5
local matHover = Material("gui/ps_hover.png", "nocull")
local boxHover = GWEN.CreateTextureBorder(border, border, 64 - border * 2, 64 - border * 2, border_w, border_w, border_w, border_w, matHover)

local PANEL = {}

cvars.AddChangeCallback("lambda_playermdl", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelChanged")

cvars.AddChangeCallback("lambda_playermdl_skin", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelSkinChanged")

cvars.AddChangeCallback("lambda_playermdl_bodygroup", function()
    net.Start("LambdaPlayerSettingsChanged")
    net.SendToServer()
end, "LambdaPlayerModelBGChanged")

function PANEL:Init()
    local sheetPanel = self:Add("DPropertySheet")
    sheetPanel:Dock(FILL)

    local mdlPanel = sheetPanel:Add("DPanel")
    mdlPanel:Dock(FILL)

    local searchBar = mdlPanel:Add("DTextEntry")
    searchBar:Dock(TOP)
    searchBar:DockMargin(0, 0, 0, 8)
    searchBar:SetUpdateOnType(true)
    searchBar:SetPlaceholderText("Search for model")
    searchBar:SetPlaceholderColor(Color(140, 140, 140, 255))

    local mdlListPanel = mdlPanel:Add("DPanelSelect")
    mdlListPanel:Dock(FILL)

    local modelTbl = GAMEMODE:GetAvailablePlayerModels()
    for name, v in pairs(modelTbl) do
        local item = mdlListPanel:Add("SpawnIcon")
        item:SetModel(v)
        item:SetSize(64, 64)
        item:SetTooltip(name)
        item.plymdl = name
        item.mdlPath = player_manager.TranslatePlayerModel(name)
        item.PaintOver = function(this, w, h)
            if this.OverlayFade > 0 then
                boxHover(0, 0, w, h, Color(255, 255, 255, this.OverlayFade))
            end
            this:DrawSelections()
        end
        mdlListPanel:AddPanel(item, {lambda_playermdl = name})
    end

    searchBar.OnValueChange = function(s, str)
        for i, pnl in pairs(mdlListPanel:GetItems()) do
            if not pnl.plymdl:find(str, 1, true) and not pnl.mdlPath:find(str, 1, true) then
                pnl:SetVisible(false)
            else
                pnl:SetVisible(true)
            end
        end
        mdlListPanel:InvalidateLayout()
    end

    sheetPanel:AddSheet("MODEL", mdlPanel)

    local voicePanel = sheetPanel:Add("DPanel")

    local voiceLabel = voicePanel:Add("DLabel")
    voiceLabel:Dock(TOP)
    voiceLabel:SetText("Voice Group")
    voiceLabel:SetTextColor(Color(255, 255, 255, 255))
    voiceLabel:SetFont("TargetIDSmall")
    voiceLabel:SizeToContents()
    voiceLabel:DockMargin(0, 5, 0, 5)

    local voiceCombo = voicePanel:Add("DComboBox")
    voiceCombo:Dock(TOP)

    local categories = GAMEMODE:GetAvailableTauntCategories()
    for _, category in ipairs(categories) do
        local displayName = category == "auto" and "Auto" or (string.upper(category:sub(1,1)) .. category:sub(2))
        voiceCombo:AddChoice(displayName, category)
    end

    voiceCombo:SetTextColor(Color(255, 255, 255, 255))
    voiceCombo:SetSortItems(false)

    local lastKnownVoiceGroup = ""

    local function UpdateVoiceCombo()
        local currentVoiceGroup = GetConVar("lambda_voice_group"):GetString()
        if currentVoiceGroup ~= lastKnownVoiceGroup then
            for id, data in ipairs(voiceCombo.Data) do
                if data == currentVoiceGroup then
                    voiceCombo:ChooseOptionID(id)
                    lastKnownVoiceGroup = currentVoiceGroup
                    break
                end
            end
        end
    end

    voiceCombo.OnSelect = function(_, _, _, data)
        RunConsoleCommand("lambda_voice_group", data)
        lastKnownVoiceGroup = data
    end

    UpdateVoiceCombo()

    -- Update only when the panel becomes visible
    self.OnVisible = function()
        UpdateVoiceCombo()
    end

    sheetPanel:AddSheet("VOICE", voicePanel)

    local bgPanel = sheetPanel:Add("DPanel")

    local bgList = bgPanel:Add("DPanelList")
    bgList:Dock(FILL)
    bgList:EnableVerticalScrollbar(true)

    local nobgLabel = bgPanel:Add("DLabel")
    nobgLabel:Dock(TOP)
    nobgLabel:SetText("NO OPTIONS FOR THIS MODEL")
    nobgLabel:SetTextColor(Color(255, 255, 255, 255))
    nobgLabel:SetFont("TargetIDSmall")
    nobgLabel:SizeToContents()
    nobgLabel:DockMargin(0, 5, 0, 0)
    nobgLabel:SetContentAlignment(5)
    nobgLabel:SetVisible(false)

    local bgTab = sheetPanel:AddSheet("BODYGROUPS", bgPanel)

    local function HighlightTab(state)
        if state then
            bgTab.Tab:SetTextColor(Color(248, 128, 0, 255))
            nobgLabel:SetVisible(false)
        else
            bgTab.Tab:SetTextColor(Color(140, 140, 140, 255))
            nobgLabel:SetVisible(true)
        end
    end

    local function SetMdlChanges(pnl, val)
        if pnl.type == "skin" then
            lambda_playermdl_skin:SetString(math.Round(val))
        end

        if pnl.type == "bg" then
            local str = string.Explode(" ", lambda_playermdl_bodygroup:GetString())
            if #str < pnl.n + 1 then
                for i = 1, pnl.n + 1 do
                    str[i] = str[i] or 0 end
            end
            str[pnl.n + 1] = math.Round(val)
            lambda_playermdl_bodygroup:SetString(table.concat(str, " "))
        end
    end

    local function RebuildBgPnl()
        bgList:Clear()
        HighlightTab(false)
        -- Slight delay to make sure model is set on entity
        timer.Simple(0.1, function()
            if not nobgLabel:IsValid() then return end
            local ply = LocalPlayer()
            local mdlStr = player_manager.TranslatePlayerModel(lambda_playermdl:GetString())
            local numSkins = NumModelSkins(mdlStr) - 1
            if numSkins > 0 then
                local slider = vgui.Create("DNumSlider")
                slider:Dock(TOP)
                slider:DockMargin(20, 0, 0, 0)
                slider:SetText("SKIN")
                slider:SetSkin("Lambda")
                slider:SetTall(30)
                slider:SetDecimals(0)
                slider:SetMax(numSkins)
                slider:SetValue(lambda_playermdl_skin:GetString())
                slider:GetTextArea():SetFont("TargetIDSmall")
                slider:GetTextArea():SetTextColor(Color(255, 255, 255, 255))
                slider.Label:SetFont("TargetIDSmall")
                slider.Label:SetTextColor(Color(255, 255, 255, 255))
                slider.type = "skin"
                slider.OnValueChanged = SetMdlChanges

                bgList:AddItem(slider)
                HighlightTab(true)
            end

            local bgroups = string.Explode(" ", lambda_playermdl_bodygroup:GetString())
            for k = 0, ply:GetNumBodyGroups() - 1 do
                if ply:GetBodygroupCount(k) <= 1 then continue end

                local bgsldr = vgui.Create("DNumSlider")
                bgsldr:Dock(TOP)
                bgsldr:DockMargin(20, 0, 0, 0)
                bgsldr:SetText(string.upper(ply:GetBodygroupName(k)))
                bgsldr:SetSkin("Lambda")
                bgsldr:SetTall(30)
                bgsldr:SetDecimals(0)
                bgsldr:SetMax(ply:GetBodygroupCount(k) - 1)
                bgsldr:SetValue(bgroups[k + 1] or 0)
                bgsldr:GetTextArea():SetFont("TargetIDSmall")
                bgsldr:GetTextArea():SetTextColor(Color(255, 255, 255, 255))
                bgsldr.Label:SetFont("TargetIDSmall")
                bgsldr.Label:SetTextColor(Color(255, 255, 255, 255))
                bgsldr.type = "bg"
                bgsldr.n = k
                bgsldr.OnValueChanged = SetMdlChanges

                bgList:AddItem(bgsldr)
                HighlightTab(true)
            end
        end)
    end

    function RebuildPanel()
        RebuildBgPnl()
    end

    RebuildPanel()

    function mdlListPanel:OnActivePanelChanged(old, new)
        if old != new then
            lambda_playermdl_skin:SetString("0")
            lambda_playermdl_bodygroup:SetString("0")
        end
        timer.Simple(0.1, function()
            RebuildPanel()
        end)
    end
end

vgui.Register("LambdaPlayerPanel", PANEL, "DPanel")