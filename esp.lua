--// Declaring
getgenv = getgenv

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local keybindlib = getgenv().EB2S()
function getModel(tar)
	if tar.Parent.ClassName == 'Model' then
		return tar.Parent
	elseif tar.Parent == game:GetService('Workspace') or not tar.Parent then
		return nil
	else
		getModel(tar.Parent)
	end
end
Drawing = Drawing
--//
local Current = {
	Teamate = {},
	Flags = {},
	Flags_inst = {},
}
local DataStructure = {
	ESP_Player = false,
	ESP_PlayerBind = '',
	
	ESP_DefTeam = false, --// Be Friend or add from a list?,...
	ESP_TeamBind = '',
	
	ESP_ShowBox = false,
	ESP_BoxBind = '',
	
	ESP_ShowDistance = false,
	
	ESP_ShowHealth = false,
	
	ESP_ShowHealthBar = false,
	ESP_HealthBarBind = '',
	
	ESP_Size = 16,
	ESP_MaxDistance = 2000,
	ESP_YOffset = 4,
	ESP_ZOffset = 0,
	
	ESP_PlayerColor = {
		R = 255,
		G = 0,
		B = 0
	},
	ESP_TeamColor = {
		R = 0,
		G = 255,
		B = 0,
	},
	
	ESP_Teamate = {},
}
local Variables = {}
local file = 'Tushub/Config.json'
getgenv().tushub_saving(file,DataStructure,Variables)
function WTS(pos)
	local screen = workspace.CurrentCamera:WorldToViewportPoint(pos)
	return Vector2.new(screen.x, screen.y)
end

local data = {
	Track = {},
	Anchored = {},
}
function AddESP(part, color, args, Flag, Features)
	local pos
	if typeof(part) == 'Vector3' then
		pos = part
	elseif typeof(part) == 'CFrame' or typeof(part) == 'Instance' then
		pos = part.Position
	end
	if pos then
		--// Fetching Layers
		local layers,Result = {},{}
		if args then
			for i,v in pairs(args) do
				if not layers[v.Layer] then
					layers[v.Layer] = {}
				end
				local layer = v.Layer
				v.Layer = nil
				table.insert(layers[layer],v)
			end
		end
		
		--// Fetching Priority
		for i,v in pairs(layers) do
			local layer = {}
			for o,c in pairs(v) do
				local pri = c.Priority
				if not pri then error('I dont see the priority. From: '..game:GetService('HttpService'):JSONEncode(v)) end
				c.Priority = nil
				layer[pri] = c
			end
			Result[i] = layer
		end
		
		if not next(Result) then Result = nil end
		
		local name = Drawing.new("Text")
		name.Font = Drawing.Fonts.Monospace
		name.Color = color or Color3.fromRGB(255,0,0)
		name.Position = WTS(pos)
		name.Size = Variables.ESP_Size
		name.Outline = true
		name.Center = true
		name.Visible = false
		
		if args.Anchored then --// Ill script this later?... or not necessary. im lzazy
			table.insert(data.Anchored,{
				Tag = name,
				Layers = Result
			})
		else
			local argto = {
				Tag = name,
				Flag = Flag	,
				Layers = Result,
				Part = part,
			}
			if Features then
				for i,v in pairs(Features) do
					argto[i] = v
					if i == 'Box' and v then
						if Features['BoxSize'] then
							argto.BoxSize = Features['BoxSize']
						else
							argto.BoxSize = part.Size
							if getModel(part) then
								argto.BoxSize = getModel(part):GetExtentsSize()
							end
						end
					end
				end
			end
			
			table.insert(data.Track,argto)
		end
	end
end

