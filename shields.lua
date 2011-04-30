local name, ns = ...
------------------------------------------------------------------------------
local tinsert = tinsert
local tremove = tremove
local tsort = table.sort
local ipairs = ipairs
------------------------------------------------------------------------------
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
	[7812] = true,	-- Sacrifice (Voidwalker)
	-- Mage stuff
	[11426] = true,	-- Ice Barrier
	[543] = true,	-- Mage Ward
	
	-- non class
	[96988] = true,	-- Stay of Execution (25800 damage)
	[29719] = true,	-- Greater Shielding (4k damage on shield)
	[29674] = true, -- Lesser Shielding (1k damage on shield)
	[57350] = true,	-- Darkmoon Card: Illusion
	[4077] = true,	-- Ice Deflector
	[71586] = true,	-- Corroded Skeleton Key (6.4k damage)
	[96945] = true,	-- Gift of the Greatfather (7.4k damage, winterveil trinket)
	[97129] = true,	-- Gaze of the Greatfather (8350 damage, winterveil trinket)
	[31771] = true, -- Runed Fungalcap (440 damage)
	[91296] = true, -- Corrupted egg shell (4060 damage)
	[29506] = true, -- The burrowers shell(900 damage)
	[21956] = true, -- Mark of resolution(500 damage)
	[55019] = true,	-- Noise Machine (1.1k damage)
	[32278] = true, -- Greater Warding Shield?? (400 damage)
	[93745] = true, -- Seed Casing??? (1500 damage)
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
function ns:HasActiveShields()
	return #active > 0
end
function ns:GetNumShields()
	return #active
en
function ns:GetShield(i)
	return active[i]
end
function ns:FindActiveShieldIndexFromGUID(guid, id)
	for index, tbl in next, active do
		if tbl.guid == guid and tbl.id == id then
			return index, tbl
		end
	end
	self:Debugf('Can not find table index for guid:"%s" spellid:"%d" in active shields table.', guid, id)
end

function ns:IsTrackableShield(id)
	return self.shields[id] and 1 or nil
end
function ns:UpdateFromTooltipByGUID(guid, id, amount, absorbType, icon, count, debuffType, duration, expirationTime)
	local tbl = self.activeShields[guid..'_'..id]
	if not tbl then return end
	if amount > tbl.max then
		tbl.max = 0 + amount
	end
	tbl.cur = 0 + amount
	tbl.absorbType = absorbType and absorbType:lower() or nil
	tbl.icon = icon
	tbl.count = min(1, 0 + count)
	tbl.debuffType = debuffType
	tbl.duration = 0 + duration
	tbl.expirationTime = expirationTime
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
		tbl.id = 0 + id
		tbl.name = name
		tbl.type = type
		tbl.max = 0 + amount
		tbl.cur = 0 + amount
		tinsert(active, tbl)
		self.activeShields[guid..'_'..id] = tbl
	end
	ns:UpdateFromTooltips()
	ns:UpdateAllBars()
end