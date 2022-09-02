--// Delcaring
getgenv = getgenv
Drawing = Drawing
mousemoverel = mousemoverel
--// Funcs
local EB2SLib = getgenv().EB2S()
local Players = game:GetService('Players')
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService('UserInputService')
--//
local IsAiming = false
local DataStructure = {
	Advanced_Aimbot = false,
	AimbotCamera = false,
	AimPart = 'Head',
	Sensitivity = 0, -- How many seconds it takes for the aimbot script to officially lock onto the target's aimpart.
	TeamCheck = false,
	
	CircleColor = Color3.fromRGB(255,0,0),
	CircleRadius = 70, -- or FOV
	CircleFilled = false,
	CircleVisible = false,
	CircleThickness = 0,
	
	--// Bind
	AimbotBind = '',
	TeamBind = '',
	CircleVisibleBind = '',
	CircleFilledBind = '',
}
local Variables = {}
local file = 'Tushub/Config.json'
getgenv().tushub_saving(file,DataStructure,Variables)

--// Init Aimbot!
local Camera = game:GetService('Workspace').CurrentCamera
local FOVCircle = Drawing.new("Circle")
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
FOVCircle.Radius = Variables.CircleRadius
FOVCircle.Filled = Variables.CircleFilled
FOVCircle.Color = Variables.CircleColor
FOVCircle.Visible = Variables.CircleVisible
FOVCircle.Transparency = 0.7 --// For now..
FOVCircle.NumSides = 0
FOVCircle.Thickness = Variables.CircleThickness
--// Init Advanced Aimbot
local mouse = game:GetService('Players').LocalPlayer:GetMouse()
local mt = getrawmetatable(game)
local index = mt.__index
setreadonly(mt, false)
mt.__index = newcclosure(function(t,i)
	if t == mouse and Variables.Advanced_Aimbot == true and tostring(i):lower() == 'hit' then
		local clostestplr = GetClosestPlayer()
		if clostestplr then
			return clostestplr.Character[Variables.AimPart].CFrame
		end
		return index(t,i)
	end
	return index(t,i)
end)
setreadonly(mt, true)


local userid = game:GetService('Players').LocalPlayer.UserId
function GetClosestPlayer()
	local MaximumDistance = Variables.CircleRadius
	local Target = nil
	local Center = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
	
	local function inside(x,y)
		local x = math.abs(Center.X - x)
		x = x*x --// ^2
		local y = math.abs(Center.Y - y)
		y = y*y
		local d = (x+y)/(x+y) --// Radical
		local r = Variables.CircleRadius
		if d <= r then
			return true
		end
		return false
	end
	
	for _, v in next, Players:GetPlayers() do
		if v.Name ~= LocalPlayer.Name then
			if Variables.TeamCheck == true then
				if v.Team ~= LocalPlayer.Team and not v:IsFriendsWith(userid) then
					if v.Character ~= nil then
						if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
							if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
								local ScreenPoint,visible = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
								if visible then
									--// Check inside circle
									if inside(ScreenPoint.X, ScreenPoint.Y) then
										if ScreenPoint.Z < MaximumDistance then
											Target = v
										end
									end
								end
							end
						end
					end
				end
			else
				if v.Character ~= nil then
					if v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
						if v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health ~= 0 then
							local ScreenPoint,visible = Camera:WorldToScreenPoint(v.Character:WaitForChild("HumanoidRootPart", math.huge).Position)
							if visible then
								--// Check inside circle
								if inside(ScreenPoint.X, ScreenPoint.Y) then
									if ScreenPoint.Z < MaximumDistance then
										Target = v
									end
								end
							end
						end
					end
				end
			end
		end
	end
	return Target
end

UserInputService.InputBegan:Connect(function(input, processed)
	if not processed then
		print(Variables.AimbotBind)
		if Variables.AimbotBind and Variables.AimbotBind[input.KeyCode] or Variables.AimbotBind[input.UserInputType] then
			IsAiming = true
			print('Isaming')
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if Variables.AimbotBind and Variables.AimbotBind[input.KeyCode] or Variables.AimbotBind[input.UserInputType] then
		IsAiming = false
		print('OFFu')
	end
end)

game:GetService('RunService').RenderStepped:Connect(function()
	local Center = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
	FOVCircle.Position = Center
	FOVCircle.Radius = Variables.CircleRadius
	FOVCircle.Filled = Variables.CircleFilled
	FOVCircle.Color = Variables.CircleColor
	FOVCircle.Visible = Variables.CircleVisible
	FOVCircle.Transparency = 0.7 --// For now..
	FOVCircle.NumSides = 0
	FOVCircle.Thickness = Variables.CircleThickness

	if IsAiming == true then
		print('Isaming')
		local part = GetClosestPlayer().Character[Variables.AimPart]
		if part then
			print(part.Name)
			if Variables.AimbotCamera == true then
				game:GetService('TweenService'):Create(Camera, TweenInfo.new(Variables.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = CFrame.new(Camera.CFrame.Position, part.Position)}):Play()
			end
			wait(Variables.Sensitivity)
			local pos, screen = workspace.CurrentCamera:WorldToViewportPoint(part.Position)
			if screen then
				mousemoverel(pos.X,pos.Y)
			end
		end
	end
end)

