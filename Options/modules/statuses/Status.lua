-- Library of common/shared methods

local L = Grid2Options.L

-- Grid2Options:MakeStatusLoadOptions(status, options, optionParams)
do
	local UNIT_REACTIONS = {
		friendly = L['Friendly'],
		hostile  = L['Hostile'],
		}

	local GROUP_TYPES = {
		solo  = L['Solo'],
		party = L['Party'],
		arena = L["Arena"],
		raid  = L["Raid"],
	}

	local INSTANCE_TYPES = {
		none   = L["None"],
		normal = L["Normal Dungeon"],
		heroic = L["Heroic Dungeon"],
		mythic = L["Mythic Dungeon/Raid"],
		flex   = L["Normal/Heroic Raid"],
		lfr    = L["Looking for Raid"],
		pvp    = L["PvP"],
		other  = L["Other"],
	}

	local PLAYER_CLASSES = Grid2Options.PLAYER_CLASSES

	local UNIT_TYPES = { player = L['Players'], pet = L['Pets'], boss = L['Bosses'], target = L['Target'], focus = L['Focus'], targettarget = L['Target of Target'], focustarget = L['Target of Focus'] }

	local NOYES_TYPES = { L["No"], L['Yes'] }

	local COMBAT_TYPES = { L["Out of Combat"], L['In Combat'] }

	local PLAYER_ROLES = { TANK = L['Tank'], HEALER = L['Healer'], DAMAGER = L['Damager'], NONE = L['None'] }

	local CLASSES_SPECS = {}
	if Grid2.versionCli>=30000 then
		for classID = 1, 30 do
		  local info = C_CreatureInfo.GetClassInfo(classID)
		  if info then
			local class = info.classFile
			local coord = CLASS_ICON_TCOORDS[class]
			for index=Grid2Options.GetNumSpecializationsForClassID(classID), 1,-1 do
				local _, specName, _, specIcon = Grid2Options.GetSpecializationInfoForClassID(classID, index)
				if specName and specIcon then
					CLASSES_SPECS[class..index] = string.format("|TInterface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES:0:0:0:0:256:256:%f:%f:%f:%f:0|t|T%s:0|t%s",coord[1]*256,coord[2]*256,coord[3]*256,coord[4]*256,specIcon,specName)
				end
			end
		  end
		end
	end

	local function SetFilterBooleanOptions( status, options, order, key, defValue, name, desc, values )
		local dbx = status.dbx
		options[key..'1'] = {
			type = "toggle",
			name = name,
			desc = desc,
			order = order,
			get = function(info) return dbx.load and dbx.load[key]~=nil end,
			set = function(info, value)
				if value then
					dbx.load = dbx.load or {}
					dbx.load[key] = defValue
				elseif dbx.load then
					dbx.load[key] = nil
					if not next(dbx.load) then dbx.load = nil end
				end
				status:RefreshLoad()
			end,
			disabled = function() return dbx.load and dbx.load.disabled end,
		}
		options[key..'2'] = {
			type = "select",
			name = name,
			desc = desc,
			order = order+1,
			get = function()
				if dbx.load and dbx.load[key]~=nil then
					return dbx.load[key] and 2 or 1
				end
			end,
			set = function(_,v)
				dbx.load[key] = (v==2)
				status:RefreshLoad()
			end,
			disabled = function() return not dbx.load or dbx.load.disabled or dbx.load[key]==nil end,
			values = values,
		}
		options[key..'3'] = {
			type = "description",
			name = "",
			order = order+3,
		}
	end

	local function SetFilterDropdownOptions( status, options, order, key, defValue, name, desc, values, sorting )
		local dbx = status.dbx
		options[key..'1'] = {
			type = "toggle",
			name = name,
			desc = desc,
			order = order,
			get = function(info) return dbx.load and dbx.load[key]~=nil end,
			set = function(info, value)
				if value then
					dbx.load = dbx.load or {}
					dbx.load[key] = defValue or next(values)
				elseif dbx.load then
					dbx.load[key] = nil
					if not next(dbx.load) then dbx.load = nil end
				end
				status:RefreshLoad()
			end,
			disabled = function() return dbx.load and dbx.load.disabled end,
		}
		options[key..'2'] = {
			type = "select",
			name = name,
			desc = desc,
			order = order+1,
			get = function()
				return dbx.load and dbx.load[key]
			end,
			set = function(_,v)
				dbx.load[key] = v
				status:RefreshLoad()
			end,
			disabled = function() return not dbx.load or dbx.load.disabled or dbx.load[key]==nil end,
			values = values,
			sorting = sorting,
		}
		options[key..'3'] = {
			type = "description",
			name = "",
			order = order+3,
		}
	end

	local function SetFilterOptions( status, options, order, key, values, defValue, name, desc, isUnitFilter, isSingle )
		local dbx    = status.dbx
		local filter = dbx.load and dbx.load[key]
		local multi  = filter and next(filter, next(filter))~=nil
		options[key] = {
			type = "toggle",
			name = name,
			desc = desc or name,
			order = order,
			get = function(info) return filter end,
			set = function(info)
				if multi or (isSingle and filter) then
					multi, filter, dbx.load[key] = nil, nil, nil
					if not next(dbx.load) then dbx.load = nil end
				elseif filter and not isSingle then
					multi = true
				else
					dbx.load = dbx.load or {}
					filter = { [defValue] = true }
					dbx.load[key] = filter
				end
				status:RefreshLoad()
			end,
			disabled = function() return dbx.load and dbx.load.disabled end,
		}
		options[key..'1'] = {
			type = "select",
			name = name,
			desc = desc or name,
			order = order+1,
			get = function() return filter and next(filter) end,
			set = function(_,v)
				wipe(filter)[v] = true
				status:RefreshLoad()
			end,
			disabled = function() return not filter or dbx.load.disabled end,
			hidden   = function() return multi end,
			values   = values,
		}
		options[key..'2'] = {
			type = "multiselect",
			order = order+2,
			name = name,
			get = function(info, value) return filter[value] end,
			set = function(info, value)
				filter[value] = (not filter[value]) or nil
				status:RefreshLoad()
			end,
			hidden = function() return not multi end,
			disabled = function() return dbx.load and dbx.load.disabled end,
			values = values,
		}
		options[key.."3"] = {
			type = "description",
			name = "",
			order = order+3,
		}
	end

	local function GetFilterZoneText(filter)
		if filter then
			local lines = ""
			for line in pairs(filter) do
				lines = lines .. line .. "\n"
			end
			return lines
		end
	end

	local function SetFilterZoneText(status, filter, text)
		wipe(filter)
		local count = 0
		for _,zone in pairs( { strsplit("\n,", strtrim(text)) } ) do
			zone = strtrim(zone)
			if #zone>0 then
				filter[zone], count = zone, count + 1
			end
		end
		if count==0 then
			filter[zone] = GetInstanceInfo()
		end
		status:RefreshLoad()
		return count>1
	end

	local function GetZoneDescription()
		local name,_,_,_,_,_,_,id = GetInstanceInfo()
		return string.format( L["Supports multiple names or IDs separated by commas or newlines.\n\nCurrent Instance:\n%s(%d)"], name, id )
	end

	local function SetFilterZoneOptions(status, options, order, key)
		local dbx    = status.dbx
		local filter = dbx.load and dbx.load[key]
		local multi  = filter and next(filter, next(filter))~=nil
		options[key] = {
			type = "toggle",
			name = L["Instance Name/ID"],
			desc = GetZoneDescription,
			order = order,
			get = function(info) return filter end,
			set = function(info)
				if multi then
					multi, filter, dbx.load[key] = nil, nil, nil
					if not next(dbx.load) then dbx.load = nil end
				elseif filter then
					multi = true
				else
					dbx.load = dbx.load or {}
					filter = { [ (GetInstanceInfo()) ] = true }
					dbx.load[key] = filter
				end
				status:RefreshLoad()
			end,
			disabled = function() return dbx.load and dbx.load.disabled end,
		}
		options[key..'1'] = {
			type = "input",
			name = L["Instance Name/ID"],
			order = order+1,
			get = function() return GetFilterZoneText(filter) end,
			set = function(_,v) multi = SetFilterZoneText(status, filter,v) end,
			disabled = function() return not filter or dbx.load.disabled end,
			hidden   = function() return multi end,
		}
		options[key..'2'] = {
			type = "input",
			name = L["Instance Name/ID"],
			order = order+1,
			width = "full",
			multiline = 3,
			get = function() return GetFilterZoneText(filter) end,
			set = function(_,v) multi = SetFilterZoneText(status,filter,v) end,
			hidden = function() return not multi end,
			disabled = function() return dbx.load and dbx.load.disabled end,
		}
		options[key.."3"] = {
			type = "description",
			name = "",
			order = order+3,
		}
	end

	function Grid2Options:MakeStatusLoadOptions(status, options, optionParams)
		options.Never = {
			type = "toggle",
			width = "full",
			name = L["Never"],
			desc = L["Never load this status"],
			order = 1,
			get = function(info) return status.dbx.load and status.dbx.load.disabled end,
			set = function(info, value)
				if value then
					if status.dbx.load==nil then status.dbx.load = {} end
					status.dbx.load.disabled = true
				else
					status.dbx.load.disabled = nil
					if not next(status.dbx.load) then status.dbx.load = nil end
				end
				status:RefreshLoad()
			end,
		}
		SetFilterBooleanOptions( status, options, 5,
			'combat',
			true,
			L["Combat"],
			L["Combat"],
			COMBAT_TYPES
		)
		SetFilterOptions( status, options, 10,
			'playerClass',
			PLAYER_CLASSES,
			select(2,UnitClass('player')),
			L["Player Class"],
			L["Load the status only if your toon belong to the specified class."]
		)
		if Grid2.versionCli>=30000 then
			SetFilterOptions( status, options, 20,
				'playerClassSpec',
				CLASSES_SPECS,
				Grid2.playerClass..(Grid2.GetSpecialization() or 0),
				L["Player Class&Spec"],
				L["Load the status only if your toon has the specified class and specialization."]
			)
		end
		SetFilterOptions( status, options, 40,
			'groupType',
			GROUP_TYPES,
			'solo',
			L["Group Type"],
			L["Load the status only if you are in the specified group type."]
		)
		SetFilterOptions( status, options, 50,
			'instType',
			INSTANCE_TYPES,
			'none',
			L["Instance Type"],
			L["Load the status only if you are in the specified instance type."]
		)
		SetFilterZoneOptions(status, options, 55, 'instNameID')
		if status.handlerType then
			local spells, sorted = self:GetPlayerSpells()
			SetFilterDropdownOptions( status, options, 60,
				'cooldown',
				nil,
				L["Spell Ready"],
				L["Load the status only if the specified player spell is not in cooldown."],
				spells,
				sorted
			)
		end
		if status.handlerType or (optionParams and optionParams.unitFilter) then -- hackish to detect buff/debuff type statuses
			SetFilterBooleanOptions( status, options, 65,
				'unitAlive',
				true,
				L["Unit Alive"],
				L["Load the status only if the unit is alive/dead."],
				NOYES_TYPES
			)
			SetFilterOptions( status, options, 70,
				'unitReaction',
				UNIT_REACTIONS,
				'friendly',
				L["Unit Reaction"],
				L["Load the status only if the unit has the specified reaction towards the player."],
				true, true
			)
			SetFilterOptions( status, options, 75,
				'unitClass',
				PLAYER_CLASSES,
				select(2,UnitClass('player')),
				L["Unit Class"],
				L["Load the status only if the unit belong to the specified class."],
				true
			)
			SetFilterOptions( status, options, 80,
				'unitRole',
				PLAYER_ROLES,
				'NONE',
				L["Unit Role"],
				L["Load the status only if the unit has the specified role."],
				true
			)
			SetFilterOptions( status, options, 85,
				'unitType',
				UNIT_TYPES,
				'player',
				L["Unit Type"],
				L["Load the status only for the specified unit types."],
				true
			)
			SetFilterBooleanOptions( status, options, 90,
				'unitPlayer',
				true,
				L["Unit is Me"],
				L["Load the status only if the unit is my character."],
				NOYES_TYPES
			)
		end
		return options
	end
	Grid2:RegisterMessage("Grid_StatusLoadChanged", Grid2Options.NotifyChange)
