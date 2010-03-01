local Grid2StatusRaidDebuffsOptions = {}
Grid2Options.plugins["Grid2StatusRaidDebuffsOptions"] = Grid2StatusRaidDebuffsOptions

local L = LibStub("AceLocale-3.0"):GetLocale("Grid2Options")
local DBL = LibStub:GetLibrary("LibDBLayers-1.0")

function Grid2StatusRaidDebuffsOptions.UpgradeDefaults(dblData)
	local versionsSrc = dblData.versionsSrc

	if (versionsSrc.Grid2StatusRaidDebuffsOptions < 1) then
		local layer = "account"
		DBL:SetupLayerObject(dblData, "statuses", layer, "raid-debuffs", {type = "raid-debuffs", color1 = {r=1,g=.5,b=1,a=1}})
		DBL:SetupMapObject(dblData, "statusMap", layer, "icon-center", "raid-debuffs", 1000)

		DBL:SetupLayerObject(dblData, "indicators", layer, "center-left", {type = "icon", level = 9, location = "center-left", iconSize = 16, fontSize = 8,})
		DBL:SetupLayerObject(dblData, "statuses", layer, "debuff-MysticBuffet", {type = "debuff", spellName = 70127, color1 = {r=.5,g=0,b=1,a=1}})
		DBL:SetupMapObject(dblData, "statusMap", layer, "center-left", "debuff-MysticBuffet", 110)

		DBL:SetupLayerObject(dblData, "indicators", layer, "center-right", {type = "icon", level = 9, location = "center-right", iconSize = 16, fontSize = 8,})
		DBL:SetupLayerObject(dblData, "statuses", layer, "debuff-UnchainedMagic", {type = "debuff", spellName = 69762, color1 = {r=.5,g=0,b=1,a=1}})
		DBL:SetupMapObject(dblData, "statusMap", layer, "center-right", "debuff-UnchainedMagic", 110)
		
		versionsSrc.Grid2StatusRaidDebuffsOptions = 1
	end
end


local function MakeStatusOptions(self, status, options, optionParams)
	options = options or {}
	options = self:MakeStatusStandardOptions(status, options, optionParams)
	options = self:MakeStatusMissingOptions(status, options, optionParams)
	options = self:MakeStatusBlinkThresholdOptions(status, options, optionParams)
	return options
end

local prev_MakeStatusOptions = Grid2Options.MakeStatusOptions
function Grid2Options:MakeStatusOptions(dblData, reset, ...)
	self:AddOptionHandler("raid-debuffs", MakeStatusOptions)

	prev_MakeStatusOptions(self, dblData, reset, ...)
end

