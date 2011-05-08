-- The bar setup procedure is totally unfinished :)
local name, ns = ...
ns.widgets = ns.widgets or {}
local widgets = ns.widgets
local config = ns.config
local spacing = config.spacing + 2
------------------------------------------------------------------------------
local GetTime = GetTime
local unpack = unpack
local tinsert, tremove, wipe, next = tinsert, tremove, wipe, next
local UnitClass, UnitName = UnitClass, UnitName
------------------------------------------------------------------------------
-- Partially stolen from LibCandyBar-3.0 and LibBars-1.0 :)
-- Thank you so much Ammo and Rabbit!
local dummyFrame = CreateFrame("Frame")
local barFrame_meta = {__index = dummyFrame}
local barPrototype = setmetatable({}, barFrame_meta)
local barPrototype_meta = {__index = barPrototype}
local availableBars = {}
local activeBars = {}
------------------------------------------------------------------------------
widgets.barPrototype = barPrototype
widgets.activeBars = activeBars
------------------------------------------------------------------------------
local container = CreateFrame('Frame', name..'AddOnContainerFrame', UIParent)
container:SetClampedToScreen(true)
container:SetMovable(true)
if Tukui then
	container:Size(config.width, config.height + spacing)
else
	container:SetSize(config.width, config.height + spacing)
end
container:SetPoint('CENTER', 0, -200)
widgets.container = container
------------------------------------------------------------------------------
local SecondsToTimeDetail
do
	local tformat1 = "%d:%02d"
	local tformat2 = "%1.1f"
	local tformat3 = "%.0f"
	function SecondsToTimeDetail( t )
		if t >= 3600 then -- > 1 hour
			local h = floor(t/3600)
			local m = t - (h*3600)
			return tformat1, h, m
		elseif t >= 60 then -- 1 minute to 1 hour
			local m = floor(t/60)
			local s = t - (m*60)
			return tformat1, m, s
		elseif t < 10 then -- 0 to 10 seconds
			return tformat2, t
		else -- 10 seconds to one minute
			return tformat3, floor(t + .5)
		end
	end
end
local function SetFontString(parent, fontName, fontHeight)
	local fontStyle = fontHeight == 8 and "MONOCHROME,OUTLINE" or "OUTLINE"
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetShadowColor(0, 0, 0, 0)
	fs:SetShadowOffset(0, 0)
	
	ns:Debug(parent:GetName(), 'SetFontString', fontName, fontHeight, fontStyle)
	
	return fs
end
local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	insets = { left = -1, right = -1, top = -1, bottom = -1}
}
local colornames = {}
local colors = {}
local randomcolors = {}
local function SetColors()
	wipe(randomcolors)
	for class, c  in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		colornames[class] = string.format("(|cff%02x%02x%02x%%s|r)", c.r*255, c.g*255, c.b*255)
		-- because I am lazy and want to use unpack
		c[1], c[2], c[3] = c.r, c.g, c.b
		colors[class] = c
		tinsert(randomcolors, c)
	end
end
SetColors()
if CUSTOM_CLASS_COLORS then 
	CUSTOM_CLASS_COLORS:RegisterCallback(SetColors)
end
SetColors = nil
local debugLine = '|cFFFF9900----|r'
------------------------------------------------------------------------------
local testObject
do
	local name, rank, icon = GetSpellInfo(17)
	testObject = {
		name = name,
		icon = icon,
		unit = 'player', 
		guid = UnitGUID('player'), 
		type = 'BUFF', 
		max = 1600, 
		cur = 1500, 
		absorbType = nil, 
		count = 1, 
		debuffType = debuffType, 
		duration = 15, 
		expirationTime = GetTime() + 10
	}
