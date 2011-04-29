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
local function setFontString()

end
------------------------------------------------------------------------------
function barPrototype:IsData(object)
	return self.data and object and self.data == object
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
			local frame = CreateFrame("Frame", name..'AddOnBar'..i, UIParent)
			bar = setmetatable(frame, barPrototype_meta)
			
			local icon = bar:CreateTexture(nil, "LOW")
			icon:SetPoint("TOPLEFT")
			icon:SetPoint("BOTTOMLEFT")
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			frame.icon = icon

			local absorbBar = CreateFrame("StatusBar", name..'AddOnBar'..i..'AbsorbBar', bar)
			absorbBar:SetPoint("TOPRIGHT")
			absorbBar:SetPoint("BOTTOMRIGHT")
			absorbBar:SetStatusBarTexture(texture)
			hooksecurefunc(absorbBar, "SetValue", setValue)
			
			local bg = absorbBar:CreateTexture(nil, "BACKGROUND")
			bg:SetAllPoints()
			bg:SetTexture(texture)
			absorbBar.bg = bg			
			bar.absorbBar = absorbBar
			
			local spellText = absorbBar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
			spellText:SetPoint("LEFT", absorbBar, 2, 0)
			bar.spellText = spellText

			local name = statusbar:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmallOutline")
			name:SetPoint("LEFT", statusbar, "LEFT", 2, 0)
			name:SetPoint("RIGHT", statusbar, "RIGHT", -2, 0)
			bar.candyBarLabel = name
			i = i + 1
		end
		bar.width = width
		bar.height = height
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