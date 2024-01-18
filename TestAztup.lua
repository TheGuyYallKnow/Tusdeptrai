local isGaia = false
local debugMode = false
local isUserTrolled = false

local moderatorInGame = false;
local sprinting = false;
local playerGotManualKick = false;

local Maid = loadstring(game:HttpGet(("https://raw.githubusercontent.com/TheGuyYallKnow/Tusdeptrai/main/Maid.lua")))()
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

function ControlModuleGet()
	local ControlModule = {};
	do
		ControlModule.__index = ControlModule

		function ControlModule.new()
			local self = {
				forwardValue = 0,
				backwardValue = 0,
				leftValue = 0,
				rightValue = 0
			}

			setmetatable(self, ControlModule)
			self:init()
			return self
		end

		function ControlModule:init()
			local handleMoveForward = function(actionName, inputState, inputObject)
				self.forwardValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
				return Enum.ContextActionResult.Pass
			end

			local handleMoveBackward = function(actionName, inputState, inputObject)
				self.backwardValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
				return Enum.ContextActionResult.Pass
			end

			local handleMoveLeft = function(actionName, inputState, inputObject)
				self.leftValue = (inputState == Enum.UserInputState.Begin) and -1 or 0
				return Enum.ContextActionResult.Pass
			end

			local handleMoveRight = function(actionName, inputState, inputObject)
				self.rightValue = (inputState == Enum.UserInputState.Begin) and 1 or 0
				return Enum.ContextActionResult.Pass
			end

			ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveForward, false, Enum.KeyCode.W);
			ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveBackward, false, Enum.KeyCode.S);
			ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveLeft, false, Enum.KeyCode.A);
			ContextActionService:BindAction(HttpService:GenerateGUID(false), handleMoveRight, false, Enum.KeyCode.D);
		end

		function ControlModule:GetMoveVector()
			return Vector3.new(self.leftValue + self.rightValue, 0, self.forwardValue + self.backwardValue)
		end
	end

	return ControlModule.new();
end

local ControlModule = ControlModuleGet().new()

local function findPlayer(playerName)
	if game:GetService('Players'):FindFirstChild(playerName) then
		return game:GetService('Players'):FindFirstChild(playerName)
	end
end

local function getPlayerStats(player)
	if(isGaia) then
		return player:GetAttribute('FirstName') or 'Unknown', player:GetAttribute('LastName') or 'Unknown';
	else
		local leaderstats = player:FindFirstChild('leaderstats');
		local firstName = leaderstats and leaderstats:FindFirstChild('FirstName');
		local lastName = leaderstats and leaderstats:FindFirstChild('LastName');

		if(not leaderstats or not firstName or not lastName) then
			return 'Unknown', 'Unknown';
		end;

		return firstName.Value, lastName.Value;
	end;
end;

local function chargeMana()
	if(not manaCharge) then return end;

	if(isGaia) then
		manaCharge.FireServer(manaCharge, {math.random(1, 10), math.random()});
	else
		manaCharge.FireServer(manaCharge, true);
	end;
end;

local function dechargeMana()
	if(not manaCharge) then return end;

	if(isGaia) then
		manaCharge.FireServer(manaCharge);
	else
		manaCharge.FireServer(manaCharge, false);
	end;
end

local function canUseMana()
	local character = LocalPlayer.Character;
	if(not character) then return end;

	if (character:FindFirstChild('Grabbed')) then return end;
	if (character:FindFirstChild('Climbing')) then return end;
	if (character:FindFirstChild('ClimbCoolDown')) then return end;

	if (character:FindFirstChild('ManaStop')) then return end;
	if (character:FindFirstChild('SpellBlocking')) then return end;
	if (character:FindFirstChild('ActiveCast')) then return end;
	if (character:FindFirstChild('Stun')) then return end;

	if CollectionService:HasTag(character, 'Knocked') then return end;
	if CollectionService:HasTag(character, 'Unconscious') then return end;

	return true;
end;

local function makeNotification(title, text)
	game.StarterGui:SetCore("SendNotification", {
		Title = title,
		Text = text,
		Duration = 5,
	})
end;

