local name, ns = ...
ns.widgets = ns.widgets or {}
local widgets = ns.widgets
------------------------------------------------------------------------------
local UnitGUID, UnitBuff = UnitGUID, UnitBuff
------------------------------------------------------------------------------
local absorbpattern1 = "Absorbs (%d+)"
local absorbpattern2 = "Absorbs (%d+) (%a+) damage"
-- Mana shield
local absorbpattern3 = "Absorbing up to (%d+)"
-- Stay of execution
local absorbpattern4 = "Absorbs up to (%d+)"
widgets.tooltip = CreateFrame("GameTooltip", name..'AddOnTooltip', UIParent, "GameTooltipTemplate")
widgets.tooltiptext = _G[name..'AddOnTooltipTextLeft2']

local function GetBuffText(unit, num)
	widgets.tooltip:SetOwner(UIParent, "ANCHOR_NONE")
	widgets.tooltip:SetUnitBuff(unit, num)
	local n = widgets.tooltiptext:GetText()
	widgets.tooltip:Hide()
	return n
end

function ns:UpdateFromTooltips()
	--self:Debug('Updating buffs with tooltipscanner.')
	local i = 1
	local guid
	local buffname, rank, icon, count, debuffType, duration, expirationTime, sourceUnit, _, _, id = UnitBuff('player', i)
	while id do
		if ns:IsTrackableShield(id) and sourceUnit ~= nil and sourceUnit ~= '' then
			--self:Debugf('Scanning: %q from %q at index %d', buffname, sourceUnit, i)
			local text = GetBuffText(sourceUnit, i)
			local amount, absorbType
			amount = text:match(absorbpattern1)
			if not amount then
				amount, absorbType = text:match(absorbpattern2)
				if not amount then
					amount = text:match(absorbpattern3)
					if not amount then
						amount = text:match(absorbpattern4)
					end
				end
			end
			
			if amount then
				amount = amount + 0
				--self:Debugf('Found: text: %q, amount: %q(%s), absorbType: %q', text, amount, type(amount), absorbType or 'nil')
				ns:UpdateFromTooltipByGUID(UnitGUID(sourceUnit), id, amount, absorbType, icon, count, debuffType, duration, expirationTime)
			end
		end
		i = i +1
		buffname, rank, icon, count, debuffType, duration, expirationTime, sourceUnit, _, _, id = UnitBuff('player', i)
	end
end