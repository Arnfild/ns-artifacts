local PLUGIN = PLUGIN
local PANEL = {}

function PANEL:Init()
	self:SetTitle(L("anomalySpawnManager"))
	self:SetSize(500, 400)
	self:Center()
	self:MakePopup()

	local noticeBar = self:Add("DLabel")
	noticeBar:Dock(TOP)
	noticeBar:SetTextColor(color_white)
	noticeBar:SetExpensiveShadow(1, color_black)
	noticeBar:SetContentAlignment(8)
	noticeBar:SetFont("nutChatFont")
	noticeBar:SizeToContents()
	noticeBar:SetText(L"anomalySpawnManagerTip")

	self.list = self:Add("PanelList")
	self.list:Dock(FILL)
	self.list:DockMargin(0, 5, 0, 0)
	self.list:SetSpacing(5)
	self.list:SetPadding(5)
	self.list:EnableVerticalScrollbar()

	self:loadSpawnPoints()
end

function PANEL:loadSpawnPoints()
	for class, data in pairs(PLUGIN.areaTable) do
		local panel = self.list:Add("DButton")
		panel:SetText(data.spawnName.."\n"..data.anomalyClass)
		panel:SetFont("ChatFont")
		panel:SetTextColor(color_white)
		panel:SetTall(50)
		panel:SetContentAlignment(1)
		panel:SizeToContentsY()
		panel:SizeToContentsX()
		--panel:SetWrap(true)
		local onConfirm = function(newName)
			netstream.Start("areaEdit", class, {name = newName})
			self:Close()
		end
		panel.OnMousePressed = function(this, code)
			if (code == MOUSE_RIGHT) then
				surface.PlaySound("buttons/blip2.wav")

				local menu = DermaMenu()
					menu:AddOption(L"moveToArea", function()
						netstream.Start("anomalyTeleport", class)
					end):SetImage("icon16/door_in.png")
					menu:AddOption(L"deleteArea", function()
						netstream.Start("anomalyRemove", class)
						self:Close()
					end):SetImage("icon16/cross.png")
				menu:Open()
			end
		end
		self.list:AddItem(panel)
	end
end

vgui.Register("nutAnomalySpawnManager", PANEL, "DFrame")

netstream.Hook("nutAnomalySpawnManager", function(areaList)
	PLUGIN.areaTable = areaList
	AnomalySpawnManager = vgui.Create("nutAnomalySpawnManager")
end)