local function kickPlayer(reason)
	if (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
		repeat
			task.wait()
		until not LocalPlayer.Character:FindFirstChild('Danger');
	end;

	playerGotManualKick = true;
	LocalPlayer:Kick(reason);
	task.wait(1);
end;

do -- // Anti Cheat Bypass
	local Humanoid = Instance.new('Humanoid', game);

	local Animation = Instance.new('Animation');
	Animation.AnimationId = 'rbxassetid://4595066903';

	local Play = Humanoid:LoadAnimation(Animation).Play;
	Humanoid:Destroy();

	local getKey;

	local function grabKeyHandler()
		if(isGaia) then
			for i, v in next, getgc() do
				if(typeof(v) == 'function' and islclosure(v) and table.find(getconstants(v), 'plum')) then
					local keyHandler = getupvalue(v, 1);
					if(typeof(keyHandler) == 'table' and typeof(rawget(keyHandler, 1)) == 'function') then
						getKey = rawget(keyHandler, 1);
						break
					end;
				end;
			end;
		else
			for i, v in next, getgc(true) do
				if(typeof(v) == 'table' and rawget(v, 'getKey')) then
					getKey = rawget(v, 'getKey');
					break;
				end;
			end;
		end;
	end;

	getgenv().remotes = {};
	local function setRemote(name, remote, isPcall)
		-- print('[Remote Grabbed] Got', name, 'as', remote);

		if (isPcall) then remote = isPcall; end;
		getgenv().remotes[name] = remote;

		if(name == 'tango') then
			tango = remote;
		elseif(name == 'fallDamage') then
			fallDamage = remote;
		elseif(name == 'dodge') then
			dodge = remote;
		elseif(name == 'manaCharge') then
			manaCharge = remote;
		elseif(name == 'dialog') then
			dialog = remote;
		elseif(name == 'dolorosa') then
			dolorosa = remote;
		elseif(name == 'changeArea') then
			changeArea = remote;
		end;
	end;

	grabKeyHandler();
	if(not getKey) then
		warn('Didn\'t got keyhandler retrying with loop...');
		repeat
			grabKeyHandler();
			task.wait(2);
		until getKey;
	end;

	hookfunction(
		Instance.new('Part').BreakJoints,
		newcclosure(function() end)
	);

	local oldPlay;
	oldPlay = hookfunction(Play, newcclosure(function(self)
		if (isUserTrolled) then return oldPlay(self) end;
		if(typeof(self) == 'Instance' and self.ClassName == 'AnimationTrack' and (string.find(self.Animation.AnimationId, '4595066903'))) then
			return warn('Ban Attempt -> Play');
		end;

		return oldPlay(self);
	end));

	oldFireServer = hookfunction(Instance.new('RemoteEvent').FireServer, function(self, ...)
		if(typeof(self) ~= 'Instance' or not self:IsA('RemoteEvent') or isUserTrolled) then return oldFireServer(self, ...); end;
		if(debugMode) then
			-- print(prettyPrint({
			--     ...,
			--     __self = self,
			--     __traceback = debug.traceback()
			-- }));
		end;

		if(not tango) then return print('Remote return cause no tango got!'); end;
		if(not isGaia and self == tango) then return warn('Ban Attempt -> Drop'); end;

		local args = {...};
		if(self == tango) then
			local sprintData = rawget(args, 1);
			local sprintValue = sprintData and rawget(sprintData, 1);
			local randomValue = sprintData and rawget(sprintData, 2);

			if(typeof(randomValue) == 'number' and not (randomValue <= 4 and randomValue >= 2)) then
				print('[Tango Args]', randomValue <= 4, randomValue >= 2, randomValue, sprintValue);
				return warn('Ban Attempt -> Tango');
			elseif((sprintValue == 1 or sprintValue == 2) and randomValue < 3) then
				print(randomValue);
				print(sprintValue);
				sprinting = sprintValue == 1;
				dechargeMana();
			end;

			-- print(sprintValue);
			-- sprinting = sprintValue == 1;
			-- -- if(sprintValue == 1) then
			-- -- end;
		elseif(self == dolorosa) then
			return warn('Ban Attempt -> Dolorosa');
		elseif(self == fallDamage and (getgenv().noFallDamage) and not checkcaller()) then
			return warn('Fall Damage -> Attempt');
		elseif(self.Name == 'LeftClick') then
			if(getgenv().antiBackfire) then
				local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
				if(not tool) then return oldFireServer(self, ...) end;

				-- local useSnap = library.flags[toCamelCase(tool.Name .. ' Use Snap')];
				local amount = spellValues[tool.Name]
				amount = amount and amount[1];

				if(not amount) then return oldFireServer(self, ...) end;

				local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
				if(mana.Value < amount.min or mana.Value > amount.max) then
					return;
				end;
			end;
		elseif(self.Name == 'RightClick') then
			if(getgenv().antiBackfire) then
				local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
				if(not tool) then return oldFireServer(self, ...) end;

				-- local useSnap = library.flags[toCamelCase(tool.Name .. ' Use Snap')];
				local amount = spellValues[tool.Name]
				amount = amount and amount[2];

				if(not amount) then return oldFireServer(self, ...) end;

				local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
				if(mana.Value < amount.min or mana.Value > amount.max) then
					return;
				end;
			end;
		elseif(self == changeArea and getgenv().temperatureLock) then
			args[1] = 'Oresfall'
			return oldFireServer(self, unpack(args));
		end;

		return oldFireServer(self, ...);
	end);

	remotes.loadKeys = true;

	-- // Thanks Unluac
	local TANGO_PASSWORD = 30195.341357415226
	local POST_DIALOGUE_PASSWORD = 404.5041892976703
	local DODGE_PASSWORD = 398.00010021400533
	local APPLY_FALL_DAMAGE_PASSWORD = 90.32503962905011
	local SET_MANA_CHARGE_STATE_PASSWORD = 27.81839265298673

	if(isGaia) then
		do -- // FindFirstChild Hook cuz recursive FindFirstChild is so laggy
			local soundService = game:GetService('SoundService');

			local turrets = workspace.Turrets;
			local turretsBody = turrets:FindFirstChild('Body', true);
			local map = workspace.Map;

			local killBrick = map:FindFirstChild('KillBrick', true);
			local lavaBrick = map:FindFirstChild('Lava', true);

			local robloxGui = CoreGui:FindFirstChild('RobloxGui');
			local oldFindFirstChild;
			oldFindFirstChild = hookfunction(game.FindFirstChild, newcclosure(function(self, itemName, recursive)
				if(checkcaller() or typeof(self) ~= 'Instance' or typeof(itemName) ~= 'string') then return oldFindFirstChild(self, itemName, recursive) end;

				if(itemName == 'Body' and self == turrets and recursive) then
					return turretsBody;
				elseif(itemName == 'KB' and self == soundService) then
					return nil;
				elseif(itemName == 'Lava' and self == map) then
					return lavaBrick;
				elseif(itemName == 'KillBrick' and self == map) then
					return killBrick;
				elseif(itemName == 'RobloxGui' and self == game and recursive) then
					return robloxGui;
				elseif(itemName == 'Players' and self == game and recursive) then
					return Players;
				elseif(itemName == 'Server Pinger' and self == game and recursive) then
					return nil;
				end;

				return oldFindFirstChild(self, itemName, recursive);
			end));
		end;
	end;

	local cameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance;

	local oldNewIndex;
	local oldNameCall;
	local oldIndex;

	local requests = ReplicatedStorage:WaitForChild('Requests');
	local myRemotes;

	local function onCharacterAdded(character)
		if(not character) then return end;
		local myNewRemotes = character:WaitForChild('CharacterHandler') and character.CharacterHandler:WaitForChild('Remotes');
		if(not myNewRemotes) then return end;

		myRemotes = myNewRemotes;

		task.delay(1,function()
			ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
				local mouseT = {};
				mouseT.Hit = Mouse.Hit;
				mouseT.Target = Mouse.Target;
				mouseT.UnitRay = Mouse.UnitRay;
				mouseT.X = Mouse.X;
				mouseT.Y = Mouse.Y;
				return mouseT;
			end;
		end)

	end;

	onCharacterAdded(LocalPlayer.Character);
	LocalPlayer.CharacterAdded:Connect(onCharacterAdded);

	local cachedRemotes = {};

	oldIndex = hookmetamethod(game, '__index', function(self, p)
		if(not tango) then
			return oldIndex(self, p);
		end;

		-- if(string.find(debug.traceback(), 'KeyHandler')) then
		--     warn('kay handler call __index', self, p);
		-- end;

		if(p == 'MouseButton1Click' and IsA(self, 'GuiButton') and getgenv().autoBard) then
			local caller = getcallingscript();
			caller = typeof(caller) == 'Instance' and oldIndex(caller, 'Parent');

			if(caller and oldIndex(caller, 'Name') == 'BardGui') then
				local fakeSignal = {};
				function fakeSignal.Connect(_, f)
					coroutine.wrap(function()
						local outerRing = FindFirstChild(self, 'OuterRing');
						if(outerRing) then
							repeat
								task.wait();
							until oldIndex(outerRing, 'Parent') == nil or outerRing.Size.X.Offset <= 135;
							if(oldIndex(outerRing, 'Parent')) then
								f();
							end;
						end;
					end)();
				end;
				fakeSignal.connect = fakeSignal.Connect;
				return fakeSignal;
			end;
		elseif(self == LocalPlayer and p == 'CameraMaxZoomDistance' and not checkcaller()) then
			local stackTrace = debug.traceback();

			if(not string.find(stackTrace, 'CameraModule')) then
				return cameraMaxZoomDistance;
			end;
		end;

		return oldIndex(self, p);
	end);

	local getMouse = ReplicatedStorage.Requests.GetMouse;

	oldNewIndex = hookmetamethod(game, '__newindex', function(self, p, v)
		if(p == 'Parent' and IsA(self, 'Script') and oldIndex(self, 'Name') == 'CharacterHandler' and IsDescendantOf(self, LocalPlayer.Character)) then
			return warn('Ban Attempt -> Character Nil');
		elseif(tango and not checkcaller()) then -- // stuff that only triggers once ac is bypassed
			if(p == 'WalkSpeed' and IsA(self, 'Humanoid') and getgenv().speedHack) then
				return;
			elseif((p == 'Ambient' or p == 'Brightness') and self == Lighting and getgenv().fullbright) then
				return;
			elseif((p == 'FogEnd' or p == 'FogStart') and self == Lighting and getgenv().noFog) then
				return;
			end;
		elseif (p == 'OnClientInvoke' and self == getMouse and not checkcaller()) then
			return;
		elseif(self == LocalPlayer and p == 'CameraMaxZoomDistance' and not checkcaller()) then
			cameraMaxZoomDistance = v;
		end;

		return oldNewIndex(self, p, v);
	end);

	oldNameCall = hookmetamethod(game, '__namecall', function(self, ...)
		if(not remotes.loadKeys or checkcaller() or not string.find(debug.traceback(), 'ControlModule')) then
			return oldNameCall(self, ...);
		end;

		-- local args = {...};

		-- if(string.find(debug.traceback(), 'KeyHandler')) then
		-- warn('kay handler call __namecall', method);
		-- end;

		if(isGaia) then
			local oldGetKey = getKey;

			local function getKey(name, pwd)
				local cachedRemote = cachedRemotes[name];

				if(cachedRemote and cachedRemote.Parent and (cachedRemote.Parent == requests or cachedRemote.Parent == myRemotes)) then
					return cachedRemote;
				end;

				cachedRemotes[name] = coroutine.wrap(oldGetKey)(name, pwd);
				return cachedRemotes[name];
			end;

			--print(debug.traceback());
			if(debugMode) then
				local getRemotes = (function()
					tango = getKey(TANGO_PASSWORD, 'plum');

					setRemote('tango', tango);
					setRemote('fallDamage',getKey(APPLY_FALL_DAMAGE_PASSWORD, 'plum'));
					setRemote('dodge', getKey(DODGE_PASSWORD, 'plum'));
					setRemote('manaCharge', getKey(SET_MANA_CHARGE_STATE_PASSWORD, 'plum'));
					setRemote('dialog', getKey(POST_DIALOGUE_PASSWORD, 'plum'));
					setRemote('changeArea', getKey('SetCurrentArea', 'plum'));
				end);

				coroutine.wrap(getRemotes)();
			else
				tango = getKey(TANGO_PASSWORD, 'plum');

				setRemote('tango', tango);
				setRemote('fallDamage',getKey(APPLY_FALL_DAMAGE_PASSWORD, 'plum'));
				setRemote('dodge', getKey(DODGE_PASSWORD, 'plum'));
				setRemote('manaCharge', getKey(SET_MANA_CHARGE_STATE_PASSWORD, 'plum'));
				setRemote('dialog', getKey(POST_DIALOGUE_PASSWORD, 'plum'));
				setRemote('changeArea', getKey('SetCurrentArea', 'plum'));
			end;
		else
			local character = oldIndex(LocalPlayer, 'Character');
			local characterHandler = character and FindFirstChild(character, 'CharacterHandler');
			local remotes = characterHandler and FindFirstChild(characterHandler, 'Remotes');

			disableenvprotection();

			setrawmetatable(false, {__index = function(_, p)
				if (p == 'Parent') then
					return true;
				elseif (p == 'IsDescendantOf') then
					return true;
				end;
			end});

			setRemote('tango', pcall(getKey, 'Drop', 'apricot'));
			setRemote('fallDamage', pcall(getKey, 'FallDamage', 'apricot'));
			setRemote('dodge', remotes and FindFirstChild(remotes, 'Dash'));
			setRemote('manaCharge', pcall(getKey, 'Charge', 'apricot'));
			setRemote('dialog', pcall(getKey, 'SendDialogue', 'apricot'));
			setRemote('dolorosa', pcall(getKey, 'Dolorosa', 'apricot'));

			setrawmetatable(false, nil);

			enableenvprotection();
		end;

		remotes.loadKeys = false;

		task.delay(2, function()
			remotes.loadKeys = true;
		end);

		return oldNameCall(self, ...);
	end);

	local function onCharAdded(character)
		character.ChildRemoved:Connect(function(obj)
			if(obj.Name == 'Sprinting') then
				sprinting = false;
			end;
		end);

		repeat
			task.wait();
		until character:FindFirstChild('CharacterHandler') and character.CharacterHandler:FindFirstChild('Input');

		remotes.loadKeys = true;
	end;

	LocalPlayer.CharacterAdded:Connect(onCharAdded)

	if (LocalPlayer.Character) then
		onCharAdded(LocalPlayer.Character);
	end;
end;

do -- // Set Spells Values
	spellValues = {
		["Secare"] = {
			[1] = {
				["max"] = 95,
				["min"] = 90
			}
		},
		["Maledicta Terra"] = {
			[1] = {
				["max"] = 100,
				["min"] = 20
			}
		},
		["Better Mori"] = {
			[1] = {
				["max"] = 100,
				["min"] = 0
			},
			[2] = {
				["max"] = 100,
				["min"] = 0
			}
		},
		["Contrarium"] = {
			[1] = {
				["max"] = 95,
				["min"] = 80
			},
			[2] = {
				["max"] = 90,
				["min"] = 70
			}
		},
		["Mederi"] = {
			[1] = {
				["max"] = 100,
				["min"] = 0
			}
		},
		["Scrupus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 30
			}
		},
		["Intermissum"] = {
			[1] = {
				["max"] = 100,
				["min"] = 70
			}
		},
		["Gourdus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 75
			}
		},
		["Inferi"] = {
			[1] = {
				["max"] = 30,
				["min"] = 10
			}
		},
		["Custos"] = {
			[1] = {
				["max"] = 65,
				["min"] = 45
			}
		},
		["Gelidus"] = {
			[1] = {
				["max"] = 95,
				["min"] = 80
			},
			[2] = {
				["max"] = 100,
				["min"] = 80
			}
		},
		["Telorum"] = {
			[1] = {
				["max"] = 90,
				["min"] = 80
			},
			[2] = {
				["max"] = 80,
				["min"] = 70
			}
		},
		["Viribus"] = {
			[1] = {
				["max"] = 35,
				["min"] = 25
			},
			[2] = {
				["max"] = 70,
				["min"] = 60
			}
		},
		["Hoppa"] = {
			[1] = {
				["max"] = 60,
				["min"] = 40
			},
			[2] = {
				["max"] = 60,
				["min"] = 50
			}
		},
		["Velo"] = {
			[1] = {
				["max"] = 100,
				["min"] = 70
			},
			[2] = {
				["max"] = 60,
				["min"] = 40
			}
		},
		["Pondus"] = {
			[1] = {
				["max"] = 90,
				["min"] = 70
			},
			[2] = {
				["max"] = 30,
				["min"] = 20
			}
		},
		["Verdien"] = {
			[1] = {
				["max"] = 100,
				["min"] = 75
			},
			[2] = {
				["max"] = 85,
				["min"] = 75
			}
		},
		["Trahere"] = {
			[1] = {
				["max"] = 85,
				["min"] = 75
			}
		},
		["Dominus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 50
			}
		},
		["Armis"] = {
			[1] = {
				["max"] = 60,
				["min"] = 40
			},
			[2] = {
				["max"] = 80,
				["min"] = 70
			}
		},
		["Ligans"] = {
			[1] = {
				["max"] = 80,
				["min"] = 63
			}
		},
		["Shrieker"] = {
			[1] = {
				["max"] = 50,
				["min"] = 30
			}
		},
		["Celeritas"] = {
			[1] = {
				["max"] = 90,
				["min"] = 70
			},
			[2] = {
				["max"] = 80,
				["min"] = 70
			}
		},
		["Hystericus"] = {
			[1] = {
				["max"] = 90,
				["min"] = 75
			},
			[2] = {
				["max"] = 35,
				["min"] = 15
			}
		},
		["Snarvindur"] = {
			[1] = {
				["max"] = 75,
				["min"] = 60
			},
			[2] = {
				["max"] = 30,
				["min"] = 20
			}
		},
		["Percutiens"] = {
			[1] = {
				["max"] = 70,
				["min"] = 60
			},
			[2] = {
				["max"] = 80,
				["min"] = 70
			}
		},
		["Furantur"] = {
			[1] = {
				["max"] = 80,
				["min"] = 60
			}
		},
		["Nosferatus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 90
			}
		},
		["Reditus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 50
			}
		},
		["Floresco"] = {
			[1] = {
				["max"] = 100,
				["min"] = 90
			},
			[2] = {
				["max"] = 95,
				["min"] = 80
			}
		},
		["Howler"] = {
			[1] = {
				["max"] = 80,
				["min"] = 60
			}
		},
		["Manus Dei"] = {
			[1] = {
				["max"] = 95,
				["min"] = 90
			},
			[2] = {
				["max"] = 60,
				["min"] = 50
			}
		},
		["Fons Vitae"] = {
			[1] = {
				["max"] = 100,
				["min"] = 75
			},
			[2] = {
				["max"] = 100,
				["min"] = 75
			}
		},
		["Ignis"] = {
			[1] = {
				["max"] = 95,
				["min"] = 80
			},
			[2] = {
				["max"] = 60,
				["min"] = 50
			}
		},
		["Globus"] = {
			[1] = {
				["max"] = 100,
				["min"] = 70
			}
		},
		["Fimbulvetr"] = {
			[1] = {
				["max"] = 92,
				["min"] = 84
			},
			[2] = {
				["max"] = 80,
				["min"] = 70
			}
		},
		["Perflora"] = {
			[1] = {
				["max"] = 90,
				["min"] = 70
			},
			[2] = {
				["max"] = 50,
				["min"] = 30
			}
		},
		["Gate"] = {
			[1] = {
				["max"] = 83,
				["min"] = 75
			},
			[2] = {
				["max"] = 83,
				["min"] = 75
			}
		},
		["Nocere"] = {
			[1] = {
				["max"] = 85,
				["min"] = 70
			},
			[2] = {
				["max"] = 85,
				["min"] = 70
			}
		},
		["Sagitta Sol"] = {
			[1] = {
				["max"] = 65,
				["min"] = 50
			},
			[2] = {
				["max"] = 60,
				["min"] = 40
			}
		},
		["Claritum"] = {
			[1] = {
				["max"] = 100,
				["min"] = 90
			}
		},
		["Trickstus"] = {
			[1] = {
				["max"] = 70,
				["min"] = 30
			},
			[2] = {
				["max"] = 50,
				["min"] = 30
			}
		}
	}
