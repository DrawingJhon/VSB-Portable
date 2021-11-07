wait();script:Destroy()
print("RUN START: OutputGui")

local player = game:GetService("Players").LocalPlayer
local playerGui = player:findFirstChildOfClass("PlayerGui")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local mouse = player:GetMouse()
local dataTransfer = player:WaitForChild("SB_DataTransfer")
local commandRemote = dataTransfer:WaitForChild("SB_ReplicatorRemote")
local actionRemote = dataTransfer:WaitForChild("SB_ActionRemote")
local playerData = dataTransfer:WaitForChild("SB_PlayerData"):InvokeServer()

local OutputGUI = player:WaitForChild("SB_OutputGUI"):Clone()
player.SB_OutputGUI:Destroy()

local huge = tonumber(string.rep(9, 30))
local outputDebounce = 0
local Connections = {}
local StopOutput = false

local scriptColors = {
	Normal = Color3.new(1, 1, 1), 
	Edit = Color3.new(1, 0.6, 0.4), 
	Run = Color3.new(0, 1, 0)
}

local outputColors = {
	Note = Color3.new(0, 1, 0), 
	Run = Color3.new(0.4, 0.5, 1), 
	Error = Color3.new(1, 25/255, 25/255), 
	Print = Color3.new(1, 1, 1), 
	Warn = Color3.new(1, 0.6, 0.4)
}

-------------------------------------------------------------

local encode, decode
do
	local Key53 = 8186484168865098
	local Key14 = 4887
	local inv256
	function encode(str)
		if not inv256 then
			inv256 = {}
			for M = 0, 127 do
				local inv = -1
				repeat inv = inv + 2
				until inv * (2*M + 1) % 256 == 1
				inv256[M] = inv
			end
		end
		local K, F = Key53, 16384 + Key14
		return (str:gsub('.', function(m)
			local L = K % 274877906944  -- 2^38
			local H = (K - L) / 274877906944
			local M = H % 128
			m = m:byte()
			local c = (m * inv256[M] - (H - M) / 128) % 256
			K = L * F + H + c + m
			return ('%02x'):format(c)
		end))
	end
	function decode(str)
		local K, F = Key53, 16384 + Key14
		return (str:gsub('%x%x', function(c)
			local L = K % 274877906944  -- 2^38
			local H = (K - L) / 274877906944
			local M = H % 128
			c = tonumber(c, 16)
			local m = (c + (H - M) / 128) * (2*M + 1) % 256
			K = L * F + H + c + m
			return string.char(m)
		end))
	end
end

local sent = 0

local function replicateServer(obj)
	commandRemote:InvokeServer(sent, obj)
	sent = sent + 1
end

local function getTime()
	local sec = tick()
	return ("%.2d:%.2d:%.2d"):format(sec/3600%24, sec/60%60, sec%60)
end

local function newThread(func)
	coroutine.resume(coroutine.create(func))
end

local function sendNotification(info)
	return game:GetService("StarterGui"):SetCore("SendNotification", info)
end

local function ScrollSystem(listFrame)
	local scroll = {
		X={
			Index = 0, 
			Size = 0, 
			viewSize = listFrame.AbsoluteSize.x
		}, 
		Y = {
			Index = 0, 
			Size = 0, 
			viewSize = listFrame.AbsoluteSize.y
		}
	}
	local function updateScroll(_, x, y, sizeX, sizeY)
		scroll.X.Index = x or listFrame.CanvasPosition.X
		scroll.X.Size = sizeX or listFrame.CanvasSize.X.Offset
		scroll.Y.Index = y or listFrame.CanvasPosition.Y
		scroll.Y.Size = sizeY or listFrame.CanvasSize.Y.Offset
		listFrame.CanvasSize = UDim2.new(0, sizeX or scroll.X.Size, 0, sizeY or scroll.Y.Size)
		listFrame.CanvasPosition = Vector2.new(x or scroll.X.Index, y or scroll.Y.Index)
	end
	return {updateScroll = updateScroll, scrollingFrame = listFrame, X = scroll.X, Y = scroll.Y}
