local name, ns = ...
------------------------------------------------------------------------------
local tinsert = tinsert
local tremove = tremove
local tsort = table.sort
local ipairs = ipairs
ns.shields = {
	-- Druid Stuff
	[62606] = true,	-- Savage Defense
	-- Priest stuff
	[17] = true,	-- Power Word: Shield
	[47753] = true,	-- Divine Aegis
	-- DK stuff
	[77535] = true,	-- Blood Shield
	-- Paladin stuff
	[86273] = true,	-- Illuminated Healing
	[96263] = true,	-- Sacred Shield
	-- Warlock stuff
	[6229] = true,	-- Shadow Ward
	[91711] = true,	-- Nether Ward
	-- Mage stuff
	[11426] = true,	-- Ice Barrier
}
-- two dimensional arrays
-- cache and active are only used to track how many shields there are in total
local cache, active = {}, {}
-- array where key consists of guid and spell id
ns.activeShields = {}
------------------------------------------------------------------------------
do
	local sortFunc = function(a,b)
		return a.max - a.cur < b.max - b.cur
	end
	function ns:SortShields()
		tsort(active, sortFunc)
	end
end
function ns:IterateShields()
	return ipairs(active)
end
function ns:FindActiveShieldIndexFromGUID(guid, id)
	for index, tbl in ipairs(active) do
		if tbl.guid == guid and tbl.id == id then
			return index, tbl
		end
	end
	self:Debugf('Can not find table index for guid:"%s" spellid:"%d" in active shields table.', guid, id)
end

function ns:IsTrackableShield(id)
	return self.shields[id] and 1 or nil
end

--[[
function ns:HasShieldFromGUID(guid, id)
	return self.activeShields[guid..'_'..id] and 1 or nil
end
]]

function ns:HasActiveShields()
	return #active > 0, #active
end

function ns:UpdateFromTooltipByGUID(guid, id, amount, absorbType, icon, count, debuffType, duration, expirationTime)
	local tbl = self.activeShields[guid..'_'..id]
	if not tbl then return end
	if amount > tbl.max then
		tbl.max = amount
	end
	tbl.cur = amount
	tbl.absorbType = absorbType:lower()
	tbl.icon = icon
	tbl.count = count
	tbl.debuffType = debuffType
	tbl.duration = duration
	tbl.expirationTIme = expirationTime
	--self:Debugf('%s is now at %d/%d %s absorb value.', tbl.name, tbl.cur, tbl.max, tbl.absorbType)
end

function ns:UpdateMax(unit, guid, id, name, type, amount, removed)
	--self:Debugf('UpdateMax: %q, %q, %q, %q, %q, %q, %q', unit, guid, id, name, type, amount or 0, removed and 'removed' or 'applied or refreshed')
	if removed then
		local index, tbl = self:FindActiveShieldIndexFromGUID(guid, id)
		if not index then
			return
		end
		-- Move the table from active to cache
		tinsert(cache, tbl)
		active[index] = nil
		self.activeShields[guid..'_'..id] = nil
	else
		local tbl = tremove(cache) or {}
		tbl.unit = unit
		tbl.guid = guid
		tbl.id = id
		tbl.name = name
		tbl.type = type
		tbl.max = amount
		tbl.cur = amount
		tinsert(active, tbl)
		self.activeShields[guid..'_'..id] = tbl
	end
	ns:UpdateFromTooltips()
	ns:UpdateAllBars()
end