end;

do -- // Captcha Bypass
	local function readCSG(union)
		local unionData = select(2, getpcdprop(union));
		local unionDataStream = unionData;

		local function readByte(n)
			local returnData = unionDataStream:sub(1, n);
			unionDataStream = unionDataStream:sub(n+1, #unionDataStream);

			return returnData;
		end;

		readByte(51); -- useless data

		local points = {};

		while #unionDataStream > 0 do
			readByte(20) -- trash
			readByte(20) -- trash 2

			local vertSize =  string.unpack('ii', readByte(8));

			for i = 1, (vertSize/3) do
				local x, y, z = string.unpack('fff', readByte(12))
				table.insert(points, union.CFrame:ToWorldSpace(CFrame.new(x, y, z)).Position);
			end;

			local faceSize = string.unpack('I', readByte(4));
			readByte(faceSize * 4);
		end;

		return points;
	end;

	function solveCaptcha(union)
		local worldModel = Instance.new('WorldModel');
		worldModel.Parent = CoreGui;

		local newUnion = union:Clone()
		newUnion.Parent = worldModel;

		local cameraCFrame = gethiddenproperty(union.Parent, 'CameraCFrame');
		local points = readCSG(union);

		local rangePart = Instance.new('Part');
		rangePart.Parent = worldModel;
		rangePart.CFrame = cameraCFrame:ToWorldSpace(CFrame.new(-8, 0, 0))
		rangePart.Size = Vector3.new(1, 100, 100);

		local model = Instance.new('Model', worldModel);
		local baseModel = Instance.new('Model', worldModel);

		baseModel.Name = 'Base';
		model.Name = 'Final';

		for i, v in next, points do
			local part = Instance.new('Part', baseModel);
			part.CFrame = CFrame.new(v);
			part.Size = Vector3.new(0.1, 0.1, 0.1);
		end;

		local seen = false;

		for i = 0, 100 do
			rangePart.CFrame = rangePart.CFrame * CFrame.new(1, 0, 0)

			local overlapParams = OverlapParams.new();
			overlapParams.FilterType = Enum.RaycastFilterType.Include;
			overlapParams.FilterDescendantsInstances = {baseModel};

			local bob = worldModel:GetPartsInPart(rangePart, overlapParams);
			if(seen and #bob <= 0) then break end;

			for i, v in next, bob do
				seen = true;

				local new = v:Clone();

				new.Parent = model;
				new.CFrame = CFrame.new(new.Position);
			end;
		end;

		for i, v in next, model:GetChildren() do
			v.CFrame = v.CFrame * CFrame.Angles(0, math.rad(union.Orientation.Y), 0);
		end;

		local shorter, found = math.huge, '';
		local result = model:GetExtentsSize();

		local values = {
			['Arocknid'] = Vector3.new(11.963972091675, 6.2284870147705, 12.341609954834),
			['Howler'] = Vector3.new(2.904595375061, 7.5143890380859, 6.4855442047119),
			['Evil Eye'] = Vector3.new(6.7253036499023, 6.2872190475464, 11.757738113403),
			['Zombie Scroom'] = Vector3.new(4.71413230896, 4.400146484375, 4.7931442260742),
			['Golem'] = Vector3.new(17.123439788818, 21.224365234375, 6.9429664611816),
		};

		for i, v in next, values do
			if((result - v).Magnitude < shorter) then
				found = i;
				shorter = (result - v).Magnitude;
			end;
		end;

		worldModel:Destroy();
		worldModel = nil;

		return found;
	end;
end;

do -- // Player Classes
	playerClassesList = {
		["Warrior"] = {
			["Active"] = {"Pommel Strike", "Action Surge"};
			["Classes"] = {
				["Sigil Knight"] = {"Thunder Charge", Level = 1};
				["Blacksmith"] = {"Remote Smithing", "Grindstone", "Shockwave", Level = 1};
				["Greatsword"] = {"Greatsword Training", "Stun Resistance", Level = 1};
				["Sigil Knight Commander"] = {"Charged Blow", "White Flame Charge", "Hyper Body", Level = 2};
				["Lapidarist"] = {"Hammer Training", "Improved Grindstone", "Gem Mastery", "Gem Abilities", Level = 2},
				["AbyssWalker"] = {"Wrathful Leap", "Abyssal Scream", Level = 2};
				["Wraith Knight"] = {"Wraith Training", Level = 2};
				["Pilgrim Knight"] = {"Chain of Fate", "Rod of Narsa", "Pasmarkinti", Level = 3};
				["Abyss Dancer"] = {"Great Cyclone", "Spinning Soul", "Void Slicer", "Deflecting Spin", Level = 3};
				["Reaper"] = {"Mirror", "Chase", "Hunt", "Soul Burst", Level = 3};
			}
		};
		["Pit Fighter"] = {
			["Active"] = {"Serpent Strike", "Triple Strike"};
			["Classes"] = {
				["Dragon Knight"] = {"Spear Crusher", "Dragon Roar", "Dragon Blood", Level = 1};
				["Church Knight"] = {"Church Knight Helmet", "Impale", "Light Piercer", Level = 1};
				["Dragon Slayer"] = {"Wing Soar", "Thunder Spear Crash", "Dragon Awakening", Level = 2};
				["Deep Knight"] = {"Deep Sacrifice", "Leviathan Plunge", "Chain Pull", Level = 2};
				["Dragon Rider"] = {"Heroic Volley", "Call Drake", "Ensnaring Strike", "Justice Spears", Level = 3};
				["Abomination"] = {"Tethering Lance", "Void Spear", "Aura of Despair", "Soul Siphon", Level = 3};
			}
		};
		["Scholar"] = {
			["Active"] = {"FastSigns", "CurseBlock", "WiseCasting"};
			["Classes"] = {
				["Illusionist"] = {"Custos", "Claritum", "Observe", Level = 1};
				["Botanist"] = {"Fons Vitae", "Verdien", "Life Sense", Level = 1};
				["Necromancer"] = {"Inferi", "Reditus", "Ligans", Level = 1};
				["Master Illusionist"] = {"Globus", "Intermissium", "Dominus", Level = 2};
				["Druid"] = {"Snap Verdien", "Snap Fons Vitae", "Perflora", "Snap Perflora", "Floresco", "Snap Floresco", Level = 2};
				["Master Necromancer"] = {"Secare", "Furantur", "Command Monsters", "Howler Summoning", Level = 2};
				["Uber Illusionist"] = {"Doube", "Compress", "Terra Rebus", Level = 3};
				["Monster Hunter"] = {"Coercere", "Liber", "Scribo", Level = 3};
				["Crystal Cage"] = {"Mirgeti", "Krusa", "Spindulys", Level = 3};
				["Worm Prophet"] = {"Worm Bombs", "Worm Blast", "Call of the Dead", Level = 3};
			}
		};
		["Thief"] = {
			["Active"] = {"Dagger Throw", "Pickpocket", "Trinket Steal", "Lock Manipulation"};
			["Classes"] = {
				["Spy"] = {"Interrogation", Level = 1};
				["Assassin"] = {"Lethality", "Bane", "Triple Dagger Throw", Level = 1};
				["Whisperer"] = {"Elegant Slash", "The Shadow", "Needle's Eye", "The Wraith", "The Soul", Level = 2};
				["Cadence"] = {"Music Meter", "Faster Meter Charge", "Feel Invincible", Level = 2};
				["Faceless"] = {"Shadow Step", "Chain Lethality", "Improved Bane", "Faceless", Level = 2};
				["Shinobi"] = {"Resurrection", Level = 2};
				["Duelist"] = {"Mana Grenade", "Auto Reload", "Duelist Dash", "Bomb Jump", "Bullseye", Level = 3};
				["Uber Bard"] = {"Inferno March", "Galecaller's Melody", "Bad Time Symphony", "Theme of Reversal", Level = 3};
				["Friendless One"] = {"Shadow Buddy", "Falling Darkness", "Flash of Darkness", Level = 3};
				["Shura"] = {"Rising Cloud", "Autumn Rain", "Cruel Wind", Level = 3};
			};
		};
		["Monk"] = {
			Level = 1,
			["Active"] = {"Monastic Stance"};
			["Classes"] = {
				["Dragon Sage"] = {"Lightning Drop", "Lightning Elbow", "Lightning Dash", "Dragon Static", Level = 2};
				["Vhiunese Monk"] = {"Thundering Leap", "Seismic Toss", "Electric Smite", Level = 3};
			};
		};
		["Akuma"] = {
			["Active"] = {"Leg Breaker", "Spin Kick", "Rising Dragon", Level = 1};
			["Classes"] = {
				["Oni"] = {"Demon Flip", "Axe Kick", "Demon Step", Level = 2};
				["Uber Oni"] = {"Consuming Flames", "Rampage", "Augimas M1 & M2", "Axe Kick M2", Level = 3}
			};
		};
	};
end;

--do -- // AA Gun Counter
--	local aaGunCounterGUI = library:Create('ScreenGui', {
--		Enabled = false;
--	});

--	if(gethui) then
--		aaGunCounterGUI.Parent = gethui();
--	else
--		syn.protect_gui(aaGunCounterGUI);
--		aaGunCounterGUI.Parent = CoreGui;
--	end;

--	local aaGunCounterText = library:Create('TextLabel', {
--		Parent = aaGunCounterGUI,
--		RichText = true,
--		TextSize = 25,
--		Text = '',
--		BackgroundTransparency = 1,
--		Position = UDim2.new(0.5, 0, 0, 50),
--		AnchorPoint = Vector2.new(0.5, 0.5),
--		Size = UDim2.new(0, 200, 0, 50),
--		Font = Enum.Font.SourceSansSemibold,
--		TextColor3 = Color3.fromRGB(255, 255, 255)
--	});

--	local params = RaycastParams.new();
--	params.FilterType = Enum.RaycastFilterType.Blacklist;
--	params.FilterDescendantsInstances = {workspace.Live, workspace:FindFirstChild('NPCs') or Instance.new('Folder'), workspace:FindFirstChild('AreaMarkers') or Instance.new('Folder')};

--	local flying        = false;
--	local lastFly       = tick();
--	local onGroundAt    = tick();
--	local flyStartedAt  = lastFly;

--	function aaGunCounter(toggle)
--		aaGunCounterGUI.Enabled = toggle;

--		if(not toggle) then
--			maid.aaGunCounter = nil;
--			return;
--		end;

--		maid.aaGunCounter = RunService.RenderStepped:Connect(function()
--			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
--			if(not rootPart) then return end;

--			local isOnGround = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), params)
--			if(not isOnGround) then
--				if(not flying) then
--					flyStartedAt = tick();
--				end;
--				flying = true;
--				lastFly = tick();
--			else
--				if(flying) then
--					onGroundAt = tick();
--				end;
--				flying = false;
--			end;

--			local timeSinceLastFly = tick() - flyStartedAt;
--			local timeOnGround = tick() - onGroundAt;
--			local shouldFly = (timeOnGround >= 6 and (flying and timeSinceLastFly < 5 or not flying and true));

--			local red, green = 'rgb(255, 0, 0)', 'rgb(0, 255, 0)'
--			local onGroundText = string.format('<font color="%s"> %s </font>', isOnGround and green or red, isOnGround and 'Yes' or 'No')
--			local timeOnGroundText = string.format('<font color="%s"> %.01f </font>', flying and red or green, flying and -timeSinceLastFly or timeOnGround);
--			local canFlyText = string.format('<font color="%s"> %s </font>', shouldFly and green or red, shouldFly and 'Yes' or 'No');

--			aaGunCounterText.Text = string.format('On Ground: %s\nTime on ground: %s\nCan Fly (Recommended): %s', onGroundText, timeOnGroundText, canFlyText);
--		end);
--	end;
--end;

