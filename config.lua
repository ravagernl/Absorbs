local config = {
	height = 24,
	width = 260,
	spacing = 1,
	growup = true,
	showicon = true,
	tukuishadows = true,
	tukuiskinning = true,
	smoothbar = true,
	texture = [[Interface\TargetingFrame\UI-StatusBar]],
	font = {
		path = [[Fonts\ARIALN.TTF]], 
		size = 12,
		spacing = 3,
		decimals = 1,
	},
	timercolor = {1, 1, 1, .1},
	barcolor = {.3, .3, .3},
	barbgcolor = {.1, .1, .1},
	classcolorbars = false,
	shortspell = true,
	hidespell = false,
	shortnames = true,
}
local name, ns = ...
ns.config = config