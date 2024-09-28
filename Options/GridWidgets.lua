-------------------------------------------------------------------------------------------------
-- Grid2 AceGUI widgets to be used in AceConfigTables, using dialogControl property.
-------------------------------------------------------------------------------------------------

local AceGUI = LibStub("AceGUI-3.0", true)
local AceDlg = LibStub("AceConfigDialog-3.0")

local optionsFrame -- Main Grid2Options AceGUI widget frame

-------------------------------------------------------------------------------------------------
-- Grid2 Main Options Widget:
-- A Modified AceGUI "Frame" widget see: AceGUIContainer-Frame.lua
-------------------------------------------------------------------------------------------------
do
	local WidgetType = "Grid2OptionsFrame"

	local function Frame_OnClose(frame)
		AceGUI:Release(frame.obj)
		Grid2Options:SetLayoutTestMode(false)
		Grid2Options.optionsFrame = nil
	end

	local function TestButton_OnClick(frame)
		Grid2Options:SetLayoutTestMode()
	end

	AceGUI:RegisterWidgetType( WidgetType, function()
		assert(optionsFrame==nil, "Error: Only one Grid2 options frame can be created.")
		local widget = AceGUI:Create("Frame")
		widget.type = WidgetType
		widget.frame:SetScript("OnHide", Frame_OnClose)
		-- min frame size
		if widget.frame.SetResizeBounds then
			widget.frame:SetResizeBounds(570, 500)
		else
			widget.frame:SetMinResize(570, 500)
		end
		-- changing button status text widget position and width to make room for a test button
		local statusbg = widget.statustext:GetParent()
		statusbg:SetPoint("BOTTOMLEFT", 132, 15)
		statusbg:SetPoint("BOTTOMRIGHT", -132, 15) -- statusbg in AceGUIContainer-frame
		-- changing height of down sizer frame to avoid overlap with the Test Layout button
		widget.sizer_s:SetHeight(16)
		-- test layout Button
		local button = CreateFrame("Button", nil, widget.frame, "UIPanelButtonTemplate")
		button:SetPoint("BOTTOMLEFT", 27, 17)
		button:SetHeight(20)
		button:SetWidth(100)
		button:SetText( Grid2Options.L["Test"] )
		button:SetScript("OnClick", TestButton_OnClick)
		-- to close the frame with ESCAPE key, warning: _G["Grid2OptionsFrame"] == Grid2Options.optionsFrame.frame
		_G["Grid2OptionsFrame"] = widget.frame
		table.insert(UISpecialFrames, "Grid2OptionsFrame")
		-- for failsafe check
		optionsFrame = widget
		return widget
	end , 1)
end

-------------------------------------------------------------------------------------------------
-- Modified Multiline Editbox that vertical fills the parent container even in AceConfigDialog Flow layouts.
-- The multiline editbox must be the last defined element in an AceConfigTable.
-------------------------------------------------------------------------------------------------
do
	local WidgetType, container = "Grid2ExpandedEditBox"
	local function Resize(frame, width, height)
		if not container then -- container used as recursion lock
			container = frame.obj.parent
			frame.obj:SetHeight( frame:GetTop() - container.frame:GetBottom() - 2 )
			container = nil
		end
	end
	AceGUI:RegisterWidgetType( WidgetType, function()
		local widget = AceGUI:Create("MultiLineEditBox")
		widget.type = WidgetType
		widget.frame:HookScript("OnSizeChanged", Resize)
		return widget
	end , 1)
end