end
------------------------------------------------------------------------------
do
	local function OnAbsorbValueChanged(bar, value)
		ns:Debug(bar.__owner:GetID(), 'OnAbsorbValueChanged', bar:GetMinMaxValues(), value)
		local self = bar.__owner
		self.widgets.fontstrings.absorb:SetFormattedText("%d/%d", self.data.cur, self.data.max)
	end
	function barPrototype:SetData(object)
		if not (self.data and object and self.data == object) then
			ns:Debug(debugLine, self:GetID(), 'SetData')
			self.data = object
			self:SetSpell()
			self:SetUnit()
			self:SetTimer()
			return true
		end
		return false
	end
	function barPrototype:SetUnlocked()
		self.unlocked = true
	end
	function barPrototype:SetLocked()
		self.unlocked = false
	end
	function barPrototype:Delete()
		ns:Debug(debugLine, self:GetID(), 'Delete')
		self.widgets.bars.timer:Hide()
		if config.smoothbar then
			self.widgets.bars.absorb:SetScript('OnValueChanged', nil)
		end
		self.data = nil
		tinsert(availableBars, self)
		self:Hide()
	end
	function barPrototype:InitAbsorbBar()
		self.widgets.bars.absorb:SetMinMaxValues(0, 1)
		self.widgets.bars.absorb:SetValue(.5)
		self.widgets.bars.absorb:SetScript('OnValueChanged', OnAbsorbValueChanged)
	end
	function barPrototype:SetAbsorbValue()
		ns:Debug(self:GetID(), 'SetAbsorbValue')
		if self.data.maxChanged or self.data.curChanged then
			if self.data.maxChanged then
				-- Do something
			elseif self.data.curChanged then
				-- Do something
			end
			self.data.maxChanged = false
			self.data.curChanged = false
		end
		self.widgets.bars.absorb:SetMinMaxValues(0, self.data.max)
		self.widgets.bars.absorb:SetValue(self.data.cur)
	end
	function barPrototype:SetAbsorbColor(r, g, b)
		ns:Debug(self:GetID(), 'SetAbsorbColor', r, g, b)
		self.widgets.bars.absorb:SetStatusBarColor(r, g, b)
		self.widgets.textures.absorb:SetVertexColor(r/3, g/3, b/3)
	end
	function barPrototype:SetSpell()
		ns:Debug(self:GetID(), 'SetSpell', self.data.name)
		self.widgets.fontstrings.spell:SetText(self.data.name)
		self:SetIcon()
	end
	function barPrototype:SetTimer()
		ns:Debug(self:GetID(), 'SetTimer')
		self.widgets.bars.timer:Show()
	end
	function barPrototype:SetIcon()
		ns:Debug(self:GetID(), 'SetIcon')
		self.widgets.textures.icon:SetTexture(self.data.icon)
		if config.showicon and self.widgets.textures.icon:GetTexture() then
			ns:Debug(self:GetID(), 'SetIcon', '|cFF00FF00Icon visible!|', self.data.icon)
			self.widgets.textures.icon:Show()
		elseif config.showicon then
			ns:Debug(self:GetID(), 'SetIcon', '|cFFFF0000Icon not set.|r', self:GetID())
			self.widgets.textures.icon:Hide()
		else
			ns:Debug(self:GetID(), 'SetIcon', '|cFFFF0000Icons are disabled.|r', self.data.icon)
			self.widgets.textures.icon:Hide()
		end
		self:UpdateHeight()
	end
	function barPrototype:SetStackCount()
		ns:Debug(self:GetID(), 'SetStackCount', self.data.count)
		self.widgets.fontstrings.count:SetText(self.data.count > 1 and self.data.count or '')
	end
	function barPrototype:SetUnit()
		ns:Debug(self:GetID(), 'SetUnit', self.data.unit)
		local unit = self.data.unit
		if unit and unit ~= '' then
			local _, class = UnitClass(unit)
			local color
			if self.unlocked then
				color = randomcolors[math.random(#randomcolors)]
			else
				color = colors[class]
			end
			self:SetAbsorbColor(unpack(color))
			if unit == 'player' then
				self.widgets.fontstrings.name:SetText('')
			else
				local colorname = colornames[class]:format(UnitName(unit))
				self.widgets.fontstrings.name:SetText(colorname)
			end
		else
			self.widgets.fontstrings.name:SetText('')
			self:SetAbsorbColor(0, 0, 0)
		end
	end
	function barPrototype:Style()
		ns:Debug(debugLine, self:GetID(), 'Style')
		if Tukui then
			self:SetTemplate()
			if config.tukuishadows then
				self:CreateShadow()
			end
		else
			self:SetBackdrop(backdrop)
			self:SetBackdropColor(0, 0, 0, 1)
		end
		-- Set textures
		self.widgets.bars.absorb:SetStatusBarTexture(config.texture)
		self.widgets.textures.absorb:SetTexture(config.texture)
		self.widgets.bars.timer:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
		-- Icon
		self.widgets.textures.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		if Tukui then
			self.widgets.textures.icon:Point('TOPLEFT', self, 2, -2)
			self.widgets.textures.icon:Point('BOTTOMLEFT', self, 2, 2)
		else
			self.widgets.textures.icon:SetPoint('TOPLEFT', self)
			self.widgets.textures.icon:SetPoint('BOTTOMLEFT', self)
		end
		-- Absorb
		if Tukui then
			self.widgets.bars.absorb:Point('BOTTOMLEFT', 2, 2)
			self.widgets.bars.absorb:Point('TOPRIGHT', -2, -2)
		else
			self.widgets.bars.absorb:SetAllPoints()
		end
		-- timer
		self.widgets.bars.timer:SetAllPoints(self.widgets.bars.absorb)
		self.widgets.bars.timer:SetStatusBarColor(unpack(config.timercolor))
		self.widgets.bars.timer:SetMinMaxValues(0, 1)
		self.widgets.bars.timer:SetValue(.8)
		-- fontstrings
		--if Tukui then
		--	self.widgets.fontstrings.name:Point('LEFT', self.widgets.bars.timer, config.font.spacing, 0)
		--else
		--	self.widgets.fontstrings.name:SetPoint('LEFT', self.widgets.bars.timer, config.font.spacing, 0)
		--end
		self.widgets.fontstrings.name:SetPoint('CENTER', UIParent)
	end
	function barPrototype:UpdateHeight(height)
		ns:Debug(self:GetID(), 'UpdateHeight', self.height, height)
		if height then
			self.height = height
		end
		if Tukui then
			self:Height(self.height)
		else
			self:SetHeight(self.height)
		end	
		self.widgets.bars.absorb:ClearAllPoints()
		if Tukui then
			self.widgets.bars.absorb:Point('BOTTOM', 0, 2)
			self.widgets.bars.absorb:Point('RIGHT', -2, 0)
			self.widgets.bars.absorb:Point('TOP', 0, -2)
		else
			self.widgets.bars.absorb:SetPoint('BOTTOM')
			self.widgets.bars.absorb:SetPoint('RIGHT')
			self.widgets.bars.absorb:SetPoint('TOP')
		end
		if self.widgets.textures.icon:IsShown() then
			if Tukui then
				self.widgets.textures.icon:Width(self.height - 4)
				self.widgets.bars.absorb:Point('LEFT', self.widgets.textures.icon, 'RIGHT', 1, 0)
			else
				self.widgets.textures.icon:SetWidth(self.height)
				self.widgets.bars.absorb:SetPoint('LEFT', self.widgets.textures.icon, 'RIGHT', 1, 0)
			end
		else
			if Tukui then 
				self.widgets.bars.absorb:Point('LEFT', 2, 0)
			else
				self.widgets.bars.absorb:SetPoint('LEFT')
			end
		end
	end
end
------------------------------------------------------------------------------
widgets.barPrototype = barPrototype
------------------------------------------------------------------------------
local newBar
do
	local function UpdateTexCoords(self, value)
		ns:Debug(self.__owner:GetID(), 'UpdateTexCoords', value)
		local min, max = self:GetMinMaxValues()
		self:GetStatusBarTexture():SetTexCoord(0, (value - min) / (max - min), 0, 1)
	end
	local i = 1
	function newBar(height)
		local bar = tremove(availableBars)
		if bar then
			bar:Show()
		else
			bar = setmetatable(CreateFrame("Frame", name..'AddOnBar'..i, UIParent), barPrototype_meta)
			bar:SetID(i)
			-- Anchor to container
			bar:SetPoint('LEFT', container)
			bar:SetPoint('RIGHT', container)
			-- Setup tables
			bar.widgets = {}
			local widgets = bar.widgets
			widgets.frames = {}
			local frames = widgets.frames
			widgets.bars = {}
			local bars = widgets.bars
			widgets.textures = {}
			local textures = widgets.textures
			widgets.fontstrings = {}
			local fontstrings = widgets.fontstrings
			-- Add elements to tables
			frames.icon =	CreateFrame("Frame", name..'AddOnBar'..i..'IconFrame', bar)
				textures.icon =			frames.icon:CreateTexture(nil, "ARTWORK")
				fontstrings.count =		SetFontString(frames.icon, config.font.path, config.font.size)
			bars.absorb =	CreateFrame("StatusBar", name..'AddOnBar'..i..'AbsorbStatusBar', bar)
				hooksecurefunc(bars.absorb, "SetValue", UpdateTexCoords)
				textures.absorb =		bars.absorb:CreateTexture(nil, "BACKGROUND")
				fontstrings.spell =		SetFontString(bars.absorb, config.font.path, config.font.size)
				fontstrings.name =		SetFontString(bars.absorb, config.font.path, config.font.size)
				fontstrings.absorb = 	SetFontString(bars.absorb, config.font.path, config.font.size)
			bars.timer =	CreateFrame("StatusBar", name..'AddOnBar'..i..'TimerStatusBar', bars.absorb)
			-- Set __owner field on each widget to bar
			for key, tbl in next, widgets do
				for key, object in next, tbl do
					object.__owner = bar
				end
			end
			bar:Style()		
			i = i + 1
		end
		bar.unlocked = false
		bar:UpdateHeight(height)
		bar:InitAbsorbBar()		
		tinsert(activeBars, bar)
		return bar
	end
end
------------------------------------------------------------------------------
function ns:UpdateAllBars()
	if self.moving then return end
	self:SortShields()
end
------------------------------------------------------------------------------
local anchor = CreateFrame('Frame', name..'AddOnAnchorFrame', container)
anchor:SetAlpha(0)
anchor:SetHeight(config.height)
if not config.growup then
	anchor:SetPoint('TOPLEFT')
	anchor:SetPoint('TOPRIGHT')
else
	anchor:SetPoint('BOTTOMLEFT')
	anchor:SetPoint('BOTTOMRIGHT')
end

local sbar = anchor:CreateTexture(nil, 'ARTWORK')
sbar:SetTexture(config.texture)
sbar:SetVertexColor(0,6/16,9/16)
anchor.sbar = sbar

if Tukui then
	anchor:SetTemplate()
	if config.tukuishadows then
		anchor:CreateShadow()
	end
	sbar:Point('BOTTOMLEFT', 2, 2)
	sbar:Point('TOPRIGHT', -2, -2)
else
	anchor:SetBackdrop(backdrop)
	anchor:SetBackdropColor(0,0,0,1)
	sbar:SetAllPoints()
end

local text = SetFontString(anchor, config.font.path, config.font.size, 'CENTER')
text:SetAllPoints()
text:SetText(name.."AddOn unlocked.")
anchor.text = text
widgets.anchor = anchor
------------------------------------------------------------------------------
-- slash command
_G['SLASH_'..name:upper()..'ADDON1'] = "/"..name:lower()
SlashCmdList[name:upper()..'ADDON'] = function()
	--if InCombatLockdown() then print(ERR_NOT_IN_COMBAT) return end
	if not ns.moving then
		ns.moving = true
		anchor:EnableMouse(true)
		anchor:SetAlpha(1)
		anchor:SetScript("OnMouseDown", function(self) container:StartMoving() end)
		anchor:SetScript("OnMouseUp", function(self) container:StopMovingOrSizing() end)
		local prev = anchor
		for i = 1, 5 do
			local bar = activeBars[i] or newBar(config.height)
			activeBars[i] = bar
			bar:SetUnlocked()

			local id = ns.shieldsIndex[math.random(#ns.shieldsIndex)]
			local name, _, icon = GetSpellInfo(id)
			testObject.id = id
			testObject.name = name
			testObject.icon = icon
			testObject.expirationTime = GetTime() + (i * 2)
			testObject.cur = (testObject.max / 5) * (6 - i)

			bar:SetData(testObject)
			bar:SetStackCount()
			bar:SetAbsorbValue()
			if Tukui then
				if config.growup then
					bar:Point('BOTTOM', prev, 'TOP', 0, spacing)
				else
					bar:Point('TOP', prev, 'BOTTOM', 0, -spacing)
				end
			else
				if config.growup then
					bar:Point('BOTTOM', prev, 'TOP', 0, spacing)
				else
					bar:Point('TOP', prev, 'BOTTOM', 0, -spacing)
				end
			end
			prev = bar
		end
		local height = ((config.height + spacing) * (#activeBars + 1)) - spacing
		if Tukui then
			container:Height(height)
		else
			container:SetHeight(height)
		end
	else
		ns.moving = false
		anchor:EnableMouse(false)
		anchor:SetAlpha(0)
		for i, bar in next, activeBars do
			bar:SetLocked()
			bar:Delete()
			activeBars[i] = nil
		end
		ns:UpdateAllBars()
	end
end