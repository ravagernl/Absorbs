-- The bar setup procedure is totally unfinished :)
local name, ns = ...
ns.widgets = ns.widgets or {}
local widgets = ns.widgets
local config = ns.config
------------------------------------------------------------------------------
local GetTime = GetTime
local unpack = unpack
local tinsert, tremove = tinsert, tremove
local UnitClass, UnitName = UnitClass, UnitName
------------------------------------------------------------------------------
-- Native Tukui support
local Tukui = config.tukuiskinning and (ElvUI or Tukui)
local T, C, L
if Tukui then
	T, C, L = unpack(Tukui)
	config.font.path = C.media.uffont
	config.font.style = "THINOUTLINE"
	config.font.size = T.Duffed and C.unitframes.fontsize or 12
	config.texture = C.media.normTex
end
-- Adjust as backdropinset is = -1
config.spacing = config.spacing+2
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
	container:Size(config.width, config.height + config.spacing)
else
	container:SetSize(config.width, config.height + config.spacing)
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

	return fs
end
local backdrop = {
	bgFile = "Interface/Tooltips/UI-Tooltip-Background",
	insets = { left = -1, right = -1, top = -1, bottom = -1}
}
local colornames = {}
local colors = {}
local function SetColors()
	for class, c  in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		colornames[class] = string.format("(|cff%02x%02x%02x%%s|r)", c.r*255, c.g*255, c.b*255)
		-- because I am lazy and want to use unpack
		c[1], c[2], c[3] = c.r, c.g, c.b
		colors[class] = c
	end
end
SetColors()
if CUSTOM_CLASS_COLORS then 
	CUSTOM_CLASS_COLORS:RegisterCallback(SetColors)
end
SetColors = nil
------------------------------------------------------------------------------
local testObject
do
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(17)
	testObject = {
		unit = 'player',
		guid = UnitGUID('target'),
		id = 17,
		name = 'w00p w00p w00p',
		type = 'BUFF',
		max = 1600,
		cur = 1500,
		absorbType = nil,
		icon = icon,
		count = 1,
		debuffType = debuffType,
		duration = 15,
		expirationTime = GetTime() + 10
	}
end
------------------------------------------------------------------------------
function barPrototype:SetData(object)
	if not (self.data and object and self.data == object) then
		self.data = object
		self:SetSpell()
		self:SetUnit()
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
	self.widgets.bars.absorb:SetMinMaxValues(0, 1)
	self.widgets.bars.absorb:SetValue(1)
	self.widgets.textures.icon:SetTexture()
	self.data = nil
	tinsert(availableBars, self)
	self:Hide()
end
function barPrototype:SetAbsorbColor(r, g, b)
	self.widgets.bars.absorb:SetStatusBarColor(r, g, b)
	self.widgets.textures.absorb:SetVertexColor(r/3, g/3, b/3)
end
function barPrototype:SetAbsorbValue()
	self.widgets.bars.absorb:SetMinMaxValues(0, self.data.max)
	self.widgets.bars.absorb:SetValue(self.data.cur)
	self.widgets.fontstrings.absorb:SetFormattedText("%d/%d", self.data.cur, self.data.max)
end
function barPrototype:SetSpell()
	if config.showicon then
		self:SetIcon()
	end
	self.widgets.fontstrings.spell:SetText(self.data.name)
end
function barPrototype:SetIcon()
	self.widgets.textures.icon:SetTexture(self.data.icon)
	self:UpdateSize()
end
function barPrototype:SetStackCount()
	self.widgets.fontstrings.count:SetText(self.data.count > 1 and self.data.count or '')
end
function barPrototype:SetUnit()
	local unit = self.data.unit
	if unit and unit ~= '' then
		local _, class = UnitClass(unit)
		self:SetAbsorbColor(unpack(colors[class]))
		if unit == 'player' then
			self.widgets.fontstrings.name:SetText('')
		else
			local colorname = colornames[class]:format(UnitName(unit))
			self.widgets.fontstrings.name:SetText(colorname)
		end
	else
		self.widgets.fontstrings.name:SetText('')
	end
end
do
	local function OnAbsorbValueChanged(bar, value)
		ns:Debug(bar, value)
	end
	function barPrototype:Style()
		if Tukui then
			self:SetTemplate()
			if config.tukuishadows then
				self:CreateShadow()
			end
		else
			self:SetBackdrop(backdrop)
			self:SetBackdropColor(0,0,0,1)
		end

		for _, bar in pairs(self.widgets.bars) do
			bar:SetStatusBarTexture(config.texture)
		end
		self.widgets.textures.absorb:SetTexture(config.texture)

		-- Icon
		self.widgets.textures.icon:SetTexCoord(0.07,0.93,0.07,0.93)
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
			self.widgets.bars.absorb:Point('LEFT', 2, 0)
			self.widgets.bars.absorb:Point('BOTTOM', 0, 2)
			self.widgets.bars.absorb:Point('RIGHT', -2, 0)
			self.widgets.bars.absorb:Point('TOP', 0, -2)
		else
			self.widgets.bars.absorb:SetAllPoints()
		end
		self.widgets.bars.absorb:SetScript('OnValueChanged', OnAbsorbValueChanged)
		self.widgets.bars.absorb:SetMinMaxValues(0, 1)
		self.widgets.bars.absorb:SetValue(.8)

		-- timer
		self.widgets.bars.timer:SetAllPoints(self.widgets.bars.absorb)
		self.widgets.bars.timer:SetStatusBarColor(unpack(config.timercolor))
		self.widgets.bars.timer:SetMinMaxValues(0, 1)
		self.widgets.bars.timer:SetValue(.8)
	end
