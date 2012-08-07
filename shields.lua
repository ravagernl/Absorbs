local name, ns = ...
------------------------------------------------------------------------------
local tinsert = tinsert
local tremove = tremove
local tsort = table.sort
local ipairs = ipairs
local next = next
------------------------------------------------------------------------------
local shields = {
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
	[1463] = true,	-- Mana Shield

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
ns.shields = shields
ns.shieldsIndex = {}
for k, _ in pairs(shields) do
	tinsert(ns.shieldsIndex, k)
end
------------------------------------------------------------------------------
-- two dimensional arrays
-- cache and active are only used to track how many shields there are in total
local cache, active, activeShields = {}, {}, {}
-- array where key consists of guid and spell id
ns.activeShields = activeShields
------------------------------------------------------------------------------
do
	local sortFunc = function(a,b)
		-- Sometimes it doesn't give along a or b
		if not a and b then return end
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
end
function ns:GetShield(i)
	return active[i]
end
function ns:FindActiveShieldIndexFromGUID(guid, id)
	for index, tbl in next, active do
		if tbl.guid == guid and tbl.id == id then
			return index, tbl
		end
	end
	self:Debugf('|cffff6666Can not find table index for guid:"%s" spellid:"%d" in active shields table.|r', guid, id)
end

function ns:IsTrackableShield(id)
	return shields[id]
end
function ns:UpdateFromTooltipByGUID(guid, id, amount, icon, count, debuffType, duration, expirationTime)
	local tbl = activeShields[guid..'_'..id]
	if not tbl then return end
	if amount > tbl.max then
		tbl.maxChanged = true
		tbl.max = 0 + amount
	end
	if tbl.cur ~= amount then
		tbl.cur = 0 + amount
		tbl.curChanged = true
	end
	tbl.icon = icon
	tbl.count = min(1, 0 + count)
	tbl.debuffType = debuffType
	tbl.duration = 0 + duration
	if tbl.expirationTime ~= expirationTime then
		tbl.expirationTime = expirationTime
		tbl.timeChanged = true
	end
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
		activeShields[guid..'_'..id] = nil
	else
		local tbl = tremove(cache) or {}
		tbl.unit = unit
		tbl.guid = guid
		tbl.id = id
		tbl.name = name
		tbl.type = type
		tbl.max = tonumber(amount) or 0
		tbl.cur = tonumber(amount) or 0
		tbl.maxChanged = true
		tbl.curChanged = true
		tinsert(active, tbl)
		activeShields[guid..'_'..id] = tbl
	end
	ns:UpdateFromTooltips()
	ns:UpdateAllBars()
end