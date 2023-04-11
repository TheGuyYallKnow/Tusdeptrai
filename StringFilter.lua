_G.nofall = false
_G.spidercloakboost = false
_G.Speed = 250
_G.ws = 250
_G.autotrinket = false
_G.autoingredient = false
local Nocliping = false
local WalkSpeed = false
local Speed = _G.Speed
local plr = game:GetService("Players").LocalPlayer
local char = plr.Character
local realws 
realws = char.Humanoid.WalkSpeed
local function onchar (c)
	print("1")
	local hrp = c:WaitForChild("HumanoidRootPart",9e9)
	char = c
	realws = char.Humanoid.WalkSpeed
	spawn(function()
		local chandler = plr.Character:WaitForChild("CharacterHandler",9e9)
		local remote = chandler:WaitForChild('Remotes',9e9)
		local fdr = remote:WaitForChild('ApplyFallDamage',9e9)
		for i,v in next, getconnections(remote.ChildRemoved) do
			v:Disable()
		end
		fdr:Destroy()
	end)
end
onchar(char)
plr.CharacterAdded:Connect(onchar)
local function notification(text)
	game.StarterGui:SetCore("SendNotification", {
		Title = "Peepoo Peepoo",
		Text = text,
		Duration = 5,
	})
end

local mt = getrawmetatable(game)
local namecall
local newnamecall = newcclosure(function(self,...)
	local args = {...}
	local method = getnamecallmethod()
	local b = table.remove(args) -- last value 
	if _G.nofall == true and  method:lower() == "fireserver" and not checkcaller() and tonumber(b) ~= nil and tostring(self) == "ApplyFallDamage" then
		return 1
	end
	return namecall(self,...)
end)
namecall = hookfunction(mt.__namecall, newnamecall)

local UIS = game:GetService("UserInputService")
local OnRender = game:GetService("RunService").RenderStepped

local Player = game:GetService("Players").LocalPlayer
local Character = char

local Camera = workspace.CurrentCamera
local Root = Character:WaitForChild("HumanoidRootPart")

local C1, C2, C3;
local Nav = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
local lNav = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
local ChangeTab = {}
local NoclipTab = {}
local NoclippingLoop = nil