end
function barPrototype:UpdateSize(height)
	if height then
		self.height = height
	end
	if Tukui then
		self:Height(self.height)
	else
		self:SetHeight(self.height)
	end

	-- Repoint absorb bar if icon texture is hidden
	if self.widgets.textures.icon:GetTexture() then
		if Tukui then 
			self.widgets.textures.icon:Width(self.height-4)
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
------------------------------------------------------------------------------
widgets.barPrototype = barPrototype
------------------------------------------------------------------------------
local newBar
do
	local function UpdateTexCoords(self, value)
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

			bar:SetPoint('LEFT', container)
			bar:SetPoint('RIGHT', container)

			bar.widgets = {}
			bar.widgets.frames = {}
			bar.widgets.bars = {}
			bar.widgets.textures = {}
			bar.widgets.fontstrings = {}
			
			local iconFrame = CreateFrame("Frame", name..'AddOnBar'..i..'IconFrame', bar)
			bar.widgets.frames.icon = iconFrame
			
			local icon = iconFrame:CreateTexture(nil, "ARTWORK")
			bar.widgets.textures.icon = icon
			
			local absorb = CreateFrame("StatusBar", name..'AddOnBar'..i..'AbsorbStatusBar', bar)
			hooksecurefunc(absorb, "SetValue", UpdateTexCoords)
			bar.widgets.bars.absorb = absorb
			
			local bg = absorb:CreateTexture(nil, "BACKGROUND")	
			bar.widgets.textures.absorb = bg
			
			local timer = CreateFrame("StatusBar", name..'AddOnBar'..i..'TimerStatusBar', absorb)
			hooksecurefunc(absorb, "SetValue", UpdateTexCoords)
			bar.widgets.bars.timer = timer
			
			-- texts
			local count = SetFontString(iconFrame, config.font.path, config.font.size)
			bar.widgets.fontstrings.count = count
			
			local spell = SetFontString(absorb, config.font.path, config.font.size)
			bar.widgets.fontstrings.spell = spell

			local name = SetFontString(absorb, config.font.path, config.font.size)
			bar.widgets.fontstrings.name = name
			
			local absorb = SetFontString(absorb, config.font.path, config.font.size)
			bar.widgets.fontstrings.absorb = absorb

			-- Set __owner field on each widget to bar
			for key, tbl in next, bar.widgets do
				for key, object in next, tbl do
					object.__owner = bar
				end
			end
			
			bar:Style()		
			i = i + 1
		end
		bar.unlocked = false
		bar:UpdateSize(height)		
		tinsert(activeBars, bar)
		return bar
	end
end
------------------------------------------------------------------------------
local move = false
function ns:UpdateAllBars()
	if move then return end
	self:SortShields()
	--for i, tbl in ns:IterateShields() do
	--	self:Debugf('%d: %s', i, tbl.name)
	--end
	
	--bar:SetUnlocked(true)
end

-- code for moving the frames :)
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
local testObject
do
	local name, rank, icon, cost, isFunnel, powerType, castTime, minRange, maxRange = GetSpellInfo(17)
	testObject = {
		unit = 'player',
		guid = UnitGUID('target'),
		id = 17,
		name = 'w00p w00p w00p',
		type = 'BUFF',
		max = 1600,
		cur = 1500,
		absorbType = nil,
		icon = icon,
		count = 1,
		debuffType = debuffType,
		duration = 15,
		expirationTime = GetTime() + 10
	}
end
-- slash command
_G['SLASH_'..name:upper()..'ADDON1'] = "/"..name:lower()
SlashCmdList[name:upper()..'ADDON'] = function()
	--if InCombatLockdown() then print(ERR_NOT_IN_COMBAT) return end
	if not move then
		move = true
		anchor:EnableMouse(true)
		anchor:SetAlpha(1)
		anchor:SetScript("OnMouseDown", function(self) container:StartMoving() end)
		anchor:SetScript("OnMouseUp", function(self) container:StopMovingOrSizing() end)
		local prev = anchor
		for i = 1, 5 do
			local bar = activeBars[i] or newBar(config.width, config.height)
			activeBars[i] = bar
			bar:SetData(testObject)
			bar:SetStackCount()
			bar:SetAbsorbValue()
			bar:SetUnlocked()
			if Tukui then
				if config.growup then
					bar:Point('BOTTOM', prev, 'TOP', 0, config.spacing)
				else
					bar:Point('TOP', prev, 'BOTTOM', 0, -config.spacing)
				end
			else
				if config.growup then
					bar:Point('BOTTOM', prev, 'TOP', 0, config.spacing)
				else
					bar:Point('TOP', prev, 'BOTTOM', 0, -config.spacing)
				end
			end
			prev = bar
		end
		local height = ((config.height + config.spacing) * (#activeBars + 1)) - config.spacing
		if Tukui then
			container:Height(height)
		else
			container:SetHeight(height)
		end
	else
		move = false
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