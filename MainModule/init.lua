local mainScript = script.oxSB
local ssFolder = Instance.new("Folder")
ssFolder.Name = "ServerScriptService"
mainScript.Parent = ssFolder

local init = newproxy(true)
local meta = getmetatable(init)
meta.__metatable = "The metatable is locked"
meta.__call = function(self, ...)
	local success, r1, r2 = pcall(function(...)
		return require(mainScript)(...)
	end, ...)
	if not success then
		warn("SB_Module: "..tostring(r1))
		return false, r1
	end
	return r1, r2
end

return init
