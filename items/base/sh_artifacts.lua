ITEM.name = "Artifact"
ITEM.desc = "A Artifact Base."
ITEM.category = "Artifact"
ITEM.model = "models/props_c17/BriefCase001a.mdl"
ITEM.width = 1
ITEM.height = 1
ITEM.artifactType = "uid"

-- Increases character's max health when the artifact is equipped
ITEM.health = 0

-- Increases character's max armor when the artifact is equipped
ITEM.armor = 0

-- Increases character's attributes when the artifact is equipped
ITEM.attribBoosts = {}
--[[
	ITEM.attribBoosts is a table, each key corresponds to some attribute's UID and it's value corresponds to some integer value
	Here's an example:
	ITEM.attribBoosts = {
		['stm'] = 10,
		['end'] = 10,
		['str'] = 10,
	}
	This will increase Stamina, Endurance and Strength by 10
	Attribute's UID is it's unique id, it follows the file's name
	In example, sh_str.lua is file containing Strength attribute. Cut sh_ part, so str is strength attribute's unique id
--]]

-- Increases character's regenerations when the artifact is equipped
ITEM.regenBoosts = {}
--[[
	ITEM.regenBoosts is a table, it only accepts the following keys: health, armor, hunger
	Each key has two values: integer amount, integer interval, interval can't be less than one
	Here's an example:
	ITEM.regenBoosts = {
		['health'] = { 1, 1 },
		['armor'] = { 1, 1 },
		['hunger'] = { 1, 10 },
	}
	This will regenerate 1 health per second, 1 armor per second, 1 hunger per 10 seconds
	These work the same way ITEM:intervalFunction() do, so they were just created to make editing faster and easier
--]]

-- ITEM:intervalFunction() is called every ITEM.interval seconds, by default it's nil, so ITEM:intervalFunction() isn't called
-- It can't be less than one second
ITEM.interval = nil

-- Call your custom interval functions from there, ITEM:intervalFunction() is called every second ITEM.interval seconds
function ITEM:intervalFunction()
end

-- Call your custom functions from there, ITEM:onArtifactEquipped(isFirstTime) is called when a character equips the artifact
function ITEM:onArtifactEquipped(isFirstTime)
end

-- Call your custom functions from there, ITEM:onArtifactUnEquipped() is called when a character unequips the artifact
function ITEM:onArtifactUnEquipped()
end

-- Inventory drawing
if (CLIENT) then
	-- Draw camo if it is available.
	function ITEM:paintOver(item, w, h)
		if (item:getData("equip")) then
			surface.SetDrawColor(110, 255, 110, 100)
			surface.DrawRect(w - 14, h - 14, 8, 8)
		end
	end
end

function ITEM:wearArtifact(client, isForLoadout)
	if (isnumber(self.health)) then
		client:SetMaxHealth(client:GetMaxHealth() + self.health)
	end

	if (isnumber(self.armor)) then
		client:SetMaxArmor(client:GetMaxArmor() + self.armor)
	end

	self:setupArtifactTimer()

	self:call("onArtifactEquipped", client, nil, isForLoadout)

end

function ITEM:removeArtifact(client)
	local character = client:getChar()

	self:setData("equip", nil)

	-- Remove max health bonus added by this artifact
	if (isnumber(self.health)) then
		client:SetMaxHealth(math.max(client:GetMaxHealth() - self.health, 100))
		if client:Health() > client:GetMaxHealth() then
			client:SetHealth(client:GetMaxHealth())
		end
	end

	-- Remove max armor bonus added by this artifact
	if (isnumber(self.armor)) then
		client:SetMaxArmor(math.max(client:GetMaxArmor() - self.armor, 100))
		if client:Armor() > client:GetMaxArmor() then
			client:SetArmor(client:GetMaxArmor())
		end
	end

	-- Remove attribute boosts added by this artifact
	if (istable(self.attribBoosts)) then
		for attribute, boost in pairs(self.attribBoosts) do
			self:removeArtifactBoost(attribute, boost)
		end
	end

	self:removeArtifactTimer()

	self:call("onArtifactUnEquipped", client)
end

function ITEM:addArtifactBoost(attribID, amount)
	self.player:getChar():addBoost(self.uniqueID, attribID, amount)
end

function ITEM:removeArtifactBoost(attribID, amount)
	local boosts = self.player:getChar():getVar("boosts", {})
	if boosts[attribID] and boosts[attribID][self.uniqueID] then
		self.player:getChar():removeBoost(self.uniqueID, attribID)
	end
end

function ITEM:regenerateHealthWithArtifact(client, amount)
	if !client then return end

	if client:Health() + amount <= client:GetMaxHealth()then
		client:SetHealth(client:Health() + amount)
	end
end

function ITEM:regenerateArmorWithArtifact(client, amount)
	if !client then return end

	if client:Armor() + amount <= client:GetMaxArmor() then
		client:SetArmor(client:Armor() + amount)
	end
end

function ITEM:regenerateHungerWithArtifact(client, amount)
	if !client then return end

	client:addHunger(amount) 
end
  
