local speed = math.rad(135)
local bin = script.Parent.Parent
local player = game:GetService("Players").LocalPlayer
local mouse = player:GetMouse()
local cam = workspace.CurrentCamera
local char = player.Character
local hum = char:WaitForChild("Humanoid")
local torso = char:WaitForChild("HumanoidRootPart")
local ball = script:WaitForChild("ball")
local mConn

local function newThread(func)
	coroutine.resume(coroutine.create(func))
end

bin.Equipped:Connect(function()
	hum.PlatformStand = true
	mConn = mouse.KeyDown:Connect(function(key)
		if key == "w" then
			local keyUp = false
			newThread(function()
				repeat until mouse.KeyUp:wait() == "w"
				keyUp = true
			end)
			while hum.PlatformStand and not keyUp and wait(1/60) do
				local lv = cam.CoordinateFrame.lookVector
				torso.RotVelocity = torso.RotVelocity + Vector3.new(lv.z,0,-lv.x) * speed
			end
		elseif key == "s" then
			local keyUp = false
			newThread(function()
				repeat until mouse.KeyUp:wait() == "s"
				keyUp = true
			end)
			while hum.PlatformStand and not keyUp and wait(1/60) do
				local lv = cam.CoordinateFrame.lookVector
				torso.RotVelocity = torso.RotVelocity + Vector3.new(-lv.z,0,lv.x) * speed
			end
		elseif key == "a" then
			local keyUp = false
			newThread(function()
				repeat until mouse.KeyUp:wait() == "a"
				keyUp = true
			end)
			while hum.PlatformStand and not keyUp and wait(1/60) do
				local lv = cam.CoordinateFrame.lookVector
				local dir = math.atan2(lv.z,-lv.x) + math.rad(90)
				torso.RotVelocity = torso.RotVelocity + Vector3.new(math.sin(dir),0,math.cos(dir)) * speed           
			end
		elseif key == "d" then
			local keyUp = false
			newThread(function()
				repeat until mouse.KeyUp:wait() == "d"
				keyUp = true
			end)
			while hum.PlatformStand and not keyUp and wait(1/60) do
				local lv = cam.CoordinateFrame.lookVector
				local dir = math.atan2(lv.z,-lv.x) - math.rad(90)
				torso.RotVelocity = torso.RotVelocity + Vector3.new(math.sin(dir),0,math.cos(dir)) * speed   
			end
		elseif key == " " then
			if math.abs(ball.Velocity.y) <= 10 then
				hum.PlatformStand = true
				ball.Velocity = torso.Velocity + Vector3.new(0,75,0)
			end
		end
	end)
end)

bin.Unequipped:Connect(function()
	hum.PlatformStand = false
	if mConn then
		mConn:Disconnect()
	end
end)