local LoadedModule = {}
local LoadedGuiModule = {}
local Connections = {}
function getChar(inst)
	local conn
	function get(c)
		repeat 
			wait(0.1)
		until (inst.Character:FindFirstChild('HumanoidRootPart') and inst.Character:FindFirstChildOfClass('Humanoid')) or not inst:IsDescendantOf(game) or not inst.Character:IsDescendantOf(game:GetService('Workspace'))
		pcall(function()
			if inst.Character:FindFirstChild('HumanoidRootPart') and inst.Character:FindFirstChildOfClass('Humanoid') then
				repeat wait() until inst.Character:FindFirstChild('HumanoidRootPart'):IsDescendantOf(game:GetService('Workspace'))
				local rgb = Variables.ESP_PlayerColor
				local upperlayer = {
					{
						Text_front = '[',
						TrackInst = inst.Character,
						TrackValue = 'Name',
						Text_end = ']',
						Layer = 1,
						Priority = 1,
						FriendTrack = true,
						ColorFlag = 'ESP_PlayerColor',
					},
					{
						Text_front = '[',
						TrackInst = inst.Character:FindFirstChild('HumanoidRootPart'),
						TrackDistance = true,
						Text_end = ']',
						Flag = 'ESP_ShowDistance',
						Layer = 1,
						Priority = 2,
					},
				}
				local args = {
					{
						Layer = 1,
						Priority = 1,
					},
					{
						Text_front = '[',
						TrackInst = inst.Character:FindFirstChildOfClass('Humanoid'),
						TrackValue = 'Health',
						Layer = 2,
						Flag = 'ESP_ShowHealth',
						Priority = 1,
					},
					{
						Text_front = '/',
						TrackInst = inst.Character:FindFirstChildOfClass('Humanoid'),
						TrackValue = 'MaxHealth',
						Text_end = ']',
						Layer = 2,
						Flag = 'ESP_ShowHealth',
						Priority = 2,
					},
					{
						Text_front = '[',
						Text_end = ']',
						TrackInst = inst.Character:FindFirstChildOfClass('Humanoid'),
						TrackInst_2 = inst.Character:FindFirstChildOfClass('Humanoid'),
						TrackValue = 'Health',
						TrackValue_2 = 'MaxHealth',
						Layer = 2,
						Flag = 'ESP_ShowHealth',
						Priority = 3,
					},
				}
				if next(LoadedModule) then
					for i,v in pairs(LoadedModule) do
						if v.Tag == 'Player' then
							local new = v
							new.Tag = nil
							table.insert(args,new)
						end
					end
				end
				local Features = {
					Box = 'ESP_ShowBox',
					HealthBar = 'ESP_ShowHealthBar',
					BoxSize = Vector3.new(3.5,5,2),
				}
				AddESP(inst.Character:FindFirstChild('HumanoidRootPart'), Color3.fromRGB(rgb.R,rgb.G,rgb.B), upperlayer, 'ESP_Player')
				AddESP(inst.Character:FindFirstChild('HumanoidRootPart'), Color3.fromRGB(rgb.R,rgb.G,rgb.B), args, 'ESP_Player',Features)
			end
		end)
	end
	
	if inst.Character then get(inst.Character) end
	conn = inst.CharacterAdded:Connect(get)
	Connections[inst.Name] = conn
end

--// Load Module here
local userid = game:GetService('Players').LocalPlayer.UserId
for i,v in pairs(game:GetService('Players'):GetChildren()) do
	if v ~= game:GetService('Players').LocalPlayer then
		task.spawn(getChar,v)
		if v:IsFriendsWith(userid) then
			if not table.find(Current.Teamate,v.Name) then
				table.insert(Current.Teamate,v.Name)
			end
		end
	end
end
game:GetService('Players').PlayerAdded:Connect(function(p)
	task.spawn(getChar,p)
	if p:IsFriendsWith(userid) then
		if not table.find(Current.Teamate,p.Name) then
			table.insert(Current.Teamate,p.Name)
		end
	end
end)
game:GetService('Players').PlayerRemoving:Connect(function(p)
	if Connections[p.Name] then
		Connections[p.Name]:Disconnect()
		Connections[p.Name] = nil
	end
	if table.find(Current.Teamate,p.Name) then
		table.remove(Current.Teamate,p.Name)
	end
end)