-------------------------------------------------------------------------------------------------
-- Custom "description" AceConfigDialog control
-- Title displayed on top of the configuration panel for items like statuses, indicators, etc
-- optional action icons displayed on the top right can be defined.
-- AceConfigTable option usage example:
--	iconsTable = {
--		size = 32, padding = 2, spacing = 4 , offsetx = 0, offsety = 0, anchor = 'TOPRIGHT',
--		[1] = { image = "Path to icon texture", tooltip = "Delete Item", func = deleteFunction },
--		[2] = { image = "Path to icon texture", tooltip = 'Create Item', func = createFunction },
--	} )
--  description = {
--	  type  = "description", dialogControl = "Grid2Title",
--    order = 0, width = "full", fontSize = "large",
--	  image = icon, imageWidth = 34, imageHeight = 34, name = "Title", desc = "Tooltip",
--	  arg = iconsTable || { icons = iconsTable },
--  }
-------------------------------------------------------------------------------------------------
do
	local Type, Version = "Grid2Title", 1

	-- tooltips management
	local function ShowTooltip(frame, text)
		local tooltip = AceGUI.tooltip
		tooltip:SetOwner(frame, "ANCHOR_NONE")
		tooltip:ClearAllPoints()
		tooltip:SetPoint("TOP",frame,"BOTTOM", 0, -8)
		tooltip:ClearLines()
		if text:find( "^spell:%d+$" ) then
			tooltip:SetHyperlink(text)
		else
			tooltip:SetText(text , 1, 1, 1, 1, true)
		end
		tooltip:Show()
	end

	local function OnEnter(frame)
		local desc = frame.obj.userdata.option.desc
		if desc then
			ShowTooltip(frame, desc)
		end
	end

	local function OnLeave(frame)
		AceGUI.tooltip:Hide()
	end

	local function OnIconEnter(self)
		local option = self.parentObj.options[self.index]
		if option.tooltip then
			ShowTooltip(self.frame, option.tooltip)
		end
	end

	local function OnIconClick(self)
		local option = self.parentObj.options[self.index]
		if option.func then
			option.func( self.parentObj.userdata, self.index )
		end
	end

	-- create action icons when AceConfigTable userdata configuration is available
	local function OnShow(frame)
		local self = frame.obj
		local options = self.userdata and self.userdata.option
		if options then
			frame:SetScript("OnShow",nil)
			self.options = options.arg and options.arg.icons or options.arg
			if self.options then
				self:AcquireIcons()
			end
		end
	end

	local methods = {
		["OnAcquire"] = function(self)
			self:SetWidth(200)
			self:SetText()
			self:SetColor()
			self:SetFontObject()
			self:SetJustifyH("LEFT")
			self:SetJustifyV("TOP")
			self:SetImage()
			self:SetImageSize(32,32)
			self.frame:SetScript("OnShow",OnShow)
		end,
		["OnRelease"] = function(self)
			for _,icon in ipairs(self.icons) do
				icon.index, icon.parentObj = nil, nil
				icon:Release()
			end
			wipe(self.icons)
			self.options = nil
		end,
		["SetImageSize"] = function(self, width, height)
			self.image:SetWidth(width)
			self.image:SetHeight(height)
			self:SetHeight(height+3)
		end,
		["SetImage"] = function(self, path,...)
			self.image:SetTexture(path)
			local n = select("#", ...)
			if n == 4 or n == 8 then
				self.image:SetTexCoord(...)
			else
				self.image:SetTexCoord(0, 1, 0, 1)
			end
		end,
		["SetText"] = function(self, text)
			self.label:SetText(text)
		end,
		["SetColor"]= function(self, r, g, b)
			self.label:SetVertexColor(r or 1, g or 1, b or 1)
		end,
		["SetFont"] = function(self, font, height, flags)
			self.label:SetFont(font, height, flags)
		end,
		["SetFontObject"] = function(self, font)
			self:SetFont((font or GameFontHighlightSmall):GetFont())
		end,
		["SetJustifyH"] = function(self, justifyH)
			self.label:SetJustifyH(justifyH)
		end,
		["SetJustifyV"] = function(self, justifyV)
			self.label:SetJustifyV(justifyV)
		end,
		["AcquireIcons"] = function(self)
			local options  = self.options
			local spacing  = options.spacing or 0
			local iconSize = options.size or 32
			local offsetx  = options.offsetx or 0
			local offsety  = options.offsety or 0
			local anchor   = options.anchor or 'TOPRIGHT'
			local imgSize  = iconSize - (options.padding or 0)*2
			local multx    = string.find(anchor,'LEFT') and (iconSize+spacing) or -(iconSize+spacing)
			for i,option in ipairs(options) do
				local icon = AceGUI:Create("Icon")
				icon.index = i
				icon.parentObj = self
				icon:SetImage(option.image)
				icon:SetImageSize(imgSize,imgSize)
				icon:SetHeight(iconSize)
				icon:SetWidth(iconSize)
				icon:SetCallback( "OnClick", OnIconClick )
				icon:SetCallback( "OnEnter", OnIconEnter )
				icon:SetCallback( "OnLeave", OnLeave )
				icon.frame:SetParent( self.frame )
				icon.frame:SetPoint( anchor, (i-1)*multx+offsetx, offsety )
				icon.image:ClearAllPoints()
				icon.image:SetPoint( "CENTER" )
				icon.frame:Show()
				self.icons[i] = icon
			end
		end
	}

	local function Constructor()
		local frame = CreateFrame("Frame", nil, UIParent)
		frame:EnableMouse(true)
		frame:SetScript("OnEnter", OnEnter)
		frame:SetScript("OnLeave", OnLeave)
		frame:Hide()

		local image = frame:CreateTexture(nil, "BACKGROUND")
		image:SetPoint("TOPLEFT")

		local label = frame:CreateFontString(nil, "BACKGROUND", "GameFontHighlightSmall")
		label:SetPoint("LEFT", image, "RIGHT", 4, 0)

		local line = frame:CreateTexture(nil, "BACKGROUND")
		line:SetHeight(6)
		line:SetPoint("BOTTOMLEFT", 0, -4)
		line:SetPoint("BOTTOMRIGHT", 0, -4)
		line:SetTexture(137057) -- Interface\\Tooltips\\UI-Tooltip-Border
		line:SetTexCoord(0.81, 0.94, 0.5, 1)

		local widget = { label = label, image = image, frame = frame, type  = Type, line = line, icons = {} }
		for method, func in pairs(methods) do
			widget[method] = func
		end

		return AceGUI:RegisterAsWidget(widget)
	end

	AceGUI:RegisterWidgetType(Type, Constructor, Version)
