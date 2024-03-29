--: Fix Notification
--// Declaring
getgenv,syn = getgenv,syn

local UIS = game:GetService('UserInputService')
local StringFilterFunc = getgenv().stringfilter
local EB2SLib = getgenv().EB2S()

local Debugmode = true

function Debugout(text)
	if Debugmode == true then
		print(text)
	end
end

if not StringFilterFunc then
	game:GetService('Players').LocalPlayer:Kick('I dont see String Filter')
end

local Variables = {
	Flags = {},
	Debounces = {},
	Buttons = {},
	Tab_Closedfuncs = {},
	
	Keybinds = {},
	Keybinds_ = {}, --// False state
	link = {},

	held = false,
	mousepressed = false,
	CurrentSlider = nil,
	CurrentSlider_callback = nil,
	
	Selection = nil,
}
local modules = {
	main = {},
	side = {},
}

local TweenService = game:GetService('TweenService')
local function createTween(frame,info,props)
	local tween = TweenService:Create(frame,info,props)
	return tween
end

local function updateCs(scrollingFrame,listLayout,plus)
	scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + plus)
end

local function create_LeftButton(buttonname)
	local TextButton = Instance.new("TextButton")
	local Title = Instance.new("TextLabel")
	local UICorner = Instance.new("UICorner")
	local UICorner_2 = Instance.new("UICorner")

	--Properties:

	TextButton.BackgroundTransparency = 1.000
	TextButton.BorderSizePixel = 0
	TextButton.Size = UDim2.new(1, 0, 0, 30)
	TextButton.AutoButtonColor = false
	TextButton.Text = ""

	Title.Name = "Title"
	Title.Parent = TextButton
	Title.BackgroundColor3 = Color3.fromRGB(72, 72, 72)
	Title.BackgroundTransparency = 1.000
	Title.Position = UDim2.new(0.0333333351, 0, 0.0333333351, 0)
	Title.Size = UDim2.new(0.933333337, 0, 0.933333337, 0)
	Title.Font = Enum.Font.GothamBlack
	Title.Text = tostring(buttonname)
	Title.TextColor3 = Color3.fromRGB(240, 240, 240)
	Title.TextSize = 14.000
	Title.TextXAlignment = Enum.TextXAlignment.Left

	UICorner.CornerRadius = UDim.new(1, 10)
	UICorner.Parent = Title

	UICorner_2.CornerRadius = UDim.new(1, 10)
	UICorner_2.Parent = TextButton

	return TextButton
end

modules.side.AddFrame = function()
	local Frame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	local Content = Instance.new("TextLabel")

	Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	Frame.BorderSizePixel = 0
	Frame.Size = UDim2.new(1, 0, 0, 33)

	UICorner.CornerRadius = UDim.new(0, 5)
	UICorner.Parent = Frame

	Content.Name = "Content"
	Content.Parent = Frame
	Content.BackgroundTransparency = 1.000
	Content.Position = UDim2.new(0, 12, 0, 0)
	Content.Size = UDim2.new(1, -12, 1, 0)
	Content.Font = Enum.Font.GothamBold
	Content.Text = ""
	Content.TextColor3 = Color3.fromRGB(240, 240, 240)
	Content.TextSize = 15.000
	Content.TextXAlignment = Enum.TextXAlignment.Left
	return Frame, Content
end
modules.side.AddToggle = function(args)
	local frameto = args.Frame
	local Name = args.Name
	local Callback = args.Callback
	local Flag = args.Flag
	local Default = args.Default
	local CanPress = args.CanPress or true
	if Name and Callback and frameto then
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Content = Instance.new("TextLabel")
		local TextButton = Instance.new("TextButton")
		local UIStroke = Instance.new('UIStroke')

		--Properties:

		Frame.Parent = frameto
		Frame.BackgroundColor3 = Color3.fromRGB(80, 211, 40)
		Frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(1, 0, 0, 38)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Frame

		Content.Name = "Content"
		Content.Parent = Frame
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 0)
		Content.Size = UDim2.new(1, -12, 1, 0)
		Content.Font = Enum.Font.GothamBold
		Content.Text = Name
		Content.TextColor3 = Color3.fromRGB(240, 240, 240)
		Content.TextSize = 15.000
		Content.TextXAlignment = Enum.TextXAlignment.Left

		TextButton.Parent = Frame
		TextButton.BackgroundTransparency = 1.000
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.AutoButtonColor = false
		TextButton.Text = ""
		
		UIStroke.Parent = Frame
		UIStroke.Thickness = 1
		UIStroke.LineJoinMode = Enum.LineJoinMode.Round
		UIStroke.Transparency = 0
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		UIStroke.Enabled = true

		if not Variables.Debounces[Frame] then
			Variables.Debounces[Frame] = Default
		end

		local function changeColor()
			if Variables.Debounces[Frame] == true then
				Frame.BackgroundColor3 = Color3.fromRGB(80, 211, 40)
				UIStroke.Color = Color3.fromRGB(255,255,255)
			else
				Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
				UIStroke.Color = Color3.fromRGB(60, 60, 60)
			end
		end

		changeColor()
		local Click = function()
			Variables.Debounces[Frame] = not Variables.Debounces[Frame]
			changeColor()
			Callback(Variables.Debounces[Frame])
		end
		
		if CanPress == true then
			TextButton.MouseButton1Down:Connect(Click)
		end

		if Flag then
			Variables.Flags[Flag] = function(args)
				if not args then args = {} end
				if not args.Set then
					args.Set = not Variables.Debounces[Frame]
				end
				Variables.Debounces[Frame] = args.Set
				changeColor(args.Set)
				Callback(args.Set)
			end
		end
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
			Variables.Flags[Flag] = nil
		end
		return methods
	end
end
modules.side.AddButton = function(args)
	local Frame = args.Frame
	local Name = args.Name
	local Callback = args.Callback
	if Name and Callback and Frame then
		local frame,content = modules.side.AddFrame()
		frame.Parent = Frame
		content.Text = Name

		local TextButton = Instance.new("TextButton")
		TextButton.Parent = frame
		TextButton.BackgroundTransparency = 1.000
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.AutoButtonColor = false
		TextButton.Text = ""

		TextButton.MouseButton1Down:Connect(function()
			local ti = TweenInfo.new(0.15,Enum.EasingStyle.Quart,Enum.EasingDirection.Out)
			local props_1 = {BackgroundColor3 = Color3.fromRGB(100,100,100)}
			local props_2 = {BackgroundColor3 = Color3.fromRGB(32,32,32)}
			local tween_1 = createTween(frame,ti,props_1)
			local tween_2 = createTween(frame,ti,props_2)
			tween_1:Play()
			tween_1.Completed:Wait()
			Callback()
			tween_2:Play()
		end)
		
		local methods = {}
		function methods:Destroy()
			TextButton:Destroy()
		end
		return methods
	end
end
modules.side.AddLabel = function(args)
	local Frame = args.Frame
	local Name = args.Name
	if Frame and Name then
		local frame,content = modules.side.AddFrame()
		frame.Parent = Frame
		content.Text = Name
		
		local methods = {}
		function methods:Destroy()
			frame:Destroy()
		end
		function methods:Set(get)
			content.Text = get
		end
		return methods
	end
