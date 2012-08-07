-- The bar setup procedure is in beta :)
local name, ns = ...
ns.widgets = ns.widgets or {}
local widgets = ns.widgets
local config = ns.config
local spacing = config.spacing + 2
local Tukui = config.tukuiskinning and (ElvUI or Tukui)
------------------------------------------------------------------------------
local GetTime = GetTime
local unpack = unpack
local tinsert, tremove, wipe, next, floor = tinsert, tremove, wipe, next, math.floor
local UnitClass, UnitName = UnitClass, UnitName
local GetPlayerInfoByGUID = GetPlayerInfoByGUID
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
	container:Size(config.width, config.height)
else
	container:SetSize(config.width, config.height)
end
container:SetPoint('CENTER', 0, -200)
widgets.container = container
------------------------------------------------------------------------------
local shortnum
do 
	local function round(num, idp)
		if idp and idp > 0 then
			local mult = 10^idp
			return floor(num * mult + 0.5) / mult
		end
		return floor(num + 0.5)
	end
	function shortnum(num)
		if num < 5000 then
			return floor(num + .5)
		elseif num < 1e6 then
			return round(num/1e3,config.font.decimals).."k"
		else
			return round(num/1e6,config.font.decimals).."m"
		end
	end
end
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
local utf8sub = function(string, i, dots)
	local bytes = string:len()
	if (bytes <= i) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if c > 240 then
				pos = pos + 4
			elseif c > 225 then
				pos = pos + 3
			elseif c > 192 then
				pos = pos + 2
			else
				pos = pos + 1
			end
			if (len == i) then break end
		end

		if (len == i and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and "..." or "")
		else
			return string
		end
	end
end
-- Credit to Satrina (SBF)
local shortName
do
	local strTmp = CreateFrame("Button")
	shortName = function(name)
		local colon = false
		strTmp:SetFormattedText("")
		for word in name:gmatch("[^%s]+") do
			if colon then
				strTmp:SetFormattedText("%s%s", strTmp:GetText() or "", word)
			elseif tonumber(word) then
				strTmp:SetFormattedText("%s%s", strTmp:GetText() or "", word)
			else
				strTmp:SetFormattedText("%s%s", strTmp:GetText() or "", word:match("^."))
			end
			if word:find("[:]") then
				colon = true
				strTmp:SetFormattedText("%s:", strTmp:GetText())
			end
		end
		return strTmp:GetText()
	end
