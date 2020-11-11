PLUGIN.name = "S.T.A.L.K.E.R. - Artifacts"
PLUGIN.author = "Sample Name"
PLUGIN.desc = "Artifact item base and items based on S.T.A.L.K.E.R.: CoP"
PLUGIN.anomalyTable = PLUGIN.anomalyTable or {}
PLUGIN.anomalyClasses = {
	["anom_bubble"] = false,
	["anom_burner"] = {"battery", "sparkler", "nightstar", "shell"},
	["anom_damage"] = false,
	["anom_deathfog"] = {"stoneblood"},
	["anom_divide"] = {"goldfish", "gravi", "stoneflower"},
	["anom_electro"] = {"battery", "sparkler", "nightstar", "shell"},
	["anom_evade"] = false,
	["anom_heat"] = {"flame", "beads", "crystall", "eye"},
	["anom_hydro"] = false,
	["anom_static"] = {"battery", "sparkler", "nightstar", "shell"},
	["anom_trapper"] = {"goldfish", "gravi", "stoneflower"},
	["anom_whirlgig"] = {"goldfish", "gravi", "stoneflower"},
}

local PLUGIN = PLUGIN

nut.util.include("sv_plugin.lua")

nut.config.add("maxArtifactsEquipped", 3, "Number of artifacts a character can wear at once.", nil, {
	data = {min = 1, max = 10},
	category = PLUGIN.name
})

nut.config.add("minArtifactRespawnTime", 180, "Minimum time (in seconds) required for artifacts to respawn.", nil, {
	data = {min = 60, max = 21600},
	category = PLUGIN.name
})

nut.config.add("maxArtifactRespawnTime", 360, "Maximum time (in seconds) required for artifacts to respawn.", nil, {
	data = {min = 60, max = 21600},
	category = PLUGIN.name
})

nut.config.add("maxArtifactsSpawned", 2, "Number of artifacts that can be spawned in one anomaly.", nil, {
	data = {min = 1, max = 5},
	category = PLUGIN.name
})

nut.config.add("freezeArtifactsAfterSpawn", false, "Whether spawned artifacts should be frozen.", nil, {
	category = PLUGIN.name
})

nut.command.add("anomalyadd", {
	adminOnly = true,
	syntax = "<string spawnName> <string anomalyClass>",
	onRun = function(client, arguments)
		local spawnName = arguments[1] or "AnomalySpawnPoint"
		local anomalyClass = arguments[2] or false
		local posVector = client:GetEyeTraceNoCursor().HitPos

		if !table.HasValue(table.GetKeys(PLUGIN.anomalyClasses), anomalyClass) then
			client:notifyLocalized("wrongAnomalyClass")
			return false
		end

		netstream.Start(client, "anomalyAddRequest", spawnName, anomalyClass, posVector)

		return "@anomalyAdded", spawnName
	end
})

nut.command.add("anomalymanager", {
	adminOnly = true,
	onRun = function(client, arguments)
		if (client:Alive()) then
			netstream.Start(client, "nutAnomalySpawnManager", PLUGIN:getAllAnomalies())
		end
	end
})

if CLIENT then
	netstream.Hook("anomalyAddRequest", function(spawnName, anomalyClass, posVector)
		netstream.Start("anomalyAdd", spawnName, anomalyClass, posVector)
	end)
end