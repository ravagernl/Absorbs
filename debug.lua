local name, ns = ...
------------------------------------------------------------------------------
local debugf = tekDebug and tekDebug:GetFrame(name)
function ns:Debug(...)
	if debugf then 
		debugf:AddMessage(string.join(", ", ...)) 
	end
end
function ns:Debugf(...)
	if debugf then
		debugf:AddMessage(format(...))
	end
end