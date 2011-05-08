local name, ns = ...
local select = select
------------------------------------------------------------------------------
local debugf = tekDebug and tekDebug:GetFrame(name)
function ns:Debug(...)
	if not debugf then return end
	if select('#', ...) == 1 then
		debugf:AddMessage(tostring(...))
	else
		debugf:AddMessage(string.join(', ', tostringall(...)))
	end
end
function ns:Debugf(...)
	if debugf then
		debugf:AddMessage(format(...))
	end
end