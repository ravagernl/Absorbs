local name, ns = ...
local config = {
	height = 24,
	width = 260,
	spacing = -1,
	growup = false,
	showicon = true,
	tukuishadows = false,
	tukuiskinning = true,
	smoothbar = true,
	scaletime = 15, -- For people that want timers that tick down evenly, set this to a duration (10 suggested)
	timerheight = 12,
	--texture = [[Interface\TargetingFrame\UI-StatusBar]],
	texture = [[Interface\AddOns\]]..name..[[\media\tex]],
	font = {
		path = [[Fonts\ARIALN.TTF]], 
		size = 11,
		spacing = 3,
		decimals = 1,
	},
	timercolor = {0, 0, 0, .5},
	barcolor = {.3, .6, .1},
	barbgcolor = {.15, .3, .05},
	classcolorbars = true,
	shortspell = true,
	shortname = true,
	hidespell = false,
	hidename = false,
}
ns.config = config
ns:Debug('Config set.')