local Places = {
	MainMenu = 1730877806,
	Hub = 6360478118, -- Can be teleported to
	firstsea = 3978370137,
}

local DataStructure = {
	DungeonFarming_GPO = true,
	DungeonFarming_Tool_GPO = 'Kage',
	
	Nofall_GPO = true,
	NoDrown_GPO = true,
	NoStamTake_GPO = true,
	
	AutoStoreFruit_GPO = true,
	AutoStoreFruit_Enable_GPO = true,
	AutoStoreFruit_Webhooklink_GPO = '',
}
local Variables = DataStructure

if not isfolder('Tushub') then
	makefolder('Tushub')
end 
local file = 'Tushub/Config.json'
if not isfile(file) then
	writefile(file,'[]')
end

setmetatable(Variables,{
	__index = function(t,k,v)
		if not k then 
			return DataStructure
		else
			return DataStructure[k]
		end
	end,
	__newindex = function(t,k,v)
		DataStructure[k] = v
		
		--// Saving
		local get_data = game:service'HttpService':JSONDecode(readfile(file))
		for i,v in pairs(DataStructure) do
			get_data[i] = v
		end
		writefile(file, game:service'HttpService':JSONEncode(get_data))
	end,
})

local data_Get = game:GetService('HttpService'):JSONDecode(readfile(file))
for i,v in pairs(DataStructure) do
	if not data_Get[i] then
		data_Get[i] = v
		writefile(file,game:GetService('HttpService'):JSONEncode(data_Get))
	else
		Variables[i] = v
	end
end

local mt = getrawmetatable(game)
local index = mt.__index
local newindex = mt.__newindex
local namecall = mt.__namecall
setreadonly(mt, false)
mt.__namecall = newcclosure(function(self,...)
	local args = {...}
	local method = getnamecallmethod()
	if method:lower() == "fireserver" and not checkcaller() then
		if Variables.Nofall_GPO == true and tostring(self) == 'FallDmg' then
			return 1
		end
		if Variables.NoDrown_GPO == true and tostring(self) == 'swim' then
			if rawget(args,1) == 'drown' then
				return
			end
		end
		if Variables.NoStamTake_GPO == true and tostring(self) == 'takestam' then
			return
		end
	end
	return namecall(self,...)
end)
setreadonly(mt, true)


local function teleport(id)
	game:GetService("TeleportService"):Teleport(id, game:GetService('Players').LocalPlayer)
end

if Variables.DungeonFarming_GPO == true then
	if game.PlaceId == Places.MainMenu then
		teleport(Places.Hub)
	elseif game.PlaceId == Places.Hub then
		local function Queue()
			local args = {
				[1] = "Dungeon"
			}
			game:GetService("ReplicatedStorage").Events.Queue:InvokeServer(unpack(args))
		end
		task.spawn(function()
			while true do
				wait(1)
				Queue()
			end
		end)
	elseif game.PlaceId == Places.firstsea then
		local reservedcode = game:GetService('ReplicatedStorage'):WaitForChild('reservedCode')
		if reservedcode.Value == 'arena' then -- Being Dungeon
			repeat wait() until game:GetService('Players').LocalPlayer.Character
			local rp = game:GetService('Players').LocalPlayer.Character:WaitForChild('HumanoidRootPart')
			local hum = game:GetService('Players').LocalPlayer.Character:WaitForChild('Humanoid')
			local path = game:GetService("Workspace").Islands
			local con,map
			for i,v in pairs(path:GetChildren()) do
				if v.Name ~= 'Lobby' then
					map = v
				end
			end
			if not map then
				con = path.ChildAdded:Connect(function(c)
					wait(1)
					if c.Name ~= 'Lobby' then
						map = c
					end
				end)
			end
			repeat wait(0.1) until map
			if con then con:Disconnect() end
			--SpawnPoint
			repeat wait() until map:FindFirstChild('SpawnPoint')
			repeat 
				wait(1)
			until (rp.Position - map:FindFirstChild('SpawnPoint').Position).Magnitude <= 20
			
			task.spawn(function()
				repeat 
					wait(10)
				until game:GetService("ReplicatedStorage").Matchinfo.wave.Value >= 25
				local function reset()
					local N = game:GetService("VirtualInputManager")
					N:SendKeyEvent(true,Enum.KeyCode.Escape,false,game)
					wait()
					N:SendKeyEvent(false,Enum.KeyCode.Escape,false,game)
					wait()
					N:SendKeyEvent(true,Enum.KeyCode.R,false,game)
					wait()
					N:SendKeyEvent(false,Enum.KeyCode.R,false,game)
					wait()
					N:SendKeyEvent(true,Enum.KeyCode.Return,false,game)
					wait()
					N:SendKeyEvent(false,Enum.KeyCode.Return,false,game)
				end
				repeat
					if (rp.Position - map:FindFirstChild('SpawnPoint').Position).Magnitude < 300 then
						reset()
					end
					wait(5)
				until (rp.Position - map:FindFirstChild('SpawnPoint').Position).Magnitude >= 300
			end)
			
			--// Loading modules
			if Variables.DungeonFarming_Tool_GPO == 'Kage' then
				task.spawn(function()
					loadstring(game:HttpGetAsync("https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/GPO_KAGEKAGE.lua"))()
				end)
			end
		end
	end
end

game:GetService('Players').LocalPlayer.Backpack.ChildAdded:Connect(function(c)
	wait(1)
	if c:FindFirstChild('FruitModel') and Variables.AutoStoreFruit_GPO == true then
		c.Parent = game:GetService('Players').LocalPlayer.Character
		wait(1)
		local args = {
			[1] = true
		}
		game:GetService("ReplicatedStorage").Events.FruitStorage:InvokeServer(unpack(args))
		if Variables.AutoStoreFruit_Enable_GPO == true then
			if Variables.AutoStoreFruit_Webhooklink_GPO ~= '' then
				local webhookcheck =
					is_sirhurt_closure and "Sirhurt" or pebc_execute and "ProtoSmasher" or syn and "Synapse X" or
					secure_load and "Sentinel" or
					KRNL_LOADED and "Krnl" or
					SONA_LOADED and "Sona" or
					"Kid with shit exploit"

				local data = {
					["content"] = "Peepoo Peepoo, a wild DF has arrived!",
					["embeds"] = {
						{
							["title"] = "Username: " .. game.Players.LocalPlayer.Name,
							["description"] = tostring(c.Name),
							["type"] = "rich",
							["color"] = tonumber(0x7269da),
						}
					}
				}
				local newdata = game:GetService("HttpService"):JSONEncode(data)

				local headers = {
					["content-type"] = "application/json"
				}
				request = http_request or request or HttpPost or syn.request
				local abcdef = {Url = Variables.AutoStoreFruit_Webhooklink_GPO, Body = newdata, Method = "POST", Headers = headers}
				request(abcdef)
			end
		end
	end
end)

game:GetService("Players").LocalPlayer.OnTeleport:Connect(function(State)
	if State == Enum.TeleportState.Started then
		syn.queue_on_teleport(game:HttpGetAsync("https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/gpo.lua"))
	end
end)
