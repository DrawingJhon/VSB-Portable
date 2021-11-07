local player = game:GetService("Players").LocalPlayer
if workspace.CurrentCamera then
	workspace.CurrentCamera:Destroy()
end
local camera = Instance.new("Camera", workspace)
if player.Character then
	local hum = player.Character:findFirstChildOfClass("Humanoid")
	if hum then
		camera.CameraSubject = hum
	end
end
camera.CameraType = "Custom"

workspace.CurrentCamera = camera
wait(); script:Destroy()
