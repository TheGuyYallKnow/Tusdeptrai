# Tu's UI Lib
Tutorials

## Booting the Library
```lua
local HubLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/TuUILib.lua')))()
```

## Creating a Window
```lua
local Window = HubLib:MakeWindow({Name = "Title of the library"})

--[[
Name = <string> - The name of the game.
Callback = <function> - Function to execute when the window is closed.
Flag = <string> - send <bool>, determines whether on or off
]]
```



## Creating a Tab
```lua
local Tab = Window:MakeTab({
	Name = "Tab 1",
})

--[[
Name = <string> - The name of the tab.
Closedcallback = <function> -- Executed when the tab is closed.
Callback = <function> -- Executed when the tab is opened.
Flag = <string>
]]
```
## Creating a Section
```lua
local Section = Tab:AddSection({
	Name = "Section"
})

--[[
Name = <string> - The name of the section.
]]
```
## Creating a Button
```lua
Tab:AddButton({
	Name = "Button!",
	Callback = function()
      		print("button pressed")
  	end    
})

--[[
Name = <string> - The name of the button.
Callback = <function> - The function of the button.
]]
```


## Creating a Toggler
```lua
Tab:AddToggle({
	Name = "This is a toggle!",
	Default = false,
	Callback = function(Value)
		print(Value) -- this will return <bool>
	end    
})

--[[
Name = <string> - The name of the toggle.
Default = <bool> - The default value of the toggle.
CanPress = <bool> - default is true
Callback = <function> - The function of the toggle.
Flag = <string>
]]
```

### Toggle with script
```lua
Tab:AddToggle({
	Name = "This is a toggle!",
	Default = false,
	Flag = 'Tu',
	Callback = function(Value)
		print(Value) -- this will return <bool>
	end    
})

local FlagName = 'Tu'
local args = {
  Set = true, -- Determines the value of the toggle
}
HubLib:FireFlag(FlagName,args)

-- >> 'true'
```



## Creating a Color Picker (Not TODAY)
```lua
Tab:AddColorpicker({
	Name = "Colorpicker",
	Default = Color3.fromRGB(255, 0, 0),
	Callback = function(Value)
		print(Value)
	end	  
})

--[[
Name = <string> - The name of the colorpicker.
Default = <color3> - The default value of the colorpicker.
Callback = <function> - The function of the colorpicker.
]]
```

### Setting the color picker's value
```lua
ColorPicker:Set(Color3.fromRGB(255,255,255))
```


## Creating a Slider
```lua
Tab:AddSlider({
	Name = "Slider",
	Min = 1,
	Max = 3,
	Default = 3,
	Increment = 1,
	ValueName = "Tomoes",
  	Flag = "Tu_Slider",
	Callback = function(Value)
		print(Value)
	end    
})
--[[
Name = <string> - The name of the slider.
Min = <number> - The minimal value of the slider.
Max = <number> - The maxium value of the slider.
Increment = <number> - How much the slider will change value when dragging.
Default = <number> - The default value of the slider.
ValueName = <string> - The text after the value number.
Callback = <function> - The function of the slider.
Flag = <string>
]]
```
### Change Slider Value
```lua
Slider:Set(2)
```
Or
```lua
HubLib:FireFlag("Tu_Slider",{Set = 2})
```
Make sure you make your slider a variable (local CoolSlider = Tab:AddSlider...) for this to work.


## Creating a Label
```lua
local CoolLabel = Tab:AddLabel("Im Tu")
```
### Changing the value of an existing label
```lua
CoolLabel:Set("Tu is handsome tbh")
```


## Creating a Paragraph
```lua
local CoolParagraph = Tab:AddParagraph({
    Name = 'Titleto',
    Content = 'Cool Paragraph',
  }
)
```
### Changing an existing paragraph
```lua
CoolParagraph:Set({
    Name = 'Titleto',
    Content = 'Cool Paragraph',
  }
)
```


## Creating an Adaptive Input
```lua
Tab:AddTextbox({
	Name = "Textbox",
	Default = "default box input",
	TextDisappear = true,
	Callback = function(Value)
		print(Value)
	end	  
})

--[[
Name = <string> - The name of the textbox.
Default = <string> - The default value of the textbox.
TextDisappear = <bool> - Makes the text disappear in the textbox after focuses.
Callback = <function> - The function of the textbox, when changed.
]]
```


## Creating a Keybind
```lua
Tab:AddBind({
	Name = "Bind",
	Default = Enum.KeyCode.F,
	Callback = function()
		print("press")
	end    
})

--[[
Name = <string> - The name of the bind.
Default = <keycode> - The default value of the bind.
DoubleSided = <bool> - Fire the callback function even when input ended.
Callback = <function> - The function of the bind. // return {key,issettingkey <bool>, inputed <bool>}
Flag = <string> - Fire with true state only ;3
]]
```

### Chaning the value of a bind
```lua
Bind:Set(Enum.KeyCode.H)
```


