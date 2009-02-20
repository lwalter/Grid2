-- GridCore.lua
-- insert boilerplate here

--{{{ Libraries

local L = LibStub("AceLocale-3.0"):GetLocale("Grid2")

--}}}
--{{{ Grid2
--{{{  Initialization

Grid2 = LibStub("AceAddon-3.0"):NewAddon("Grid2", "AceEvent-3.0", "AceConsole-3.0")
Grid2.debugFrame = Grid2DebugFrame or ChatFrame1
function Grid2:Debug(s, ...)
	if self.debugging then
		if s:find("%", nil, true) then
			Grid2:Print(self.debugFrame, "DEBUG", self.name, s:format(...))
		else
			Grid2:Print(self.debugFrame, "DEBUG", self.name, s, ...)
		end
	end
end

--{{{ AceDB defaults

Grid2.defaults = {
	profile = {
		debug = false,
	}
}

--}}}
--{{{  Module prototype

local modulePrototype = {}
modulePrototype.core = Grid2

function modulePrototype:OnInitialize()
	if not self.db then
		self.db = self.core.db:RegisterNamespace(self.name, self.defaultDB)
	end
	self.debugFrame = Grid2.debugFrame
	self.debugging = self.db.profile.debug
	self:Debug("OnInitialize")
	self:RegisterModules()
end

function modulePrototype:OnEnable()
	self:EnableModules()
end

function modulePrototype:OnDisable()
	self:DisableModules()
end

function modulePrototype:Reset()
	self.debugging = self.db.profile.debug
	self:Debug("Reset")
	self:ResetModules()
end

function modulePrototype:RegisterModules()
	for name, module in self:IterateModules() do
		self:RegisterModule(name, module)
	end
end

function modulePrototype:RegisterModule(name, module)
	self:Debug("Registering ", name)

	if not module.db then
		module.db = self.core.db:RegisterNamespace(name, module.defaultDB)
	end

	if Grid2Options then
		Grid2Options:AddModule(self.name, name, module)
	end
end

function modulePrototype:EnableModules()
	for name,module in self:IterateModules() do
		self:SetEnabledState(module, true)
	end
end

function modulePrototype:DisableModules()
	for name,module in self:IterateModules() do
		self:SetEnabledState(module, false)
	end
end

function modulePrototype:ResetModules()
	for name,module in self:IterateModules() do
		module:Reset()
	end
end

modulePrototype.Debug = Grid2.Debug

Grid2:SetDefaultModulePrototype(modulePrototype)
Grid2:SetDefaultModuleLibraries("AceEvent-3.0")

--}}}

function Grid2:InitializeElement(type, element)
	if element.defaultDB and not element.db then
		element.db = self.db:RegisterNamespace(type.."-"..element.name, element.defaultDB)
	end
	if Grid2Options then
		Grid2Options:AddElement(type, element)
	end
end

function Grid2:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("Grid2DB", self.defaults, "profile")

	self:RegisterChatCommand("grid2", "OnChatCommand")
	self:RegisterChatCommand("gr2", "OnChatCommand")
	local optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Grid2", "Grid2")

	local prev_OnShow = optionsFrame:GetScript("OnShow")
	optionsFrame:SetScript("OnShow", function (self, ...)
		Grid2:LoadOptions()
		self:SetScript("OnShow", prev_OnShow)
		return prev_OnShow(self, ...)
	end)

	self.optionsFrame = optionsFrame
	self:RegisterModules()

	for _, location in self:IterateLocations() do
		self:InitializeElement("location", location)
	end
	for _, indicator in self:IterateIndicators() do
		self:InitializeElement("indicator", indicator)
	end
	for _, status in self:IterateStatuses() do
		self:InitializeElement("status", status)
	end

	local media = LibStub("LibSharedMedia-3.0", true)
	if media then
		media:Register("statusbar", "Gradient", "Interface\\Addons\\Grid2\\gradient32x32")
	end
end

function Grid2:LoadOptions()
	if Grid2Options then return end
	if not IsAddOnLoaded("Grid2Options") then
		LoadAddOn("Grid2Options")
		if Grid2Options then
			Grid2Options:Initialize()
		end
	end
end

function Grid2:OnChatCommand(input)
	self:LoadOptions()
	if Grid2Options then
		Grid2Options:OnChatCommand(input)
	else
		self:Print("You need the Grid2Options addon available to be able to configure Grid2.")
	end
end

function Grid2:OnEnable()
	self:RegisterEvent("PARTY_MEMBERS_CHANGED", "RosterUpdated")
	self:RegisterEvent("RAID_ROSTER_UPDATED", "RosterUpdated")
	self:RegisterEvent("UNIT_PET")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")

	self.db.RegisterCallback(self, "OnProfileChanged")

	self:SendMessage("Grid_Enabled")

	self:EnableModules()

	self:Setup()
end

function Grid2:OnDisable()
	self:Debug("OnDisable")
	self:SendMessage("Grid_Disabled")
	self:DisableModules()
end

function Grid2:OnProfileChanged()
	self.debugging = self.db.profile.debug
	self:Debug("Loaded profile (", self:GetProfile(),")")
	self:ResetModules()
end

function Grid2:RegisterModule(name, module)
	self:Debug("Registering ", name)

	if not module.db then
		module.db = self.db:RegisterNamespace(name, module.defaultDB)
	end

	if Grid2Options then
		Grid2Options:AddModule(self.name, name, module)
	end
end

function Grid2:ResetModules()
	for name, module in self:IterateModules() do
		module.db = self.db:RegisterNamespace(name)
		module:Reset()
	end
end

Grid2.RegisterModules = modulePrototype.RegisterModules
Grid2.EnableModules = modulePrototype.EnableModules
Grid2.DisableModules = modulePrototype.DisableModules

--{{{ Event handlers

local groupType
function Grid2:PLAYER_ENTERING_WORLD()
	-- this is needed to trigger an update when switching from one BG directly to another
	groupType = nil
	return self:RosterUpdated()
end

function Grid2:RosterUpdated()
	local instType = select(2, IsInInstance())

	if instType == "none" then
		if GetNumRaidMembers() > 0 then
			instType = "raid"
		elseif GetNumPartyMembers() > 0 then
			instType = "party"
		else
			instType = "solo"
		end
	elseif instType == "raid" and GetCurrentDungeonDifficulty() > 1 then
		instType = "hraid"
	end

	self:Debug("RosterUpdated", groupType, "=>", instType)

	if groupType ~= instType then
		groupType = instType
		self:SendMessage("Grid_GroupTypeChanged", groupType)
	end

	self:UpdateRoster()
end

Grid2.framesByUnit = {}
function Grid2:SetFrameUnit(frame, unit)
	for key, value in pairs(self.framesByUnit) do
		if value == frame then
			self.framesByUnit[key] = nil
			break
		end
	end
	if unit then
		self.framesByUnit[unit] = frame
	end
end

function Grid2:GetUnitFrame(unit)
	return self.framesByUnit[unit]
end

--}}}
--}}}
