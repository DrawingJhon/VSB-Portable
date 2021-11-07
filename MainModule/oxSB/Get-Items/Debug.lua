local function debug(obj,rec)
	for i,child in ipairs(obj:GetChildren()) do
		if child:IsA("Hint") or child:IsA("Message") then
			child:Destroy()
		end
		if rec then
			debug(child)
		end
	end
end

debug(workspace,true)
debug(script.Parent)
wait();script:Destroy()
