local isGaia = true
local debugMode = false
local isUserTrolled = false

local moderatorInGame = false;
local sprinting = false;
local playerGotManualKick = false;

--// EB2S
do
	function EnumBind2String()
		local modules = {}

		local tab = {
			MouseButton1 = 'LMB',
			MouseButton2 = 'RMB',
			MouseButton3 = 'MMB',
		}

		modules.E2S = function(en)
			if en then
				local give = string.split(tostring(en),'.')[3]
				if tab[tostring(give)] then
					give = tab[tostring(give)]
				end
				return give
			else
				return ''
			end
		end

		modules.S2E = function(str)
			if str ~= '' then
				local get
				for i,v in pairs(tab) do
					if tostring(str) == tostring(v) then
						get = tostring(i)
					end
				end
				if not get then
					if Enum.KeyCode[str] then
						get = Enum.KeyCode[str]
					end
				else
					get = Enum.UserInputType[tostring(get)]
				end
				if get then
					return get
				end
			end
			return nil
		end
		return modules
	end
	local func_ = newcclosure(EnumBind2String)
	getgenv().EB2S = func_
end
--// String filter shit
do 
	local function split(str)
		return string.split(tostring(str),'')
	end
	function filter (str, str2)
		local get = split(str)
		local get2 = split(str2)
		local toreturn = true
		for i = 1,#str do
			if str[i] ~= str2[2] then
				toreturn = false
			end
		end
		return toreturn
	end
	local stringfilter = newcclosure(filter)
	getgenv().stringfilter = stringfilter
end

local Maid = loadstring(game:HttpGet(("https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/Maid.lua")))()
local GUILIB = loadstring(game:HttpGet(("https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/GUILIB.lua")))()
local createBaseESP = function() end

local CoreGui = game:GetService('CoreGui')
local Players = game:GetService('Players')
local CollectionService = game:GetService('CollectionService')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ContextActionService = game:GetService('ContextActionService')
local UserInputService = game:GetService('UserInputService')
local StarterGui = game:GetService('StarterGui')
local HttpService = game:GetService('HttpService')
local Lighting = game:GetService('Lighting')
local RunService = game:GetService('RunService')
local FindFirstChild = game.FindFirstChild
local IsA = game.IsA
local IsDescendantOf = game.IsDescendantOf
local Heartbeat = RunService.Heartbeat

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

checkcaller,newcclosure,getgc,islclosure,getconstants,getupvalue = checkcaller,newcclosure,getgc,islclosure,getconstants,getupvalue
getgenv,hookfunction,getcallingscript,hookmetamethod,setrawmetatable,gethiddenproperty = getgenv,hookfunction,getcallingscript,hookmetamethod,setrawmetatable,gethiddenproperty
getpcdprop,getconnections = getpcdprop,getconnections

local disableenvprotection = disableenvprotection or function() end;
local enableenvprotection = enableenvprotection or function() end;

local playerGotManualKick;
local ingredientsFolder;
local tango;
local fallDamage;
local dodge;
local manaCharge;
local dialog;
local dolorosa;
local changeArea;
local flyBV;
local speedHackBV;

local Trinkets = {};
local spellValues = {};
local Ingredients = {"Acorn Light","Glow Scroom","Lava Flower","Canewood","Moss Plant","Freeleaf","Trote","Scroom","Zombie Scroom","Potato","Tellbloom","Polar Plant","Strange Tentacle","Vile Seed","Ice Jar","Dire Flower","Crown Flower","Bloodthorn","Periascroom","Orcher Leaf","Uncanny Tentacle","Creely","Desert Mist","Snow Scroom"};
local injuryObjects = {'Careless', 'PsychoInjury', 'MindWarp', 'NoControl', 'Maniacal', 'BrokenLeg', 'BrokenArm', 'VisionBlur'};

local trinkets = {};
local ingredients = {};
local mobs = {};
local npcs = {};
local bags = {};
local queue = {};
local noclipBlocks = {};
local killBricks = {};
local trinketsData = {};
local playerClassesList = {};
local playerClasses = {};
local remotes = {};
local allMods = {};
local illusionists = {};
local ingredientEspBase = createBaseESP('ingredientEsp', ingredients);
