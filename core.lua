local name, ns = ...
local widgets = ns.widgets or {}
_G[name..'AddOn'] = ns -- expose
------------------------------------------------------------------------------
local unpack = unpack
local format = format
local print = print
local wipe = wipe
local _
local UnitGUID = UnitGUID
------------------------------------------------------------------------------
local evtframe = CreateFrame("Frame", name..'EventFrame')
widgets.eventframe = evtframe
------------------------------------------------------------------------------
local function GUIDToUnitID(guid)
	local prefix, min, max = "raid", 1, GetNumRaidMembers()
	if max == 0 then
		prefix, min, max = "party", 0, GetNumPartyMembers()
	end

	for i = min, max do
		local unit = i == 0 and "player" or prefix .. i
		if (UnitGUID(unit) == guid) then
			return unit
		end
	end

	-- This properly detects target units
	if (UnitGUID("target") == guid) then
        return "target"
	elseif (UnitGUID("focus") == guid) then
		return "focus"
	elseif (UnitGUID("mouseover") == guid) then
		return "mouseover"
    end

	for i = min, max + 3 do
		local unit
		if i == 0 then
			unit = "player"
		elseif i == max + 1 then
			unit = "target"
		elseif i == max + 2 then
			unit = "focus"
		elseif i == max + 3 then
			unit = "mouseover"
		else
			unit = prefix .. i
		end
		if (UnitGUID(unit .. "target") == guid) then
			return unit .. "target"
		elseif (i <= max and UnitGUID(unit.."pettarget") == guid) then
			return unit .. "pettarget"
		end
	end
	return nil
end
------------------------------------------------------------------------------
evtframe:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
evtframe:SetScript("OnEvent", function(self, event, timestamp, type, hideCaster, srcGUID, srcName, sourceFlags, sourceFlags2, dstGUID, dstName, dstFlags, dstFlags2, ...)
	if dstGUID ~= UnitGUID('player') then
		return
	end

	local hasshields = ns:HasActiveShields()
	-- Aura applied or removed
	if type == 'SPELL_AURA_APPLIED' or
		hasshields and (
			type == 'SPELL_AURA_REFRESHED' or
			type == 'SPELL_AURA_REMOVED'
		)
	then
		local unit = GUIDToUnitID(srcGUID)
		local id, name, school, spelltype, amount = ...
		-- make sure we have a trackable unit
		-- make sure we want to track the aura
		if not unit or not ns:IsTrackableShield(id) then return end
		if type == 'SPELL_AURA_REMOVED' then
			ns:UpdateMax(srcGUID, id, name, spelltype, amount, true)
		else
			ns:UpdateMax(srcGUID, id, name, spelltype, amount)
		end
	-- Do not proceed if there are no shields active
	-- This is to prevent tracking of absorbed damage via soul link (warlocks)
	-- and other shields that absorb a percentage of health
	-- There is no need to check in that case.
	elseif hasshields then
		-- "Melee" partial absorb
		if type == "SWING_DAMAGE" then
			local _, _, _, _, _, absorbed = ...
			if not absorbed then return end
			ns:UpdateFromTooltips()
			ns:UpdateAllBars()
		-- "Spell" partial absorb
		elseif type == "RANGE_DAMAGE" 
			or type == "SPELL_DAMAGE" 
			or type == "SPELL_PERIODIC_DAMAGE"
		then
			local _, _, _, _, _, _, _, _, absorbed = ...
			if not absorbed then return end
			ns:UpdateFromTooltips()
			ns:UpdateAllBars()
		-- "Melee" full absorb
		elseif type == "SWING_MISSED"  then
			local missType = ...
			if missType ~= "ABSORB"  then return end
			ns:UpdateFromTooltips()
			ns:UpdateAllBars()
		-- "Spell" full absorb
		elseif type == "RANGE_MISSED" 
			or type == "SPELL_MISSED" 
			or type == "SPELL_PERIODIC_MISSED"
		then
			local _, _, _, missType = ...
			if missType ~= "ABSORB" then return end
			ns:UpdateFromTooltips()
			ns:UpdateAllBars()
		end
	end
end)

_G[name..'AddOn'] = ns