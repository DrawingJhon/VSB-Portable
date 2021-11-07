wait(); script.Parent = nil

local clientScripts = {}
local scriptEnvs = {}
local script = script
local seed = math.random()
local events = {}
local randomStep = Random.new(seed)

local players = game:GetService("Players")
local context = game:GetService("ScriptContext")
local replicated = game:GetService("ReplicatedStorage")
local teleport = game:GetService('TeleportService')
local http = game:GetService("HttpService")
local player = players.LocalPlayer
local Library = script.Library
local RbxGui = require(Library:WaitForChild("RbxGui"))
local RbxStamper = require(Library:WaitForChild("RbxStamper"))
local RbxUtility = require(Library:WaitForChild("RbxUtility"))

local mainEnv = getfenv(0)
local mainEnvFunc = setfenv(1, mainEnv);
mainEnv.script = nil

local _G, game, script, getfenv, setfenv, workspace,
getmetatable, setmetatable, loadstring, coroutine,
rawequal, typeof, print, math, warn, error,  pcall,
xpcall, select, rawset, rawget, ipairs, pairs,
next, Rect, Axes, os, time, Faces, unpack, string, Color3,
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
NumberSequenceKeypoint, PhysicalProperties, Region3int16,
Vector3int16, elapsedTime, require, table, type, wait,
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, spawn, delay, task =
	_G, game, script, getfenv, setfenv, workspace,
getmetatable, setmetatable, loadstring, coroutine,
rawequal, typeof, print, math, warn, error,  pcall,
xpcall, select, rawset, rawget, ipairs, pairs,
next, Rect, Axes, os, time, Faces, unpack, string, Color3,
newproxy, tostring, tonumber, Instance, TweenInfo, BrickColor,
NumberRange, ColorSequence, NumberSequence, ColorSequenceKeypoint,
NumberSequenceKeypoint, PhysicalProperties, Region3int16,
Vector3int16, elapsedTime, require, table, type, task.wait,
Enum, UDim, UDim2, Vector2, Vector3, Region3, CFrame, Ray, spawn, delay, task;

-------------------------------------------------------------

local getLocalOwner = player:WaitForChild("SB_DataTransfer"):WaitForChild("SB_GetLocalOwner")
local actionRemote = player:WaitForChild("SB_DataTransfer"):WaitForChild("SB_ActionRemote")

actionRemote:InvokeServer("SetSeed", seed)

local function newThread(func, ...)
	return coroutine.resume(coroutine.create(func), ...)
end

local function newEvent(event, func)
	local conn = event:connect(func)
	table.insert(events, conn)
	return conn
end

local responseQueue = {}
local function newScript(...)
	local mTick = math.random()
	table.insert(responseQueue, mTick)
	local pos = table.find(responseQueue, mTick)
	if pos > 1 then
		repeat task.wait() pos = table.find(responseQueue, mTick) until pos <= 1
	end
	local _, s = pcall(actionRemote.InvokeServer, actionRemote, "NewScript", randomStep:NextNumber(), ...)
	table.remove(responseQueue, pos)
	return s
end

local function sendData(plyr, data, sync)
	local player2 = type(plyr) == "userdata" and plyr or players:FindFirstChild(plyr)
	if player2 and player2:IsA("Player") then
		local type, text = unpack(data)
		if player2 ~= player and sync then
			local dataEntry = Instance.new("StringValue")
			dataEntry.Name = "SB_Output:Output"
			dataEntry.Value = http:JSONEncode({type, "[" .. player2.Name .. "]: " .. text})
			dataEntry.Parent = player
			text = "[" .. player.Name .. "]: " .. text
		end
		local dataEntry = Instance.new("StringValue")
		dataEntry.Name = "SB_Output:Output"
		dataEntry.Value = http:JSONEncode({type, text})
		dataEntry.Parent = player2
	end
end