function ITEM:setupArtifactTimer()
	-- Table and value initialization takes time, so we better do it the safe way
	local uniqueID = "artifactFunctions"..self.player:getChar().id
	local charToFollow = self.player:getChar().id
	local playerToFollow = self.player

	artifactFunctions[charToFollow] = artifactFunctions[charToFollow] or {}

	artifactFunctions[charToFollow][self.uniqueID] = {}
	for toRegenerate, v in pairs(self.regenBoosts) do
		artifactFunctions[charToFollow][self.uniqueID][toRegenerate] = { v[1], v[2], CurTime() }
	end
	artifactFunctions[charToFollow][self.uniqueID]["interval"] = { self.interval or nil, CurTime() }

	timer.Create(uniqueID, 1, 0, function()
		-- Make sure timer is only initialized when the character is present
		if !IsValid(playerToFollow) or !playerToFollow:getChar() or !playerToFollow:getChar().id == charToFollow or !artifactFunctions[charToFollow] then
			timer.Remove(uniqueID)
			artifactFunctions[charToFollow] = nil
			return
		end

		-- Make sure timer functions don't work when the character is dead
		if !playerToFollow:Alive() then return end
		
		if artifactFunctions[charToFollow] and artifactFunctions[charToFollow][self.uniqueID] then
			-- Health regeneration
			if artifactFunctions[charToFollow][self.uniqueID]["health"] then
				if CurTime() < artifactFunctions[charToFollow][self.uniqueID]["health"][3] then return end
				self:regenerateHealthWithArtifact(playerToFollow, artifactFunctions[charToFollow][self.uniqueID]["health"][1])
				artifactFunctions[charToFollow][self.uniqueID]["health"][3] = CurTime() + artifactFunctions[charToFollow][self.uniqueID]["health"][2]
			end

			-- Armor regeneration
			if artifactFunctions[charToFollow][self.uniqueID]["armor"] then
				if CurTime() < artifactFunctions[charToFollow][self.uniqueID]["armor"][3] then return end
				self:regenerateArmorWithArtifact(playerToFollow, artifactFunctions[charToFollow][self.uniqueID]["armor"][1])
				artifactFunctions[charToFollow][self.uniqueID]["armor"][3] = CurTime() + artifactFunctions[charToFollow][self.uniqueID]["armor"][2]
			end

			-- Hunger regeneration
			if artifactFunctions[charToFollow][self.uniqueID]["hunger"] then
				if CurTime() < artifactFunctions[charToFollow][self.uniqueID]["hunger"][3] then return end
				self:regenerateHungerWithArtifact(playerToFollow, artifactFunctions[charToFollow][self.uniqueID]["hunger"][1])
				artifactFunctions[charToFollow][self.uniqueID]["hunger"][3] = CurTime() + artifactFunctions[charToFollow][self.uniqueID]["hunger"][2]
			end

			-- Custom interval functions
			if self.interval and artifactFunctions[charToFollow][self.uniqueID]["interval"] then
				if CurTime() < artifactFunctions[charToFollow][self.uniqueID]["interval"][2] then return end
				self:intervalFunction()
				artifactFunctions[charToFollow][self.uniqueID]["interval"][2] = CurTime() + artifactFunctions[charToFollow][self.uniqueID]["interval"][1]
			end
		end
	end)
end

function ITEM:removeArtifactTimer()
	if artifactFunctions[self.player:getChar().id] then
		artifactFunctions[self.player:getChar().id][self.uniqueID] = nil
	end
end

ITEM:hook("drop", function(item)
	if (item:getData("equip")) then
		item:removeArtifact(item.player)
	end
end)

ITEM:hook("take", function(item)
	if item:getData("anomalyID") then
		anomReduceArtifactCount(item:getData("anomalyID"))
		item:setData("anomalyID", false)
	end
end)

ITEM.functions.EquipUn = {
	name = "Unequip",
	tip = "equipTip",
	icon = "icon16/cross.png",
	onRun = function(item)
		item:removeArtifact(item.player)
		return false
	end,
	onCanRun = function(item)
		return not IsValid(item.entity) and item:getData("equip") == true
	end
}

ITEM.functions.Equip = {
	name = "Equip",
	tip = "equipTip",
	icon = "icon16/tick.png",
	onRun = function(item)
		local char = item.player:getChar()
		local items = char:getInv():getItems()

		local artifactsEquipped = 0
		for id, other in pairs(items) do
			-- A character can't wear multiple artifacts of the same type
			if (
				item ~= other and
				item.artifactType == other.artifactType and
				other:getData("equip")
			) then
				item.player:notifyLocalized("sameArtifactType")
				return false
			end

			-- Count how many artifacts are already equipped
			if (
				item ~= other and
				item.artifactType and
				other:getData("equip")
			) then
				artifactsEquipped = artifactsEquipped + 1
			end
		end

		-- Make sure a character can't equip more artifacts than set in the config
		if artifactsEquipped > nut.config.get("maxArtifactsEquipped") - 1 then 
			item.player:notifyLocalized("artifactLimitReached")
			return false
		end

		item:setData("equip", true)

		-- Add artifact's attribute boosts
		if (istable(item.attribBoosts)) then
			for attribute, boost in pairs(item.attribBoosts) do
				item:addArtifactBoost(attribute, boost)
			end
		end

		item:wearArtifact(item.player, false)

		return false
	end,
	onCanRun = function(item)
		return not IsValid(item.entity) and item:getData("equip") ~= true
	end
}

function ITEM:onCanBeTransfered(oldInventory, newInventory)
	if (newInventory and self:getData("equip")) then
		return false
	end

	return true
end

function ITEM:onLoadout()
	if (self:getData("equip")) then
		self:wearArtifact(self.player, true)
	end
end

function ITEM:onRemoved()
	local inv = nut.item.inventories[self.invID]
	if (IsValid(receiver) and receiver:IsPlayer()) then
		if (self:getData("equip")) then
			self:removeArtifact(receiver)
		end
	end
end

function ITEM:onInstanced(id)
	self:setData("isArtifact", true)
end