end
modules.side.AddParagraph = function(args)
	local Frameto = args.Frame
	local Name = args.Name
	local Contento = args.Content
	if Frameto and Name and Contento then
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Title = Instance.new("TextLabel")
		local Content = Instance.new("TextLabel")

		Frame.Parent = Frameto
		Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame.BackgroundTransparency = 0.700
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(1, 0, 0, 48)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Frame

		Title.Name = "Title"
		Title.Parent = Frame
		Title.BackgroundTransparency = 1.000
		Title.Position = UDim2.new(0, 12, 0, 10)
		Title.Size = UDim2.new(1, -12, 0, 14)
		Title.Font = Enum.Font.GothamBold
		Title.Text = Name
		Title.TextColor3 = Color3.fromRGB(240, 240, 240)
		Title.TextSize = 15.000
		Title.TextXAlignment = Enum.TextXAlignment.Left

		Content.Name = "Content"
		Content.Parent = Frame
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 26)
		Content.Size = UDim2.new(1, -24, 0, 13)
		Content.Font = Enum.Font.GothamMedium
		Content.Text = Contento
		Content.TextColor3 = Color3.fromRGB(150, 150, 150)
		Content.TextSize = 13.000
		Content.TextWrapped = true
		Content.TextXAlignment = Enum.TextXAlignment.Left
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
		end
		function methods:Set(get)
			Content.Text = get.Content
			Title.Text = get.Name
		end
		return methods
	end
end
modules.side.AddSlider = function(args)
	local Frameto = args.Frame
	local Name = args.Name
	local Min = args.Min
	local Max = args.Max
	local Default = args.Default
	local Increment = args.Increment or 1
	local ValueName = args.ValueName or ''
	local Callback = args.Callback
	local Flag = args.Flag
	if Frameto and Name and Min and Max and Default and Increment and ValueName then
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Content = Instance.new("TextLabel")
		local Frame_2 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local Value = Instance.new("TextLabel")
		local Frame_3 = Instance.new("Frame")
		local UICorner_3 = Instance.new("UICorner")
		local Value_2 = Instance.new("TextLabel")

		Frame.Parent = Frameto
		Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(1, 0, 0, 65)

		UICorner.CornerRadius = UDim.new(0, 4)
		UICorner.Parent = Frame

		Content.Name = "Content"
		Content.Parent = Frame
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 10)
		Content.Size = UDim2.new(1, -12, 0, 14)
		Content.Font = Enum.Font.GothamBold
		Content.Text = Name
		Content.TextColor3 = Color3.fromRGB(240, 240, 240)
		Content.TextSize = 15.000
		Content.TextXAlignment = Enum.TextXAlignment.Left

		Frame_2.Parent = Frame
		Frame_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame_2.BackgroundTransparency = 0.900
		Frame_2.BorderSizePixel = 0
		Frame_2.Position = UDim2.new(0, 12, 0, 30)
		Frame_2.Size = UDim2.new(1, -24, 0, 26)

		UICorner_2.CornerRadius = UDim.new(0, 5)
		UICorner_2.Parent = Frame_2

		Value.Name = "Value"
		Value.Parent = Frame_2
		Value.BackgroundTransparency = 1.000
		Value.Position = UDim2.new(0, 12, 0, 6)
		Value.Size = UDim2.new(1, -12, 0, 14)
		Value.Font = Enum.Font.GothamBold
		Value.Text = tostring(Default)..' '..ValueName
		Value.TextColor3 = Color3.fromRGB(240, 240, 240)
		Value.TextSize = 13.000
		Value.TextTransparency = 0.800
		Value.TextXAlignment = Enum.TextXAlignment.Left

		Frame_3.Parent = Frame_2
		Frame_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		Frame_3.BackgroundTransparency = 0.300
		Frame_3.BorderSizePixel = 0
		Frame_3.ClipsDescendants = true
		
		local fakemax = Max-Min
		local fakenumber = Default-Min
		local newpercentage = math.clamp(fakenumber/fakemax,0,1)

		local fakenumber,fakemax
		if Min < 0 then
			fakemax = Max + math.abs(Min)
			if Default < 0 then
				newpercentage = math.clamp(math.abs((Min + math.abs(Default)))/fakemax,0,1)
			else
				newpercentage = math.clamp((Default + math.abs(Min))/fakemax,0,1)
			end
		end
		
		Frame_3.Size = UDim2.new(newpercentage, 0, 1, 0)

		UICorner_3.CornerRadius = UDim.new(0, 5)
		UICorner_3.Parent = Frame_3

		Value_2.Name = "Value"
		Value_2.Parent = Frame_3
		Value_2.BackgroundTransparency = 1.000
		Value_2.Position = UDim2.new(0, 12, 0, 6)
		Value_2.Size = UDim2.new(1, -12, 0, 14)
		Value_2.Font = Enum.Font.GothamBold
		Value_2.Text = ""
		Value_2.TextColor3 = Color3.fromRGB(240, 240, 240)
		Value_2.TextSize = 13.000
		Value_2.TextXAlignment = Enum.TextXAlignment.Left

		local Value_3 = Instance.new('StringValue',Frame_3)
		Value_3.Name = 'Nameto'
		Value_3.Value = ValueName

		local maxto = Instance.new('NumberValue',Frame_3)
		maxto.Name = 'Maxto'
		maxto.Value = Max

		local minto = Instance.new('NumberValue',Frame_3)
		minto.Name = 'Minto'
		minto.Value = Min
		
		local incremento = Instance.new('NumberValue',Frame_3)
		incremento.Name = 'Increment'
		incremento.Value = Increment

		local connection = Frame.MouseEnter:connect(function()
			local cancel = false
			local con_ = Frame.MouseLeave:Connect(function()
				cancel = true
			end)
			repeat
				if Variables.mousepressed then
					Variables.held = true
					Variables.CurrentSlider = Frame_3
					Variables.CurrentSlider_callback = Callback
				end
				task.wait()
			until cancel == true
			con_:Disconnect()
		end)
		
		if Flag then
			Variables.Flags[Flag] = function(args)
				local Set = args.Set
				if Set then
					local SliderBtn = Variables.CurrentSlider.Parent
					local Sliderr = Variables.CurrentSlider
					local MousePos = UIS:GetMouseLocation().X
					local BtnPos = SliderBtn.Position
					local SliderSize = Sliderr.AbsoluteSize.X
					local SliderPos = Sliderr.AbsolutePosition.X
					
					local newnumber = snap(Set,Increment,Max,Min)

					if string.split(tostring(Increment),'.')[2] then
						local roundupto = #(string.split(tostring(Increment),'.')[2])
						local get = string.split(tostring(newnumber),'.')
						if get[2] then
							local rounded = string.sub(get[2],1,roundupto)
							newnumber = tonumber(get[1]..'.'..rounded)
						end
					end

					local fakemax = Max-Min
					local fakenumber = newnumber-Min
					local newpercentage = math.clamp(fakenumber/fakemax,0,1)

					local fakenumber,fakemax
					if Min < 0 then
						fakemax = Max + math.abs(Min)
						if newnumber < 0 then
							newpercentage = math.clamp(math.abs((Min + math.abs(newnumber)))/fakemax,0,1)
						else
							newpercentage = math.clamp((newnumber + math.abs(Min))/fakemax,0,1)
						end
					end
					
					SliderBtn.Size = UDim2.new(newpercentage, 0, 1, 0)

					local Val = {
						Variables.CurrentSlider:FindFirstChild('Value'),
						Variables.CurrentSlider.Parent:FindFirstChild('Value'),
					}

					local Nameto = Variables.CurrentSlider:FindFirstChild('Nameto')
					local function changeval(text)
						for i,v in pairs(Val) do
							v.Text = tostring(text)..' '..Nameto.Value
						end
					end

					changeval(newnumber)
					Callback(newnumber)
				end
			end
		end
		
		local methods = {}
		function methods:Destroy()
			Variables.Flags[Flag] = nil
			connection:Disconnect()
			connection = nil
			Frame:Destroy()
		end
		function methods:Set(valueto)
			local argto = {
				Set = valueto
			}
			Variables.Flags[Flag](argto)
		end
		return methods
	end