newEvent(replicated.ChildAdded, function(child) -- recieve "DS" aka DisableScript, little trick to affect nil players
	if child:IsA("StringValue") and child.Name == "DS" and child.Value == player.Name then
		for script, tab in pairs(clientScripts) do
			scriptEnvs[clientScripts[script].env] = nil
			clientScripts[script] = nil
			script:Destroy()
		end
		wait();
		child:Destroy()
	end
end)

-----------------------------------------------------------------

local newProxyEnv;
local proxies = setmetatable({}, {__mode="v"});

local customLibrary = {
	print = function(...)
		local owner = scriptEnvs[getfenv(0)]
		local args = {...}
		for i = 1, select("#", ...) do
			args[i] = tostring(args[i])
		end
		sendData(owner.Name, {"Print", table.concat(args, "\t")}, true)
	end, 
	warn = function(...)
		local owner = scriptEnvs[getfenv(0)];
		local args = {...};
		for i = 1, select("#", ...) do
			args[i] = tostring(args[i]);
		end
		sendData(owner.Name, {"Warn", table.concat(args, "\t")}, true)
	end,
	["newScript,NS"] = function(...)
		local source, parent = select(1, ...), select(2, ...)
		assert(select("#", ...) ~= 0, "NS: missing argument #1 to 'NS' (string expected)")
		assert(type(source) == "string", "NS: invalid argument #1 to 'NS' (string expected, got "..typeof(source)..")")
		assert(select("#", ...) ~= 1, "NS: missing argument #2 to 'NS' (Instance expected)")
		assert(typeof(parent) == "Instance", "NS: invalid argument #2 to 'NS' (Instance expected, got "..typeof(parent)..")")
		local owner = scriptEnvs[getfenv(0)]
		local scriptObj = newScript("Script", "NS - "..parent:GetFullName(), source, "NLS", parent)
		return scriptObj
	end,
	["newLocalScript,NLS"] = function(...)
		local source, parent = select(1, ...), select(2, ...)
		assert(select("#", ...) ~= 0, "NLS: missing argument #1 to 'NLS' (string expected)")
		assert(type(source) == "string", "NLS: invalid argument #1 to 'NLS' (string expected, got "..typeof(source)..")")
		assert(select("#", ...) ~= 1, "NLS: missing argument #2 to 'NLS' (Instance expected)")
		assert(typeof(parent) == "Instance", "NLS: invalid argument #2 to 'NLS' (Instance expected, got "..typeof(parent)..")")
		local owner = scriptEnvs[getfenv(0)]
		local scriptObj = newScript("Local", "NLS - "..parent:GetFullName(), source, "NLS", parent)
		return scriptObj
	end,
	--require = function()
	--	error("require is blocked", 0)
	--end,
	getfenv = function(arg)
		local typ = type(arg);
		local env;
		if (typ == "number" and arg >= 0) then
			local lvl = (arg == 0 and 0 or arg+1);
			env = getfenv(lvl);
		elseif (typ == "nil") then
			env = getfenv(2);
		elseif (typ == "function") then
			env = getfenv(arg);
		else
			getfenv(arg);
		end
		if (env == mainEnv) then
			return getfenv(0);
		else
			return env;
		end
	end,
	setfenv = function(arg, tbl)
		local typ = type(arg);
		local func;
		if (typ == "number" and arg >= 0) then
			local lvl = (arg == 0 and 0 or arg+1);
			func = setfenv(lvl, tbl);
		elseif (typ == "function") then
			func = setfenv(arg, tbl);
		else
			setfenv(arg, tbl);
		end
		if (func == mainEnvFunc) then
			setfenv(mainEnvFunc, mainEnv);
			error("Error occured setfenv");
		else
			return func;
		end
	end,
	LoadLibrary = function(library)
		local LoadLibrary = function(Lib)
			if Lib=="RbxGui" then
				return RbxGui
			elseif Lib=="RbxStamper" then
				return RbxStamper
			elseif Lib=="RbxUtility" then
				return RbxUtility
			end
		end
		if LoadLibrary(library) then
			local Library = LoadLibrary(library)
			local userdata = newproxy(true)
			local meta = getmetatable(userdata)
			meta.__index = function(self, index)
				return Library[index]
			end
			meta.__tostring = function(self)
				return library
			end
			meta.__metatable = "The metatable is locked"
			return userdata
		else
			error("Invalid library name")
		end
	end,
}