local function removeGroup(instance, list)
	for _, listObject in next, list do
		local foundListObject = instance:FindFirstChild(listObject)
		if(foundListObject) then
			foundListObject:Destroy();
		end;

		CollectionService:RemoveTag(instance, listObject);
	end;
end;

local function isUnderWater()
	local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
	if(not head) then return end;

	local min = head.Position - (0.5 * head.Size);
	local max = head.Position + (0.5 * head.Size);

	local region = Region3.new(min, max):ExpandToGrid(4);

	local material = workspace.Terrain:ReadVoxels(region,4)[1][1][1];

	return material == Enum.Material.Water;
end;

local function isKnocked()
	local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
	if(head and head:FindFirstChild('Bone')) then
		return true;
	end;
end;

function noClip(toggle)
	if(not toggle) then return end;

	repeat
		local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");

		if(Humanoid and not isUnderWater() and not isKnocked()) then
			for _, part in next, LocalPlayer.Character:GetDescendants() do
				if(part:IsA('BasePart')) then
					part.CanCollide = false;
				end;
			end;
		end;
		Humanoid:ChangeState("Jumping");
		Humanoid.JumpPower = 0;
		RunService.Stepped:Wait();
	until not getgenv().noClip;
	local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");

	if (not Humanoid) then return; end
	LocalPlayer.Character.Humanoid.JumpPower = 45;