## Creating a Dropdown menu 
```lua
Tab:AddDropdown({
	Name = "Dropdown",
	Default = "1",
	Options = {"1", "2"},
	Filter = true,
	TextDisappear = false,
	Callback = function(Value)
		print(Value)
	end    
})

--[[
Name = <string> - The name of the dropdown.
Default = <string> - The default value of the dropdown.
Options = <table> - The options in the dropdown. -- Default is {}
Filter = <bool> - Adds in a filter or not.
TextDisappear = <bool> - Makes the text disappear in the textbox after focuses. -- Default is false.
Quantity = <int> - Designs how long the scrolling frame will be. -- Default is #Options
Callback = <function> - The function of the dropdown.
]]
```

### Adding a set of new Dropdown buttons to an existing menu
```lua
Dropdown:Refresh(List<table>,true)
```
The above boolean value "true" is whether or not the current buttons will be deleted.

### Selecting a dropdown option
```lua
Dropdown:Set("Tudeptrai") -- Set the current selection to 'Tudeptrai' and run the callback function
```

### Setting the quantity option
```lua
Dropdown:SetQuantity(4) -- its fine to go negative, but must be int
```

# Finishing your script (REQUIRED)
The below function needs to be added at the end of your code.
```lua
HubLib:Init() -- Enable the gui
```
Idk, useless but still necessarry

### How flags work.
```lua
HubLib:FireFlag('Tu',args)
```
Pass the args to the function of that flag, actually its an event but ill call it flag

## Destroying the Interface and all the Callback function
```lua
HubLib:Destroy()
```

## Notifying the user
```lua
OrionLib:Notify({
	Content = "Notification content... what will it say??",
	Duration = 5
})

--[[
Content = <string> - The content of the notification.
Duration = <number> - The duration of the notfication. -- Default will be 20
]]
```

# Tu's ESP Modules:
## Arguments:

### Layer:int
``` The Layer where the text should be located. ```

### Priority:int
``` The lowest => leftest. ```

### Text_front:str
``` Start of the Text. ```

### Text_end:str
``` End of the Text. ```

### TrackInst:inst
``` Getting the instance to trace, we will require its components later. ```

### TrackValue:str
``` Track the value of the 'TrackInst'. ```

### Flag:str
``` Specify the track, so we can make a toggle for it. ```

### ColorFlag:str
``` 
To variables child, RGB Type.
Note: Put it in priority 1!
```

### IsTeam:bool
``` Determines Teammate. ```

### FriendTrack:bool
``` Tracks friend and gives it the correct color. ```

## Special Arguments:
### TrackInst_2 and TrackValue_2: inst,str
``` If added, used for tracking % between 'TrackValue' and 'TrackValue_2' (Highest).```

### TrackDistance:bool
``` Special module to Check the distance between the 'TrackInst' and self. ```

## Global Arguments:
### CustomHealthTrack
```lua
local sent = {}
sent.CustomHealthTrack = {
	HealthPath = 'char/Health',
	HealthValue = 'Value',
	
	MaxHealthPath = 'char/Health',
	MaxHealthValue = 'MaxValue',
}
```
Path Guide: 'char' = .Character; '/' = Dir; 
Ex: 'char/Health'

## External Module Arguments:
### ESP
DATA (Table, no mt, with indexes), Pretty much the same args as above
```lua
local Gave = {
	{
		Layer = 3,
		Priority = 1,
		Text_front = "[BP: ",
		Text_end = "]",
		TrackInst = 'char/Config/BattlePower',
		TrackValue = 'Value',
		Flag = 'BP_XO2',
		ColorFlag = 'ESP_PlayerColor',
	},
	{},
	{},
}
```
### GUI
Args (Table, no mt, with indexes), Same as 'Bind' (only 'Bind' and 'Toggle' for now)
```lua
local Gave = {
	{
		Type = 'Toggle',
		Flag = 'BP_XO2',
		Save = 'ESP_ShowBP_XO2',
		NoSave = true, -- Default will be false.
	}
}
```
Category (Table)
```lua
local GUI = {
	Player = {
		Gave, -- Above there ;3
		{
			-- do shit here
		},
		{},
	}
}
```
CATEGORIES LIST
```lua
local Categories = {
	Player = {},
	Team = {},
	Player_Global = {},
	Team_Global = {},
	Misc = {}, --// Thinking of Areas esp or npcs, going to make sections inside o.o
}
```
See the priority in the script ;3
### ColorFlags
DATA (Table, no mt, with indexes)
```lua
local ColorFlags = {
	{
		Name = 'LGBT Supporter',
		R = 255,
		G = 255,
		B = 255,
	},
	{
		Name = 'Pog',
		R = 0,
		G = 255,
		B = 0
	}
}
--[[
Name: = <string> - Name of that flag
R,G,B = <int> - Color in RGB only please, thanks
]]
```
