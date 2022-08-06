# Tu's UI Lib
Tutorials

## Booting the Library
```lua
local HubLib = loadstring(game:HttpGet(('')))()
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


## Creating an Adaptive Input (NOT TODAY)
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
TextDisappear = <bool> - Makes the text disappear in the textbox after losing focus.
Callback = <function> - The function of the textbox.
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
Callback = <function> - The function of the bind. // return {key,issettingkey <bool>}
Flag = <string>
]]
```

### Chaning the value of a bind
```lua
Bind:Set(Enum.KeyCode.H)
```


## Creating a Dropdown menu (NOT TODAY)
```lua
Tab:AddDropdown({
	Name = "Dropdown",
	Default = "1",
	Options = {"1", "2"},
	Callback = function(Value)
		print(Value)
	end    
})

--[[
Name = <string> - The name of the dropdown.
Default = <string> - The default value of the dropdown.
Options = <table> - The options in the dropdown.
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
Dropdown:Set("dropdown option")
```

# Finishing your script (REQUIRED)
The below function needs to be added at the end of your code.
```lua
HubLib:Init() -- Enable the gui
```

### How flags work.
The flags feature in the ui may be confusing for some people. It serves the purpose of being the ID of an element in the config file, and makes accessing the value of an element anywhere in the code possible.
Below in an example of using flags.
```lua
Tab1:AddToggle({
    Name = "Toggle",
    Default = true,
    Save = true,
    Flag = "toggle"
})

print(OrionLib.Flags["toggle"].Value) -- prints the value of the toggle.
```
Flags only work with the toggle, slider, dropdown, bind, and colorpicker.

### Making your interface work with configs.
In order to make your interface use the configs function you first need to add the `SaveConfig` and `ConfigFolder` arguments to your window function. The explanation of these arguments in above.
Then you need to add the `Flag` and `Save` values to every toggle, slider, dropdown, bind, and colorpicker you want to include in the config file.
The `Flag = <string>` argument is the ID of an element in the config file.
The `Save = <bool>` argument includes the element in the config file.
Config files are made for every game the library is launched in.

## Destroying the Interface and all the Callback function
```lua
HubLib:Destroy()
```

## Notifying the user (Not today)
```lua
OrionLib:MakeNotification({
	Name = "Title!",
	Content = "Notification content... what will it say??",
	Image = "rbxassetid://4483345998",
	Time = 5
})

--[[
Title = <string> - The title of the notification.
Content = <string> - The content of the notification.
Image = <string> - The icon of the notification.
Time = <number> - The duration of the notfication.
]]
```
