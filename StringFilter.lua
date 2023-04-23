_G.nofall = false
_G.nostun = false
_G.antibackfire = false
_G.spidercloakboost = false
_G.autotrinket = false
_G.autoingredient = false
local Nocliping = false

local function notification(text)
	game.StarterGui:SetCore("SendNotification", {
		Title = "Peepoo Peepoo",
		Text = text,
		Duration = 5,
	})
end

do -- // Animation Play Ban Bypass
	if(not banAnimation or typeof(banAnimation) ~= 'Instance' or not banAnimation:IsA('AnimationTrack')) then
		local humanoid;
		for i, v in next, workspace.NPCs:GetChildren() do
			if(v:FindFirstChildWhichIsA('Humanoid', true)) then
				humanoid = v.Humanoid;
			end;
		end;

		local animation = Instance.new('Animation');
		animation.AnimationId = 'rbxassetid://4595066903';

		banAnimation = humanoid:LoadAnimation(animation);
	end;

	local old;
	old = hookfunction(banAnimation.Play, newcclosure(function(self)
		if(typeof(self) ~= 'Instance' or not self:IsA('AnimationTrack')) then return old(self); end;

		if(string.find(self.Animation.AnimationId, '4595066903')) then
			return;
		end;

		return old(self);
	end));
end;

local UIS = game:GetService("UserInputService")
local OnRender = game:GetService("RunService").RenderStepped

local Player = game:GetService("Players").LocalPlayer
local plr = Player

local Camera = workspace.CurrentCamera

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
			--[[
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
			]]
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
			local Character = Player.Character
			_G.spidercloakboost = not _G.spidercloakboost
			notification('Spidercloak mode: '..tostring(_G.spidercloakboost))
			if not Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost') then
				local cb = Instance.new('NumberValue')
				cb.Name = 'ClimbBoost'
				cb.Value = 0.15
				cb.Parent = Character:FindFirstChild('Boosts')
			end
			if _G.spidercloakboost == true then
				oldClimboost = Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value or 0.15
				Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value = 0.65
				
				if oldSpboost then return end
				oldSpboost = Instance.new('NumberValue',Character:FindFirstChild('Boosts'))
				oldSpboost.Name = 'SpeedBoost'
				oldSpboost.Value = 4
			else
				Character:FindFirstChild('Boosts'):FindFirstChild('ClimbBoost').Value = oldClimboost
				if oldSpboost then
					oldSpboost:Destroy()
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
		elseif Input.KeyCode == Enum.KeyCode.J then
			_G.nostun = not _G.nostun
			notification('No stun: '..tostring(_G.nostun))
		elseif Input.KeyCode == Enum.KeyCode.K then
			_G.antibackfire = not _G.antibackfire
			notification('Anti backfire: '..tostring(_G.antibackfire))
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
local target,frameto,oldframeto,oldtextcolor = nil,nil,nil,nil
local guiname = "LeaderboardGui"
local function removespaces(str)
	return str:gsub(" ","")
end
local function spectate()
	wait()
	if frameto.TextTransparency == 0 then return end
	if frameto == oldframeto then 
		target = Player.Name
	end
	if oldframeto and oldtextcolor then oldframeto.TextColor3 = oldtextcolor end
	game:GetService("Workspace").Camera.CameraType = "Custom"
	if not Players:FindFirstChild(target) then
		workspace.CurrentCamera.CFrame = Player.Character.HumanoidRootPart.CFrame*CFrame.new(Vector3.new(0,4,10))
		workspace.CurrentCamera.CameraSubject = Player.Character.Humanoid
		return
	end
	workspace.CurrentCamera.CFrame = Players:FindFirstChild(target).Character.HumanoidRootPart.CFrame*CFrame.new(Vector3.new(0,4,10))
	workspace.CurrentCamera.CameraSubject = Players:FindFirstChild(target).Character.Humanoid
	
	if target ~= Player.Name then
		oldframeto = frameto
		oldtextcolor = frameto.TextColor3
		frameto.TextColor3= Color3.fromRGB(255,0,0)
	else
		oldframeto = nil
		oldtextcolor = nil
	end