end

-------------------------------------------------------------------------------------------------
-- Widget to manage statuses mapped to indicators.
-------------------------------------------------------------------------------------------------
do
	local WidgetType = "Grid2IndicatorCurrentStatuses"

	local dummy = function() end
	local sorttable = {}
	local curwidth = 0

	local function OnWidthSet(self, width)
		self:OnWidthSetP(width)
		if math.abs(width-curwidth)>1.5 then
			local scroll = self.children[1]
			if scroll then
				local children = scroll.children
				for i=1,#children,4 do
					children[i]:SetWidth(width-120)
				end
				curwidth = width
			end
		end
	end

	local function Execute(widget) -- Code specific for AceConfigDialog because custom multiselect management code is bugged/unfinished in AceConfigDialog library
		local user = widget.parent.parent:GetUserDataTable()
		user.option.set( user, widget:GetUserData('cmd'), widget:GetUserData('key') )
		AceDlg:Open('Grid2', optionsFrame, unpack(optionsFrame:GetUserData('basepath') or {}))
	end

	local function CreateItem(parent, type, event, key, cmd, width, imglabel, tooltip)
		local item = AceGUI:Create(type)
		item:SetUserData('key', key)
		item:SetUserData('cmd', cmd)
		item:SetWidth(width)
		item:SetCallback(event, Execute)
		if type=='Icon' then
			item:SetImage(imglabel)
			item:SetImageSize(16,14)
		else
			item:SetLabel(imglabel)
			item:SetValue(true)
		end
		item:SetHeight(18)
		parent:AddChild(item)
	end

	local function SetList(self, values)
		-- sort values
		for key, desc in pairs(values) do
			sorttable[#sorttable+1] = key
		end
		table.sort(sorttable)
		-- create scroll
		local scroll = AceGUI:Create("ScrollFrame")
		scroll:SetLayout("Flow")
		scroll:SetFullWidth(true)
		scroll:SetFullHeight(false)
		self:PauseLayout()
		self:AddChild(scroll)
		-- create checkbox & icons
		curwidth = math.max(250, curwidth)
		for _,key in ipairs(sorttable) do
			CreateItem( scroll, 'CheckBox', 'OnValueChanged', key, 'rm', curwidth - 120, values[key] )
			if #sorttable>1 then
				CreateItem( scroll, 'Icon', 'OnClick', key, 'up', 25, "Interface\\Addons\\Grid2Options\\media\\arrow-up" )
				CreateItem( scroll, 'Icon', 'OnClick', key, 'dn', 25, "Interface\\Addons\\Grid2Options\\media\\arrow-down" )
			end
			CreateItem( scroll, 'Icon', 'OnClick', key, 'st', 25, "Interface\\Addons\\Grid2Options\\media\\test" )
		end
		-- adjust height
		local child = scroll.children[1]
		local rows = math.min(#sorttable,10)
		scroll:SetHeight( child and (child.frame.height+3)*rows+6 or 4 )
		self:ResumeLayout()
		-- clean up
		wipe(sorttable)
	end

	AceGUI:RegisterWidgetType( WidgetType, function()
		local widget = AceGUI:Create("InlineGroup")
		widget.type = WidgetType
		widget.SetLabel = widget.SetTitle
		widget.SetList = SetList
		widget.OnWidthSetP = widget.OnWidthSet
		widget.OnWidthSet  = OnWidthSet
		widget.SetMultiselect = dummy
		widget.SetItemValue = dummy
		widget.SetDisabled = dummy
		return widget
	end , 1)
end

-------------------------------------------------------------------------------------------------
-- Widget to manage available statuses for an indicator.
-------------------------------------------------------------------------------------------------
do
	local WidgetType = "Grid2SimpleMultiselect"

	local sorttable, dummy = {}, function() end

	local function Execute(widget, event, ...) -- Code specific for AceConfigDialog because custom multiselect management code is bugged/unfinished in AceConfigDialog library
		local user = widget.parent:GetUserDataTable()
		user.option.set( user, widget:GetUserData("value"), ... )
		AceDlg:Open('Grid2', optionsFrame, unpack(optionsFrame:GetUserData('basepath') or {}))
	end

	local function SetList(self, values)
		-- sort values
		for key, desc in pairs(values) do
			sorttable[#sorttable+1] = key
		end
		table.sort(sorttable, function(a,b) return values[a]<values[b] end )
		-- create checkboxes
		local children = {}
		self:PauseLayout()
		self:SetFullWidth(true)
		self:SetLayout("Flow")
		self:SetUserData('children',children)
		for idx,key in ipairs(sorttable) do
			local check = AceGUI:Create("CheckBox")
			check:SetUserData("value", key)
			check:SetWidth(225)
			check:SetCallback("OnValueChanged", Execute)
			check:SetLabel(values[key])
			check:SetValue(false)
			check:SetHeight(18)
			self:AddChild(check)
			children[key] = check
		end
		self:ResumeLayout()
		-- clean up
		wipe(sorttable)
	end

	local function SetItemValue (self, key, value)
		local check = self:GetUserData('children')[key]
		if check and check.checked ~= value then
			check:SetValue(value)
		end
	end

	AceGUI:RegisterWidgetType( WidgetType, function()
		local widget = AceGUI:Create("SimpleGroup")
		widget.type = WidgetType
		widget.SetList = SetList
		widget.SetItemValue = SetItemValue
		widget.SetMultiselect = dummy
		widget.SetDisabled = dummy
		widget.SetLabel = dummy
		return widget
	end , 1)
end
