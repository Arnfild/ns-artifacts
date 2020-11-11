local PLUGIN = PLUGIN

PLUGIN.anomalyTable = PLUGIN.anomalyTable or {}
PLUGIN.anomalyClasses = PLUGIN.anomalyClasses or {}
artifactFunctions = artifactFunctions or {}

--[[
	We have to make sure artifacts aren't destroyed by anomalies. Darsenvall's Anomalies (https://steamcommunity.com/sharedfiles/filedetails/?id=251251473)
	Use point_hurt to apply damage, mostly anomalies that are placed in Hammer Editor work the same way
	So the only option is to scale damage by 0 :smorc:
--]]
function PLUGIN:EntityTakeDamage(entity, dmgInfo)
	if entity:GetClass() == "nut_item" and entity:getData("isArtifact") then
		if dmgInfo:GetAttacker():GetClass() == "point_hurt" then  
			dmgInfo:ScaleDamage(0)
			return 
		end
	end
end

function PLUGIN:getAnomaly(anomalyID)
    return PLUGIN.anomalyTable[anomalyID]
end

function PLUGIN:getAllAnomalies()
    return PLUGIN.anomalyTable
end

function PLUGIN:saveAnomalies()
    self:setData(self.anomalyTable)
end

function PLUGIN:LoadData()
    self.anomalyTable = self:getData() or {}

    if self.anomalyTable then
		for k, anomaly in ipairs(self.anomalyTable) do
            local anom = ents.Create(anomaly.anomalyClass)
            anom:SetPos(anomaly.posVector)
            anom:Spawn()
            anomaly.anomalyObject = anom
        end
        PLUGIN:saveAnomalies()
    end
end

function PLUGIN:addAnomaly(spawnName, anomalyClass, posVector, anomalyObject)
    if (!spawnName or !anomalyClass or !posVector) then
        return false, "Required arguments are not provided."
    end

    table.insert(PLUGIN.anomalyTable, {
        spawnName = spawnName,
        anomalyClass = anomalyClass,
        posVector = posVector,
        nextSpawn = CurTime() + math.random(nut.config.get("minArtifactRespawnTime"), nut.config.get("maxArtifactRespawnTime")),
        anomalyObject = anomalyObject or false,
        artifactsCount = 0,
    })

    PLUGIN:saveAnomalies()
end

function PLUGIN:spawnArtifact(anomalyID)
    local anomaly = PLUGIN:getAnomaly(anomalyID)
    if !anomaly then return false end
    if !anomaly.anomalyObject then return false end
    if !PLUGIN.anomalyClasses[anomaly.anomalyClass] then return false end
    if anomaly.artifactsCount >= nut.config.get("maxArtifactsSpawned") then return end
    anomaly.artifactsCount = anomaly.artifactsCount + 1
    local item = nut.item.spawn(table.Random(PLUGIN.anomalyClasses[anomaly.anomalyClass]), anomaly.posVector + Vector(0, 0, 20))
    item.value:setData("anomalyID", anomalyID)
    if nut.config.get("freezeArtifactsAfterSpawn") == true then
        timer.Simple(1, function()
            if item.value:getEntity() then
                item.value:getEntity():SetMoveType(MOVETYPE_NONE)
            end
        end)
    end
end

function anomReduceArtifactCount(anomalyID)
    if !PLUGIN:getAnomaly(anomalyID) then return end
    local anomaly = PLUGIN:getAnomaly(anomalyID)
    anomaly.artifactsCount = anomaly.artifactsCount - 1
    PLUGIN:saveAnomalies()
end

netstream.Hook("anomalyTeleport", function(client, anomalyID, editData)
    if (!client:IsAdmin()) then
        return false
    end

    local anomalyData = table.Copy(PLUGIN:getAnomaly(anomalyID))

    if (anomalyData) then
        client:SetPos(anomalyData.posVector)
    end
end)

netstream.Hook("anomalyAdd", function(client, spawnName, anomalyClass, posVector)
    if (!client:IsAdmin() or !spawnName or !anomalyClass or !posVector) then
        return false
    end

    local anom = ents.Create(anomalyClass)
    anom:SetPos(posVector)
    anom:Spawn()

    PLUGIN:addAnomaly(spawnName, anomalyClass, posVector, anom)
end)

netstream.Hook("anomalyRemove", function(client, anomalyID, editData)
    if (!client:IsAdmin()) then
        return false
    end

    local anomalyData = table.Copy(PLUGIN:getAnomaly(anomalyID))
    if (anomalyData) then
        client:notifyLocalized("anomalyRemoved", PLUGIN.anomalyTable[anomalyID].spawnName)
        if PLUGIN.anomalyTable[anomalyID].anomalyObject and IsValid(PLUGIN.anomalyTable[anomalyID].anomalyObject) then
            PLUGIN.anomalyTable[anomalyID].anomalyObject:Remove()
        end
        PLUGIN.anomalyTable[anomalyID] = nil
        PLUGIN:saveAnomalies()
    end
end)

PLUGIN.anomalyTable = PLUGIN:getAllAnomalies()
timer.Create("anomalySpawner", 3, 0, function()
    local saveFlag = false
    for k, anomaly in pairs(PLUGIN.anomalyTable) do
        if CurTime() > anomaly.nextSpawn and anomaly.artifactsCount < nut.config.get("maxArtifactsSpawned") and IsValid(anomaly.anomalyObject) then 
            anomaly.nextSpawn = CurTime() + math.random(nut.config.get("minArtifactRespawnTime"), nut.config.get("maxArtifactRespawnTime"))
            PLUGIN:spawnArtifact(k)
            saveFlag = true
        end
    end
    if saveFlag then PLUGIN:saveAnomalies() end
end)