local oldClimboost = 0.15
local oldSpboost
C1 = UIS.InputBegan:Connect(function(Input,typin)
	if typin then return end
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		if Input.KeyCode == Enum.KeyCode.C then
			Nav.Flying = not Nav.Flying
			if Nav.Flying then
				local T = char.HumanoidRootPart
				local BG = Instance.new('BodyGyro')
				local BV
				BV = Instance.new('BodyVelocity')
				BV.Name = "jka0ixlw"
				BG.Name = "ASJDOZX"
				BG.P = 9e4
				BG.Parent = T
				BV.Parent = T
				BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
				BG.cframe = T.CFrame
				BV.velocity = Vector3.new(0, 0, 0)
				BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
				task.spawn(function()
					repeat wait()
						if not BV or BV.Parent ~= char.HumanoidRootPart then
							if not char.HumanoidRootPart then break end
							BV = Instance.new('BodyVelocity')
							BV.Name = "jka0ixlw"
							BV.Parent = T
							BV.velocity = Vector3.new(0, 0, 0)
							BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
						end
						if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
							game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
						end
						if Nav.L + Nav.R ~= 0 or Nav.F + Nav.B ~= 0 or Nav.Q + Nav.E ~= 0 then
							Speed = 250
						elseif not (Nav.L + Nav.R ~= 0 or Nav.F + Nav.B ~= 0 or Nav.Q + Nav.E ~= 0) and Speed ~= 0 then
							Speed = 0
						end
						if (Nav.L + Nav.R) ~= 0 or (Nav.F + Nav.B) ~= 0 or (Nav.Q + Nav.E) ~= 0 then
							BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (Nav.F + Nav.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(Nav.L + Nav.R, (Nav.F + Nav.B + Nav.Q + Nav.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * Speed
							lNav = {F = Nav.F, B = Nav.B, L = Nav.L, R = Nav.R}
						elseif (Nav.L + Nav.R) == 0 and (Nav.F + Nav.B) == 0 and (Nav.Q + Nav.E) == 0 and Speed ~= 0 then
							BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lNav.F + lNav.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lNav.L + lNav.R, (lNav.F + lNav.B + Nav.Q + Nav.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * Speed
						else
							BV.velocity = Vector3.new(0, 0, 0)
						end
						BG.cframe = workspace.CurrentCamera.CoordinateFrame
					until not Nav.Flying
					--Nav = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
					--lNav = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
					Speed = 0
					BG:Destroy()
					BV:Destroy()
					if game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
						game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
					end
					pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
				end)
			end
		elseif Input.KeyCode == Enum.KeyCode.X then
			--[[
			Nocliping = not Nocliping
			if not Nocliping then
				if NoclippingLoop then
					NoclippingLoop:Disconnect()
					NoclippingLoop = nil
				end
			else
				local function noclipping()
					for i,v in pairs(char:GetDescendants()) do
						if v:IsA("BasePart") then
							if v.CanCollide == true then
								v.CanCollide = false
							end
						end
					end
				end
				NoclippingLoop = game:GetService("RunService").Stepped:Connect(noclipping)
			end
			]]
		elseif Input.KeyCode == Enum.KeyCode.Z then
			_G.spidercloakboost = not _G.spidercloakboost
			notification('Spidercloak mode: '..tostring(_G.spidercloakboost))
			if _G.spidercloakboost == true then
				oldClimboost = Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value or 0.15
				Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value = 0.65

				local spboost = Character:FindFirstChild('Boosts'):FindFirstChild('SpeedBoost')
				if not spboost then
					spboost = Instance.new('NumberValue',Character:FindFirstChild('Boosts'))
					spboost.Name = 'SpeedBoost'
					spboost.Value = 4
				else
					oldSpboost = spboost.Value
				end
			else
				Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value = oldClimboost
				if not oldSpboost then
					local spboost = Character:FindFirstChild('Boosts'):FindFirstChild('SpeedBoost')
					spboost:Destroy()
				end
			end
		elseif Input.KeyCode == Enum.KeyCode.N then
			_G.autotrinket = not _G.autotrinket
			notification('Auto Trinket: '..tostring(_G.autotrinket))
		elseif Input.KeyCode == Enum.KeyCode.M then
			_G.autoingredient = not _G.autoingredient
			notification('Auto Ingredients: '..tostring(_G.autoingredient))
		elseif Input.KeyCode == Enum.KeyCode.H then
			_G.nofall = not _G.nofall
			notification('No fall: '..tostring(_G.nofall))
		end
	end
end)
UIS.InputBegan:Connect(function(Input)
	if Input.KeyCode == Enum.KeyCode.W then
		Nav.F = 1
	elseif Input.KeyCode == Enum.KeyCode.S then
		Nav.B = -1
	elseif Input.KeyCode == Enum.KeyCode.A then
		Nav.L = -1
	elseif Input.KeyCode == Enum.KeyCode.D then
		Nav.R = 1
	end
end)
C2 = UIS.InputEnded:Connect(function(Input)
	if Input.UserInputType == Enum.UserInputType.Keyboard then
		if Input.KeyCode == Enum.KeyCode.W then
			Nav.F = 0
		elseif Input.KeyCode == Enum.KeyCode.S then
			Nav.B = 0
		elseif Input.KeyCode == Enum.KeyCode.A then
			Nav.L = 0
		elseif Input.KeyCode == Enum.KeyCode.D then
			Nav.R = 0
		end
	end
end)

local Players = game:GetService("Players")
local target = nil
local guiname = "LeaderboardGui"
local function removespaces(str)
	return str:gsub(" ","")
end
local function spectate()
	game:GetService("Workspace").Camera.CameraType = "Custom"
	if not Players:FindFirstChild(target) then return end
	workspace.CurrentCamera.CFrame = Players:FindFirstChild(target).Character.HumanoidRootPart.CFrame*CFrame.new(Vector3.new(0,4,10))
	workspace.CurrentCamera.CameraSubject = Players:FindFirstChild(target).Character.Humanoid
end
local mouse = plr:GetMouse()
local way = plr.PlayerGui:FindFirstChild(guiname).MainFrame.ScrollingFrame
for i,v in pairs(way:GetChildren()) do
	v.MouseEnter:connect(function()
		wait()
		target = v.Text
		if string.match(target,"#") then
			target = target:sub(4)
			local str = removespaces(target)
			target = str
		end
	end)
	v.MouseLeave:connect(function()
		target = nil
	end) 
end
way.ChildAdded:Connect(function(v)
	v.MouseEnter:connect(function()
		wait()
		target = v.Text
	end)
	v.MouseLeave:connect(function()
		target = nil
	end) 
end)
UIS.InputBegan:Connect(function(input,typin)
	if typin then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 and target ~= nil then
		wait()
		spectate()
	end
end)

local plrnamepath = Players.LocalPlayer.PlayerGui.StatGui.Container.CharacterName
local function output(player, msg)
	if player.Name == plr.Name then return end
	local illu = false
	if player.Character:FindFirstChild("Observe") then
		illu = true
	end
	if illu == true then
		local isbeingspectated = false
		if string.sub(msg:lower(),1,1) == string.sub(plrnamepath.Text:lower(),1,1) then
			isbeingspectated = true
		elseif string.sub(plrnamepath.Text:lower(),1,#msg:lower()) == plrnamepath.Text:lower() then
			isbeingspectated = true
		elseif msg:lower():sub(1,#plrnamepath.Text) == plrnamepath.Text:lower() then
			isbeingspectated = true
		elseif string.sub(msg:lower(),1,#plrnamepath.Text:lower()) == plrnamepath.Text:lower() then
			isbeingspectated = true
		end
		if isbeingspectated == true then
			notification("WARNING SOME ONE IS SPECTATING YOU")
		end
	end
end
local Alert = {"Contributor","Moderator","Junior Moderator","Senior Moderator","Head Moderator","Developer","Owner"}
spawn(function()
	for i,v in pairs(game:GetService("Players"):GetChildren()) do
		if v.Name == Player.Name then return end
		local a = v:GetRoleInGroup(13071308)
		if table.find(Alert,a) then
			notification(v.Name.." Is a "..a)
		end
		v.Chatted:Connect(function(msg)
			output(v, msg)
		end)
	end
end)
game:GetService("Players").ChildAdded:Connect(function(v)
	local a = v:GetRoleInGroup(17262561)
	if table.find(Alert,a) then
		notification(v.Name.." Joined as "..a)
	end
	v.Chatted:Connect(function(msg)
		output(v, msg)
	end)
end)
local RunService = game:GetService("RunService")
local TrinketPath = game:GetService("Workspace").Trinkets
local IngredientsPath = game:GetService("Workspace").Ingredients

local Trinkets = {}
local CheckTrinket = function(holder)
	for _,part in pairs(holder:GetChildren()) do
		if part:FindFirstChildOfClass('Weld') then
			if part:FindFirstChildOfClass("ClickDetector") then
				Trinkets[holder] = part
				break
			end
		end
	end
end
for i,v in pairs(TrinketPath:GetChildren()) do
	CheckTrinket(v)
end
TrinketPath.ChildAdded:Connect(function(c)
	wait()
	CheckTrinket(c)
end)
TrinketPath.ChildRemoved:Connect(function(c)
	if Trinkets[c] then
		Trinkets[c] = nil
	end
end)

spawn(function()
	-- Auto pickup
	local RunService = game:GetService("RunService")
	RunService.RenderStepped:Connect(function()
		if _G.autotrinket == true then
			for i,part in pairs(Trinkets) do
				if i and part and part.Parent and part:FindFirstChildOfClass('Weld') and part:FindFirstChildOfClass("ClickDetector") then
					local mag = (part.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
					if part:FindFirstChildOfClass("ClickDetector").MaxActivationDistance > mag + 5 then
						fireclickdetector(part:FindFirstChildOfClass("ClickDetector"))
						wait()
						break
					end
				else
					Trinkets[i] = nil
				end
			end
		end
		if _G.autoingredient == true then
			for i,v in pairs(IngredientsPath:GetChildren()) do
				if v.Transparency ~= 1 and not v:FindFirstChild('Blacklist') then
					local mag = (v.Position - Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
					if v:FindFirstChildOfClass("ClickDetector").MaxActivationDistance > mag + 5 then
						fireclickdetector(v:FindFirstChildOfClass("ClickDetector"))
						wait()
					end
				end
			end
		end
	end)
end)
notification("Loaded in!")