end
modules.side.AddSection = function(args)
	local Name = args.Name
	local Parent = args.Frame
	if Name and Parent then
		local Frame = Instance.new("Frame")
		local TextLabel = Instance.new("TextLabel")
		--Properties:
		Frame.Parent = Parent
		Frame.BackgroundTransparency = 1.000
		Frame.Size = UDim2.new(1, 0, 0, 26)

		TextLabel.Parent = Frame
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.Position = UDim2.new(0, 0, 0, 3)
		TextLabel.Size = UDim2.new(1, -12, 0, 16)
		TextLabel.Font = Enum.Font.GothamMedium
		TextLabel.Text = Name
		TextLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		TextLabel.TextSize = 14.000
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
		end
		return methods
	end
end
modules.side.AddBind = function(args)
	local frameto = args.Frame
	local Name = args.Name
	local Default = args.Default
	local Callback = args.Callback
	local Flag = args.Flag
	local DoubleSided = args.DoubleSided or false
	
	if Name and Callback then
		local function EnumtoString(enum)
			return EB2SLib.E2S(enum)
		end
		
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Content = Instance.new("TextLabel")
		local Frame_2 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local Value = Instance.new("TextLabel")
		local TextButton = Instance.new("TextButton")

		--Properties:

		Frame.Parent = frameto
		Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(1, 0, 0, 38)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Frame

		Content.Name = "Content"
		Content.Parent = Frame
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 0)
		Content.Size = UDim2.new(1, -12, 1, 0)
		Content.Font = Enum.Font.GothamBold
		Content.Text = Name
		Content.TextColor3 = Color3.fromRGB(240, 240, 240)
		Content.TextSize = 15.000
		Content.TextXAlignment = Enum.TextXAlignment.Left

		Frame_2.Parent = Frame
		Frame_2.AnchorPoint = Vector2.new(1, 0.5)
		Frame_2.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		Frame_2.BorderSizePixel = 0
		Frame_2.Position = UDim2.new(1, -12, 0.5, 0)
		Frame_2.Size = UDim2.new(0, 25, 0, 24)

		UICorner_2.CornerRadius = UDim.new(0, 4)
		UICorner_2.Parent = Frame_2

		Value.Name = "Value"
		Value.Parent = Frame_2
		Value.BackgroundTransparency = 1.000
		Value.Size = UDim2.new(1, 0, 1, 0)
		Value.Font = Enum.Font.GothamBold
		local Default_ = EnumtoString(Default) or ''
		Value.Text = Default_
		Value.TextColor3 = Color3.fromRGB(240, 240, 240)
		Value.TextSize = 14.000

		TextButton.Parent = Frame
		TextButton.BackgroundTransparency = 1.000
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.AutoButtonColor = false
		TextButton.Text = ""
		
		local Callback_ = function(Key,Setting,Pressed)
			Callback(Key,Setting,Pressed)
		end
		
		--//Flag
		if Flag then
			Variables.Flags[Flag] = Callback_
		end
		
		if Default then
			if not Variables.Keybinds[Default] then
				Variables.Keybinds[Default] = {}
			end
			table.insert(Variables.Keybinds[Default],Callback_)
			
			if DoubleSided and DoubleSided == true then
				if not Variables.Keybinds_[Default] then
					Variables.Keybinds_[Default] = {}
				end
				table.insert(Variables.Keybinds_[Default],Callback_)
			end
		end
		
		local function setkey(input)
			--// Old
			if Default then
				if Variables.Keybinds[Default] then
					if table.find(Variables.Keybinds[Default],Callback_) then
						table.remove(Variables.Keybinds[Default],table.find(Variables.Keybinds[Default],Callback_))
						if #Variables.Keybinds[Default] == 0 then
							Variables.Keybinds[Default] = nil
						end
					end
				end
				if Variables.Keybinds_[Default] then
					if table.find(Variables.Keybinds_[Default],Callback_) then
						table.remove(Variables.Keybinds_[Default],table.find(Variables.Keybinds_[Default],Callback_))
						if #Variables.Keybinds_[Default] == 0 then
							Variables.Keybinds_[Default] = nil
						end
					end
				end
			end
			--// New
			if input.UserInputType == Enum.UserInputType.Keyboard then
				Default = input.KeyCode
			else
				Default = input.UserInputType
			end
			if input.KeyCode == Enum.KeyCode.Backspace then
				Default = nil
			end
			if Default and not Variables.Keybinds[Default] then
				Variables.Keybinds[Default] = {}
			end
			Value.Text = EnumtoString(Default)
			Callback(Default,true)
			wait()
			if Default then
				table.insert(Variables.Keybinds[Default],Callback_)
				if DoubleSided == true then
					if not Variables.Keybinds_[Default] then
						Variables.Keybinds_[Default] = {}
					end
					table.insert(Variables.Keybinds_[Default],Callback_)
				end
			end
		end
		
		TextButton.MouseButton1Down:Connect(function()
			Value.Text = '...'
			wait()
			local connection
			connection = UIS.InputBegan:Connect(function(input)
				connection:Disconnect()
				connection = nil
				setkey(input)
			end)
		end)
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
			Variables.Flags[Flag] = nil
			if Default then
				if Variables.Keybinds[Default] then
					if table.find(Variables.Keybinds[Default],Callback_) then
						table.remove(Variables.Keybinds[Default],table.find(Variables.Keybinds[Default],Callback_))
					end
				end
			end
		end
		function methods:Set(keycode)
			setkey(keycode)
		end
		return methods
	end
