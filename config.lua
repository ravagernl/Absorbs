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
	scaletime = false, -- For people that want timers that tick down evenly, set this to a duration (10 suggested)
	timerheight = 4,
	--texture = [[Interface\TargetingFrame\UI-StatusBar]],
	texture = [[Interface\AddOns\]]..name..[[\media\tex]],
	font = {
		path = [[Fonts\ARIALN.TTF]], 
		size = 11,
		spacing = 3,
		decimals = 1,
	},
	timercolor = {0, 0, 0, .5},
	barcolor = {.5, .5, .5},
	barbgcolor = {.25, .25, .25},
	classcolorbars = false,
	shortspell = true,
	shortname = true,
	hidespell = false,
	hidename = false,
	hideownname = false
}
ns.config = config
ns:Debug('Config set.')