return function(lib,window)
	local tab = window:MakeTab({
		Name = 'Aimbot'
	})
	tab:AddBind({
		Name = 'Aimbot keybind',
		Default = Variables.AimbotBind,
		Callback = function(key,setting)
			if key and setting then
				wait()
				Variables.AimbotBind = EB2SLib.E2S(key)
			end
		end,
	})
	
	--// Settings
	tab:AddSlider({
		Name = 'Delay time',
		Min = 0,
		Max = 2,
		Default = Variables.Sensitivity,
		Increment = 0.1,
		ValueName = 's',
		Callback = function(Val)
			Variables.Sensitivity = Val
		end,
	})
	tab:AddSlider({
		Name = 'Radius (FOV)',
		Min = 5,
		Max = 280,
		Default = Variables.CircleRadius,
		Increment = 1,
		ValueName = 'px',
		Callback = function(val)
			Variables.CircleRadius = val
		end,
	})
	tab:AddSlider({
		Name = 'Circle thickness',
		Min = 0,
		Max = 10,
		Default = Variables.CircleThickness,
		ValueName = 'px',
		Callback = function(val)
			Variables.CircleThickness = val
		end,
	})
	--//
	tab:AddToggle({
		Name = 'Circle filled',
		Default = Variables.CircleFilled,
		Flag = 'Aimbot_Circle_Filled',
		Callback = function(val)
			Variables.CircleFilled = val
		end,
	})
	tab:AddBind({
		Name = 'Circle filled keybind',
		Default = Variables.CircleFilledBind,
		Callback = function(key,setting)
			if not setting then
				lib:FireFlag('Aimbot_Circle_Filled')
			else
				Variables.CircleFilledBind = EB2SLib.E2S(key)
			end
		end,
	})
	--//
	tab:AddToggle({
		Name = 'Circle visible',
		Default = Variables.CircleVisible,
		Flag = 'Aimbot_Circle_visible',
		Callback = function(val)
			Variables.CircleVisible = val
		end,
	})
	tab:AddBind({
		Name = 'Circle visible keybind',
		Default = Variables.CircleFilledBind,
		Callback = function(key,setting)
			if not setting then
				lib:FireFlag('Aimbot_Circle_visible')
			else
				Variables.CircleFilledBind = EB2SLib.E2S(key)
			end
		end,
	})
	--// Team
	tab:AddToggle({
		Name = 'Ignore Teammate',
		Default = Variables.TeamCheck,
		Flag = 'Aimbot_Ignore_Teammate',
		Callback = function(val)
			Variables.TeamCheck = val
		end,
	})
	tab:AddBind({
		Name = 'Ignore teammate keybind',
		Default = Variables.TeamBind,
		Callback = function(key,setting)
			if not setting then
				lib:FireFlag('Aimbot_Ignore_Teammate')
			else
				Variables.TeamBind = EB2SLib.E2S(key)
			end
		end,
	})
	--// So... Part Choose:
	local R6 = '["HumanoidRootPart","Torso","Left Leg","Right Leg","Left Arm","Right Arm","Head"]'
	local R15 = '["HumanoidRootPart","LeftHand","LeftLowerArm","LeftUpperArm","RightHand","RightLowerArm","RightUpperArm","UpperTorso","LeftFoot","LeftLowerLeg","LeftUpperLeg","RightFoot","RightLowerLeg","RightUpperLeg","LowerTorso","Head"]'
	repeat wait() until game:GetService('Players').LocalPlayer.Character and game:GetService('Players').LocalPlayer.Character:FindFirstChildOfClass('Humanoid')
	wait()
	local Parts
	if game:GetService('Players').LocalPlayer.Character:FindFirstChildOfClass('Humanoid').RigType == Enum.HumanoidRigType.R6 then
		Parts = R6
	else
		Parts = R15
	end
	Parts = game:GetService('HttpService'):JSONDecode(Parts)
	if not table.find(Parts,Variables.AimPart) then
		Variables.AimPart = 'HumanoidRootPart'
	end
	tab:AddDropdown({
		Name = 'Aim Part',
		Default = Variables.AimPart,
		Options = Parts,
		Callback = function(val)
			Variables.AimPart = val
		end,
	})
	--// Aimbot Camera
	tab:AddToggle({
		Name = 'Camera Aiming (Rec in fps games)',
		Default = Variables.AimbotCamera,
		Callback = function(val)
			Variables.AimbotCamera = val
		end,
	})
	--// Advanced Aimbot (hook shit)
	tab:AddToggle({
		Name = 'Advanced Aimbot',
		Default = Variables.Advanced_Aimbot,
		Callback = function(val)
			Variables.Advanced_Aimbot = val
		end,
	})
end