end

-- Grid2Options:MakeStatusDeleteOptions()
do
	local function DeleteStatus(info)
		local status   = info.arg.status
		local category = Grid2Options:GetStatusCategory(status)
		Grid2.db.profile.statuses[status.name] = nil
		Grid2:UnregisterStatus(status)
		Grid2Frame:UpdateIndicators()
		Grid2Options:DeleteStatusOptions(category, status)
		Grid2Options:SelectGroup('statuses', category)
	end
	function Grid2Options:MakeStatusDeleteOptions(status, options, optionParams)
		self:MakeHeaderOptions( options, "Delete")
		options.delete = {
			type = "execute",
			order = 500,
			width = "half",
			name = L["Delete"],
			desc = L["Delete this element"],
			func = DeleteStatus,
			confirm = function() return L["Are you sure you want to delete this status ?"] end,
			disabled = function() return next(status.indicators)~=nil or status:IsSuspended() end,
			arg = { status = status },
		}
		options.deletemsg = {
			type = "description", order = 510, fontSize = "small", width = "double", name = L["There are indicators linked to this status or the status is not enabled for this character."],
			hidden = function() return next(status.indicators)==nil and not status:IsSuspended() end,
		}
	end
end

-- Grid2Options:MakeStatusColorOptions()
do
	local function GetStatusColor(info)
		local c = info.arg.status.dbx["color"..(info.arg.colorIndex)]
		return c.r, c.g, c.b, c.a
	end
	local function SetStatusColor(info, r, g, b, a)
		local status = info.arg.status
		local c = status.dbx["color"..(info.arg.colorIndex)]
		c.r, c.g, c.b, c.a = r, g, b, a
		status:UpdateDB()
		status:UpdateAllUnits()
	end
	function Grid2Options:MakeStatusColorOptions(status, options, optionParams)
		local colorCount = status.dbx.colorCount or 1
		local name  = L["Color"]
		local desc  = L["Color for %s."]:format(status.name)
		local width = optionParams and optionParams.width or "half"
		for i = 1, colorCount do
			local colorKey = "color" .. i
			if optionParams and optionParams[colorKey] then
				name = optionParams[colorKey]
			elseif colorCount > 1 then
				name = L["Color %d"]:format(i)
			end
			local colorDescKey = "colorDesc" .. i
			if optionParams and optionParams[colorDescKey] then
				desc = optionParams[colorDescKey]
			elseif colorCount > 1 then
				desc = name
			end
			options[optionParams and optionParams.optionKey or colorKey] = {
				type = "color",
				order = (10 + i),
				width = width,
				name = name,
				desc = desc,
				get = GetStatusColor,
				set = SetStatusColor,
				hasAlpha = true,
				arg = {status = status, colorIndex = i },
			}
		end
	end
end

-- Grid2Options:MakeStatusColorThresholdOptions()
function Grid2Options:MakeStatusColorThresholdOptions(status, options, optionParams)
	self:MakeStatusColorOptions(status, options, optionParams)
	self:MakeStatusThresholdOptions(status, options, optionParams, nil, nil, nil, true)
end

-- Grid2Options:MakeStatusThresholdOptions()
function Grid2Options:MakeStatusThresholdOptions(status, options, optionParams, min, max, step, percent)
	options.threshold = {
		type = "range",
		order = 20,
		name = optionParams and optionParams.threshold or L["Threshold"],
		desc = optionParams and optionParams.thresholdDesc or L["Threshold at which to activate the status."],
		min = min or 0,
		max = max or 1,
		bigStep = step or 0.01,
		isPercent = percent or nil,
		get = function ()
			return status.dbx.threshold
		end,
		set = function (_, v)
			status.dbx.threshold = v
			status:Refresh()
		end,
	}
end

-- Grid2Options:MakeStatusStandardOptions()
Grid2Options.MakeStatusStandardOptions = Grid2Options.MakeStatusColorOptions