end

-------------------------------------------------------------

local Scripts = {}
local Output = {{"Note", getTime() .. " - Welcome to Voidacity's Script Builder. Please don't abuse. Enjoy!"}}
local scriptScroll
local outputScroll
local inputBar
local lastMouseTexture
local SB_OutputGui = nil
local isFirst = true
local lastChange = tick()

function createOutputGUI(scriptIndex, outputIndex, visible, toolmode)
	local RbxEvents = {}
	local function RbxEvent(signal, func)
		local event = signal:Connect(func)
		table.insert(RbxEvents, event)
		return event
	end
	local outputGui = OutputGUI:Clone()
	SB_OutputGui = outputGui
	outputGui.Parent = player:WaitForChild("PlayerGui")
	local mainFrame = outputGui.Main
	local taskFrame = outputGui.CommandBar
	local tip = outputGui.Tip
	local scriptFrame = mainFrame.ScriptList
	local outputFrame = mainFrame.Output
	local controlFrame = mainFrame.Control
	-- TaskFrame
	local openButton = taskFrame.Open
	inputBar = taskFrame.InputBar
	local defY = - (35 + mainFrame.AbsoluteSize.Y) -- in vsb 35
	local toolDefY = - (100 + mainFrame.AbsoluteSize.Y) -- in vsb 100 
	local defOpenedX = 6 -- in vsb 6
	local defClosedX = - (50 + mainFrame.AbsoluteSize.X) -- in vsb same (50)
	mainFrame.Changed:Connect(function(prop)
		if prop == "Size" or prop == "Position" then
			defY = - (35 + mainFrame.AbsoluteSize.Y)
			toolDefY = - (100 + mainFrame.AbsoluteSize.Y)
			defOpenedX = 6
			defClosedX = - (50 + mainFrame.AbsoluteSize.X)
		end
	end)
	RbxEvent(openButton.MouseButton1Up, function()
		if not visible then
			visible = true
			openButton.Text = "Close Output"
			mainFrame:TweenPosition(UDim2.new(0, defOpenedX, 1, (toolmode and toolDefY or defY)), "Out", nil, 0.3, true)
		else
			visible = false
			openButton.Text = "Open Output"
			mainFrame:TweenPosition(UDim2.new(0, defClosedX, 1, defY), "Out", nil, 0.3, true)	
		end
	end)
	RbxEvent(inputBar.FocusLost, function(enter, input)
		if enter and input and input.KeyCode == Enum.KeyCode.Return then
			local focused = false
			newThread(function()
				inputBar.Focused:Wait()
				focused = true
			end)
			replicateServer(inputBar.Text)
			if not focused then
				inputBar.Text = "Click here or press (') to run a command"
			end
		end
	end)
	-- ScriptFrame
	local scriptEntries = {}
	local scriptList = scriptFrame.Entries
	local scriptTemplate = scriptList.Script
	local scriptMessage = scriptFrame.Message
	local lastEntry;
	scriptScroll = ScrollSystem(scriptList)
	scriptScroll.Update = function(_, x, y)
		local maxY = 0
		for i, data in ipairs(Scripts) do
			local type, name, isSaved = unpack(data)
			local color = scriptColors[type]
			local entry = scriptEntries[i] or scriptTemplate:Clone()
			entry.Name = "Script"
			entry.Parent = scriptList
			entry.Text = (isSaved and "(" .. name .. ")" or name)
			entry.TextColor3 = color
			entry.Size = UDim2.new(1, 0, 0, 14)
			entry.Position = UDim2.new(0, 0, 0, maxY)
			entry.Visible = true
			if not scriptEntries[i] then
				RbxEvent(entry.MouseEnter, function(x, y)
					lastEntry = entry
					tip.Text = entry.Text
					tip.Size = UDim2.new(0, tip.TextBounds.X + 30, 0, 16)
					tip.Position = UDim2.new(0, x, 0, y-14)
					tip.Visible = true
					local con = RbxEvent(entry.MouseMoved, function(x, y)
						tip.Position = UDim2.new(0, x, 0, y-14)
					end)
					entry.MouseLeave:wait()
					con:disconnect()
					if lastEntry == entry then
						tip.Visible = false
					end
				end)
			end
			maxY = maxY + entry.AbsoluteSize.y + 0
			scriptEntries[i] = entry
		end
		scriptScroll:updateScroll(x, y, scriptList.AbsoluteSize.X, maxY)
		scriptMessage.Visible = (#Scripts == 0)
	end
	scriptScroll.Add = function(_, script, location)
		for i, tab in ipairs(Scripts) do
			if tab[2] == script[2] then
				table.remove(Scripts, i)
				break
			end
		end
		table.insert(Scripts, location, script)
	end	
	scriptScroll.Remove = function(_, name)
		for i, tab in ipairs(Scripts) do
			if tab[2] == name then
				table.remove(Scripts, i)
				table.remove(scriptEntries, i):Destroy()
				break
			end
		end
	end
	scriptScroll:Update(0, huge)
	scriptList.MouseEnter:Connect(function()
		scriptList.ScrollBarThickness = 6
	end)
	scriptList.MouseLeave:Connect(function()
		scriptList.ScrollBarThickness = 0
	end)
	-- OutputFrame
	local outputEntries = {}
	local outputHeader = outputFrame.Header
	local outputList = outputFrame.Entries
	local outputTemplate = outputFrame.Template
	outputScroll = ScrollSystem(outputList)
	outputScroll.Update = function(_, x, y)
		local reNum = outputDebounce
		local maxX, maxY = 0, 0
		for i, data in ipairs(Output) do
			if reNum ~= outputDebounce then break end
			local type, text = unpack(data)
			local entry = outputEntries[i] or outputTemplate:clone()
			entry.Name = "OutputText"
			entry.Parent = outputList
			entry.Text = text
			entry.TextColor3 = outputColors[type]
			entry.Size = UDim2.new(0, entry.TextBounds.x, 0, entry.TextBounds.y)
			entry.Position = UDim2.new(0, 2, 0, maxY)
			entry.Visible = true
			maxX = math.max(maxX, entry.AbsoluteSize.x + 5)
			maxY = maxY + entry.AbsoluteSize.y + 2
			outputEntries[i] = entry
			if reNum ~= outputDebounce then break end
		end
		local scroll = outputScroll.scrollingFrame
		local y = (maxY >= scroll.AbsoluteWindowSize.Y and y or scroll.CanvasPosition.Y)
		outputScroll:updateScroll(x, y, maxX, maxY)
	end
	outputScroll:Update(outputIndex.x, outputIndex.y)
	newThread(function()
		while outputGui.Parent do
			outputHeader.FPS.Text = "FPS: " .. ("%05.2f"):format(workspace:GetRealPhysicsFPS())
			wait(0.1)
		end
	end)
	-- Settings
	local clear = controlFrame.Clear
	local toolMode = controlFrame.ToolMode
	local exit = controlFrame.Exit
	RbxEvent(clear.MouseButton1Up, function()
		for i = 1, #Output do
			table.remove(Output, 1)
			table.remove(outputEntries, 1):Destroy()
		end
		outputScroll:Update()
	end)
	RbxEvent(toolMode.MouseButton1Up, function()
		if toolmode then
			toolmode = false
			toolMode.Selected = false
			mainFrame:TweenPosition(UDim2.new(0, defOpenedX, 1, defY), "Out", nil, 0.3, true)
		else
			toolmode = true
			toolMode.Selected = true
			mainFrame:TweenPosition(UDim2.new(0, defOpenedX, 1, toolDefY), "Out", nil, 0.3, true)
		end
	end)
	RbxEvent(exit.MouseButton1Up, function()
		visible = false
		openButton.Text = "Open Output"
		mainFrame:TweenPosition(UDim2.new(0, defClosedX, 1, defY), "Out", nil, 0.3, true)
	end)

	if isFirst then
		isFirst = false
		mainFrame.Position = UDim2.new(0, -600, 1, -206)
	else
		mainFrame.Position = UDim2.new(0, (visible and defOpenedX or defClosedX), 1, (toolmode and visible and toolDefY or defY))
	end
	openButton.Text = (visible and "Close" or "Open") .. " Output"
	toolMode.Selected = not not toolmode

	--//Resizable code
	local aroundDrag, pressing;
	local topMouseTexture = "rbxassetid://1195128791"
	local rightMouseTexture = "rbxassetid://1243635772"
	lastMouseTexture = mouse.Icon
	local minY = 106 -- in size
	local maxY = 391 -- in size
	local minX = 320 -- in size
	local maxX = 900 -- in size
	local function uiTyp(input)
		return input.UserInputType == Enum.UserInputType.MouseButton1
	end
	RbxEvent(mouse.Changed, function(prop)
		if prop == "Icon" and not aroundDrag then
			lastMouseTexture = mouse.Icon
		end
	end)
	RbxEvent(mouse.Move, function()
		local x, y = mouse.X, mouse.Y
		local absPos, absSize = mainFrame.AbsolutePosition, mainFrame.AbsoluteSize
		if pressing == "Top" then
			local sizeY = absSize.Y
			local posY = absPos.Y
			local maxPos, minPos = posY - (maxY - sizeY), posY + (sizeY - minY)
			local resultY = math.min(math.max(y, maxPos), minPos)
			local magnitude = posY - resultY
			mainFrame.Position = UDim2.new(0, absPos.X, 0, resultY)
			mainFrame.Size = UDim2.new(0, absSize.X, 0, sizeY + magnitude, maxY)
			scriptScroll:Update(0, huge)
		elseif pressing == "Right" then
			local sizeX = absSize.X
			local posX = absPos.X
			local result = math.min(math.max(x - posX, minX), maxX)
			mainFrame.Size = UDim2.new(0, result, 0, absSize.Y)
			scriptScroll:Update(0, huge)
		end
	end)
	RbxEvent(game:GetService("RunService").Stepped, function()
		local x, y = mouse.X, mouse.Y
		local absPos, absSize = mainFrame.AbsolutePosition, mainFrame.AbsoluteSize
		local dist = 3
		if (x <= (absPos.X + absSize.X + dist) and x >= (absPos.X + absSize.X - dist)) and (y >= absPos.Y and y <= (absPos.Y + absSize.Y)) then
			-- Right dragging
			aroundDrag = "Right"
			mouse.Icon = rightMouseTexture
		elseif (y <= (absPos.Y + dist) and y >= (absPos.Y - dist)) and (x >= absPos.X and x <= (absPos.X + absSize.X)) then
			-- Top dragging
			aroundDrag = "Top"
			mouse.Icon = topMouseTexture
		else
			aroundDrag = nil
			mouse.Icon = lastMouseTexture
		end
	end)
	RbxEvent(UIS.InputBegan, function(input)
		if uiTyp(input) then
			pressing = aroundDrag
		end
	end)
	RbxEvent(UIS.InputEnded, function(input)
		if uiTyp(input) then
			pressing = nil
		end
	end)

	local guiconn; guiconn = outputGui.Changed:Connect(function(prop)
		if prop == "Parent" then
			guiconn:Disconnect()
			spawn(function()
				outputGui:Destroy()
			end)
			for i, v in pairs(RbxEvents) do
				v:Disconnect()
			end
			mouse.Icon = lastMouseTexture
			if not StopOutput then
				if tick() - lastChange < 1 then
					wait(0.1)
				end
				createOutputGUI({x=0, y=0}, {x=outputScroll.scrollingFrame.CanvasPosition.X, y=outputScroll.scrollingFrame.CanvasPosition.Y}, visible, toolmode)
				lastChange = tick()
				warn("The output has been replaced. (The previous one was probably destroyed)")
				if not playerData.Mod and not warned then
					warned = true
					warn("WARNING: If you want to leave vsb use \"g/exit\" command in the command bar.")
				end
			end
		end
	end)
end

createOutputGUI({x=0, y=0}, {x=0, y=0})

-----------------------------------------------------

local http = game:GetService("HttpService")

function getData(child)
	if child:IsA("StringValue") and child.Name:match("^SB_Output:") then
		local type = child.Name:match("SB_Output:(%w+)")
		local data = http:JSONDecode(child.Value)
		if type == "Script" then
			for i, tab in ipairs(data) do
				scriptScroll:Add(tab, 1)
			end
			scriptScroll:Update(0, huge)
		elseif type == "Quick" then
			for i, name in ipairs(data) do
				scriptScroll:Add({"Normal", name}, #Scripts+1)
			end
			scriptScroll:Update(0, huge)
		elseif type == "RemoveScript" then
			for i, name in ipairs(data) do
				scriptScroll:Remove(name)
			end
			scriptScroll:Update(0, huge)
		elseif type == "Output" then
			outputDebounce = outputDebounce + 1
			if #Output == 1000 then
				table.remove(Output, 1)
			end
			local type, text, stack = unpack(data)
			if type == "Print" then
				table.insert(Output, {"Print", "> " .. text:gsub("\n", "\n  ")})
			else
				local prefix = getTime() .. " - "
				table.insert(Output, {type, prefix .. text:gsub("\n", "\n ") .. (stack or ""):gsub("\n", "\n"..prefix)})
			end
			local scroll = outputScroll.scrollingFrame
			local offset = scroll.CanvasSize.Y.Offset
			if ((offset - scroll.CanvasPosition.Y) <= (scroll.AbsoluteWindowSize.Y + 10)) then
				outputScroll:Update(scroll.CanvasPosition.X, huge);
			else
				outputScroll:Update();
			end
		end
		wait();
		child:Destroy()
	end
end

table.insert(Connections, player.ChildAdded:Connect(function(child) pcall(getData, child) end))

for i, child in pairs(player:GetChildren()) do
	pcall(getData, child)
end

Connections[#Connections + 1] = mouse.KeyDown:Connect(function(key)
	if key == "'" then
		inputBar:CaptureFocus()
	end
end)

local isClosed = false
local closureDb = false

if not playerData.Mod or true then
	local function deleteAll(t)
		isClosed = true
		for i, v in pairs(Connections) do
			v:Disconnect()
		end
		StopOutput = true
		if SB_OutputGui then
			SB_OutputGui:Destroy()
		end
		return {Sent = sent; Ticket = t; Response = encode("AcceptedRequest")}
	end
	actionRemote.OnClientInvoke = function(act, data)
		if act == encode("ClosureRequest") and type(data) == "table" and data.Sent == sent and not isClosed then
			if closureDb then return end
			closureDb = true
			local t = data.Ticket * 2
			if data.IsForced then
				closureDb = false
				return deleteAll(t)
			else
				local init = tick()
				local responsed = false
				local rData
				local bindable = Instance.new("BindableFunction")
				bindable.OnInvoke = function(response)
					if response == "Accept" then
						rData = deleteAll(t)
						responsed = true
					end
				end
				sendNotification({
					Title = "Closure request";
					Text = "You won't have access to vsb commands unless a moderator gives it to you.";
					Duration = 15;
					Button1 = "Accept";
					Button2 = "Decline";
					Callback = bindable;
				})
				repeat wait() until responsed or tick()-init > 15
				closureDb = false
				return rData
			end
		end
	end
end

sendNotification({
	Title = "Welcome to Script Builder";
	Text = "You have access to the commands. Don't abuse, enjoy!";
	Duration = 10;
	Button1 = "Accept";
	--Icon = "rbxassetid://2514057241";
})

print("OUTPUTGUI RUNNING")