end
modules.side.AddTextBox = function(args)
	local Frameto = args.Frame
	local Name = args.Name
	local Default = args.Default
	local TextDisappear = args.TextDisappear
	local Callback = args.Callback
	if Name and Frameto then
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local Content = Instance.new("TextLabel")
		local Frame_2 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local TextBox = Instance.new("TextBox")
		local TextButton = Instance.new("TextButton")

		--Properties:

		Frame.Parent = Frameto
		Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame.BorderSizePixel = 0
		Frame.Size = UDim2.new(1, 0, 0, 38)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Frame

		Content.Name = "Content"
		Content.Parent = Frame
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 0)
		Content.Size = UDim2.new(1, -12, 1, 0)
		Content.Font = Enum.Font.GothamBold
		Content.Text = "Textbox"
		Content.TextColor3 = Color3.fromRGB(240, 240, 240)
		Content.TextSize = 15.000
		Content.TextXAlignment = Enum.TextXAlignment.Left

		Frame_2.Parent = Frame
		Frame_2.AnchorPoint = Vector2.new(1, 0.5)
		Frame_2.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		Frame_2.BorderSizePixel = 0
		Frame_2.Position = UDim2.new(1, -12, 0.5, 0)
		Frame_2.Size = UDim2.new(0, 130, 0, 24)

		UICorner_2.CornerRadius = UDim.new(0, 4)
		UICorner_2.Parent = Frame_2

		TextBox.Parent = Frame_2
		TextBox.BackgroundTransparency = 1.000
		TextBox.Size = UDim2.new(1, 0, 1, 0)
		TextBox.ClearTextOnFocus = TextDisappear or false
		TextBox.Font = Enum.Font.GothamMedium
		TextBox.PlaceholderColor3 = Color3.fromRGB(210, 210, 210)
		TextBox.PlaceholderText = "???"
		TextBox.Text = Default or ''
		TextBox.TextColor3 = Color3.fromRGB(240, 240, 240)
		TextBox.TextSize = 14.000

		TextButton.Parent = Frame
		TextButton.BackgroundTransparency = 1.000
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.AutoButtonColor = false
		TextButton.Text = ""
		
		TextButton.MouseButton1Down:Connect(function()
			TextBox:CaptureFocus()
			TextBox.FocusLost:Connect(function()
				Callback(TextBox.Text)
			end)
		end)
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
		end
		function methods:Set(texto)
			TextBox.Text = texto
			Callback(TextBox.Value)
		end
		return methods
	end