do
	local modifiedcustomLibrary = {};
	for keys, value in next, customLibrary do
		for key in string.gmatch(keys, "[^,]+") do
			modifiedcustomLibrary[key] = value
		end
	end
	customLibrary = modifiedcustomLibrary
end

function newProxyEnv(script, owner)	
	local env = setmetatable({script = script; owner = owner}, {
		__index = function(self, index)
			if (not scriptEnvs[getfenv(0)]) then error("Script ended"); end
			rawset(mainEnv, index, nil);
			local lib = (customLibrary[index] or mainEnv[index]);
			if (proxies[lib]) then 
				return proxies[lib]; 
			end
			if (lib and type(lib) == "function" and index ~= "setfenv" and index ~= "getfenv" and index ~= "error") then
				local func = function(...)
					if scriptEnvs[mainEnv.getfenv(0)] then
						return lib(...)
					else
						error("Script ended", 0)
					end
				end
				proxies[lib] = func;
				return func;
			else
				return lib;
			end
		end,
		__metatable = getmetatable(mainEnv)
	})
	return env
end

-------------------------------------------------------------

newEvent(context.Error, function(error, stack, script)
	if clientScripts[script] then
		local owner, name = unpack(clientScripts[script])
		local editedStack = "\n"
		for line in (stack.."\n"):gmatch("(.-)\n") do
			local source, errLine = line:match("(.+), (.+)")
			if source then
				editedStack = editedStack .. "[" .. name .. "], " .. errLine .. "\n"
			end
		end
		sendData(owner, {"Error", error:gsub("^.+:(%d+):", "["..name.."] :%1:"), editedStack:sub(1, -2):gsub("(, .-) %- [^\n]+$", "%1")})
	end
end)

local meta_shared = {
	__call = function(self, script)
		if not clientScripts[script] then
			local owner, name = getLocalOwner:InvokeServer(script)
			local env = newProxyEnv(script, owner)
			setfenv(0, env)
			setfenv(2, env)
			scriptEnvs[env] = owner
			clientScripts[script] = {owner, name, env = env}
			sendData(owner.Name, {"Run", "Running ("..name..")"}, true)
		end
	end, 
	__metatable = "The metatable is locked (from ox-side)"
}

setmetatable(shared, meta_shared)

-------------------------------------------------------------

newEvent(player.Chatted, function(text)
	if text == "\\rj" or text == "-rj" then
		game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
	end
end)

local function antiFallDeath(char)
	local hasBodyPos = false
	local torso = char:findFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")
	newEvent(game:GetService("RunService").Stepped, function()
		if torso.Position.Y <= -240 then
			local rNum1 = math.random(-100, 100)
			local rNum2 = math.random(-100, 100)
			torso.CFrame = CFrame.new(rNum1, 5, rNum2) * (torso.CFrame - torso.CFrame.p)
			if not hasBodyPos then
				hasBodyPos = true
				local body = Instance.new("BodyPosition", torso)
				body.Position = Vector3.new(rNum1, 5, rNum2)
				body.MaxForce = Vector3.new(0, math.huge, 0)
				delay(1, function()
					body:Destroy()
					hasBodyPos = false
				end)
			end
		end
	end)
end

if player.Character then
	coroutine.resume(coroutine.create(antiFallDeath), player.Character)
end

newEvent(player.CharacterAdded, antiFallDeath)

newEvent(player.ChildAdded, function(child)
	if child:IsA("StringValue") and child.Name == "Exit: "..seed  and child.Value == player.Name then
		for i, v in pairs(events) do
			v:Disconnect()
		end
		for script, tab in pairs(clientScripts) do
			scriptEnvs[clientScripts[script].env] = nil
			clientScripts[script] = nil
			script:Destroy()
		end
		table.clear(meta_shared)
		setmetatable(shared, nil)
		wait()
		child:Destroy()
	end
end)