end;

function noInjuries(toggle)
	if(not toggle) then return end;

	repeat
		local character = LocalPlayer.Character;
		local boosts = character and character:FindFirstChild('Boosts');
		if(character) then
			removeGroup(character, injuryObjects);

			if(boosts) then
				removeGroup(boosts, injuryObjects);
			end;
		end;
		task.wait();
	until not getgenv().noInjuries;
end;

function noFog(toggle)
	if(not toggle) then return end;
	local oldFogStart, oldFogEnd = Lighting.FogStart, Lighting.FogEnd;

	repeat
		Lighting.FogStart = 99999;
		Lighting.FogEnd = 99999;
		task.wait();
	until not getgenv().noFog;

	Lighting.FogStart, Lighting.FogEnd = oldFogStart, oldFogEnd;
end;

function speedHack(toggle)
	if(not toggle) then
		RunService:UnbindFromRenderStep('speedHack')
		return;
	end;

	RunService:BindToRenderStep('speedHack',997,function()
		local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
		if (not rootPart) then return end;

		local camera = workspace.CurrentCamera;
		if (not camera) then return end;
		if(getgenv().fly) then
			if speedHackBV and speedHackBV.Parent then
				speedHackBV:Destroy()
			end
			return;
		end;

		speedHackBV = (speedHackBV.Parent and speedHackBV) or Instance.new('BodyVelocity');
		speedHackBV.Parent = rootPart;
		speedHackBV.MaxForce = Vector3.new(100000, 0, 100000);
		speedHackBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * getgenv().speedhackSpeed);
	end)
end;

function fly(toggle)
	if not toggle then
		RunService:UnbindFromRenderStep('fly')
		return
	end

	RunService:BindToRenderStep('fly',998,function()
		local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		if (not rootPart) then return end;

		local camera = workspace.CurrentCamera;
		if (not camera) then return end;

		flyBV = (flyBV.Parent and flyBV) or Instance.new('BodyVelocity');
		flyBV.Parent = rootPart;
		flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
		flyBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * getgenv().flySpeed);
	end)
end;

function antiFire(toggle)
	if not toggle then
		getgenv().antiFire = nil
		return
	end
	getgenv().antiFire = toggle

	repeat
		local Character = LocalPlayer.Character;
		if(Character and Character:FindFirstChild('Burning') and dodge) then
			if(isGaia) then
				dodge:FireServer({4, math.random()});
			else
				dodge:FireServer('back', workspace.CurrentCamera);
			end;
		end;

		Heartbeat:Wait();
	until not getgenv().antiFire;
end;

function removeKillBricks(toggle)
	if(not toggle) then
		RunService:UnbindFromRenderStep('removeKillBricks')
	else
		RunService:BindToRenderStep('removeKillBricks',999,function()
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if(not rootPart) then return end;

			local inDanger = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger');

			if(rootPart.Position.Y <= -550 and not getgenv().fly and inDanger) then
				fly(true)
				makeNotification('LMAO','You were about to die, so script automatically enabled fly to prevent you from dying :sungl:');
			end;
		end)
	end;

	for i,v in next, killBricks do
		v.Parent = not toggle and workspace or nil;
	end;
end;

function maxZoom(toggle)
	for _, v in next, getconnections(LocalPlayer.Changed) do
		v:Disable();
	end;

	LocalPlayer.CameraMaxZoomDistance = toggle and 9e9 or 50;

	for _, v in next, getconnections(LocalPlayer.Changed) do
		v:Enable();
	end;
end;

function respawn()
	local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
	if(not humanoid) then return end;

	humanoid.Health = 0;
end;