end
local mouse = plr:GetMouse()
local way = plr.PlayerGui:FindFirstChild(guiname).MainFrame.ScrollingFrame

FrameAdded = function(frame)
	frame.MouseEnter:connect(function()
		wait()
		target = frame.Name
		frameto = frame
	end)
	frame.MouseLeave:connect(function()
		target = nil
		frameto = nil
	end) 
end
for i,v in pairs(way:GetChildren()) do
	FrameAdded(v)
end
way.ChildAdded:Connect(function(v)
	FrameAdded(v)
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

local NostunTab = {'LightAttack','NoJump','NoCharge','ChargeBlock','NoDash','ClimbCooldown','Stun','Action','RecentDash'}
local onChar = function(char)
	char.ChildAdded:Connect(function(item)
		wait()
		if _G.nostun == true and table.find(NostunTab,item.Name) then
			item:Destroy()
		end
	end)
end
onChar(plr.Character)
plr.CharacterAdded:Connect(function()
	wait(1)
	onChar(plr.Character)
end)

_G.FallionForgive = 5
_G.spellsNeed = {
	["Armis"] = {
		{min = 40, max = 60};
		{min = 70, max = 80};
	};
	["Trickstus"] = {
		{min = 30, max = 70};
		{min = 30, max = 50};
	};
	["Scrupus"] = {
		{min = 30, max = 100};
		{min = 30, max = 100};
	};
	["Celeritas"] = {
		{min = 70, max = 90};
		{min = 70, max = 80};
	};
	["Velo"] = {
		{min = 70, max = 100};
		{min = 40, max = 60};
	};
	["Ignis"] = {
		{min = 80, max = 95};
		{min = 40, max = 60};
	};
	["Gelidus"] = {
		{min = 80, max = 95};
		{min = 80, max = 100};
	};
	["Viribus"] = {
		{min = 25, max = 35};
		{min = 60, max = 70};
	};
	["Sagitta Sol"] = {
		{min = 50, max = 65};
		{min = 40, max = 60};
	};
	["Tenebris"] = {
		{min = 90, max = 100};
		{min = 40, max = 60};
	};
	["Nocere"] = {
		{min = 70, max = 85};
		{min = 70, max = 85};
	};
	["Hystericus"] = {
		{min = 75, max = 90};
		{min = 15, max = 35};
	};
	["Shrieker"] = {
		{min = 30, max = 50};
		{min = 30, max = 50};
	};
	["Verdien"] = {
		{min = 75, max = 100};
		{min = 75, max = 85};
	};
	["Contrarium"] = {
		{min = 80, max = 95};
		{min = 70, max = 90};
	};
	["Floresco"] = {
		{min = 90, max = 100};
		{min = 80, max = 95};
	};
	["Perflora"] = {
		{min = 70, max = 90};
		{min = 30, max = 50};
	};
	["Manus Dei"] = {
		{min = 90, max = 95};
		{min = 50, max = 60};
	};
	["Fons Vitae"] = {
		{min = 75, max = 100};
		{min = 75, max = 100};
	};
	["Trahere"] = {
		{min = 75, max = 85};
		{min = 75, max = 85};
	};
	["Furantur"] = {
		{min = 60, max = 80};
		{min = 60, max = 80};
	};
	["Inferi"] = {
		{min = 10, max = 30};
		{min = 10, max = 30};
	};
	["Howler"] = {
		{min = 60, max = 80};
		{min = 60, max = 80};
	};
	["Secare"] = {
		{min = 90, max = 95};
		{min = 90, max = 95};
	};
	["Ligans"] = {
		{min = 63, max = 80};
		{min = 63, max = 80};
	};
	["Reditus"] = {
		{min = 50, max = 100};
		{min = 50, max = 100};
	};
	["Fimbulvetr"] = {
		{min = 86, max = 90};
		{min = 70, max = 80};
	};
	["Gate"] = {
		{min = 75, max = 85};
		{min = 75, max = 85};
	};
	["Snarvindur"] = {
		{min = 60, max = 75};
		{min = 20, max = 30};
	};
	["Hoppa"] = {
		{min = 40, max = 60};
		{min = 50, max = 60};
	};
	["Percutiens"] = {
		{min = 60, max = 70};
		{min = 70, max = 80};
	};
	["Dominus"] = {
		{min = 50, max = 100};
		{min = 50, max = 100};
	};
	["Custos"] = {
		{min = 45, max = 65};
		{min = 45, max = 65};
	};
	["Claritum"] = {
		{min = 90, max = 100};
		{min = 90, max = 100};
	};
	["Globus"] = {
		{min = 70, max = 100};
		{min = 70, max = 100};
	};
	["Intermissum"] = {
		{min = 70, max = 100};
		{min = 70, max = 100};
	};
}

local players = game:service'Players';
local player = players.LocalPlayer;

local uIP = game:GetService'UserInputService';

local throwns = workspace.Thrown

local remoteNames = {
	["LeftClick"] = 1; -- normal
	["RightClick"] = 2; -- snap
}

local function checkForThrown(spell)
	local playername = player.Name;
	if not throwns:FindFirstChild(spell) then return false end;
	for i,v in pairs(throwns:GetChildren()) do
		if v.Name == spell then
			if v.Weld.Part0.Parent.Name == playername then
				return true;
			end
		end
	end
	return false
end

local function checkForTool(toolName)
	return player.Backpack:FindFirstChild(toolName) or player.Character:FindFirstChild(toolName)
end

local function getMageClass()
	if checkForTool("Furantur") or checkForTool("Globus") then return 15 end
	if checkForTool("Inferi") or checkForTool("Observe") or checkForTool("Perflora") then return 50 end
	return 100;
end

local Forgive = {'Contrarium','Ignis','Geldius','Celeritas','Hystericus','Nocere'}

local mt = getrawmetatable(game)
local namecall
local newnamecall = newcclosure(function(self,...)
	local args = {...}
	local method = getnamecallmethod()
	local b = table.remove(args) -- last value 
	if method:lower() == 'fireserver' then
		if _G.nofall == true and not checkcaller() and tonumber(b) ~= nil and tostring(self) == "ApplyFallDamage" then
			return 1
		end
		local castType = remoteNames[tostring(self)]
		if _G.antibackfire == true and castType then
			local char = player.Character;
			if not char then return namecall(self, ...) end;
			local tool = char:FindFirstChildOfClass'Tool';
			if not tool then return namecall(self, ...) end;
			if not tool:FindFirstChild'Spell' then return namecall(self, ...) end;
			local backpack = player.Backpack;
			local isFallion = backpack:FindFirstChild'WiseCasting';
			local spellsNeed = _G.spellsNeed;
			local spell = tool.Name;
			local spellInfo = spellsNeed[spell][castType];
			local min = spellInfo.min;
			local max = spellInfo.max;
			local FallionForgive = _G.FallionForgive;
			local isNotSnap = castType==1;
			min = (isFallion and isNotSnap) and (min - FallionForgive) or min;
			max = (isFallion and isNotSnap) and (max + FallionForgive) or max;
			local mana = char.Mana.Value;
			if char.Artifacts:FindFirstChild'PhilosophersStone' then
				if mana > getMageClass() then
					return namecall(self, ...);
				end
			end
			if table.find(Forgive,tool.Name) and char:FindFirstChild('ActiveCast') then
				return namecall(self, ...);
			end
			if mana > min and mana < max then
				return namecall(self, ...);
			else
				if spell == "Tenebris" and castType == 2 then
					if checkForThrown("DarkBall") then
						return namecall(self, ...);
					end
				elseif spell == "Gate" then
					if not char:FindFirstChild'Combat' and char:FindFirstChild'AzaelHorn' then
						return namecall(self, ...);
					end
				elseif spell == "Velo" then
					if char:FindFirstChild'LightBall' then
						return namecall(self, ...);
					end
				end
			end
			return nil;
		end
	end
	return namecall(self,...)
end)
namecall = hookfunction(mt.__namecall, newnamecall)

notification("Loaded in!")
