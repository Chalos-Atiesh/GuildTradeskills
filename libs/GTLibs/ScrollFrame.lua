--[[-----------------------------------------------------------------------------
ScrollFrame Container
Plain container that scrolls its content and doesn't grow in height.
-------------------------------------------------------------------------------]]
local Type, Version = 'InfiniteScrollFrame', 26
local AceGUI = LibStub and LibStub('AceGUI-3.0', true)
if not AceGUI or (AceGUI:GetWidgetVersion(Type) or 0) >= Version then return end

-- Lua APIs
local pairs, assert, type = pairs, assert, type
local min, max, floor = math.min, math.max, math.floor

-- WoW APIs
local CreateFrame, UIParent = CreateFrame, UIParent

--[[-----------------------------------------------------------------------------
Support functions
-------------------------------------------------------------------------------]]
local function FixScrollOnUpdate(frame)
	frame:SetScript('OnUpdate', nil)
	frame.obj:FixScroll()
end

--[[-----------------------------------------------------------------------------
Scripts
-------------------------------------------------------------------------------]]
local function ScrollFrame_OnMouseWheel(frame, value)
	frame.obj:MoveScroll(value)
end

local function ScrollFrame_OnSizeChanged(frame)
	frame:SetScript('OnUpdate', FixScrollOnUpdate)
end

local function ScrollBar_OnScrollValueChanged(frame, value)
	frame.obj:SetScroll(value)
end

