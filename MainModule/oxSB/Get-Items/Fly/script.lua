local bin = script.Parent
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local char = player.Character
local torso = char:FindFirstChild("HumanoidRootPart")
local seleted = false
local pos, gyro;

bin.Equipped:Connect(function()
	selected = true
	pos = Instance.new("BodyPosition", torso)
	pos.maxForce = Vector3.new(1,1,1) * 1e99
	pos.position = torso.Position
	gyro = Instance.new("BodyGyro", torso)
	gyro.maxTorque = Vector3.new(1,1,1) * 1e99
	local angle = CFrame.new()
	mouse.Button1Down:Connect(function()
		local button_up = false
		angle = CFrame.Angles(-math.rad(70),0,0)
		coroutine.resume(coroutine.create(function()
			while not button_up do
				pos.position = pos.position + (mouse.Hit.p - torso.Position).unit * 10
				wait()
			end
		end))
		mouse.Button1Up:Wait()
		button_up = true
		angle = CFrame.new()
	end)
	while selected do
		gyro.cframe = CFrame.new(torso.Position, mouse.Hit.p) * angle
		wait()
	end
end)

bin.Unequipped:Connect(function()
	selected = false
	pos:Destroy()
	gyro:Destroy()
end)