function disableAmbientColors(toggle)
	if(not toggle) then
		RunService:UnbindFromRenderStep('disableAmbientColors')
		task.wait();
		Lighting.areacolor.Enabled = true;
		return;
	end;
	
	RunService:BindToRenderStep('disableAmbientColors',990,function()
		if(not Lighting:FindFirstChild('areacolor')) then return end;
		Lighting.areacolor.Enabled = false;
	end)
end;

function antiHystericus(toggle)
	local antiHystericusList = {'NoControl', 'Confused'};
	if(not toggle) then return end;

	repeat
		task.wait();
		if(not LocalPlayer.Character) then continue end;

		removeGroup(LocalPlayer.Character, antiHystericusList);
	until not getgenv().antiHystericus;
end;

function spectatePlayer(playerName)
	playerName = tostring(playerName);
	local player = findPlayer(playerName);
	local playerHumanoid = player and player.Character and player.Character:FindFirstChildOfClass('Humanoid');

	if(playerHumanoid) then
		workspace.CurrentCamera.CameraType = Enum.CameraType.Custom;
		workspace.CurrentCamera.CameraSubject = playerHumanoid;
	end;
end;

local furnaceFolder;
local allFurnaces = {};

do -- // Get Ingredient Folder
	for i, v in next, workspace:GetChildren() do
		if(v:IsA("Folder")) then
			local union = v:FindFirstChild('UnionOperation');
			if(union) then
				ingredientsFolder = v;
				break;
			end;
		end;
	end;
end;

do
	game.Workspace.ChildAdded:Connect(function(obj)
		if(obj.Name == 'PortableFurnace' and obj:IsA('Model')) then
			table.insert(allFurnaces, obj);
			obj.Destroying:Connect(function()
				table.remove(allFurnaces, table.find(allFurnaces, obj));
			end);
		end;
	end)
end;

do -- // Auto Pickup
	local trinkets = {};
	local ingredients = {};

	local function onChildAdded(obj)
		local isIngredient = obj.Parent == ingredientsFolder;
		local isTrinket = not isIngredient;
		local t = isIngredient and ingredients or trinkets;

		if(isIngredient or (obj:FindFirstChild('Part') and obj.Part.Size == Vector3.new(1.5, 1.5, 1.5))) then
			table.insert(t, obj);

			local propertyWatched = isIngredient and 'Transparency' or 'Parent';
			local connection;
			connection = obj:GetPropertyChangedSignal(propertyWatched):Connect(function()
				task.wait();
				if(obj.Parent and isIngredient or not connection) then return end;

				if(obj:IsDescendantOf(game)) then return; end

				connection:Disconnect();
				connection = nil;

				table.remove(t, table.find(t, obj));
			end);
		end;
	end;

	library.OnLoad:Connect(function()
		if (library.flags.collectorAutoFarm) then
			warn('[Auto Pickup] Not enabling cuz collector bot is on');
			return;
		end;

		if(ingredientsFolder) then
			for _, obj in next, ingredientsFolder:GetChildren() do
				task.spawn(onChildAdded, obj);
			end;

			ingredientsFolder.ChildAdded:Connect(onChildAdded);
		end;

		for _, obj in next, workspace:GetChildren() do
			task.spawn(onChildAdded, obj);
		end;

		workspace.ChildAdded:Connect(onChildAdded);
	end);

	local function makeAutoPickup(maidName, t)
		return function(toggle)
			if(not toggle) then
				maid[maidName] = nil;
				return;
			end;

			local lastUpdate = 0;

			maid[maidName] = RunService.RenderStepped:Connect(function()
				local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
				if(not rootPart or tick() - lastUpdate < 0.2) then return end;

				lastUpdate = tick();

				for i,v in next, t do
					if((rootPart.Position - v.Position).Magnitude <= 25) then
						local clickDetector = v:FindFirstChildWhichIsA('ClickDetector', true);
						if(clickDetector and clickDetector.MaxActivationDistance <= 100) then
							fireclickdetector(clickDetector, 1);
						end;
					end;
				end;
			end);
		end;
	end;

	autoPickup = makeAutoPickup('autoPickup', trinkets);
	autoPickupIngredients = makeAutoPickup('autoPickupIngredients', ingredients);
end;

function autoSmelt(toggle)
	if(not toggle) then return end;

	if (not furnaceFolder) then
		furnaceFolder = workspace:FindFirstChild('Bed', true);
		furnaceFolder = furnaceFolder and furnaceFolder.Parent;
	end;

	local lastSmeltAttempt;
	repeat
		task.wait();
		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass('Humanoid');
		if(not humanoid or not furnaceFolder or not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('HumanoidRootPart')) then continue end;

		local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		local isNearFurnace = false;
		local currentFurnace;

		for i, v in next, furnaceFolder:GetChildren() do
			if(v.Name == 'Furnace' and v:IsA('BasePart') and (v.Position - rootPart.Position).Magnitude <= 25) then
				isNearFurnace = true;
				currentFurnace = v;
				break;
			end;
		end;

		if (not currentFurnace) then
			for _, v in next, allFurnaces do
				if ((v.PrimaryPart.Position - rootPart.Position).Magnitude <= 25) then
					local furnace = v:FindFirstChild('Furnace');
					if (not furnace) then continue end;

					warn('wee', furnace);
					isNearFurnace = true;
					currentFurnace = furnace;
					break;
				end;
			end;
		end;

		if(not isNearFurnace) then continue; end;

		for _, v in next, LocalPlayer.Backpack:GetChildren() do
			if (not library.flags.autoSmelt) then break end;
			if (not v:FindFirstChild('Ore')) then continue end;
			local handle = v:FindFirstChild('Handle');
			if (not handle) then continue end;

			firetouchinterest(handle, currentFurnace, 0);
			lastSmeltAttempt = tick();
			humanoid:EquipTool(v);
			repeat task.wait() until v.Parent == nil or tick() - lastSmeltAttempt >= 2;
			firetouchinterest(handle, currentFurnace, 1);
		end;
	until not library.flags.autoSmelt;
end;

function autoSell(toggle)
	if(not toggle) then
		return;
	end;

	local lastUpdate = 0;
	local artifactsList = {'Phoenix Down', 'Lannis\'s Amulet', 'Spider Cloak', 'Philosopher\'s Stone', 'Ice Essence', 'Howler Friend', 'Amulet of the White King', 'Fairfrozen', 'Scroom Key', 'Nightstone', 'Rift Gem', 'Scroll of Manus Dei', 'Scroll of Fimbulvetr', 'Mysterious Artifact'};

	repeat
		task.wait()
		if(tick() - lastUpdate < 1) then continue end;

		local merchant = getCurrentNpc({'Merchant', 'Pawnbroker'});
		if(not merchant) then continue end;

		local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
		if(not humanoid) then continue end;

		if(library.flags.autoSellValues.Scrolls or library.flags.autoSellValues.Gems or library.flags.autoSellValues.Swords) then
			local scroll;

			for i, v in next, LocalPlayer.Backpack:GetChildren() do
				if(table.find(artifactsList, v.Name)) then continue end;
				if(v:FindFirstChild('SpellType') and library.flags.autoSellValues.Scrolls or v:FindFirstChild('Gem') and library.flags.autoSellValues.Gems or v:FindFirstChild('Smithed') and library.flags.autoSellValues.Swords) then
					scroll = v;
				end;
			end;

			if(not scroll) then continue end;
			lastUpdate = tick();

			humanoid:EquipTool(scroll);
			fireclickdetector(merchant.ClickDetector, 1);
			task.wait(0.2);
			dialog:FireServer({choice = 'Could you appraise this for me?'});
			task.wait(0.2);
			dialog:FireServer({choice = 'It\'s a deal.'});
			task.wait(0.2);
			dialog:FireServer({exit = true});

			continue;
		end;
	until not library.flags.autoSell;
end;

function wipe()
	fallDamage:FireServer({math.random(), 3})
	task.wait(1);
	if(LocalPlayer.Character:FindFirstChild('Head')) then
		LocalPlayer.Character.Head:Destroy();
	end;
end;

function toggleTrinketEsp(toggle)
	if(not toggle) then
		maid.trinketEsp = nil;
		trinketEspBase:Disable();
		return;
	end;

	maid.trinketEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
		debug.profilebegin('Trinket Esp Update');
		trinketEspBase:UpdateAll();
		debug.profileend();
	end);
end;

