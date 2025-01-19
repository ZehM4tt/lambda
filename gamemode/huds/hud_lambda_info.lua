local PANEL = {}
local colWHITE = Color(255, 255, 255, 235)
local colGRAY = Color(155, 155, 155, 175)

local gmPath = GM.Folder
local changelogText = "Unable to read changelog."
local logFile = file.Find(gmPath .. "/changelog.*", "GAME")
if logFile[1] then
    changelogText = file.Read(gmPath .. "/" .. logFile[1], "GAME")
end

local linkTbl = {
    ["Workshop"] = "https://steamcommunity.com/sharedfiles/filedetails/?id=780244493",
    ["Github"] = "https://github.com/GMLambda/Lambda",
    ["Discord"] = "https://discord.gg/K42JUbC"
}

local iTbl = {
    Title = "LAMBDA CO-OP FRAMEWORK",
    Version = "VERSION: " .. tostring(GM.Version),
    Gametype = "GAMETYPE: ",
    Authors = "Made by ZehMatt, knoxed, PotcFdk, Amic3r, dounai2333",
    Credits = "Huge thanks to the Garry's Mod team and the Metastruct servers"
}

local msg = [[
	Welcome to Lambda's general menu. 

	Here you can cast a vote, change your player 
	model or player options and even server settings.

	Stay tuned, there is more to come.
]]

local width
local startW, startH = 15, 10
local wOffset = 17

function PANEL:Init()
    width, height = self:GetParent():GetSize()
    iTbl.Gametype = "GAMETYPE: " .. string.upper(GAMEMODE:GetGameTypeData("Name"))
    local infoSheet = self:Add("DPropertySheet")
    infoSheet:Dock(FILL)
    local aboutPanel = infoSheet:Add("LambdaAboutPanel")
    infoSheet:AddSheet("ABOUT", aboutPanel)
    local changelogPanel = infoSheet:Add("LambdaChangelogPanel")
    infoSheet:AddSheet("CHANGELOG", changelogPanel)
end

vgui.Register("LambdaInfoPanel", PANEL, "DPanel")
local PANEL_ABOUT = {}

function PANEL_ABOUT:Init()
    local pnls = {}
    local titleOffset = 10
    pnls.Logo = self:Add("DImage")
    pnls.Logo:SetImage("gamemodes/lambda/icon24.png")
    pnls.Logo:SetSize(32, 32)
    pnls.Title = self:Add("DLabel")
    pnls.Title:SetFont("Trebuchet24")
    pnls.Version = self:Add("DLabel")
    pnls.Version:SetFont("HudHintTextSmall")
    pnls.Gametype = self:Add("DLabel")
    pnls.Gametype:SetFont("HudHintTextSmall")
    pnls.Authors = self:Add("DLabel")
    pnls.Authors:SetFont("Trebuchet18")
    pnls.Credits = self:Add("DLabel")

    for id, pnl in pairs(pnls) do
        if id ~= "Logo" then
            pnls[id]:SetText(iTbl[id])
            pnls[id]:SetTextColor(colWHITE)
            pnls[id]:SizeToContents()
        end
    end

    local txtStartW = width - startW - pnls.Logo:GetWide() - pnls.Title:GetWide() - titleOffset
    pnls.Logo:SetPos(startW, startH)
    pnls.Title:SetPos(txtStartW, startH)
    pnls.Version:SetPos(txtStartW, startH + pnls.Title:GetTall())
    pnls.Gametype:SetPos(txtStartW + pnls.Title:GetWide() - pnls.Gametype:GetWide(), startH + pnls.Title:GetTall())
    pnls.Authors:SetPos(width / 2 - pnls.Authors:GetWide() / 2 - wOffset, startH + pnls.Title:GetTall() * 2)
    pnls.Credits:SetPos(width / 2 - pnls.Credits:GetWide() / 2 - wOffset, startH + pnls.Title:GetTall() * 2 + pnls.Authors:GetTall())
    local btnPnls = {}
    local w = 10
    local offset = 10

    for b, l in pairs(linkTbl) do
        btnPnls[b] = self:Add("DButton")
        btnPnls[b]:SetSize(85, 22)
        btnPnls[b]:SetPos(w + offset, 100)
        btnPnls[b]:SetText(string.upper(b))
        btnPnls[b]:SetTextColor(colWHITE)

        btnPnls[b].DoClick = function(this)
            local option = DermaMenu(this)

            option:AddOption("Open", function()
                gui.OpenURL(l)
            end)

            option:AddOption("Copy", function()
                SetClipboardText(l)
            end)

            option:Open()
        end

        btnPnls[b]:SetFont("ChatFont")
        offset = offset + btnPnls[b]:GetWide() + 20
    end

    local msgTxt = self:Add("DLabel")
    msgTxt:Dock(FILL)
    msgTxt:DockMargin(5, 60, 5, 0)
    msgTxt:SetContentAlignment(5)
    msgTxt:SetText(msg)
    msgTxt:SetFont("TargetIDSmall")
    msgTxt:SetTextColor(colWHITE)
end

function PANEL_ABOUT:PaintOver()
    surface.SetDrawColor(colGRAY)
    surface.DrawLine(startW, 135, (width - wOffset) - startW * 2, 135)
end

vgui.Register("LambdaAboutPanel", PANEL_ABOUT, "DPanel")
local PANEL_CLOG = {}

function PANEL_CLOG:Init()
    local clog = self:Add("DTextEntry")
    clog:SetMultiline(true)
    clog:Dock(FILL)
    clog:SetValue(changelogText)
    clog:SetVerticalScrollbarEnabled(true)
    clog:SetEnabled(false)
    clog:SetPaintBackground(false)
    clog.AllowInput = function(this, stringValue) return true end
end

vgui.Register("LambdaChangelogPanel", PANEL_CLOG, "DPanel")