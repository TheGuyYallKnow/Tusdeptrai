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