--[[-----------------------------------------------------------------------------
Methods
-------------------------------------------------------------------------------]]
local methods = {
	['OnAcquire'] = function(self)
		self:SetScroll(0)
		self.scrollframe:SetScript('OnUpdate', FixScrollOnUpdate)
	end,

	['OnRelease'] = function(self)
		self.status.offset = 0
		self.scrollframe:SetPoint('BOTTOMRIGHT')
		self.scrollbar:Hide()
		self.scrollBarShown = nil
		self.allChildren = {}
		self.max = 1
		self.content.height, self.content.width, self.content.original_width = nil, nil, nil
	end,

	['GetTrueContentHeight'] = function(self)
		if self.allChildren ~= nil then
			local children = {self.content:GetChildren()}
			local singleHeight = 0
			for _, child in pairs(children) do
				singleHeight = child:GetHeight()
				break
			end
			-- print('GetTrueContentHeight', #self.allChildren, math.floor(singleHeight), math.floor(height))
			return #self.allChildren * singleHeight
		else
			return self.content:GetHeight()
		end

		return contentHeight
	end,

	['GetScroll'] = function(self)
		return self.status.offset
	end,

	['SetScroll'] = function(self, offset)
		local scrollHeight = self.scrollframe:GetHeight()
		local contentHeight = self:GetTrueContentHeight()
		local childHeight = contentHeight / #self.allChildren
		topOffset = 0
		bottomOffset = self.max

		if scrollHeight < contentHeight then
			topOffset = offset + 1
			bottomOffset = ceil(offset + (scrollHeight / childHeight)) + 1
		end

		if self.status.offset ~= nil and self.status.offset == offset then return end

		self.content:ClearAllPoints()
		self.content:SetPoint('TOPLEFT', 0, 0)
		self.content:SetPoint('TOPRIGHT', 0, 0)
		if not self.updateLock then
			self.updateLock = true

			-- print('SetScroll', floor(offset), floor(topOffset), floor(bottomOffset))
			self:ReleaseChildren()
			for i, child in pairs(self.allChildren) do
				if child.height ~= nil then
					childHeight = child.height
				end
				if child.shown and i > topOffset and i <= bottomOffset then
					-- print('SetScroll_Show', floor(topOffset), floor(bottomOffset), i, child.label)
					local widget = self:CreateWidget(child)
					child.widget = widget

					self:AddChild(widget)

				end
			end
			self.updateLock = nil
		end
		-- print('SetScroll', status.offset, offset, value)
		self.status.offset = offset
	end,

	['MoveScroll'] = function(self, value)
		if self.scrollBarShown then
			local delta = 1
			if value < 0 then
				delta = 1
			else
				delta = -1
			end
			local newValue = self.status.offset + delta
			-- print('MoveScroll', self.status.offset, value, delta, newValue)
			self.scrollbar:SetValue(newValue)
		end
	end,

	['FixScroll'] = function(self)
		if self.updateLock then return end
		self.updateLock = true
		local scrollHeight = self.scrollframe:GetHeight()
		local contentHeight = self:GetTrueContentHeight()

		local offset = self.status.offset or 0
		-- Give us a margin of error of 2 pixels to stop some conditions that i would blame on floating point inaccuracys
		-- No-one is going to miss 2 pixels at the bottom of the frame, anyhow!
		if contentHeight < scrollHeight + 2 then
			if self.scrollBarShown then
				-- print('FixScroll_HideScrollBar')
				self.scrollBarShown = nil
				self.scrollbar:Hide()
				self.scrollbar:SetValue(0)
				self.scrollframe:SetPoint('BOTTOMRIGHT')
				if self.content.original_width then
					self.content.width = self.content.original_width
				end
				self:DoLayout()
			end
		else
			if not self.scrollBarShown then
				-- print('FixScroll_ShowScrollBar')
				self.scrollBarShown = true
				self.scrollbar:Show()
				self.scrollframe:SetPoint('BOTTOMRIGHT', -20, 0)
				if self.content.original_width then
					self.content.width = self.content.original_width - 20
				end
				self:DoLayout()
			end
			self.scrollbar:SetValue(offset)
			self:SetScroll(offset)
			if offset < self.max then
				self.content:ClearAllPoints()
				self.content:SetPoint('TOPLEFT', 0, 0)
				self.content:SetPoint('TOPRIGHT', 0, 0)
				self.status.offset = offset
			end
		end
		self.updateLock = nil
	end,

	['LayoutFinished'] = function(self, width, height)
		self.content:SetHeight(height or 0 + 20)

		-- update the scrollframe
		self:FixScroll()

		-- schedule another update when everything has 'settled'
		self.scrollframe:SetScript('OnUpdate', FixScrollOnUpdate)
	end,

	['SetStatusTable'] = function(self, status)
		assert(type(status) == 'table')
		self.status = status
		if not status.scrollvalue then
			status.scrollvalue = 0
		end
	end,

	['OnWidthSet'] = function(self, width)
		local content = self.content
		content.width = width - (self.scrollBarShown and 20 or 0)
		content.original_width = width
	end,

	['OnHeightSet'] = function(self, height)
		local content = self.content
		content.height = height
	end,

	['Add'] = function(self, tbl)
		local scrollHeight = self.scrollframe:GetHeight()
		local contentHeight = self:GetTrueContentHeight()
		if self.allChildren == nil then
			self.allChildren = {}
		end
		table.insert(self.allChildren, tbl)
		-- print('Add', tbl.label)

		self.max = #self.allChildren
		local childHeight = floor(contentHeight / self.max)
		local scrollMax = max(1, ceil(self.max - (scrollHeight / childHeight))) + 1
		-- print('Add_SetScroll', self.max, floor(scrollHeight), floor(childHeight), scrollMax, tbl.label)
		self.scrollbar:SetMinMaxValues(0, scrollMax)
		-- print('Add', tbl.shown, floor(contentHeight), floor(scrollHeight))
		if tbl.shown and contentHeight < scrollHeight then
			local widget = self:CreateWidget(tbl)
			-- print('Add_Show', tbl.label)
			tbl.widget = widget
			tbl.height = widget.frame:GetHeight()
			self:AddChild(widget)
			self:DoLayout()
			-- AceGUI.WidgetContainerBase.AddChild(self, widget)
		end
	end,

	['CreateWidget'] = function(self, tbl)
		local widget = AceGUI:Create(tbl.type)
		widget:SetType(tbl.subType)
		widget:SetLabel(tbl.label)
		if tbl.value ~= nil then
			widget:SetValue(tbl.value)
		end
		for event, callback in pairs(tbl.callbacks) do
			widget:SetCallback(event, callback)
		end
		for k, v in pairs(tbl.data) do
			widget[k] = v
		end
		-- print('CreateWidget', widget.text:GetText())
		return widget
	end,

	['Clear'] = function(self)
		-- print('Clear')
		self:ReleaseChildren()
		self.allChildren = {}
	end
}
--[[-----------------------------------------------------------------------------
Constructor
-------------------------------------------------------------------------------]]
local function Constructor()
	local frame = CreateFrame('Frame', nil, UIParent)
	local num = AceGUI:GetNextWidgetNum(Type)

	local scrollframe = CreateFrame('ScrollFrame', nil, frame)
	scrollframe:SetPoint('TOPLEFT')
	scrollframe:SetPoint('BOTTOMRIGHT')
	scrollframe:EnableMouseWheel(true)
	scrollframe:SetScript('OnMouseWheel', ScrollFrame_OnMouseWheel)
	scrollframe:SetScript('OnSizeChanged', ScrollFrame_OnSizeChanged)

	local scrollbar = CreateFrame('Slider', ('AceConfigDialogScrollFrame%dScrollBar'):format(num), scrollframe, 'UIPanelScrollBarTemplate')
	scrollbar:SetPoint('TOPLEFT', scrollframe, 'TOPRIGHT', 4, -16)
	scrollbar:SetPoint('BOTTOMLEFT', scrollframe, 'BOTTOMRIGHT', 4, 16)
	scrollbar:SetMinMaxValues(0, 1)
	scrollbar:SetValueStep(1)
	scrollbar:SetValue(0)
	scrollbar:SetWidth(16)
	scrollbar:Hide()
	-- set the script as the last step, so it doesn't fire yet
	scrollbar:SetScript('OnValueChanged', ScrollBar_OnScrollValueChanged)

	local scrollbg = scrollbar:CreateTexture(nil, 'BACKGROUND')
	scrollbg:SetAllPoints(scrollbar)
	scrollbg:SetColorTexture(0, 0, 0, 0.4)

	--Container Support
	local content = CreateFrame('Frame', nil, scrollframe)
	content:SetPoint('TOPLEFT')
	content:SetPoint('TOPRIGHT')
	content:SetHeight(400)
	scrollframe:SetScrollChild(content)

	local widget = {
		scrollframe = scrollframe,
		scrollbar = scrollbar,
		content = content,
		frame = frame,
		type = Type,
		status = {},
		allChildren = {},
		max = 1,
	}
	for method, func in pairs(methods) do
		widget[method] = func
	end
	scrollframe.obj, scrollbar.obj = widget, widget

	return AceGUI:RegisterAsContainer(widget)
end

AceGUI:RegisterWidgetType(Type, Constructor, Version)