function toggleIngredientsEsp(toggle)
	if(not toggle) then
		maid.ingredientEsp = nil;
		ingredientEspBase:Disable();
		return;
	end;

	maid.ingredientEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
		debug.profilebegin('Ingredient Esp Update');
		ingredientEspBase:UpdateAll();
		debug.profileend();
	end);
end;

function goToGround()
	local params = RaycastParams.new();
	params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs, workspace.AreaMarkers};
	params.FilterType = Enum.RaycastFilterType.Exclude;

	local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
	if (not rootPart) then return end;

	-- setclipboard(tostring(Character.HumanoidRootPart.Position));
	local floor = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), params);
	if(not floor) then return end;

	rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -(rootPart.Position.Y - floor.Position.Y) + 3, 0);
	-- rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z);
end;

function infMana(toggle)
	if (not toggle) then
		RunService:UnbindFromRenderStep('infMana')
		return;
	end;

	RunService:BindToRenderStep('infMana',999,function()
		local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
		if (not mana) then return end;

		mana.Value = 100;
	end)
end;

function flyOwnership(toggle)
	if (not toggle) then
		RunService:UnbindFromRenderStep('flyOwnership')
		return;
	end;
	
	RunService:BindToRenderStep('flyOwnership',999,function()
		local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		if (not rootPart) then return end;

		local bone = rootPart and rootPart:findFirstChild('Bone');

		if (bone and bone:FindFirstChild('Weld')) then
			bone.Weld:Destroy();
		end;
	end)
end;

local function initEspStuff()
	do -- // Player Stuff
		local blacklistedHouses = {'Mudock', 'Mudockfat', 'Archfat', 'Female'};
		local mudockList = {};

		local function isInGroup(player, groupId)
			local suc, err = pcall(player.IsInGroup, player, groupId);

			if(not suc) then return false end;
			return err;
		end;

		local function addIllusionist(player)
			if(illusionists[player]) then return end;
			illusionists[player] = true;
			makeNotification('Illusionist Alert', string.format('[%s] Has joined your game', player.Name), true);
		end;

		local artifactsList = {'Phoenix Down', 'Lannis\'s Amulet', 'Spider Cloak', 'Philosopher\'s Stone', 'Ice Essence', 'Howler Friend', 'Amulet of the White King', 'Fairfrozen', 'Scroom Key', 'Nightstone', 'Rift Gem', 'Scroll of Manus Dei', 'Scroll of Fimbulvetr', 'Mysterious Artifact'};

		local function onPlayerAdded(player)
			if(player == LocalPlayer) then return end;

			local seen = {};

			local function onCharacterAdded(character)
				local backpack = player:WaitForChild('Backpack');
				local spectating = false;

				local function onChildAddedPlayer(obj)
					if (getgenv().artifactNotifier and (table.find(artifactsList, obj.Name) or obj:FindFirstChild('Artifact')) and not table.find(seen, obj.Name) and obj.Parent == backpack) then
						table.insert(seen, obj.Name);
						makeNotification('ARTIFACT',string.format('%s has %s', player.Name, obj.Name))
					end;

					if(obj.Name ~= 'Observe') then return end;
					addIllusionist(player);

					if(not getgenv().illusionistNotifier) then return end;
					print(player.Name, obj.Parent == character and 'in character' or 'in backpack');

					if(obj.Parent ~= backpack and not spectating) then
						spectating = true;
						makeNotification('Spectate Alert', string.format('[%s] Started spectating', player.Name), true);
					end;
				end;

				local function onChildRemovedPlayer(obj)
					if(obj.Name ~= 'Observe' or not spectating) then return end;
					spectating = false;
					makeNotification('Spectate Alert', string.format('[%s] Stopped spectating', player.Name), true);
				end;
				
				backpack.ChildAdded:Connect(onChildAddedPlayer)
				character.ChildAdded:Connect(onChildAddedPlayer)
				character.ChildRemoved:Connect(onChildRemovedPlayer);

				local humanoid = character:WaitForChild('Humanoid');
				local head = character:WaitForChild('Head');
				local currentHealth = humanoid.Health;
			end;

			if(player.Character) then
				task.spawn(onCharacterAdded, player.Character);
			end;

			player.CharacterAdded:Connect(onCharacterAdded);

			if isInGroup(player, 4556484) then
				moderatorInGame = true;
				allMods[player] = true;

				makeNotification('Mod Alert', string.format('[%s] Has joined your game.', player.Name), true);
			end;

			if(table.find(blacklistedHouses, player:GetAttribute('LastName') or 'Unknown')) then
				makeNotification('Mudock Alert', string.format('[%s] Has joined your game', player.Name), true);
				mudockList[player] = true;
			end;
		end;

		local function onPlayerRemoving(player)
			if(allMods[player]) then
				moderatorInGame = false;
				allMods[player] = nil;
				makeNotification('Mod Alert', string.format('%s left the game', tostring(player)), true);
			end;

			if(illusionists[player]) then
				makeNotification('Illusionist', string.format('[%s] Has left your game', player.Name), true);
				illusionists[player] = nil;
			end;

			if(mudockList[player]) then
				makeNotification('Mudock Alert', string.format('%s Has left your game', tostring(player)), true);
				mudockList[player] = nil;
			end;
		end;

		for i, v in next, Players:GetPlayers() do
			task.spawn(onPlayerAdded, v);
		end;

		Players.PlayerAdded:Connect(onPlayerAdded);
		Players.PlayerRemoving:Connect(onPlayerRemoving);
	end;
	
	local function getId(id)
		return id:gsub('%%20', ''):gsub('%D', '');
	end;

	local function findInTable(t, index, value)
		for i, v in next, t do
			if v[index] == value then
				return v;
			end;
		end;
	end;

	local opalColor = Vector3.new(1, 1, 1);

	local function getTrinketType(v) -- // This code is from the old source too lazy to remake it as this one works properly
		if (v.Name == "Part" or v.Name == "Handle" or v.Name == "MeshPart") and (v:IsA("Part") or v:IsA("UnionOperation") or v:IsA("MeshPart")) then
			local Mesh = (v:IsA("MeshPart") and v) or v:FindFirstChildOfClass("SpecialMesh");
			local ParticleEmitter = v:FindFirstChildOfClass("ParticleEmitter");
			local Attachment = v:FindFirstChildOfClass("Attachment");
			local PointLight = v:FindFirstChildOfClass("PointLight");
			local Material = v.Material;
			local className = v.ClassName;
			local Size = v.Size;
			local SizeMagnitude = Size.Magnitude;
			local Color = v.BrickColor.Name;

			if(className == "UnionOperation" and Material == Enum.Material.Neon and SizeMagnitude < 3.1 and SizeMagnitude > 2) then
				if(not v.UsePartColor) then
					return trinketsData["White King's Amulet"];
				else
					return trinketsData["Lannis Amulet"];
				end;
			end;

			if(className == "Part" and v.Shape == Enum.PartType.Block and Material == Enum.Material.Neon and Color == "Pastel Blue" and Mesh.MeshId == "") then
				return trinketsData["Fairfrozen"];
			end;

			if(SizeMagnitude < 0.9 and Material == Enum.Material.Neon and className == "UnionOperation" and v.Transparency == 0) then
				if(Color == "Persimmon") then
					return trinketsData["Philosopher's Stone"];
				elseif(Color == "Black") then
					return trinketsData["Night Stone"];
				end;
			end;

			if(Material == Enum.Material.DiamondPlate and v.Transparency == 0 and PointLight and PointLight.Brightness == 0.5) then
				return trinketsData["Scroom Key"];
			end;

			if(className == "MeshPart" and getId(v.MeshId) == "2520762076") then
				return trinketsData["Howler Friend"];
			end;

			if(Mesh and getId(Mesh.MeshId) == "2877143560") then
				if(string.find(Color, "green")) then
					return trinketsData["Emerald"];
				elseif(Color == "Really red") then
					return trinketsData["Ruby"];
				elseif(Color == "Lapis") then
					return trinketsData["Sapphire"];
				elseif(string.find(Color, "blue")) then
					return trinketsData["Diamond"];
				else
					return trinketsData["Rift Gem"];
				end;
			end;

			if(ParticleEmitter and ParticleEmitter.Texture:find("20443483") and SizeMagnitude > 0.6 and SizeMagnitude < 0.8 and v.Transparency == 1 and Material == Enum.Material.Neon) then
				if(className == "Part") then
					return trinketsData["Ice Essence"];
				end;
				return trinketsData["Spider Cloak"];
			end;

			if(ParticleEmitter) then
				local TextureId = ParticleEmitter.Texture:gsub("%D", "");
				local Trinket = findInTable(Trinkets, "Texture", TextureId);

				if(Trinket) then
					return Trinket;
				end;
			end;

			if(Mesh and Mesh.MeshId ~= "") then
				local MeshId = Mesh.MeshId:gsub("%D", "");
				local Trinket = findInTable(Trinkets, "MeshId", MeshId);

				if(Trinket) then
					return Trinket;
				end;
			end;

			if(ParticleEmitter and Material == Enum.Material.Slate) then
				return trinketsData["Idol Of The Forgotten"];
			end;

			if(Attachment) then
				if(Attachment:FindFirstChildOfClass("ParticleEmitter")) then
					local ParticleEmitter2 = Attachment:FindFirstChildOfClass("ParticleEmitter");

					if (ParticleEmitter2) then
						local TextureId = getId(ParticleEmitter2.Texture);
						if(TextureId == '1536547385') then
							if(ParticleEmitter2.Size.Keypoints[1].Value ~= 0) then
								return trinketsData['Mysterious Artifact'];
							end;

							return trinketsData['Pheonix Down'];
						end
						local Trinket = findInTable(Trinkets, "Texture", TextureId);
						return Trinket;
					end;
				end;
			end;

			if(Mesh and Mesh:IsA('SpecialMesh') and Mesh.MeshType.Name == 'Sphere' and Mesh.VertexColor == opalColor) then
				return trinketsData.Opal;
			end;
		end;
	end;

	local id = 0;

	local ingredientsIds = {
		['2766802766'] = 'Strange Tentacle',
		['2766925214'] = 'Crown Flower',
		['2766802731'] = 'Dire Flower',
		['3215371492'] = 'Potato',
		['2766802752'] = 'Orcher Leaf',
		['2620905234'] = 'Scroom',
		['2766925289'] = 'Trote',
		['2766925228'] = 'Tellbloom',
		['2766925245'] = 'Uncanny Tentacle',
		['2575167210'] = 'Moss Plant',
		['2773353559'] = 'Bloodthorn',
		['2766802713'] = 'Periascroom',
		['2766925267'] = 'Creely',
		['3049928758'] = 'Canewood',
		['3049345298'] = 'Zombie Scroom',
		['3049556532'] = 'Acorn Light',
		['2766925320'] = 'Polar Plant',
		['2577691737'] = 'Lava Flower',
		['2573998175'] = 'Freeleaf',
		['2618765559'] = 'Glow Scroom',
		['2766925304'] = 'Vile Seed',
		['2889328388'] = 'Ice Jar',
		['2960178471'] = 'Snow Scroom',
		['3293218896'] = 'Desert Mist',
	}

	local function getIngredientType(v) -- // Also old code but still works very well!
		local assetId = v.AssetId and v.AssetId:match('%d+') or 'NIL';

		if(ingredientsIds[assetId]) then
			return ingredientsIds[assetId];
		else
			id = id + 1;
			return string.format('Unknown %s', id);
		end;
	end;

	local objectsRaycastFilter = RaycastParams.new();
	objectsRaycastFilter.FilterType = Enum.RaycastFilterType.Include;
	objectsRaycastFilter.FilterDescendantsInstances = {workspace.AreaMarkers};

	local function onChildAdded(object)
		task.wait(1);
		if (not object:IsA('BasePart')) then return; end;

		local trinketType = getTrinketType(object);
		if (not trinketType or not object:FindFirstChildWhichIsA('ClickDetector', true)) then return end;

		local location = workspace:Raycast(object.Position, Vector3.new(0, 5000, 0), objectsRaycastFilter);
		location = location and location.Instance.Name or '???';

		local self = trinketEspBase.new(object, trinketType.Name);
		self._text = string.format('%s] [%s', trinketType.Name, location);

		self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
			if(object.Parent) then return end;
			self:Destroy();
		end));
	end;

	local function onChildAddedIngredient(object)
		if (not IsA(object, 'BasePart')) then return; end;

		local ingredientType = getIngredientType(object);
		if (not ingredientType) then return end;

		local location = workspace:Raycast(object.Position, Vector3.new(0, 5000, 0), objectsRaycastFilter);
		location = location and location.Instance.Name or '???';
		
		local maid = Maid.new();
		
		if (object.Transparency == 0) then
			local obj = ingredientEspBase.new(object, ingredientType);
			maid.espObject = function()
				obj:Destroy();
			end;
		end;

		object:GetPropertyChangedSignal('Transparency'):Connect(function()
			if(object.Transparency == 0) then
				local obj = ingredientEspBase.new(object, ingredientType);
				maid.espObject = function()
					obj:Destroy();
				end;
			elseif (maid.espObject) then
				maid.espObject = nil;
			end;
		end);
	end;
	
	workspace.ChildAdded:Connect(onChildAdded)
	ingredientsFolder.ChildAdded:Connect(onChildAddedIngredient)