local function NewQuad(color)
	local quad = Drawing.new("Quad")
	quad.Visible = false
	quad.PointA = Vector2.new(0,0)
	quad.PointB = Vector2.new(0,0)
	quad.PointC = Vector2.new(0,0)
	quad.PointD = Vector2.new(0,0)
	quad.Color = color
	quad.Filled = false
	quad.Thickness = 1
	quad.Transparency = 1
	return quad
end
local function NewLine(thickness, color)
	local line = Drawing.new("Line")
	line.Visible = false
	line.From = Vector2.new(0, 0)
	line.To = Vector2.new(0, 0)
	line.Color = color 
	line.Thickness = thickness
	line.Transparency = 1
	return line
end

--// RUS
task.spawn(function()
	while true do
		for i,v in pairs(data.Track) do
			if v.Part and v.Part:IsDescendantOf(game:GetService('Workspace')) then
				local newdistance
				if Variables.ESP_MaxDistance == 10000 then
					newdistance = math.huge
				else
					newdistance = Variables.ESP_MaxDistance
				end
				if newdistance ~= 0 then
					local function espto()
						if v.Tag and Variables[v.Flag] then
							if Variables[v.Flag] == true then
								if v.Layers then
									local text = ""
									for layer = 1,#v.Layers do --// Fetching layers
										for priority = 1,#(v.Layers[layer]) do
											local args = v.Layers[layer][priority]
											
											--// Really Special Arguments:
											if args.FriendTrack and args.FriendTrack == true then
												if table.find(Current.Teamate,v.Part.Parent.Name) then
													args.ColorFlag = 'ESP_TeamColor'
												end
											end
											if args.ColorFlag then
												if Variables[args.ColorFlag] then
													local rgb = Variables[args.ColorFlag]
													if rgb.R and rgb.G and rgb.B then
														v.Tag.Color = Color3.fromRGB(rgb.R,rgb.G,rgb.B)
													end
												end
											end
											
											--// Normal Arguments
											local Text_front = args.Text_front or ''
											local Text_end = args.Text_end or ''
											local TrackInst = args.TrackInst
											local TrackValue = args.TrackValue

											--// Special Arguments
											local Flag = args.Flag
											local TrackDistance = args.TrackDistance
											local TrackInst_2 = args.TrackInst_2
											local TrackValue_2 = args.TrackValue_2

											--// Loading Functions
											local function nexto()
												text = text..Text_front

												if TrackDistance and TrackInst and typeof(TrackInst) == 'Instance' and TrackInst.Position then
													if game:GetService('Players').LocalPlayer.Character then
														if game:GetService('Players').LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
															text = text..tostring(math.round(tonumber((game:GetService('Players').LocalPlayer.Character.HumanoidRootPart.Position - TrackInst.Position).Magnitude)))
														end
													end
												else
													if TrackInst_2 and TrackValue_2 then
														if TrackInst and TrackValue then
															text = text..tostring(math.round(math.clamp(tonumber(TrackInst[TrackValue]/TrackInst_2[TrackValue_2]),0,1)*100))..'%'
														end
													else
														if TrackInst and TrackValue then
															--// So we going to round it to 2nd decimal
															local stringto = tostring(TrackInst[TrackValue])
															local rounded
															local getdec = string.split(stringto,'.')
															if getdec[2] and getdec[1] then
																rounded = getdec[1]..'.'..string.sub(getdec[2],1,2)
															end
															if rounded then
																text = text..rounded
															else
																text = text..stringto	
															end
														end
													end
												end
												text = text..Text_end
												
												if args.Spacing and args.Spacing == true then
													text = text..' '
												end
											end
											if Flag then
												if Variables[Flag] and Variables[Flag] == true then
													nexto()
												end
											else
												nexto()
											end
										end
										text = text..'\n'
									end
									v.Tag.Text = text
								end
								if table.find(Current.Teamate,v.Part.Parent.Name) then
									local asd = Variables.ESP_TeamColor
									local r,g,b = asd.R,asd.G,asd.B
									v.Tag.Color = Color3.fromRGB(r,g,b)
								else
									local asd = Variables.ESP_PlayerColor
									local r,g,b = asd.R,asd.G,asd.B
									v.Tag.Color = Color3.fromRGB(r,g,b)
								end
								local cfrem = v.Part.CFrame * CFrame.new(0,Variables.ESP_YOffset,Variables.ESP_ZOffset)
								local pos = cfrem.p
								v.Tag.Position = WTS(pos)
								local _, screen = workspace.CurrentCamera:WorldToViewportPoint(pos)
								if screen then
									if v.Tag.Size ~= Variables.ESP_Size then
										v.Tag.Size = Variables.ESP_Size
									end
									v.Tag.Visible = true
								else
									v.Tag.Visible = false
								end
							else
								if typeof(v.Tag) == 'table' then
									for o,c in pairs(v.Tag) do
										c.Visible = false
									end
								else
									v.Tag.Visible = false
								end
							end
						end
						if v.Box and Variables[v.Box]then
							if not v.Boxlib then
								local color = Color3.fromRGB(255,0,0)
								if v.Flag == 'Player ESP' then
									local r,g,b = Variables.ESP_PlayerColor.R,Variables.ESP_PlayerColor.G,Variables.ESP_PlayerColor.B
									color = Color3.fromRGB(r,g,b)
									if v.IsTeam or table.find(Current.Teamate,v.Part.Parent.Name) then
										local r,g,b = Variables.ESP_TeamColor.R,Variables.ESP_TeamColor.G,Variables.ESP_TeamColor.B
										color = Color3.fromRGB(r,g,b)
									end
								end
								v.Boxlib = {
									black = NewQuad(Color3.fromRGB(0,0,0)),
									box = NewQuad(color),
								}
							end
							if Variables[v.Box] == true then
								local Size = v.BoxSize or v.Part.Size
								local CF = v.Part.CFrame
								for o,c in pairs(v.Boxlib) do
									local TLPos, Visible1	= workspace.CurrentCamera:WorldToViewportPoint((CF * CFrame.new( Size.X,  Size.Y, 0)).Position);
									local TRPos, Visible2	= workspace.CurrentCamera:WorldToViewportPoint((CF * CFrame.new(-Size.X,  Size.Y, 0)).Position);
									local BLPos, Visible3	= workspace.CurrentCamera:WorldToViewportPoint((CF * CFrame.new( Size.X, -Size.Y, 0)).Position);
									local BRPos, Visible4	= workspace.CurrentCamera:WorldToViewportPoint((CF * CFrame.new(-Size.X, -Size.Y, 0)).Position);

									--// tracking
									if Visible1 and Visible2 and Visible3 and Visible4 then
										c.Visible = true
										c.PointA = Vector2.new(TLPos.X, TLPos.Y)
										c.PointB = Vector2.new(TRPos.X, TRPos.Y)
										c.PointC = Vector2.new(BRPos.X, BRPos.Y)
										c.PointD = Vector2.new(BLPos.X, BLPos.Y)
									else
										c.Visible = false
									end
								end
							else
								--// turning off
								for o,c in pairs(v.Boxlib) do
									c:Remove()
								end
								v.Boxlib = nil
							end
						end
						if v.HealthBar and Variables[v.HealthBar] then
							if not v.HealthBarlib then
								v.HealthBarlib = {
									healthbar = NewLine(4, Color3.fromRGB(0,0,0)),
									greenhealth = NewLine(2, Color3.fromRGB(0,0,0))
								}
							end
							if Variables[v.HealthBar] == true then
								local hum = v.Part.Parent:FindFirstChildOfClass('Humanoid')
								if not hum then
									for o,c in pairs(v.HealthBarlib) do
										c:Remove()
										c = nil
									end
									v.HealthBarlib = nil
									v.HealthBarlib = nil
								else
									--// track
									local Pos, screen = workspace.CurrentCamera:WorldToViewportPoint(v.Part.Position)
									if screen then
										if v.HealthBarlib.greenhealth.Visible == false then v.HealthBarlib.greenhealth.Visible = true end
										if v.HealthBarlib.healthbar.Visible == false then v.HealthBarlib.healthbar.Visible = true end

										local head = workspace.CurrentCamera:WorldToViewportPoint(v.Part.Position + Vector3.new(0,1.5,0))
										local DistanceY = math.clamp((Vector2.new(head.X, head.Y) - Vector2.new(Pos.X, Pos.Y)).magnitude, 2, math.huge)

										local d = (Vector2.new(Pos.X - DistanceY, Pos.Y - DistanceY*2) - Vector2.new(Pos.X - DistanceY, Pos.Y + DistanceY*2)).magnitude 
										local healthoffset = hum.Health/hum.MaxHealth * d

										v.HealthBarlib.greenhealth.From = Vector2.new(Pos.X - DistanceY - 4, Pos.Y + DistanceY*2)
										v.HealthBarlib.greenhealth.To = Vector2.new(Pos.X - DistanceY - 4, Pos.Y + DistanceY*2 - healthoffset)

										v.HealthBarlib.healthbar.From = Vector2.new(Pos.X - DistanceY - 4, Pos.Y + DistanceY*2)
										v.HealthBarlib.healthbar.To = Vector2.new(Pos.X - DistanceY - 4, Pos.Y - DistanceY*2)

										local green = Color3.fromRGB(0, 255, 0)
										local red = Color3.fromRGB(255, 0, 0)

										v.HealthBarlib.greenhealth.Color = red:lerp(green, hum.Health/hum.MaxHealth);
									else
										for o,c in pairs(v.HealthBarlib) do
											c.Visible = false
										end
									end
								end
							else
								--// turning off
								for o,c in pairs(v.HealthBarlib) do
									c:Remove()
								end
								v.HealthBarlib = nil
							end
						end
					end
					if not game:GetService('Players').LocalPlayer.Character or (Players.LocalPlayer.Character and not Players.LocalPlayer.Character:FindFirstChild('HumanoidRootPart')) then
						espto()
					else
						if (v.Part.Position - game:GetService('Players').LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= newdistance then
							espto()
						else
							if typeof(v.Tag) == 'table' then
								for o,c in pairs(v.Tag) do
									c.Visible = false
								end
							else
								v.Tag.Visible = false
							end
							if v.HealthBarlib then
								for o,c in pairs(v.HealthBarlib) do
									c.Visible = false
								end
								v.HealthBarlib = nil
							end
							if v.Boxlib then
								for o,c in pairs(v.Boxlib) do
									c.Visible = false
								end
							end
						end
					end
				else
					if typeof(v.Tag) == 'table' then
						for o,c in pairs(v.Tag) do
							c.Visible = false
						end
					else
						v.Tag.Visible = false
					end
					if v.HealthBarlib then
						for o,c in pairs(v.HealthBarlib) do
							c.Visible = false
						end
						v.HealthBarlib = nil
					end
					if v.Boxlib then
						for o,c in pairs(v.Boxlib) do
							c.Visible = false
						end
					end
				end
			else
				pcall(function()
					if not v.Part then
						print('no vpart?/')
					end
					if v.Part:IsDescendantOf(game:GetService('Workspace')) then
						print('Not in workspace???')
						print(v.Part.Parent.Name)
					end
				end)
				if v.HealthBarlib then
					for o,c in pairs(v.HealthBarlib) do
						c:Remove()
						c = nil
					end
				end
				if v.Boxlib then
					for o,c in pairs(v.Boxlib) do
						c:Remove()
						c = nil
					end
				end
				v.Tag:Remove()
				table.remove(data.Track,table.find(data.Track,v))
			end
		end
		game:GetService('RunService').Heartbeat:Wait()
	end
end)

local toreturn = {}
setmetatable(toreturn,{
	__call = function(t,Lib,Window)
		local data_UI = {}
		local Tab = Window:MakeTab({
			Name = "ESP",
		})
		--// Category: Player
		Tab:AddSection({
			Name = 'Player Esp',
		})
		data_UI.PESP_toggle = Tab:AddToggle({
			Name = 'Player Esp',
			Default = Variables.ESP_Player,
			Flag = 'Player_ESP',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_Player = Value
					if Value == false then
						for i,v in pairs(data.Track) do
							if v.Tag then
								v.Tag.Visible = false
							end
						end
					end
				end
			end,
		})
		data_UI.PESP_health = Tab:AddToggle({
			Name = 'Show Health',
			Default = Variables.ESP_ShowHealth,
			Flag = 'Player_ESP_Health',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_ShowHealth = Value
				end
			end,
		})
		data_UI.PESP_distance = Tab:AddToggle({
			Name = 'Show Distance',
			Default = Variables.ESP_ShowHealth,
			Flag = 'Player_ESP_Distance',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_ShowDistance = Value
				end
			end,
		})
		data_UI.PESP_healthbar = Tab:AddToggle({
			Name = 'Show Health Bar',
			Default = Variables.ESP_ShowHealthBar,
			Flag = 'Player_ESP_Health',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_ShowHealthBar = Value
					if Value == false then
						for i,v in pairs(data.Track) do
							if v.HealthBarlib then
								for o,c in pairs(v.HealthBarlib) do
									c:Remove()
								end
								v.HealthBarlib = nil
							end
						end
					end
				end
			end,
		})
		data_UI.PESP_box = Tab:AddToggle({
			Name = 'Show Box',
			Default = Variables.ESP_ShowBox,
			Flag = 'Player_ESP_Box',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_ShowBox = Value
					if Value == false then
						for i,v in pairs(data.Track) do
							if v.Boxlib then
								for o,c in pairs(v.Boxlib) do
									c:Remove()
								end
								v.Boxlib = nil
							end
						end
					end
				end
			end,
		})
		data_UI.PESP_color = Tab:AddTextbox({
			Name = 'Color, From RBG, You can search on google!',
			Default = tostring(Variables.ESP_PlayerColor.R)..","..tostring(Variables.ESP_PlayerColor.G)..","..tostring(Variables.ESP_PlayerColor.B),
			TextDisappear = true,
			Callback = function(str)
				--// Fetching
				local get = tostring(str)
				if get then
					local split = string.split(str,',')
					local r = tonumber(str[1])
					local g = tonumber(str[2])
					local b = tonumber(str[3])
					if r and g and b then
						Variables.ESP_PlayerColor.R = r
						Variables.ESP_PlayerColor.G = g
						Variables.ESP_PlayerColor.B = b

						--// Do Change Color
						for i,v in pairs(data.Track) do
							if i:IsDescendantOf(workspace) and v.Tag and v.Flag == 'Player ESP' then
								v.Tag.Color = Color3.fromRGB(r,g,b)
								if v.Boxlib then
									v.Boxlib.box.Color = Color3.fromRGB(r,g,b)
								end
							end
						end
					end
				end
			end,
		})
		--// Loaded Module for Player Esp

		--// Category: Team Esp
		Tab:AddSection({
			Name = 'Team ESP',
		})
		data_UI.TESP_toggle = Tab:AddToggle({
			Name = 'Specify team members',
			Default = Variables.ESP_Teamate,
			Flag = 'Team_ESP',
			Callback = function(Value,set)
				if not set then
					Variables.ESP_Teamate = true
				end
			end,
		})
		data_UI.TESP_color = Tab:AddTextbox({
			Name = 'Color, From RBG, You can search on google!',
			Default = tostring(Variables.ESP_TeamColor.R)..","..tostring(Variables.ESP_TeamColor.G)..","..tostring(Variables.ESP_TeamColor.B),
			TextDisappear = true,
			Callback = function(str)
				--// Fetching
				local get = tostring(str)
				if get then
					local split = string.split(str,',')
					local r = tonumber(str[1])
					local g = tonumber(str[2])
					local b = tonumber(str[3])
					if r and g and b then
						Variables.ESP_PlayerColor.R = r
						Variables.ESP_PlayerColor.G = g
						Variables.ESP_PlayerColor.B = b

						--// Do Change Color
						for i,v in pairs(data.Track) do
							if i:IsDescendantOf(workspace) and v.Tag and v.Flag == 'Player ESP' and v.IsTeam then
								v.Tag.Color = Color3.fromRGB(r,g,b)
								if v.Box then
									v.Boxlib.box.Color = Color3.fromRGB(r,g,b)
								end
							end
						end
					end
				end
			end,
		})
		--// Loaded Module For Team

		--// Loaded module for more...

		--// Settings board
		local Tab_2 = Window:MakeTab({
			Name = "ESP Settings",
		})
		--// Category: Global
		Tab_2:AddSection({
			Name = 'Global Settings'
		})
		Tab_2:AddSlider({
			Name = 'Size',
			Min = 10,
			Max = 25,
			Default = Variables.ESP_Size,
			Increment = 1,
			ValueName = 'px',
			Flag = 'Size',
			Callback = function(Value)
				Variables.ESP_Size = Value
			end,
		})
		Tab_2:AddSlider({
			Name = 'Max Distance',
			Min = 0,
			Max = 10000,
			Default = Variables.ESP_MaxDistance,
			Increment = 1,
			ValueName = 'ft',
			Flag = 'Max_Distance',
			Callback = function(Value)
				Variables.ESP_MaxDistance = Value
			end,
		})
		Tab_2:AddSlider({
			Name = 'YOffset',
			Min = -20,
			Max = 20,
			Default = Variables.ESP_YOffset,
			Increment = 0.1,
			ValueName = 'ft',
			Flag = 'YOffset',
			Callback = function(Value)
				Variables.ESP_YOffset = Value
			end,
		})
		Tab_2:AddSlider({
			Name = 'ZOffset',
			Min = -10,
			Max = 10,
			Default = Variables.ESP_ZOffset,
			Increment = 0.1,
			ValueName = 'ft',
			Flag = 'ZOffset',
			Callback = function(Value)
				Variables.ESP_ZOffset = Value
			end,
		})
		Tab_2:AddButton({
			Name = 'Refresh Teammate list',
			Callback = function()
				Current.Teamate = {}
				for i,v in pairs(game:GetService('Players'):GetChildren()) do
					if v ~= game:GetService('Players').LocalPlayer then
						if v:IsFriendsWith(userid) then
							if not Current.Teamate[v.Name] then
								table.insert(Current.Teamate,v.Name)
							end
						end
					end
				end
			end,
		})
		--// Loaded module
		--// Category: Player
		Tab_2:AddSection({
			Name = 'Player Esp',
		})
		Tab_2:AddBind({
			Name = 'Keybind Toggle',
			Default = keybindlib.S2E(Variables.ESP_PlayerBind),
			Callback = function(newkey,issetingkey)
				if issetingkey then
					Variables.ESP_PlayerBind = keybindlib.E2S(newkey)
				else
					Lib:FireFlag('Player_ESP')
				end
			end,
		})
		Tab_2:AddBind({
			Name = 'Keybind Box',
			Default = keybindlib.S2E(Variables.ESP_BoxBind),
			Callback = function(newkey,issetingkey)
				if issetingkey then
					Variables.ESP_BoxBind = keybindlib.E2S(newkey)
				else
					Lib:FireFlag('Player_ESP_Box')
				end
			end,
		})
		--// Loaded Module...

		--// Category: Team
		Tab_2:AddSection({
			Name = 'Team ESP'
		})
		Tab_2:AddBind({
			Name = 'Keybind Toggle',
			Default = keybindlib.S2E(Variables.ESP_TeamBind),
			Callback = function(newkey,issetingkey)
				if issetingkey then
					Variables.ESP_TeamBind = keybindlib.E2S(newkey)
				else
					Lib:FireFlag('Team_ESP')
				end
			end,
		})
		--// Loaded Module...

		--// Category:?
	end,
})
return toreturn
