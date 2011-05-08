-- Native Tukui support
local name, ns = ...
local config = ns.config
------------------------------------------------------------------------------
local Tukui = config.tukuiskinning and (ElvUI or Tukui)
local T, C, L
if Tukui then
	T, C, L = unpack(Tukui)
	config.font.path = C.media.uffont
	config.font.style = "THINOUTLINE"
	config.font.size = T.Duffed and C.unitframes.fontsize or 12
	config.texture = C.media.normTex
	if C["unitframes"].unicolor then
		config.barcolor = C["unitframes"].healthbarcolor
		config.barbgcolor = C["unitframes"].deficitcolor
		if T.Duffed then -- stupid red
			config.barbgcolor = {.1,.1,.1}
		end
	else
		config.classcolorbars = true
	end
end