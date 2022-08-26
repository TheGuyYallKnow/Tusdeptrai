local module = {}

local gsTween = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Drags = {}


local function update(input)
	for i,v in pairs(Drags) do
		if v.dragging == true then
			local delta = input.Position - v.dragStart
			local dragTime = 0.01
			local SmoothDrag = {}
			SmoothDrag.Position = UDim2.new(v.startPos.X.Scale, v.startPos.X.Offset + delta.X, v.startPos.Y.Scale, v.startPos.Y.Offset + delta.Y)
			local dragSmoothFunction = gsTween:Create(v.Drag, TweenInfo.new(dragTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), SmoothDrag)
			dragSmoothFunction:Play()
		end
	end
end

local function findmatch(input)
	local toreturn = false
	for i,v in pairs(Drags) do
		if v.dragInput and v.dragInput == input then
			toreturn = true
			break
		end
	end
	return toreturn
end
UserInputService.InputChanged:Connect(function(input)
	if #Drags >= 1 and findmatch(input) then
		update(input)
	end
end)

function module.MakeDragable(Drag)
	local tab = {}
	local dragging
	local dragInput
	local dragStart
	local startPos
	local function adjust()
		table.remove(Drags,table.find(Drags,tab))
		tab.dragging = dragging
		tab.dragInput = dragInput
		tab.dragStart = dragStart
		tab.startPos = startPos
		tab.Drag = Drag
		table.insert(Drags,tab)
	end

	local connections = {}
	connections.Began = Drag.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = Drag.Position
			adjust()
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					adjust()
				end
			end)
		end
	end)
	connections.Changed = Drag.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
			adjust()
		end
	end)
	connections.End = function()
		connections.Began:disconnect()
		connections.Began = nil
		connections.Changed:disconnect()
		connections.Changed = nil
		table.remove(Drags,table.find(Drags,tab))
	end
	return connections
end

return module
