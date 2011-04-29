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
widgets.activeBars = activeBars
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
local function SetFontString(parent, fontName, fontHeight, justify)
	local fontStyle = fontHeight == 8 and "MONOCHROME,OUTLINE" or "OUTLINE"
	local fs = parent:CreateFontString(nil, "OVERLAY")
	fs:SetFont(fontName, fontHeight, fontStyle)
	fs:SetJustifyH(justify or "LEFT")
	fs:SetShadowColor(0, 0, 0, 0)
	fs:SetShadowOffset(0, 0)

	return fs
end
------------------------------------------------------------------------------
function barPrototype:IsData(object)
	return self.data and object and self.data == object
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
end
function barPrototype:SetData(object)
	self.data = object
end
function barPrototype:SetAbsorbColor(r, g, b)
	self.absorbBar:SetStatusBarColor(r, g, b)
	self.absorbBar.bg:SetVertexColor(r/2, g/2, b/2)
end
function barPrototype:UpdateAbsorbValue() end
function barPrototype:SetTimerColor(r,g,b) end
function barPrototype:SetIcon(iconTexture)
	self.icon:SetTexture(iconTexture)
end
function barPrototype:SetStackCount(count) end

local newBar
do
	local function setValue(self, value)
		local min, max = self:GetMinMaxValues()
		self:GetStatusBarTexture():SetTexCoord(0, (value - min) / (max - min), 0, 1)
	end
	local i = 1
	function newBar(width, height)
		local bar = tremove(availableBars)
		if not bar then
			bar = setmetatable(CreateFrame("Frame", name..'AddOnBar'..i, UIParent), barPrototype_meta)
			bar.widgets = {}
			bar.widgets.bars = {}
			bar.widgets.textures = {}
			bar.widgets.fontstrings = {}
			
			local icon = bar:CreateTexture(nil, "LOW")
			bar.widgets.textures.icon = icon
			
			local absorbBar = CreateFrame("StatusBar", name..'AddOnBar'..i..'AbsorbBar', bar)
			local bg = absorbBar:CreateTexture(nil, "BACKGROUND")
			hooksecurefunc(absorbBar, "SetValue", setValue)			
			absorbBar.bg = bg			
			bar.widgets.bars.absorbBar = absorbBar
			
			local timerBar = CreateFrame("StatusBar", name..'AddOnBar'..i..'TimerBar', absorbBar)
			hooksecurefunc(timerBar, "SetValue", setValue)
			bar.widgets.bars.timerBar = timerBar			
			
			-- texts
			local countText = SetFontString(bar, config.font.path, config.font.size)
			bar.widgets.fontstrings.countText = countText
			
			local spellText = SetFontString(absorbBar, config.font.path, config.font.size)
			bar.widgets.fontstrings.spellText = spellText

			local nameText = SetFontString(absorbBar, config.font.path, config.font.size)
			bar.widgets.fontstrings.nameText = nameText
			
			local absorbText = SetFontString(absorbBar, config.font.path, config.font.size)
			bar.widgets.fontstrings.absorbText = absorbText
			
			bar:Style()		
			i = i + 1
		end
		bar:UpdateSize(width, height)		
		tinsert(activeBars, bar)
		return bar
	end
end
------------------------------------------------------------------------------
function ns:UpdateAllBars()
	self:SortShields()
	--for i, tbl in ns:IterateShields() do
	--	self:Debugf('%d: %s', i, tbl.name)
	--end
end