end;

local climbBoost = Instance.new('NumberValue');
climbBoost.Name = "ClimbBoost";

task.spawn(function()
	local killPartsObjects = {'KillBrick', 'Lava', 'PoisonField', 'PitKillBrick'};

	local slate = Enum.Material.Slate;
	local map = isGaia and workspace:FindFirstChild('Map') or workspace;

	for i, v in next, map:GetChildren() do
		if(v.Name == 'Part' and IsA(v, 'Part') and v.Material == slate and v.CanCollide == false and v.Transparency == 1) then
			v.Transparency = 0.5;
			v.Color = Color3.fromRGB(255, 0, 0);

			local touchTransmitter = v:FindFirstChildWhichIsA('TouchTransmitter');

			if(touchTransmitter) then
				touchTransmitter:Destroy();
			end;
		elseif(table.find(killPartsObjects, v.Name)) then
			table.insert(killBricks, v);
		end;
	end;
end);

task.spawn(function()
	while task.wait(0.2) do
		local character = LocalPlayer.Character;
		local boosts = character and character:FindFirstChild('Boosts');

		if(boosts and getgenv().climbSpeed ~= 1) then
			climbBoost.Value = getgenv().climbSpeed;
			climbBoost.Parent = boosts;
		else
			climbBoost.Parent = nil;
		end;

		local leaderboardGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui');

		if (leaderboardGui and not leaderboardGui.Enabled) then
			leaderboardGui.Enabled = true;
		end;
	end;
end);

task.spawn(function()
	if (not LocalPlayer.Character and not LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui')) then
		local newLeaderboardGui = StarterGui:FindFirstChild('LeaderboardGui'):Clone();
		newLeaderboardGui.Parent = LocalPlayer.PlayerGui;

		LocalPlayer.CharacterAdded:Wait();
		newLeaderboardGui:Destroy();
	end;
end);

local spectating;
local oldNamesColors = {};

UserInputService.InputBegan:Connect(function(input)
	if(input.UserInputType ~= Enum.UserInputType.MouseButton2) then return end;
	if(not LocalPlayer:FindFirstChild('PlayerGui') or not LocalPlayer.PlayerGui:FindFirstChild('LeaderboardGui')) then return end;

	local leaderboardPlayers = LocalPlayer.PlayerGui.LeaderboardGui.MainFrame.ScrollingFrame:GetChildren();

	local function getHoveredPlayer()
		for i,v in next, leaderboardPlayers do
			if(v.TextTransparency ~= 0) then
				return v;
			end;
		end;
	end;

	local label = getHoveredPlayer();
	if(not label) then return end;

	local player = Players:FindFirstChild(label.Text:gsub('\226\128\142', ''));
	if(not player or not player.Character) then return end;

	if(player == LocalPlayer) then
		spectating = player;
	end;

	for i, v in next, leaderboardPlayers do
		if(not oldNamesColors[v]) then
			oldNamesColors[v] = v.TextColor3;
		end;

		v.TextColor3 = oldNamesColors[v];
	end;

	if(spectating ~= player) then
		spectating = player;
		spectatePlayer(player.Name);
		label.TextColor3 = Color3.fromRGB(46, 204, 113);
	else
		spectating = nil;
		spectatePlayer(LocalPlayer.Name);
	end;
end);