end
local function SetFontString(parent, fontName, fontHeight)
	local fontStyle = fontHeight == 8 and "MONOCHROME,OUTLINE" or "OUTLINE"
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetShadowColor(0, 0, 0, 0)
	fs:SetShadowOffset(0, 0)
	--ns:Debug(parent:GetName(), 'SetFontString', fontName, fontHeight, fontStyle)
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
		guid = UnitGUID('player'), 
		type = 'BUFF', 
		max = math.random(11000,40000),
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
		local min, max = bar:GetMinMaxValues()
		bar.__owner.widgets.fontstrings.absorb:SetFormattedText("%s/%s", shortnum(value), shortnum(max))
	end
	local function OnTimerUpdate(self, elapsed, ...)
		local left = self.__owner.data.expirationTime - GetTime()
		self:SetValue(left)
		if config.scaletime and left < self.max then
			self:SetAlpha(1)
		end
	end
	function barPrototype:SetData(object)
		if not (self.data and object and self.data == object) then
			ns:Debug(debugLine, self:GetID(), 'SetData')
			self.data = object
			self:SetSpellAndName()
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
		self.data = nil
		tinsert(availableBars, self)
		self:Hide()
	end
	function barPrototype:SetAbsorbValue()
		if self.data.maxChanged or self.data.curChanged then
			if self.data.maxChanged then
				ns:Debug(self:GetID(), 'SetAbsorbValue', 'maxChanged', self.data.max)
				self.widgets.bars.absorb:SetMinMaxValues(0, self.data.max)
				self.data.maxChanged = false
			end
			if self.data.curChanged then
				ns:Debug(self:GetID(), 'SetAbsorbValue', 'curChanged', self.data.cur)
				self.widgets.bars.absorb:SetValue(self.data.cur)
				self.data.curChanged = false
			end
		end		
	end
	function barPrototype:SetAbsorbColor(r, g, b)
		ns:Debug(self:GetID(), 'SetAbsorbColor', r, g, b)
		self.widgets.bars.absorb:SetStatusBarColor(r, g, b)
		self.widgets.textures.absorb:SetVertexColor(r/3, g/3, b/3)
	end
	function barPrototype:SetSpellAndName()
		local spell = config.hidespell and '' or config.shortspell and shortName(self.data.name) or self.data.name
		local _, class, _, _, _, name, realm = GetPlayerInfoByGUID(self.data.guid)
		if class and not config.hidename then
			local color
			if self.unlocked then
				color = randomcolors[math.random(#randomcolors)]
			else
				color = colors[class]
			end
			if config.classcolorbars then
				self:SetAbsorbColor(unpack(color))
			end
			if UnitGUID('player') ~= self.data.guid then
				name = config.shortname and utf8sub(name, 8, true) or name
				name = colornames[class]:format(name)
			end
		end
		self.widgets.fontstrings.spellandname:SetFormattedText('%s%s', spell, name)
		self:SetIcon()
	end
	function barPrototype:SetTimer()
		if self.data.timeChanged then
			self.data.timeChanged = false
			local max = config.scaletime 
				and math.min(config.scaletime, self.data.duration) 
				or self.data.duration
			self.widgets.bars.timer.max = max	
			local left = self.data.expirationTime - GetTime()
			self.widgets.bars.timer:SetMinMaxValues(0, max)
			self.widgets.bars.timer:SetValue(left)
			self.widgets.bars.timer:Show()
			if config.scaletime and left > max then
				self.widgets.bars.timer:SetAlpha(0)
			end
		end
	end
	function barPrototype:SetIcon()
		self.widgets.textures.icon:SetTexture(self.data.icon)
		if config.showicon and self.widgets.textures.icon:GetTexture() then
			--ns:Debug(self:GetID(), 'SetIcon', '|cFF00FF00Icon visible!|', self.data.icon)
			self.widgets.textures.icon:Show()
		--elseif config.showicon then
			--ns:Debug(self:GetID(), 'SetIcon', '|cFFFF0000Icon not set.|r', self:GetID())
			--self.widgets.textures.icon:Hide()
		else
			--ns:Debug(self:GetID(), 'SetIcon', '|cFFFF0000Icons are disabled.|r', self.data.icon)
			self.widgets.textures.icon:Hide()
		end
		self:UpdateHeight()
	end
	function barPrototype:SetStackCount()
		self.widgets.fontstrings.count:SetText(self.data.count > 1 and self.data.count or '')
	end
	local SmoothBar
	do
		-- Kind of stolen from oUF_Smooth.
		local smoothing = {}
		local function Smooth(self, value)
			local min, max = self:GetMinMaxValues()
			if value == max or value == min then
				self:SetValue_(value)
			elseif value ~= self:GetValue() or value == 0 then
				smoothing[self] = value
			else
				smoothing[self] = nil
			end
		end
		local f, min, max = CreateFrame('Frame'), math.min, math.max
		f:Hide()
		f:SetScript('OnUpdate', function()
			local rate = GetFramerate()
			local limit = 30/rate
			for bar, value in pairs(smoothing) do
				local cur = bar:GetValue()
				local new = cur + min((value-cur)/3, max(value-cur, limit))
				if new ~= new then
					-- Mad hax to prevent QNAN.
					new = value
				end
				bar:SetValue_(new)
				if cur == value or abs(new - value) < 2 then
					bar:SetValue_(value)
					smoothing[bar] = nil
				end
			end
		end)
		function SmoothBar(bar)
			-- Start the onupdate
			f:Show()
			bar.SetValue_ = bar.SetValue
			bar.SetValue = Smooth
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
		-- color
		if not config.classcolorbars then
			self.widgets.bars.absorb:SetStatusBarColor(unpack(config.barcolor))
			self.widgets.textures.absorb:SetVertexColor(unpack(config.barbgcolor))
		end
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
		self.widgets.textures.absorb:SetAllPoints()
		if Tukui then
			self.widgets.bars.absorb:Point('BOTTOMLEFT', 2, 2)
			self.widgets.bars.absorb:Point('TOPRIGHT', -2, -2)
		else
			self.widgets.bars.absorb:SetAllPoints()
		end
		self.widgets.bars.absorb:SetScript('OnValueChanged', OnAbsorbValueChanged)
		if config.smoothbar then
			SmoothBar(self.widgets.bars.absorb)
		end
		-- timer
		self.widgets.bars.timer:SetPoint('LEFT', self.widgets.bars.absorb)
		self.widgets.bars.timer:SetPoint('BOTTOM', self.widgets.bars.absorb)
		self.widgets.bars.timer:SetPoint('RIGHT', self.widgets.bars.absorb)
		self.widgets.bars.timer:Hide()
		self.widgets.bars.timer:SetScript('OnUpdate', OnTimerUpdate)
		if Tukui then
			self.widgets.bars.timer:Height(config.timerheight or 1)
		else
			self.widgets.bars.timer:SetHeight(config.timerheight or 1)
		end
		self.widgets.bars.timer:SetStatusBarColor(unpack(config.timercolor))
		self.widgets.bars.timer:SetMinMaxValues(0, 1)
		self.widgets.bars.timer:SetValue(.8)
		-- fontstrings
		self.widgets.fontstrings.absorb:SetPoint('CENTER')
		self.widgets.fontstrings.spellandname:SetJustifyH('LEFT')
		if Tukui then
			self.widgets.fontstrings.count:Point('RIGHT', -config.font.spacing, 0)
			self.widgets.fontstrings.spellandname:Point('LEFT', config.font.spacing, 0)
			self.widgets.fontstrings.spellandname:Point('RIGHT', self.widgets.fontstrings.absorb, 'LEFT', -config.font.spacing, 0)
		else
			self.widgets.fontstrings.count:SetPoint('RIGHT', -config.font.spacing, 0)
			self.widgets.fontstrings.spellandname:SetPoint('LEFT', config.font.spacing, 0)
			self.widgets.fontstrings.spellandname:SetPoint('RIGHT', self.widgets.fontstrings.absorb, 'LEFT', -config.font.spacing, 0)
		end
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
		--ns:Debug(self.__owner:GetID(), 'UpdateTexCoords', value)
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
			frames.icon = CreateFrame("Frame", name..'AddOnBar'..i..'IconFrame', bar)
				textures.icon = frames.icon:CreateTexture(nil, "ARTWORK")
			bars.absorb = CreateFrame("StatusBar", name..'AddOnBar'..i..'AbsorbStatusBar', bar)
				hooksecurefunc(bars.absorb, "SetValue", UpdateTexCoords)
				textures.absorb = bars.absorb:CreateTexture(nil, "BACKGROUND")
				fontstrings.count = SetFontString(bars.absorb, config.font.path, config.font.size)
				fontstrings.spellandname = SetFontString(bars.absorb, config.font.path, config.font.size)
				fontstrings.absorb = SetFontString(bars.absorb, config.font.path, config.font.size)
			bars.timer = CreateFrame("StatusBar", name..'AddOnBar'..i..'TimerStatusBar', bars.absorb)
			-- Set __owner field on each widget to bar
			for key, tbl in next, widgets do
				for key, object in next, tbl do
					object.__owner = bar
				end
			end
			bar:Style()		
			i = i + 1
		end
		bar:SetLocked()
		bar:UpdateHeight(height)
		tinsert(activeBars, bar)
		return bar
	end
end
------------------------------------------------------------------------------
function ns:UpdateAllBars()
	if self.moving then return end
	self:SortShields()
	if ns:HasActiveShields() then
		local prev = container
		for i = 1, ns:GetNumShields() do
			local bar = activeBars[i] or newBar(config.height)
			bar:SetData(ns:GetShield(i))
			bar:SetStackCount()
			bar:SetAbsorbValue()
			bar:SetTimer()
			if Tukui then
				if config.growup then
					bar:Point('BOTTOM', prev, prev == container and 'BOTTOM' or 'TOP', 0, prev == container and 0 or spacing)
				else
					bar:Point('TOP', prev, prev == container and 'TOP' or 'BOTTOM', 0, prev == container and 0 or -spacing)
				end
			else
				if config.growup then
					bar:SetPoint('BOTTOM', prev, prev == container and 'BOTTOM' or 'TOP', 0, prev == container and 0 or spacing)
				else
					bar:SetPoint('TOP', prev, prev == container and 'TOP' or 'BOTTOM', 0, prev == container and 0 or -spacing)
				end
			end
			prev = bar
		end
	end
	-- remove leftover bars.
	for i = ns:GetNumShields() + 1, #activeBars do
		local bar = activeBars[i]
		bar:Delete()
		tremove(activeBars, i)
	end
end
------------------------------------------------------------------------------
local anchor = CreateFrame('Frame', name..'AddOnAnchorFrame', container)
anchor:SetAlpha(0)
if not config.growup then
	anchor:SetPoint('TOPLEFT')
	anchor:SetPoint('TOPRIGHT')
else
	anchor:SetPoint('BOTTOMLEFT')
	anchor:SetPoint('BOTTOMRIGHT')
end
widgets.anchor = anchor
------------------------------------------------------------------------------
-- slash command
_G['SLASH_'..name:upper()..'ADDON1'] = "/"..name:lower()
SlashCmdList[name:upper()..'ADDON'] = function()
	--if InCombatLockdown() then print(ERR_NOT_IN_COMBAT) return end
	if not ns.moving then
		ns.moving = true
		anchor:EnableMouse(true)
		anchor:SetAlpha(.5)
		anchor:SetScript("OnMouseDown", function(self) container:StartMoving() end)
		anchor:SetScript("OnMouseUp", function(self) container:StopMovingOrSizing() end)
		local prev = container
		local max = testObject.max
		for i = 1, 5 do
			local bar = activeBars[i] or newBar(config.height)
			bar:SetUnlocked()

			local id = ns.shieldsIndex[math.random(#ns.shieldsIndex)]
			local name, _, icon = GetSpellInfo(id)
			testObject.id = id
			testObject.name = name
			testObject.count = i
			testObject.icon = icon
			testObject.maxChanged = true
			testObject.curChanged = true
			testObject.expirationTime = GetTime() + (i * 2)
			max = math.random(max/2, max)
			testObject.cur = max

			bar:SetData(testObject)
			bar:SetStackCount()
			bar:SetAbsorbValue()
			if Tukui then
				if config.growup then
					bar:Point('BOTTOM', prev, prev == container and 'BOTTOM' or 'TOP', 0, prev == container and 0 or spacing)
				else
					bar:Point('TOP', prev, prev == container and 'TOP' or 'BOTTOM', 0, prev == container and 0 or -spacing)
				end
			else
				if config.growup then
					bar:SetPoint('BOTTOM', prev, prev == container and 'BOTTOM' or 'TOP', 0, prev == container and 0 or spacing)
				else
					bar:SetPoint('TOP', prev, prev == container and 'TOP' or 'BOTTOM', 0, prev == container and 0 or -spacing)
				end
			end
			prev = bar
			local height = ((config.height + spacing) * #activeBars) - spacing
			if Tukui then
				anchor:Height(height)
			else
				anchor:SetHeight(height)
			end
		end
	else
		ns.moving = false
		anchor:EnableMouse(false)
		anchor:SetAlpha(0)
		for i, bar in next, activeBars do
			bar:SetLocked()
			bar:Delete()
			tremove(activeBars, i)
		end
		-- Force updating the statusbar values
		if ns:HasActiveShields() then
			local prev = container
			for i = 1, ns:GetNumShields() do
				local shield = ns:GetShield(i)
				shield.maxChanged = true
				shield.curChanged = true
			end
		end
		ns:UpdateAllBars()
	end
end