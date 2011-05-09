local name, ns = ...
ns.widgets = ns.widgets or {}
local widgets = ns.widgets
------------------------------------------------------------------------------
local UnitGUID, UnitBuff = UnitGUID, UnitBuff
------------------------------------------------------------------------------
local absorbpatterns = {
	"Absorbs (%d+)",
	"Absorbing up to (%d+)",
	"Absorbs up to (%d+)",
}
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
			local amount
			for i=1, #absorbpatterns do
				amount = text:match(absorbpatterns[i])
				if amount then
					amount = 0 + amount
					--self:Debugf('Found: text: %q, amount: %q(%s), text, amount, type(amount))
					ns:UpdateFromTooltipByGUID(UnitGUID(sourceUnit), id, amount, icon, count, debuffType, duration, expirationTime)
					break
				end
			end
		end
		i = i +1
		buffname, rank, icon, count, debuffType, duration, expirationTime, sourceUnit, _, _, id = UnitBuff('player', i)
	end
end