end
modules.side.AddDropdown = function(args)
	local Var = {
		normal = 38,
		plus = 28
	}
	local frameto = args.Frame
	local Name = args.Name
	local Default = args.Default
	local Options = args.Options or {}
	local Callback = args.Callback
	local Filter = args.Filter
	local TextDisappear = args.TextDisappear or false
	local Quantity = args.Quantity
	if Name and Callback and frameto then
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local F = Instance.new("Frame")
		local Content = Instance.new("TextLabel")
		local Ico = Instance.new("ImageLabel")
		local Selected = Instance.new("TextLabel")
		local Line = Instance.new("Frame")
		local TextButton = Instance.new("TextButton")
		local UICorner_2 = Instance.new("UICorner")

		--Properties:

		Frame.Parent = frameto
		Frame.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame.BorderSizePixel = 0
		Frame.ClipsDescendants = true
		Frame.Size = UDim2.new(1, 0, 0, 38)

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = Frame

		ScrollingFrame.Parent = Frame
		ScrollingFrame.BackgroundTransparency = 1.000
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Position = UDim2.new(0, 0, 0, 38)
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -38)
		ScrollingFrame.BottomImage = "rbxassetid://7445543667"
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 112)
		ScrollingFrame.MidImage = "rbxassetid://7445543667"
		ScrollingFrame.ScrollBarThickness = 5
		ScrollingFrame.TopImage = "rbxassetid://7445543667"

		UIListLayout.Parent = ScrollingFrame
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

		F.Name = "F"
		F.Parent = Frame
		F.BackgroundTransparency = 1.000
		F.ClipsDescendants = true
		F.Size = UDim2.new(1, 0, 0, 38)

		Content.Name = "Content"
		Content.Parent = F
		Content.BackgroundTransparency = 1.000
		Content.Position = UDim2.new(0, 12, 0, 0)
		Content.Size = UDim2.new(1, -12, 1, 0)
		Content.Font = Enum.Font.GothamBold
		Content.Text = Name
		Content.TextColor3 = Color3.fromRGB(240, 240, 240)
		Content.TextSize = 15.000
		Content.TextXAlignment = Enum.TextXAlignment.Left

		Ico.Name = "Ico"
		Ico.Parent = F
		Ico.AnchorPoint = Vector2.new(0, 0.5)
		Ico.BackgroundTransparency = 1.000
		Ico.Position = UDim2.new(1, -30, 0.5, 0)
		Ico.Size = UDim2.new(0, 20, 0, 20)
		Ico.Image = "rbxassetid://7072706796"
		Ico.ImageColor3 = Color3.fromRGB(150, 150, 150)

		Selected.Name = "Selected"
		Selected.Parent = F
		Selected.BackgroundTransparency = 1.000
		Selected.Size = UDim2.new(1, -40, 1, 0)
		Selected.Font = Enum.Font.Gotham
		Selected.Text = Default or ''
		Selected.TextColor3 = Color3.fromRGB(150, 150, 150)
		Selected.TextSize = 13.000
		Selected.TextXAlignment = Enum.TextXAlignment.Right

		Line.Name = "Line"
		Line.Parent = F
		Line.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Line.BorderSizePixel = 0
		Line.Position = UDim2.new(0, 0, 1, -1)
		Line.Size = UDim2.new(1, 0, 0, 1)
		Line.Visible = false

		TextButton.Parent = F
		TextButton.BackgroundTransparency = 1.000
		TextButton.BorderSizePixel = 0
		TextButton.Size = UDim2.new(1, 0, 1, 0)
		TextButton.AutoButtonColor = false
		TextButton.Text = ""

		UICorner_2.CornerRadius = UDim.new(0, 10)
		UICorner_2.Parent = Frame
		
		Variables.Debounces[Frame] = false
		local Textbuttons = {}
		local Holder
		
		local function migrate()
			for i,v in pairs(ScrollingFrame:GetChildren()) do
				if v ~= UIListLayout then
					v.Parent = Holder
				end
			end
		end
		
		UIListLayout.Changed:Connect(function()
			updateCs(ScrollingFrame,UIListLayout,0)
		end)
		
		--// Filter
		if Filter then
			Holder = Instance.new('Folder',Frame)
			local FilterButton = Instance.new("TextButton")
			
			FilterButton.Name = "FilterButton"
			FilterButton.Parent = F
			FilterButton.BorderSizePixel = 0
			FilterButton.Position = UDim2.new(0.38202247, 0, 0, 0)
			FilterButton.Size = UDim2.new(0.298876405, 0, 1, 0)
			FilterButton.Visible = false
			FilterButton.ZIndex = 2
			FilterButton.AutoButtonColor = false
			FilterButton.Text = ""
			
			local FilterFrame = Instance.new("Frame")
			local UICorner = Instance.new("UICorner")
			local FilterBox = Instance.new("TextBox")

			--Properties:

			FilterFrame.Name = "FilterFrame"
			FilterFrame.Parent = F
			FilterFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
			FilterFrame.BorderSizePixel = 0
			FilterFrame.Position = UDim2.new(0.388741553, 0, 0.184210524, 0)
			FilterFrame.Size = UDim2.new(0, 130, 0, 24)

			UICorner.CornerRadius = UDim.new(0, 4)
			UICorner.Parent = FilterFrame

			FilterBox.Name = "FilterBox"
			FilterBox.Parent = FilterFrame
			FilterBox.BackgroundTransparency = 1.000
			FilterBox.Size = UDim2.new(1, 0, 1, 0)
			FilterBox.ClearTextOnFocus = false
			FilterBox.Font = Enum.Font.GothamMedium
			FilterBox.PlaceholderColor3 = Color3.fromRGB(210, 210, 210)
			FilterBox.PlaceholderText = "Search..."
			FilterBox.Text = ""
			FilterBox.TextColor3 = Color3.fromRGB(240, 240, 240)
			FilterBox.TextSize = 14.000
			
			FilterButton.MouseButton1Down:Connect(function()
				FilterBox:CaptureFocus()
			end)
			
			FilterBox.Changed:Connect(function()
				local filtering = FilterBox.Text
				if filtering == '' then
					migrate()
					for i,v in pairs(Textbuttons) do
						if v and v.Parent ~= ScrollingFrame then
							v.Parent = ScrollingFrame
						end
					end
				else
					migrate()
					local SideTable = {}
					for i,v in pairs(Textbuttons) do
						if StringFilterFunc(filtering,tostring(i)) then
							table.insert(SideTable,v)
						end
					end
					for i,v in pairs(SideTable) do
						v.Parent = ScrollingFrame
					end
				end
			end)
		end
		
		local function turnoff()
			for i,v in pairs(Textbuttons) do
				if v then
					v.BackgroundTransparency = 1
				end
			end
		end
		
		local function createbuttonto(name)
			local v = name
			local TextButton = Instance.new("TextButton")
			local UICorner = Instance.new("UICorner")
			local Title = Instance.new("TextLabel")

			--Properties:

			TextButton.Parent = ScrollingFrame
			TextButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
			TextButton.BorderSizePixel = 0
			TextButton.ClipsDescendants = true
			TextButton.Size = UDim2.new(1, 0, 0, 28)
			TextButton.AutoButtonColor = false
			TextButton.Text = ""
			TextButton.BackgroundTransparency = 1

			UICorner.CornerRadius = UDim.new(0, 6)
			UICorner.Parent = TextButton

			Title.Name = "Title"
			Title.Parent = TextButton
			Title.BackgroundTransparency = 1.000
			Title.Position = UDim2.new(0, 8, 0, 0)
			Title.Size = UDim2.new(1, -8, 1, 0)
			Title.Font = Enum.Font.Gotham
			Title.Text = tostring(v)
			Title.TextColor3 = Color3.fromRGB(240, 240, 240)
			Title.TextSize = 13.000
			Title.TextXAlignment = Enum.TextXAlignment.Left

			TextButton.MouseButton1Down:Connect(function()
				turnoff()
				TextButton.BackgroundTransparency = 0
				Selected.Text = tostring(v)
				Callback(tostring(v)) -- same?
			end)

			Textbuttons[tostring(v)] = TextButton
		end
		if Options then
			for i,v in pairs(Options) do
				createbuttonto(v)
			end
		end
		
		if Default then Textbuttons[tostring(Default)].BackgroundTransparency = 0 Callback(tostring(Default)) end
		if Quantity and Quantity <= 0 then Quantity = 1 end
		
		local function Checkdot(real)
			local str = tostring(real)
			local split = string.split(str,'.')
			if split[2] then
				return math.ceil(real)
			end
			return real
		end
		Quantity = Checkdot(Quantity)
		
		TextButton.MouseButton1Down:Connect(function()
			Variables.Debounces[Frame] = not Variables.Debounces[Frame]
			if Variables.Debounces[Frame] == true then
				if not Quantity then
					local quantity = #ScrollingFrame:GetChildren() - 1
					Frame:TweenSize(UDim2.new(1, 0, 0, Var.normal + Var.plus * quantity),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
					Ico.Rotation = 180
				else
					if #ScrollingFrame:GetChildren() - 1 <= 0 then Quantity = 0 end
					Frame:TweenSize(UDim2.new(1, 0, 0, Var.normal + Var.plus * Quantity),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
					Ico.Rotation = 180
				end
			else
				Ico.Rotation = 0
				Frame:TweenSize(UDim2.new(1, 0, 0, 38),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
			end
		end)
		
		local methods = {}
		function methods:Destroy()
			Frame:Destroy()
		end
		function methods:Refresh(list,del)
			if del == true then
				for i,v in pairs(Textbuttons) do
					v:Destroy()
					i = nil
				end
			end
			if list and typeof(list) == 'table' then
				Selected.Text = ''
				for i,v in pairs(list) do
					if Textbuttons[i] then Textbuttons[i]:Destroy() Textbuttons[i] = nil end
					createbuttonto(v)
				end
			end
		end
		function methods:Set(val)
			turnoff()
			if Textbuttons[val] then
				Textbuttons[val].BackgroundTransparency = 0
			end
			Callback(val)
		end
		function methods:SetQuantity(val)
			if tonumber(val) then
				Quantity = Checkdot(val)
				if Variables.Debounces[Frame] == true then
					if not Quantity then
						local quantity = #ScrollingFrame:GetChildren() - 1
						Frame:TweenSize(UDim2.new(1, 0, 0, Var.normal + Var.plus * quantity),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
						Ico.Rotation = 180
					else
						if #ScrollingFrame:GetChildren() - 1 <= 0 then Quantity = 0 end
						Frame:TweenSize(UDim2.new(1, 0, 0, Var.normal + Var.plus * Quantity),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
						Ico.Rotation = 180
					end
				else
					Ico.Rotation = 0
					Frame:TweenSize(UDim2.new(1, 0, 0, 38),Enum.EasingDirection.Out,Enum.EasingStyle.Quart,0.5,true)
				end
			end
		end
		return methods
	end
end

modules.side.AddTab = function(args)
	local Name = args.Name
	local Closedcallback = args.Closedcallback
	local Callback = args.Callback
	local Flag = args.Flag

	if Name then
		local button = create_LeftButton(Name)
		button.Parent = Variables.link.ScrollingFrame

		--// Scrolling frames
		local ItemContainer = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local UIPadding = Instance.new("UIPadding")
		--Properties:
		ItemContainer.Name = "ItemContainer"
		ItemContainer.Parent = Variables.link.Main
		ItemContainer.BackgroundTransparency = 1.000
		ItemContainer.BorderSizePixel = 0
		ItemContainer.Position = UDim2.new(0, 150, 0, 50)
		ItemContainer.Size = UDim2.new(1, -150, 1, -50)
		ItemContainer.BottomImage = "rbxassetid://7445543667"
		ItemContainer.CanvasSize = UDim2.new(0, 0, 0, 393)
		ItemContainer.MidImage = "rbxassetid://7445543667"
		ItemContainer.ScrollBarThickness = 5
		ItemContainer.TopImage = "rbxassetid://7445543667"
		ItemContainer.Visible = false

		UIListLayout.Parent = ItemContainer
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.Padding = UDim.new(0, 6)

		UIPadding.Parent = ItemContainer
		UIPadding.PaddingBottom = UDim.new(0, 15)
		UIPadding.PaddingLeft = UDim.new(0, 10)
		UIPadding.PaddingRight = UDim.new(0, 10)
		UIPadding.PaddingTop = UDim.new(0, 15)

		Variables.Buttons[Name] = ItemContainer
		Variables.Tab_Closedfuncs[Name] = Closedcallback
		
		UIListLayout.Changed:Connect(function()
			updateCs(ItemContainer,UIListLayout,30)
		end)

		button.MouseButton1Down:Connect(function()
			if Variables.Selection then
				Variables.Selection.BackgroundTransparency = 1
			end
			for i,v in pairs(Variables.Buttons) do
				if v.Visible then
					if Variables.Tab_Closedfuncs[i] then
						Variables.Tab_Closedfuncs[i]()
					end
					v.Visible = false
				end
			end
			Variables.Buttons[Name].Visible = true
			if Callback then
				Callback()
			end
			Variables.Selection = button
			Variables.Selection.BackgroundTransparency = 0.1
		end)

		if Flag then
			Variables.Flags[Flag] = Callback
		end
		
		local methods = {}
		function methods:Destroy()
			button:Destroy()
			ItemContainer:Destroy()
			Variables.Flags[Flag] = nil
		end
		methods.self = ItemContainer
		modules.side.Tabfunc(methods)
		return methods
	end
end

gsTween = game:GetService("TweenService")

local ex_connections = {}
local con_1 = UIS.InputEnded:connect(function(input, processed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Variables.held = false
		Variables.mousepressed = false
	end
	if Variables.Keybinds_[input.KeyCode] or Variables.Keybinds_[input.UserInputType] then
		for i,v in pairs(Variables.Keybinds_[input.KeyCode] or Variables.Keybinds_[input.UserInputType]) do
			local inputo = nil
			if input.UserInputType == Enum.UserInputType.Keyboard then
				inputo = input.KeyCode
			else
				inputo = input.UserInputType
			end
			v(inputo,false,false)
		end
	end
end)
local con_2 = UIS.InputBegan:Connect(function(input,processed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		Variables.mousepressed = true
	end
	if not processed then
		print(input.KeyCode)
		if Variables.Keybinds[input.KeyCode] or Variables.Keybinds[input.UserInputType] then
			for i,v in pairs(Variables.Keybinds[input.KeyCode] or Variables.Keybinds[input.UserInputType]) do
				local inputo = nil
				if input.UserInputType == Enum.UserInputType.Keyboard then
					inputo = input.KeyCode
				else
					inputo = input.UserInputType
				end
				v(inputo,false,true)
			end
		end
	else
		print(input.KeyCode)
	end
end)
function snap(pct, increment, max, min)
	local curstep = pct*(math.abs(max-min))/increment
	local maxstep = (max-min)/increment
	local minstep = 0
	if min > 0 then
		local distance = max-min
		local delta = pct * distance
		curstep = (min+delta - min)/increment
	end
	--local curstep = pct*(max + math.abs(min))
	local newstep
	if curstep > (maxstep - 1) then
		newstep = maxstep
	elseif curstep < (minstep + 1) then
		newstep = minstep
	else
		newstep =  math.floor(curstep)
	end
	
	local newnumber = min + (newstep*increment)
	if newnumber > max then
		return max
	elseif newnumber < min then
		return min
	else
		return newnumber
	end
end
local RuS = game:GetService('RunService')
local con_3 = RuS.RenderStepped:connect(function(delta)
	if Variables.held and Variables.CurrentSlider then
		local max = Variables.CurrentSlider:FindFirstChild('Maxto').Value
		local min = Variables.CurrentSlider:FindFirstChild('Minto').Value
		local increment = Variables.CurrentSlider:FindFirstChild('Increment').Value
		
		local Slider = Variables.CurrentSlider
		local mouse = UIS:GetMouseLocation() -- LEFTEST
		local Range = {
			min = Slider.AbsolutePosition.X,
			max = Slider.AbsolutePosition.X + Slider.Parent.AbsoluteSize.X,
		}
		local ap = Vector2.new(Slider.Parent.AbsolutePosition.X, Slider.Parent.AbsolutePosition.Y)
		local as = Vector2.new(Slider.Parent.AbsoluteSize.X, Slider.Parent.AbsoluteSize.Y)
		
		local newnumber = snap(((mouse.X - ap.X)/Slider.Parent.AbsoluteSize.X),increment,max,min)
		
		if string.split(tostring(increment),'.')[2] then
			local roundupto = #(string.split(tostring(increment),'.')[2])
			local get = string.split(tostring(newnumber),'.')
			if get[2] then
				local rounded = string.sub(get[2],1,roundupto)
				newnumber = tonumber(get[1]..'.'..rounded)
			end
		end
		
		local fakemax = max-min
		local fakenumber = newnumber-min
		local newpercentage = math.clamp(fakenumber/fakemax,0,1)
		
		local fakenumber,fakemax
		if min < 0 then
			fakemax = max + math.abs(min)
			if newnumber < 0 then
				newpercentage = math.clamp(math.abs((min + math.abs(newnumber)))/fakemax,0,1)
			else
				newpercentage = math.clamp((newnumber + math.abs(min))/fakemax,0,1)
			end
		end
		
		
		--[[
		local percentage = math.clamp((mouse.X - ap.X)/Slider.Parent.AbsoluteSize.X,0,1)
		--// Snapping, the increment thingy
		local realnumber = max * percentage
		local bry = math.floor(realnumber)
		--//Check incremento
		local coun = math.floor(((bry - min)/increment) + 1)
		local newnumber = min + (coun - 1) * increment
		local newpercentage = math.clamp(newnumber/max,0,1)
		]]
		
		Slider.Size = UDim2.new(newpercentage, 0, 1, 0)

		local Val = {
			Variables.CurrentSlider:FindFirstChild('Value'),
			Variables.CurrentSlider.Parent:FindFirstChild('Value'),
		}

		local Nameto = Variables.CurrentSlider:FindFirstChild('Nameto')
		local function changeval(text)
			for i,v in pairs(Val) do
				v.Text = tostring(text)..' '..Nameto.Value
			end
		end

		changeval(newnumber)

		if Variables.CurrentSlider_callback then
			Variables.CurrentSlider_callback(newnumber)
		end
	end
end)
table.insert(ex_connections,{con_1,con_2,con_3})

modules.side.Windowfunc = function(parento)
	function parento:MakeTab(args)
		return modules.side.AddTab(args)
	end
end
modules.side.Tabfunc = function(parento)
	function parento:AddSection(args)
		args.Frame = parento.self
		local methods = modules.side.AddSection(args) or nil
		return methods
	end
	
	function parento:AddSlider(args)
		args.Frame = parento.self
		local methods = modules.side.AddSlider(args) or nil
		return methods
	end
	
	function parento:AddButton(args)
		args.Frame = parento.self
		local methods = modules.side.AddButton(args) or nil
		return methods
	end
	
	function parento:AddToggle(args)
		args.Frame = parento.self
		local methods = modules.side.AddToggle(args) or nil
		return methods
	end
	
	function parento:AddLabel(...)
		local faketo = {...}
		local args = {}
		args.Frame = parento.self
		args.Name = faketo[1]
		local methods = modules.side.AddLabel(args) or nil
		return methods
	end
	
	function parento:AddParagraph(args)
		args.Frame = parento.self
		local methods = modules.side.AddParagraph(args)
		return methods or nil
	end
	
	function parento:AddBind(args)
		args.Frame = parento.self
		local methods = modules.side.AddBind(args)
		return methods or nil
	end
	
	function parento:AddTextbox(args)
		args.Frame = parento.self
		local methods = modules.side.AddTextBox(args)
		return methods or nil
	end
	
	function parento:AddDropdown(args)
		args.Frame = parento.self
		local methods = modules.side.AddDropdown(args)
		return methods or nil
	end
end

local hub = {}

function hub:MakeWindow(args)
	local Name = args.Name
	local Flag = args.Flag
	local Callback = args.Callback
	if Name then
		local Hub = Instance.new("ScreenGui")
		local Frame = Instance.new("Frame")
		local UICorner = Instance.new("UICorner")
		local TopBar = Instance.new("Frame")
		local Tushub = Instance.new("TextLabel")
		local Frame_2 = Instance.new("Frame")
		local Gameto = Instance.new("TextLabel")
		local Frame_3 = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local ScrollingFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")
		local UIPadding = Instance.new("UIPadding")
		local CharBoard = Instance.new("Frame")
		local Frame_4 = Instance.new("Frame")
		local Frame_5 = Instance.new("Frame")
		local ImageLabel = Instance.new("ImageLabel")
		local ImageLabel_2 = Instance.new("ImageLabel")
		local UICorner_3 = Instance.new("UICorner")
		local Frame_6 = Instance.new("Frame")
		local UICorner_4 = Instance.new("UICorner")
		local TextLabel = Instance.new("TextLabel")
		local Frame_7 = Instance.new("Frame")
		
		getgenv().MakeDrag(TopBar,Frame)

		--Properties:

		Hub.Name = "Hub"
		syn.protect_gui(Hub)
		Hub.Parent = game:GetService("CoreGui")
		Hub.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		Hub.Enabled = true

		Frame.Parent = Hub
		Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
		Frame.BorderSizePixel = 0
		Frame.ClipsDescendants = true
		Frame.Position = UDim2.new(0.25, 0, 0.25, 0)
		Frame.Size = UDim2.new(0, 615, 0, 344)

		UICorner.CornerRadius = UDim.new(0, 10)
		UICorner.Parent = Frame

		TopBar.Name = "TopBar"
		TopBar.Parent = Frame
		TopBar.BackgroundTransparency = 1.000
		TopBar.Size = UDim2.new(1, 0, 0, 50)

		Tushub.Name = "Tushub"
		Tushub.Parent = TopBar
		Tushub.BackgroundTransparency = 1.000
		Tushub.Position = UDim2.new(0, 25, 0, -24)
		Tushub.Size = UDim2.new(1, -30, 2, 0)
		Tushub.Font = Enum.Font.GothamBlack
		Tushub.Text = "Tus Hub"
		Tushub.TextColor3 = Color3.fromRGB(240, 240, 240)
		Tushub.TextSize = 20.000
		Tushub.TextXAlignment = Enum.TextXAlignment.Left

		Frame_2.Parent = TopBar
		Frame_2.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Frame_2.BorderSizePixel = 0
		Frame_2.Position = UDim2.new(0, 0, 1, -1)
		Frame_2.Size = UDim2.new(1, 0, 0, 1)

		Gameto.Name = "Game"
		Gameto.Parent = TopBar
		Gameto.BackgroundTransparency = 1.000
		Gameto.Position = UDim2.new(0, 426, 0, 12)
		Gameto.Size = UDim2.new(0.339837402, -30, 0.540000021, 0)
		Gameto.Font = Enum.Font.GothamBlack
		Gameto.Text = tostring(Name)
		Gameto.TextColor3 = Color3.fromRGB(129, 129, 129)
		Gameto.TextSize = 15.000
		Gameto.TextStrokeTransparency = 0.000
		Gameto.TextXAlignment = Enum.TextXAlignment.Right

		Frame_3.Parent = Frame
		Frame_3.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
		Frame_3.BorderSizePixel = 0
		Frame_3.Position = UDim2.new(0, 0, 0, 50)
		Frame_3.Size = UDim2.new(0, 150, 1, -50)

		UICorner_2.CornerRadius = UDim.new(0, 10)
		UICorner_2.Parent = Frame_3

		ScrollingFrame.Parent = Frame_3
		ScrollingFrame.BackgroundTransparency = 1.000
		ScrollingFrame.BorderSizePixel = 0
		ScrollingFrame.Size = UDim2.new(1, 0, 1, -50)
		ScrollingFrame.BottomImage = "rbxassetid://7445543667"
		ScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 46)
		ScrollingFrame.MidImage = "rbxassetid://7445543667"
		ScrollingFrame.ScrollBarThickness = 4
		ScrollingFrame.TopImage = "rbxassetid://7445543667"

		UIListLayout.Parent = ScrollingFrame
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

		UIPadding.Parent = ScrollingFrame
		UIPadding.PaddingBottom = UDim.new(0, 8)
		UIPadding.PaddingTop = UDim.new(0, 8)

		CharBoard.Name = "CharBoard"
		CharBoard.Parent = Frame_3
		CharBoard.BackgroundTransparency = 1.000
		CharBoard.Position = UDim2.new(0, 0, 1, -50)
		CharBoard.Size = UDim2.new(1, 0, 0, 50)

		Frame_4.Parent = CharBoard
		Frame_4.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Frame_4.BorderSizePixel = 0
		Frame_4.Size = UDim2.new(1, 0, 0, 1)

		Frame_5.Parent = CharBoard
		Frame_5.AnchorPoint = Vector2.new(0, 0.5)
		Frame_5.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Frame_5.BorderSizePixel = 0
		Frame_5.Position = UDim2.new(0, 10, 0.5, 0)
		Frame_5.Size = UDim2.new(0, 32, 0, 32)

		ImageLabel.Parent = Frame_5
		ImageLabel.BackgroundTransparency = 1.000
		ImageLabel.Size = UDim2.new(1, 0, 1, 0)
		local uid = game:GetService('Players').LocalPlayer.UserId
		ImageLabel.Image = "https://www.roblox.com/headshot-thumbnail/image?userId="..tostring(uid).."&width=420&height=420&format=png"

		ImageLabel_2.Parent = Frame_5
		ImageLabel_2.BackgroundTransparency = 1.000
		ImageLabel_2.Size = UDim2.new(1, 0, 1, 0)
		ImageLabel_2.Image = "rbxassetid://4031889928"
		ImageLabel_2.ImageColor3 = Color3.fromRGB(32, 32, 32)

		UICorner_3.CornerRadius = UDim.new(1, 10)
		UICorner_3.Parent = Frame_5

		Frame_6.Parent = CharBoard
		Frame_6.AnchorPoint = Vector2.new(0, 0.5)
		Frame_6.BackgroundTransparency = 1.000
		Frame_6.Position = UDim2.new(0, 10, 0.5, 0)
		Frame_6.Size = UDim2.new(0, 32, 0, 32)

		UICorner_4.CornerRadius = UDim.new(1, 10)
		UICorner_4.Parent = Frame_6

		TextLabel.Parent = CharBoard
		TextLabel.BackgroundTransparency = 1.000
		TextLabel.ClipsDescendants = true
		TextLabel.Position = UDim2.new(0, 50, 0, 18)
		TextLabel.Size = UDim2.new(1, -60, 0, 13)
		TextLabel.Font = Enum.Font.GothamBold
		TextLabel.Text = game:GetService('Players').LocalPlayer.Name or '???'
		TextLabel.TextColor3 = Color3.fromRGB(240, 240, 240)
		TextLabel.TextSize = 13.000
		TextLabel.TextXAlignment = Enum.TextXAlignment.Left

		Frame_7.Parent = Frame_3
		Frame_7.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
		Frame_7.BorderSizePixel = 0
		Frame_7.Position = UDim2.new(1, -1, 0, 0)
		Frame_7.Size = UDim2.new(0, 1, 1, 0)

		local Notify = Instance.new("Frame")
		local UIListLayout = Instance.new("UIListLayout")

		--Properties:

		Notify.Name = "Notify"
		Notify.Parent = Hub
		Notify.AnchorPoint = Vector2.new(1, 1)
		Notify.BackgroundTransparency = 1.000
		Notify.BorderColor3 = Color3.fromRGB(27, 42, 53)
		Notify.Position = UDim2.new(1, -25, 1, -25)
		Notify.Size = UDim2.new(0, 300, 1, -25)

		UIListLayout.Parent = Notify
		UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
		UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
		UIListLayout.Padding = UDim.new(0, 5)

		if Flag then
			Variables.Flags[Flag] = function(boolean)
				Hub.Enabled = boolean
			end
		end

		local Argsto = {
			ScrollingFrame = ScrollingFrame,
			Main = Frame,
			Hub = Hub,
			Notify = Notify,
		}
		Variables.link = Argsto
		Variables.Closedcallback = Callback
		
		local methods = {}
		modules.side.Windowfunc(methods)
		
		return methods
	end
end

function hub:Notify(args)
	local Contento = args.Content
	local Duration = args.Duration or 20
	local Callback = args.Callback
	if Contento and Duration and Variables.link and Variables.link.Notify then
		local TextButton = Instance.new("TextButton")
		local Content = Instance.new("TextLabel")
		local UICorner = Instance.new("UICorner")
		local Frame = Instance.new("Frame")
		local UICorner_2 = Instance.new("UICorner")
		local Frame_2 = Instance.new("Frame")
		local UICorner_3 = Instance.new("UICorner")
		local UIStroke = Instance.new('UIStroke')

		--Properties:

		TextButton.Parent = Variables.link.Notify
		TextButton.BackgroundColor3 = Color3.fromRGB(53, 53, 53)
		TextButton.BorderColor3 = Color3.fromRGB(27,42,53)
		TextButton.BackgroundTransparency = 0
		TextButton.Size = UDim2.new(0.980000019, 0, 0, 45)
		TextButton.Font = Enum.Font.SourceSans
		TextButton.Text = ""
		TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
		TextButton.TextSize = 14.000
		
		UIStroke.Name = 'UIStroke'
		UIStroke.Parent = TextButton
		UIStroke.Color = Color3.fromRGB(60,60,60)
		UIStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
		UIStroke.LineJoinMode = Enum.LineJoinMode.Round
		UIStroke.Thickness = 1
		UIStroke.Transparency = 0

		Content.Name = "Content"
		Content.Parent = TextButton
		Content.BackgroundTransparency = 1.000
		Content.BorderColor3 = Color3.fromRGB(27,42,53)
		Content.Position = UDim2.new(0.017, 0, 0.001, 0)
		Content.Size = UDim2.new(1, -12, 0.953333139, 0)
		Content.ZIndex = 3
		Content.Font = Enum.Font.SourceSansBold
		Content.LineHeight = 2.000
		Content.Text = Contento
		Content.TextColor3 = Color3.fromRGB(65025, 65025, 65025)
		Content.TextScaled = true
		Content.TextSize = 20.000
		Content.TextWrapped = true

		UICorner.CornerRadius = UDim.new(0, 5)
		UICorner.Parent = TextButton

		Frame.Parent = TextButton
		Frame.BackgroundColor3 = Color3.fromRGB(170, 170, 170)
		Frame.BorderSizePixel = 0
		Frame.Position = UDim2.new(-0.0102040814, 0, 0, 0)
		Frame.Size = UDim2.new(1.02040815, 0, 0.266666681, 33)

		UICorner_2.CornerRadius = UDim.new(0, 5)
		UICorner_2.Parent = Frame

		Frame_2.Parent = TextButton
		Frame_2.BackgroundColor3 = Color3.fromRGB(162, 251, 255)
		Frame_2.Position = UDim2.new(0.0136054419, 0, 0.953333855, 0)
		Frame_2.Size = UDim2.new(0.966394544, 0, 0, 2)
		Frame_2.ZIndex = 3

		UICorner_3.CornerRadius = UDim.new(0, 5)
		UICorner_3.Parent = Frame_2
		
		TextButton.ZIndex = 3
		Frame.ZIndex = 2
		
		local conn = TextButton.MouseButton1Down:Connect(function()
			if Callback then
				Callback()
			end
			TextButton:Destroy()
		end)

		if tostring(Duration) ~= 'inf' and Frame_2 then
			pcall(function()
				Frame_2:TweenSize(UDim2.new(0,0,0,2),Enum.EasingDirection.In,Enum.EasingStyle.Linear,Duration,true)
			end)
			task.spawn(function()
				wait(Duration)
				if TextButton then
					conn:Disconnect()
					if Callback then
						Callback()
					end
					TextButton:Destroy()
				end
			end)
		else
			Frame_2.Visible = false
		end
	end
end

function hub:On()
	Variables.link.Hub.Enabled = true
end

function hub:Off()
	Variables.link.Hub.Enabled = false
end

function hub:Toggle()
	Variables.link.Main.Visible = not Variables.link.Main.Visible
end

function hub:Destroy()
	for i,v in pairs(ex_connections) do
		v:Disconnect()
		v = nil
	end
	pcall(function()
		syn.unprotect_gui(Variables.link.Hub)
	end)
	Variables.link.Hub:Destroy()
	Variables = nil
end

function hub:FireFlag(flagname,args)
	Debugout('Flag Name = '..tostring(flagname))
	if Variables.Flags[flagname] then
		Debugout('Has Flag')
		Debugout('Tyep of flag = '..typeof(Variables.Flags[flagname]))
		local success,err = pcall(Variables.Flags[flagname],args)
		Debugout('Executed!\nSuccess = '..tostring(success)..'\nError = '..tostring(err))
	else
		Debugout(game:GetService('HttpService'):JSONEncode(Variables.Flags))
	end
end

function hub:CheckFlag(flagname)
	if Variables.Flags[flagname] then
		return true
	end
	return false
end

return hub
