scriptVersion = 12312

function Signal()
	SX_VM_CNONE();
	--- Lua-side duplication of the API of events on Roblox objects.
	-- Signals are needed for to ensure that for local events objects are passed by
	-- reference rather than by value where possible, as the BindableEvent objects
	-- always pass signal arguments by value, meaning tables will be deep copied.
	-- Roblox's deep copy method parses to a non-lua table compatable format.
	-- @classmod Signal

	local Signal = {}
	Signal.__index = Signal
	Signal.ClassName = "Signal"

	--- Constructs a new signal.
	-- @constructor Signal.new()
	-- @treturn Signal
	function Signal.new()
		local self = setmetatable({}, Signal)

		self._bindableEvent = Instance.new("BindableEvent")
		self._argData = nil
		self._argCount = nil -- Prevent edge case of :Fire("A", nil) --> "A" instead of "A", nil

		return self
	end

	function Signal.isSignal(object)
		return typeof(object) == 'table' and getmetatable(object) == Signal;
	end;

	--- Fire the event with the given arguments. All handlers will be invoked. Handlers follow
	-- Roblox signal conventions.
	-- @param ... Variable arguments to pass to handler
	-- @treturn nil
	function Signal:Fire(...)
		self._argData = {...}
		self._argCount = select("#", ...)
		self._bindableEvent:Fire()
		self._argData = nil
		self._argCount = nil
	end

	--- Connect a new handler to the event. Returns a connection object that can be disconnected.
	-- @tparam function handler Function handler called with arguments passed when `:Fire(...)` is called
	-- @treturn Connection Connection object that can be disconnected
	function Signal:Connect(handler)
		if not self._bindableEvent then return error("Signal has been destroyed"); end --Fixes an error while respawning with the UI injected

		if not (type(handler) == "function") then
			error(("connect(%s)"):format(typeof(handler)), 2)
		end

		return self._bindableEvent.Event:Connect(function()
			handler(unpack(self._argData, 1, self._argCount))
		end)
	end

	--- Wait for fire to be called, and return the arguments it was given.
	-- @treturn ... Variable arguments from connection
	function Signal:Wait()
		self._bindableEvent.Event:Wait()
		assert(self._argData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
		return unpack(self._argData, 1, self._argCount)
	end

	--- Disconnects all connected events to the signal. Voids the signal as unusable.
	-- @treturn nil
	function Signal:Destroy()
		if self._bindableEvent then
			self._bindableEvent:Destroy()
			self._bindableEvent = nil
		end

		self._argData = nil
		self._argCount = nil
	end

	return Signal
end

function Services()
	SX_VM_CNONE();
	local Services = {};
	local vim = getvirtualinputmanager and getvirtualinputmanager();

	function Services:Get(...)
		local allServices = {};

		for _, service in next, {...} do
			table.insert(allServices, self[service]);
		end

		return unpack(allServices);
	end;

	setmetatable(Services, {
		__index = function(self, p)
			if (p == 'VirtualInputManager' and vim) then
				return vim;
			end;

			local service = game:GetService(p);
			if (p == 'VirtualInputManager') then
				service.Name = getServerConstant('VirtualInputManager ');
			end;

			rawset(self, p, service);
			return rawget(self, p);
		end,
	});

	return Services;
end

function createBaseESPParallel()
	return [[
    local Players = game:GetService('Players');
    local RunService = game:GetService('RunService');
    local LocalPlayer = Players.LocalPlayer;

    local camera, rootPart, rootPartPosition;

    local originalCommEvent = ...;
    local commEvent;

    if (typeof(originalCommEvent) == 'table') then
        commEvent = {
            _event = originalCommEvent._event,

            Connect = function(self, f)
                return self._event.Event:Connect(f)
            end,

            Fire = function(self, ...)
                self._event:Fire(...);
            end
        };
    else
        commEvent = getgenv().syn.get_comm_channel(originalCommEvent);
    end;

    local flags = {};

    local updateTypes = {};

    local BaseESPParallel = {};
    BaseESPParallel.__index = BaseESPParallel;

    local container = {};
    local DEFAULT_ESP_COLOR = Color3.fromRGB(255, 255, 255);

    local mFloor = math.floor;
    local isSynapseV3 = not not gethui;

    local worldToViewportPoint = Instance.new('Camera').WorldToViewportPoint;
    local vector2New = Vector2.new;

    local realSetRP;
    local realDestroyRP;
    local realGetRPProperty;

    if (isSynapseV3) then
        realGetRPProperty = function(self, p, v)
            return self[p];
        end;

        realSetRP = function(self, p, v)
            self[p] = v;
        end;

        realDestroyRP = function(self)
            return self:Remove();
        end;

        realGetRPProperty = getRPProperty;
    else
        local lineUpvalues = getupvalue(Drawing.new, 4).__index;
        local lineUpvalues2 = getupvalue(Drawing.new, 4).__newindex;

        realSetRP = getupvalue(lineUpvalues2, 4);
        realDestroyRP = getupvalue(lineUpvalues, 3);
        realGetRPProperty = getupvalue(lineUpvalues, 4);

        assert(realSetRP);
        assert(realDestroyRP);
        assert(realGetRPProperty);
    end;


    local updateDrawingQueue = {};
    local destroyDrawingQueue = {};

    local activeContainer = {};
    local customInstanceCache = {};

    local gameName;
    local enableESPSearch = false;

    local sLower = string.lower;
    local sFind = string.find;

    local findFirstChild = clonefunction(game.FindFirstChild);
    local getAttribute = clonefunction(game.GetAttribute);

    if (isSynapseV3) then
        setRP = realSetRP;
        getRPProperty = realGetRPProperty;
    else
        setRP = function(object, p, v)
            local cache = object._cache;
            local cacheVal = cache[p];
            if (cacheVal == v) then return end;

            cache[p] = v;
            realSetRP(object.__OBJECT, p, v);
        end;

        getRPProperty = function(object, p)
            local cacheVal = object._cache[p];
            if (not cacheVal) then
                object._cache[p] = realGetRPProperty(object.__OBJECT, p);
                cacheVal = object._cache[p];
            end;

            return cacheVal;
        end;
    end;


    function BaseESPParallel.new(data, showESPFlag, customInstance)
        local self = setmetatable(data, BaseESPParallel);

        if (customInstance) then
            if (not customInstanceCache[data._code]) then
                local func = loadstring(data._code);
                getfenv(func).library = setmetatable({}, {__index = function(self, p) return flags end});

                customInstanceCache[data._code] = func;
            end;
            self._instance = customInstanceCache[data._code](unpack(data._vars));
        end;

        local instance, tag, color, isLazy = self._instance, self._tag, self._color, self._isLazy;
        self._showFlag2 = showESPFlag;


		if (isSynapseV3 and typeof(instance) == 'Instance' and false) then
			-- if (typeof(instance) == 'table') then
			-- 	task.spawn(error, instance);
			-- end;

			self._label = TextDynamic.new(PointInstance.new(instance));
			self._label.Color = DEFAULT_ESP_COLOR;
			self._label.XAlignment = XAlignment.Center;
			self._label.YAlignment = YAlignment.Center;
			self._label.Outlined = true;
			self._label.Text = string.format('[%s]', tag);
		else
			self._label = Drawing.new('Text');
			self._label.Transparency = 1;
			self._label.Color = color;
			self._label.Text = '[' .. tag .. ']';
			self._label.Center = true;
			self._label.Outline = true;
		end;

		local flagValue = flags[self._showFlag];
		-- self._object = isSynapseV3 and self._label or self._label.__OBJECT;

		for i, v in next, self do
            if (typeof(v) == 'table' and rawget(v, '__OBJECT')) then
                rawset(v, '_cache', {});
            end;
        end;

		container[self._id] = self;

		if (isLazy) then
			self._instancePosition = instance.Position;
		end;

        self:UpdateContainer();
        return self;
    end;

	function BaseESPParallel:Destroy()
		container[self._id] = nil;
        if (table.find(activeContainer, self)) then
            table.remove(activeContainer, table.find(activeContainer, self));
        end;
        table.insert(destroyDrawingQueue, self._label);
    end;

    function BaseESPParallel:Unload()
        table.insert(updateDrawingQueue, {
            label = self._label,
            visible = false
        });
    end;

	function BaseESPParallel:BaseUpdate(espSearch)
		local instancePosition = self._instancePosition or self._instance.Position;
		if (not instancePosition) then return self:Unload() end;

		local distance = (rootPartPosition - instancePosition).Magnitude;
		local maxDist = flags[self._maxDistanceFlag] or 10000;
		if(distance >= maxDist and maxDist ~= 10000) then return self:Unload(); end;

		local visibleState = flags[self._showFlag];
		local label, text = self._label, self._text;

		if(visibleState == nil) then
			visibleState = true;
		elseif (not visibleState) then
			return self:Unload();
		end;

		-- if (isSynapseV3) then return end;

		local position, visible = worldToViewportPoint(camera, instancePosition);
		if(not visible) then return self:Unload(); end;

		local newPos = vector2New(position.X, position.Y);

		local labelText = '';

		if (flags[self._showHealthFlag]) then
            -- Custom instance do not touch they have custom funcs
            local humanoid = self._instance:FindFirstChildWhichIsA('Humanoid') or self._instance.Parent and self._instance.Parent:FindFirstChild('Humanoid');

            if (not humanoid) then
                if (gameName == 'Arcane Odyssey') then
                    local attributes = findFirstChild(self._instance.Parent, 'Attributes');
                    if (attributes) then
                        humanoid = {
                            Health = attributes.Health.Value,
                            MaxHealth = attributes.MaxHealth.Value,
                        }
                    end
                elseif (gameName == 'Voxl Blade') then
                    humanoid = {
                        Health = getAttribute(self._instance, 'HP'),
                        MaxHealth = getAttribute(self._instance, 'MAXHP'),
                    }
                end;
            end;

			if (humanoid) then
				local health = mFloor(humanoid.Health);
				local maxHealth = mFloor(humanoid.MaxHealth);

				labelText = labelText .. '[' .. health .. '/' .. maxHealth ..']';
			end;
		end;

		labelText = labelText .. '[' .. text .. ']';

        local visible = true;

        if (enableESPSearch and espSearch and not sFind(sLower(labelText), espSearch)) then
            visible = false;
        end;

		local newColor = flags[self._colorFlag] or flags[self._colorFlag2] or DEFAULT_ESP_COLOR;

		if (flags[self._showDistanceFlag]) then
			labelText = labelText .. ' [' .. mFloor(distance) .. ']';
		end;

        table.insert(updateDrawingQueue, {
            position = newPos,
            color = newColor,
            text = labelText,
            label = label,
            visible = visible
        });
	end;

    function BaseESPParallel:UpdateContainer()
        local showFlag, showFlag2 = self._showFlag, self._showFlag2;

        if (flags[showFlag] == false or not flags[showFlag2]) then
            local exists = table.find(activeContainer, self);
            if (exists) then table.remove(activeContainer, exists); end;
            self:Unload();
        elseif (not table.find(activeContainer, self)) then
            table.insert(activeContainer, self);
        end;
    end;

    function updateTypes.new(data)
        local showESPFlag = data.showFlag;
        local isCustomInstance = data.isCustomInstance;
        data = data.data;

        BaseESPParallel.new(data, showESPFlag, isCustomInstance);
    end;

    function updateTypes.destroy(data)
        task.desynchronize();
        local id = data.id;

        for _, v in next, container do
            if (v._id == id) then
                v:Destroy();
            end;
        end;
    end;

    local event;
    local flagChanged;

    local containerUpdated = false;

    function updateTypes.giveEvent(data)
        event = data.event;
        gameName = data.gameName;

        enableESPSearch = gameName == 'Voxl Blade' or gameName == 'DeepWoken' or gameName == 'Rogue Lineage';

        event.Event:Connect(function(data)
            if (data.type == 'color') then
                flags[data.flag] = data.color;
            elseif (data.type == 'slider') then
                flags[data.flag] = data.value;
            elseif (data.type == 'toggle') then
                flags[data.flag] = data.state;
            elseif (data.type == 'box') then
                flags[data.flag] = data.value;
            end;
    
            if (data.type ~= 'toggle' or containerUpdated) then return end;
            containerUpdated = true;
    
            task.defer(function()
                debug.profilebegin('containerUpdates');
                for _, v in next, container do
                    v:UpdateContainer();
                end;
                debug.profileend();
    
                containerUpdated = false;
            end);
        end);
    end;

    commEvent:Connect(function(data)
        local f = updateTypes[data.updateType];
        if (not f) then return end;
        f(data);
    end);

    commEvent:Fire({updateType = 'ready'});

    RunService.Heartbeat:Connect(function(deltaTime)
        task.desynchronize();

        camera = workspace.CurrentCamera;
        rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
        rootPartPosition = rootPart and rootPart.Position;

		if(not camera or not rootPart) then return; end;

        local espSearch = enableESPSearch and flags.espSearch;

        if (espSearch and espSearch ~= '') then
            espSearch = sLower(espSearch);
        end;

        for i = 1, #activeContainer do
            activeContainer[i]:BaseUpdate(espSearch);
        end;

        local goSerial = #updateDrawingQueue ~= 0 or #destroyDrawingQueue ~= 0;
        if (goSerial) then task.synchronize(); end;
        debug.profilebegin('updateDrawingQueue');

        for i = 1, #updateDrawingQueue do
            local v = updateDrawingQueue[i];
            local label, position, visible, color, text = v.label, v.position, v.visible, v.color, v.text;

            if (isSynapseV3) then
                if (position) then
                    label.Position = position;
                end;
    
                if (visible ~= nil) then
                    label.Visible = visible;
                end;
    
                if (color) then
                    label.Color = color;
                end;
    
                if (text) then
                    label.Text = text;
                end;
            else                
                if (position) then
                    setRP(label, 'Position', position);
                end;
    
                if (visible ~= nil) then
                    setRP(label, 'Visible', visible);
                end;
    
                if (color) then
                    setRP(label, 'Color', color);
                end;
    
                if (text) then
                    setRP(label, 'Text', text);
                end;
            end;
        end;

        debug.profileend();
        debug.profilebegin('destroyDrawingQueue');

        for i = 1, #destroyDrawingQueue do
            destroyDrawingQueue[i]:Remove();
        end;

        debug.profileend();
        debug.profilebegin('table clear');

        updateDrawingQueue = {};
        destroyDrawingQueue = {};

        debug.profileend();
    end);
]];
end

function Maid()
	SX_VM_CNONE();
	---	Manages the cleaning of events and other things.
	-- Useful for encapsulating state and make deconstructors easy
	-- @classmod Maid
	-- @see Signal

	local Signal = Signal()
	local tableStr = getServerConstant('table');
	local classNameStr = getServerConstant('Maid');
	local funcStr = getServerConstant('function');
	local threadStr = getServerConstant('thread');

	local Maid = {}
	Maid.ClassName = "Maid"

	--- Returns a new Maid object
	-- @constructor Maid.new()
	-- @treturn Maid
	function Maid.new()
		return setmetatable({
			_tasks = {}
		}, Maid)
	end

	function Maid.isMaid(value)
		return type(value) == tableStr and value.ClassName == classNameStr
	end

	--- Returns Maid[key] if not part of Maid metatable
	-- @return Maid[key] value
	function Maid.__index(self, index)
		if Maid[index] then
			return Maid[index]
		else
			return self._tasks[index]
		end
	end

	--- Add a task to clean up. Tasks given to a maid will be cleaned when
	--  maid[index] is set to a different value.
	-- @usage
	-- Maid[key] = (function)         Adds a task to perform
	-- Maid[key] = (event connection) Manages an event connection
	-- Maid[key] = (Maid)             Maids can act as an event connection, allowing a Maid to have other maids to clean up.
	-- Maid[key] = (Object)           Maids can cleanup objects with a `Destroy` method
	-- Maid[key] = nil                Removes a named task. If the task is an event, it is disconnected. If it is an object,
	--                                it is destroyed.
	function Maid:__newindex(index, newTask)
		if Maid[index] ~= nil then
			error(("'%s' is reserved"):format(tostring(index)), 2)
		end

		local tasks = self._tasks
		local oldTask = tasks[index]

		if oldTask == newTask then
			return
		end

		tasks[index] = newTask

		if oldTask then
			if type(oldTask) == "function" then
				oldTask()
			elseif typeof(oldTask) == "RBXScriptConnection" then
				oldTask:Disconnect();
			elseif typeof(oldTask) == 'table' then
				oldTask:Remove();
			elseif (Signal.isSignal(oldTask)) then
				oldTask:Destroy();
			elseif (typeof(oldTask) == 'thread') then
				task.cancel(oldTask);
			elseif oldTask.Destroy then
				oldTask:Destroy();
			end
		end
	end

	--- Same as indexing, but uses an incremented number as a key.
	-- @param task An item to clean
	-- @treturn number taskId
	function Maid:GiveTask(task)
		if not task then
			error("Task cannot be false or nil", 2)
		end

		local taskId = #self._tasks+1
		self[taskId] = task

		return taskId
	end

	--- Cleans up all tasks.
	-- @alias Destroy
	function Maid:DoCleaning()
		local tasks = self._tasks

		-- Disconnect all events first as we know this is safe
		for index, task in pairs(tasks) do
			if typeof(task) == "RBXScriptConnection" then
				tasks[index] = nil
				task:Disconnect()
			end
		end

		-- Clear out tasks table completely, even if clean up tasks add more tasks to the maid
		local index, taskData = next(tasks)
		while taskData ~= nil do
			tasks[index] = nil
			if type(taskData) == funcStr then
				taskData()
			elseif typeof(taskData) == "RBXScriptConnection" then
				taskData:Disconnect()
			elseif (Signal.isSignal(taskData)) then
				taskData:Destroy();
			elseif typeof(taskData) == tableStr then
				taskData:Remove();
			elseif (typeof(taskData) == threadStr) then
				task.cancel(taskData);
			elseif taskData.Destroy then
				taskData:Destroy()
			end
			index, taskData = next(tasks)
		end
	end

	--- Alias for DoCleaning()
	-- @function Destroy
	Maid.Destroy = Maid.DoCleaning

	return Maid;
end

function KeyBindVisualizer()
	local Services = Services()
	local UserInputService = Services:Get('UserInputService');
	local Maid = Maid()

	local keybindVisualizer = {};
	keybindVisualizer.__index = keybindVisualizer;

	local viewportSize = workspace.CurrentCamera.ViewportSize;
	local library;

	function keybindVisualizer.new()
		local self = setmetatable({}, keybindVisualizer);

		self._textSizes = {};
		self._maid = Maid.new();

		self:_init();

		local dragObject;
		local dragging;
		local dragStart;
		local startPos;

		self._maid:GiveTask(UserInputService.InputBegan:Connect(function(input)
			if (input.UserInputType == Enum.UserInputType.MouseButton1 and self:MouseInFrame()) then
				dragObject = self._textBox
				dragging = true
				dragStart = input.Position
				startPos = dragObject.Position
			end;
		end));

		self._maid:GiveTask(UserInputService.InputChanged:connect(function(input)
			if dragging and input.UserInputType.Name == 'MouseMovement' and not self._destroyed then
				if dragging then
					local delta = input.Position - dragStart;
					local yPos = (startPos.Y + delta.Y) < -36 and -36 or startPos.Y + delta.Y;

					self._textBox.Position = Vector2.new(startPos.X + delta.X,  yPos);
					library.configVars.keybindVisualizerPos = tostring(self._textBox.Position);
				end;
			end;
		end));

		self._maid:GiveTask(UserInputService.InputEnded:connect(function(input)
			if input.UserInputType.Name == 'MouseButton1' then
				dragging = false
			end
		end));

		library.OnLoad:Connect(function()
			if (not library.configVars.keybindVisualizerPos) then return end;
			self._textBox.Position = Vector2.new(unpack(library.configVars.keybindVisualizerPos:split(',')));
		end);

		return self;
	end;

	function keybindVisualizer:_getTextBounds(text, fontSize)
		local t = Drawing.new('Text');
		t.Text = text;
		t.Size = fontSize;

		local res = t.TextBounds;
		t:Remove();
		return res.X;
	end;

	function keybindVisualizer:_createDrawingInstance(instanceType, properties)
		local instance = Drawing.new(instanceType);

		if (properties.Visible == nil) then
			properties.Visible = true;
		end;

		for i,  v in next,  properties do
			instance[i] = v;
		end;

		return instance;
	end;

	function keybindVisualizer:_init()
		self._textBox = self:_createDrawingInstance('Text', {
			Size = 30,
			Position = viewportSize-Vector2.new(180, viewportSize.Y/2),
			Color = Color3.new(255, 255, 255)
		});
	end

	function keybindVisualizer:GetLargest()
		table.sort(self._textSizes, function(a, b) return a.magnitude>b.magnitude; end)
		return self._textSizes[1] or Vector2.new(0, 30);
	end

	function keybindVisualizer:AddText(txt)
		if (self._destroyed) then return end;
		self._largest = self:GetLargest();

		local tab = string.split(self._textBox.Text, '\n');
		if (table.find(tab, txt)) then return end;

		local textSize = Vector2.new(self:_getTextBounds(txt, 30), 30);
		table.insert(self._textSizes, textSize);

		table.insert(tab, txt);
		table.sort(tab, function(a, b) return #a < #b; end)

		self._textBox.Text = table.concat(tab, '\n');
		self._textBox.Position -= Vector2.new(0, 30);
	end

	function keybindVisualizer:MouseInFrame()
		local mousePos = UserInputService:GetMouseLocation();
		local framePos = self._textBox.Position;
		local bottomRight = framePos + self._textBox.TextBounds

		return (mousePos.X >= framePos.X and mousePos.X <= bottomRight.X) and (mousePos.Y >= framePos.Y and mousePos.Y <= bottomRight.Y)
	end;

	function keybindVisualizer:RemoveText(txt)
		if (self._destroyed) then return end;
		local textSize = Vector2.new(self:_getTextBounds(txt, 30), 30);
		table.remove(self._textSizes, table.find(self._textSizes,  textSize));

		self._largest = self:GetLargest();

		local tab = string.split(self._textBox.Text, '\n');
		table.remove(tab, table.find(tab, txt));

		self._textBox.Text = table.concat(tab, '\n');
		self._textBox.Position += Vector2.new(0, 30);
	end

	function keybindVisualizer:UpdateColor(color)
		if (self._destroyed) then return end;
		self._textBox.Color = color;
	end;

	function keybindVisualizer:SetEnabled(state)
		if (self._destroyed) then return end;
		self._textBox.Visible = state;
	end;

	function keybindVisualizer:Remove()
		self._destroyed = true;
		self._maid:Destroy();
		self._textBox:Remove();
	end;

	function keybindVisualizer.init(newLibrary)
		library = newLibrary;
	end;

	return keybindVisualizer;
end

function toCamelCase()
	SX_VM_CNONE();
	local stringPattern = getServerConstant('%s(.)');
	return function (text)
		return string.lower(text):gsub(stringPattern, string.upper);
	end;
end

function ToastNotif()
	local Services = Services()
	local Maid = Maid()
	local Signal = Signal()

	local TweenService, UserInputService = Services:Get('TweenService', 'UserInputService');

	local Notifications = {};

	local Notification = {};
	Notification.__index = Notification;
	Notification.NotifGap = 40;

	local viewportSize = workspace.CurrentCamera.ViewportSize;

	local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad);
	local VALUE_NAMES = {
		number = 'NumberValue',
		Color3 = 'Color3Value',
		Vector2 = 'Vector3Value',
	};

	local movingUpFinished = true;
	local movingDownFinished = true;

	local vector2Str = getServerConstant('Vector2');
	local positionStr = getServerConstant('Position');

	function Notification.new(options)
		local self = setmetatable({
			_options = options
		}, Notification);

		self._options = options;
		self._maid = Maid.new();

		self.Destroying = Signal.new();

		self._tweens = {};
		task.spawn(self._init, self);

		return self;
	end;

	function Notification:_createDrawingInstance(instanceType, properties)
		local instance = Drawing.new(instanceType);

		if (properties.Visible == nil) then
			properties.Visible = true;
		end;

		for i, v in next, properties do
			instance[i] = v;
		end;

		return instance;
	end;

	function Notification:_getTextBounds(text, fontSize)
		local t = Drawing.new('Text');
		t.Text = text;
		t.Size = fontSize;

		local res = t.TextBounds;
		t:Remove();
		return res.X;
		-- This is completetly inaccurate but there is no function to get the textbounds on v2; It prob also matter abt screen size but lets ignore that
		-- return #text * (fontSize / 3.15);
	end;

	function Notification:_tweenProperty(instance, property, value, tweenInfo, dontCancel)
		local currentValue = instance[property]
		local valueType = typeof(currentValue);
		local valueObject = Instance.new(VALUE_NAMES[valueType]);

		self._maid:GiveTask(valueObject);
		if (valueType == vector2Str) then
			value = Vector3.new(value.X, value.Y, 0);
			currentValue = Vector3.new(currentValue.X, currentValue.Y, 0);
		end;

		valueObject.Value = currentValue;
		local tween = TweenService:Create(valueObject, tweenInfo, {Value = value});

		self._tweens[tween] = dontCancel or false;

		self._maid:GiveTask(valueObject:GetPropertyChangedSignal('Value'):Connect(function()
			local newValue = valueObject.Value;

			if (valueType == vector2Str) then
				newValue = Vector2.new(newValue.X, newValue.Y);
			end;

			if self._destroyed then return; end

			instance[property] = newValue;
		end));

		self._maid:GiveTask(tween.Completed:Connect(function()
			valueObject:Destroy();
			self._tweens[tween] = nil;
		end));

		tween:Play();

		if (instance == self._progressBar and property == 'Size') then
			self._maid:GiveTask(tween.Completed:Connect(function(playbackState)
				if (playbackState ~= Enum.PlaybackState.Completed) then return end;
				self:Destroy();
			end));
		end;

		return tween;
	end;

	function Notification:_init()
		self:MoveUp();

		local textSize = Vector2.new(self:_getTextBounds(self._options.text, 19), 30);
		textSize += Vector2.new(10, 0); -- // Padding

		self._textSize = textSize

		self._frame = self:_createDrawingInstance('Square', {
			Size = textSize,
			Position = viewportSize - Vector2.new(-10, textSize.Y+10),
			Color = Color3.fromRGB(12, 12, 12),
			Filled = true
		});

		self._originalPosition = self._frame.Position;

		self._text = self:_createDrawingInstance('Text', {
			Text = self._options.text,
			Center = true,
			Color = Color3.fromRGB(255, 255, 255),
			Position = self._frame.Position + Vector2.new(textSize.X/2, 5), -- 5 Cuz of the padding
			Size = 19
		});

		self._progressBar = self:_createDrawingInstance('Square', {
			Size = Vector2.new(textSize.X, 3),
			Color = Color3.fromRGB(86, 180, 211),
			Filled = true,
			Position = self._frame.Position+Vector2.new(0, self._frame.Size.Y-3)
		});

		table.insert(Notifications,self); --Insert it into the table we are using to move up

		self._startTime = tick();
		local framePos = viewportSize - textSize - Vector2.new(10, 10);

		self:_tweenProperty(self._frame, positionStr, framePos, TWEEN_INFO,true);
		self:_tweenProperty(self._text, positionStr, framePos + Vector2.new(textSize.X/2, 5), TWEEN_INFO,true);
		local t = self:_tweenProperty(self._progressBar, positionStr, framePos + Vector2.new(0, self._frame.Size.Y-3), TWEEN_INFO, true); --We dont really want this to be cancelable

		self._maid._progressConnection = t.Completed:Connect(function() --This should prob use maids lol
			if (self._options.duration) then
				self:_tweenProperty(self._progressBar, 'Size', Vector2.new(0, 3), TweenInfo.new(self._options.duration, Enum.EasingStyle.Linear));
				self:_tweenProperty(self._progressBar, positionStr, framePos - Vector2.new(-self._frame.Size.X, -(self._frame.Size.Y-3)), TweenInfo.new(self._options.duration, Enum.EasingStyle.Linear)); --You should technically remove this after its complete but doesn't matter
			end;
		end)
	end;


	function Notification:MouseInFrame()
		local mousePos = UserInputService:GetMouseLocation();
		local framePos = self._frame.Position;
		local bottomRight = framePos + self._frame.Size

		return (mousePos.X >= framePos.X and mousePos.X <= bottomRight.X) and (mousePos.Y >= framePos.Y and mousePos.Y <= bottomRight.Y)
	end

	function Notification:GetHovered()
		for _,notif in next, Notifications do
			if notif:MouseInFrame() then return notif; end
		end

		return;
	end

	function Notification:MoveUp() --Going to use this to move all the drawing instances up one

		if (self._destroyed) then return; end

		repeat task.wait() until movingUpFinished;

		movingUpFinished = false;

		local distanceUp = Vector2.new(0, -self.NotifGap); --This can be made dynamic but I'm not sure if youd rather use screen size or an argument up to you

		for i,v in next, Notifications do
			--I mean you can obviously use le tween to make it cleaner
			v:CancelTweens(); --Cancel all current tweens that arent the default

			local newFramePos = v._frame.Position+distanceUp;

			v._frame.Position = newFramePos;
			v._text.Position = v._text.Position+distanceUp;
			v._progressBar.Position = v._progressBar.Position+distanceUp;

			if (not v._options.duration) then continue end;

			local newDuration = v._options.duration-(tick()-v._startTime);

			v:_tweenProperty(v._progressBar, 'Size', Vector2.new(0, 3), TweenInfo.new(newDuration, Enum.EasingStyle.Linear));
			v:_tweenProperty(v._progressBar, positionStr, newFramePos - Vector2.new(-v._frame.Size.X, -(v._frame.Size.Y-3)), TweenInfo.new(newDuration, Enum.EasingStyle.Linear));
		end
		movingUpFinished = true;
	end


	function Notification:MoveDown() --Going to use this to move all the drawing instances up one

		if (self._destroyed) then return; end

		repeat task.wait() until movingDownFinished;

		movingDownFinished = false;

		local distanceDown = Vector2.new(0, self.NotifGap); --This can be made dynamic but I'm not sure if youd rather use screen size or an argument up to you

		local index = table.find(Notifications,self) or 1;

		for i = index, 1,-1 do
			local v = Notifications[i];

			v:CancelTweens(); --Cancel all current tweens that arent the default

			local newFramePos = v._frame.Position+distanceDown;

			v._frame.Position = newFramePos;
			v._text.Position = v._text.Position+distanceDown;
			v._progressBar.Position = v._progressBar.Position+distanceDown;

			if (not v._options.duration) then continue end;

			v._startTime = v._startTime or tick();
			local newDuration = v._options.duration-(tick()-v._startTime);

			v:_tweenProperty(v._progressBar, 'Size', Vector2.new(0, 3), TweenInfo.new(newDuration, Enum.EasingStyle.Linear));
			v:_tweenProperty(v._progressBar, positionStr, newFramePos - Vector2.new(-v._frame.Size.X, -(v._frame.Size.Y-3)), TweenInfo.new(newDuration, Enum.EasingStyle.Linear));
		end
		movingDownFinished = true;
	end

	function Notification:CancelTweens()
		for tween,cancelInfo in next, self._tweens do
			if cancelInfo then
				self._maid._progressConnection = nil;
				tween.Completed:Wait();
				continue;
			end
			tween:Cancel();
		end
	end

	function Notification:ClearAllAbove()
		local index = table.find(Notifications,self);

		for i = 1, index do
			task.spawn(function()
				Notifications[i]:Destroy();
			end)
		end
	end

	function Notification:Remove()
		table.remove(Notifications,table.find(Notifications,self)); --We kind of want to use this and kind of don't its causing ALOT of issues with a large amount of things, but it also fixes the order issue gl
	end

	function Notification:Destroy()
		-- // TODO: Use a maid in the future
		if (self._destroyFixed) then return; end;
		self._destroyFixed = true;

		self.Destroying:Fire();

		local framePos = self._originalPosition;
		local textSize = self._textSize;

		self:CancelTweens();

		self:_tweenProperty(self._frame, positionStr, framePos, TWEEN_INFO,true);
		self:_tweenProperty(self._text, positionStr, framePos + Vector2.new(textSize.X/2, 5), TWEEN_INFO,true);
		self:_tweenProperty(self._progressBar, positionStr, framePos + Vector2.new(0, self._frame.Size.Y-3), TWEEN_INFO,true).Completed:Wait();

		self:MoveDown();

		self:Remove();

		self._destroyed = true;

		self._frame:Remove();
		self._text:Remove();
		self._progressBar:Remove();
	end;

	local function onInputBegan(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then  --Clear just that one
			local notif = Notification:GetHovered();
			if notif then
				notif:Destroy();
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then --Clear all above it
			local notif = Notification:GetHovered();
			if notif then
				notif:ClearAllAbove();
			end
		end
	end

	UserInputService.InputBegan:Connect(onInputBegan)

	return Notification;
end

function library()
	SX_VM_CNONE();

	-- // Services

	local libraryLoadAt = tick();

	local Signal = Signal()
	local Services = Services()
	local KeyBindVisualizer = KeyBindVisualizer()

	local CoreGui, Players, RunService, TextService, UserInputService, ContentProvider, HttpService, TweenService, GuiService, TeleportService = Services:Get('CoreGui', 'Players', 'RunService', 'TextService', 'UserInputService', 'ContentProvider', 'HttpService', 'TweenService', 'GuiService', 'TeleportService');

	local toCamelCase = toCamelCase()
	local Maid = Maid()
	local ToastNotif = ToastNotif()

	local LocalPlayer = Players.LocalPlayer;
	local visualizer;

	if getgenv().library then
		getgenv().library:Unload();
	end;

	if (not isfile('Aztup Hub V3/configs')) then
		makefolder('Aztup Hub V3/configs');
	end;

	if (not isfile('Aztup Hub V3/configs/globalConf.bin')) then
		-- By default global config is turned on
		writefile('Aztup Hub V3/configs/globalConf.bin', 'true');
	end;

	local globalConfFilePath = 'Aztup Hub V3/configs/globalConf.bin';
	local isGlobalConfigOn = readfile(globalConfFilePath) == 'true';

	local library = {
		unloadMaid = Maid.new(),
		tabs = {},
		draggable = true,
		flags = {},
		title = string.format('Aztup Hub | v%s', scriptVersion or 'DEBUG'),
		open = false,
		popup = nil,
		instances = {},
		connections = {},
		options = {},
		notifications = {},
		configVars = {},
		tabSize = 0,
		theme = {},
		foldername =  isGlobalConfigOn and 'Aztup Hub V3/configs/global' or string.format('Aztup Hub V3/configs/%s', tostring(LocalPlayer.UserId)),
		fileext = getServerConstant('.json'),
		chromaColor = Color3.new()
	}

	library.originalTitle = library.title;

	do -- // Load
		library.unloadMaid:GiveTask(task.spawn(function()
			while true do
				for i = 1, 360 do
					library.chromaColor = Color3.fromHSV(i / 360, 1, 1);
					task.wait(0.1);
				end;
			end;
		end));

		-- if(debugMode) then
		getgenv().library = library
		-- end;

		library.OnLoad = Signal.new();
		library.OnKeyPress = Signal.new();
		library.OnKeyRelease = Signal.new();

		library.OnFlagChanged = Signal.new();

		KeyBindVisualizer.init(library);

		library.unloadMaid:GiveTask(library.OnLoad);
		library.unloadMaid:GiveTask(library.OnKeyPress);
		library.unloadMaid:GiveTask(library.OnKeyRelease);
		library.unloadMaid:GiveTask(library.OnFlagChanged);

		visualizer = KeyBindVisualizer.new();
		local mouseMovement = Enum.UserInputType.MouseMovement;

		--Locals
		local dragging, dragInput, dragStart, startPos, dragObject

		local blacklistedKeys = { --add or remove keys if you find the need to
			Enum.KeyCode.Unknown,Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,Enum.KeyCode.Slash,Enum.KeyCode.Tab,Enum.KeyCode.Escape
		}
		local whitelistedMouseinputs = { --add or remove mouse inputs if you find the need to
			Enum.UserInputType.MouseButton1,Enum.UserInputType.MouseButton2,Enum.UserInputType.MouseButton3
		}

		local function onInputBegan(input, gpe)
			local inputType = input.UserInputType;
			if (inputType == mouseMovement) then return end;

			if (UserInputService:GetFocusedTextBox()) then return end;
			local inputKeyCode = input.KeyCode;

			local fastInputObject = {
				KeyCode = {
					Name = inputKeyCode.Name,
					Value = inputKeyCode.Value
				},

				UserInputType = {
					Name = inputType.Name,
					Value = inputType.Value
				},

				UserInputState = input.UserInputState,
				realKeyCode = inputKeyCode,
				realInputType = inputType
			};

			library.OnKeyPress:Fire(fastInputObject, gpe);
		end;

		local function onInputEnded(input)
			local inputType = input.UserInputType;
			if (inputType == mouseMovement) then return end;

			local inputKeyCode = input.KeyCode;

			local fastInputObject = {
				KeyCode = {
					Name = inputKeyCode.Name,
					Value = inputKeyCode.Value
				},

				UserInputType = {
					Name = inputType.Name,
					Value = inputType.Value
				},

				UserInputState = input.UserInputState,
				realKeyCode = inputKeyCode,
				realInputType = inputType
			};

			library.OnKeyRelease:Fire(fastInputObject);
		end;

		library.unloadMaid:GiveTask(UserInputService.InputBegan:Connect(onInputBegan));
		library.unloadMaid:GiveTask(UserInputService.InputEnded:Connect(onInputEnded));

		local function makeTooltip(interest, option)
			library.unloadMaid:GiveTask(interest.InputChanged:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if option.tip then
						library.tooltip.Text = option.tip;
						library.tooltip.Position = UDim2.new(0, input.Position.X + 26, 0, input.Position.Y + 36);
					end;
				end;
			end));

			library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if option.tip then
						library.tooltip.Position = UDim2.fromScale(10, 10);
					end;
				end;
			end));
		end;

		--Functions
		library.round = function(num, bracket)
			bracket = bracket or 1
			if typeof(num) == getServerConstant('Vector2') then
				return Vector2.new(library.round(num.X), library.round(num.Y))
			elseif typeof(num) == getServerConstant('Color3') then
				return library.round(num.r * 255), library.round(num.g * 255), library.round(num.b * 255)
			else
				return num - num % bracket;
			end
		end

		function library:Create(class, properties)
			properties = properties or {}
			if not class then return end
			local a = class == 'Square' or class == 'Line' or class == 'Text' or class == 'Quad' or class == 'Circle' or class == 'Triangle'
			local t = a and Drawing or Instance
			local inst = t.new(class)
			for property, value in next, properties do
				inst[property] = value
			end
			table.insert(self.instances, {object = inst, method = a})
			return inst
		end

		function library:AddConnection(connection, name, callback)
			callback = type(name) == 'function' and name or callback
			connection = connection:Connect(callback)
			self.unloadMaid:GiveTask(connection);
			if name ~= callback then
				self.connections[name] = connection
			else
				table.insert(self.connections, connection)
			end
			return connection
		end

		function library:Unload()
			task.wait();
			visualizer:Remove();

			for _, o in next, self.options do
				if o.type == 'toggle' and not string.find(string.lower(o.flag), 'panic') and o.flag ~= 'saveconfigauto' then
					pcall(o.SetState, o, false);
				end;
			end;

			library.unloadMaid:Destroy();
		end

		local function readFileAndDecodeIt(filePath)
			if (not isfile(filePath)) then return; end;

			local suc, fileContent = pcall(readfile, filePath);
			if (not suc) then return; end;

			local suc2, configData = pcall(HttpService.JSONDecode, HttpService, fileContent);
			if (not suc2) then return; end;

			return configData;
		end;

		local function getConfigForGame(configData)
			local configValueName = library.gameName or 'Universal';

			if (not configData[configValueName]) then
				configData[configValueName] = {};
			end;

			return configData[configValueName];
		end;

		function library:LoadConfig(configName)
			if (not table.find(self:GetConfigs(), configName)) then
				return;
			end;

			local filePath = string.format('%s/%s.%s%s', self.foldername, configName, 'config', self.fileext);
			local configData = readFileAndDecodeIt(filePath);
			if (not configData) then print('no config', configName); return; end;
			configData = getConfigForGame(configData);

			-- Set the loaded config to the new config so we save it only when its actually loaded
			library.loadedConfig = configName;
			library.options.configList:SetValue(configName);

			for _, option in next, self.options do
				if (not option.hasInit or option.type == 'button' or not option.flag or option.skipflag) then
					continue;
				end;

				local configDataVal = configData[option.flag];

				if (typeof(configDataVal) == 'nil') then
					continue;
				end;

				if (option.type == 'toggle') then
					task.spawn(option.SetState, option, configDataVal == 1);
				elseif (option.type == 'color') then
					task.spawn(option.SetColor, option, Color3.fromHex(configDataVal));

					if option.trans then
						task.spawn(option.SetTrans, option, configData[option.flag .. 'Transparency']);
					end;
				elseif (option.type == 'bind') then
					task.spawn(option.SetKeys, option, configDataVal);
				else
					task.spawn(option.SetValue, option, configDataVal);
				end;
			end;

			return true;
		end;

		function library:SaveConfig(configName)
			local filePath = string.format('%s/%s.%s%s', self.foldername, configName, 'config', self.fileext);
			local allConfigData = readFileAndDecodeIt(filePath) or {};

			if (allConfigData.configVersion ~= '1') then
				allConfigData = {};
				allConfigData.configVersion = '1';
			end;

			local configData = getConfigForGame(allConfigData);

			debug.profilebegin('Set config value');
			for _, option in next, self.options do
				if (option.type == 'button' or not option.flag) then continue end;
				if (option.skipflag or option.noSave) then continue end;

				local flag = option.flag;

				if (option.type == 'toggle') then
					configData[flag] = option.state and 1 or 0;
				elseif (option.type == 'color') then
					configData[flag] = option.color:ToHex();
					if (not option.trans) then continue end;
					configData[flag .. 'Transparency'] = option.trans;
				elseif (option.type == 'bind' and option.key ~= 'none') then
					local toSave = {};
					for _, v in next, option.keys do
						table.insert(toSave, v.Name);
					end;

					configData[flag] = toSave;
				elseif (option.type == 'list') then
					configData[flag] = option.value;
				elseif (option.type == 'box' and option.value ~= 'nil' and option.value ~= '') then
					configData[flag] = option.value;
				else
					configData[flag] = option.value;
				end;
			end;
			debug.profileend();

			local configVars = library.configVars;
			configVars.config = configName;

			debug.profilebegin('writefile');
			writefile(self.foldername .. '/' .. self.fileext, HttpService:JSONEncode(configVars));
			debug.profileend();

			debug.profilebegin('writefile');
			writefile(filePath, HttpService:JSONEncode(allConfigData));
			debug.profileend();
		end

		function library:GetConfigs()
			if not isfolder(self.foldername) then
				makefolder(self.foldername)
			end

			local configFiles = {};

			for i, v in next, listfiles(self.foldername) do
				local fileName = v:match('\\(.+)');
				local fileSubExtension = v:match('%.(.+)%.json');

				if (fileSubExtension == 'config') then
					table.insert(configFiles, fileName:match('(.-)%.config'));
				end;
			end;

			if (not table.find(configFiles, 'default')) then
				table.insert(configFiles, 'default');
			end;

			return configFiles;
		end

		function library:UpdateConfig()
			if (not library.hasInit) then return end;
			debug.profilebegin('Config Save');

			library:SaveConfig(library.loadedConfig or 'default');

			debug.profileend();
		end;

		local function createLabel(option, parent)
			option.main = library:Create('TextLabel', {
				LayoutOrder = option.position,
				Position = UDim2.new(0, 6, 0, 0),
				Size = UDim2.new(1, -12, 0, 24),
				BackgroundTransparency = 1,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				TextWrapped = true,
				RichText = true,
				Parent = parent
			})

			setmetatable(option, {__newindex = function(t, i, v)
				if i == 'Text' then
					option.main.Text = tostring(v)

					local textSize = TextService:GetTextSize(option.main.ContentText, 15, Enum.Font.Code, Vector2.new(option.main.AbsoluteSize.X, 9e9));
					option.main.Size = UDim2.new(1, -12, 0, textSize.Y);
				end
			end})

			option.Text = option.text
		end

		local function createDivider(option, parent)
			option.main = library:Create('Frame', {
				LayoutOrder = option.position,
				Size = UDim2.new(1, 0, 0, 18),
				BackgroundTransparency = 1,
				Parent = parent
			})

			library:Create('Frame', {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(1, -24, 0, 1),
				BackgroundColor3 = Color3.fromRGB(60, 60, 60),
				BorderColor3 = Color3.new(),
				Parent = option.main
			})

			option.title = library:Create('TextLabel', {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,
				TextColor3 =  Color3.new(1, 1, 1),
				TextSize = 15,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Center,
				Parent = option.main
			})

			local interest = option.main;
			makeTooltip(interest, option);

			setmetatable(option, {__newindex = function(t, i, v)
				if i == 'Text' then
					if v then
						option.title.Text = tostring(v)
						option.title.Size = UDim2.new(0, TextService:GetTextSize(option.title.Text, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 12, 0, 20)
						option.main.Size = UDim2.new(1, 0, 0, 18)
					else
						option.title.Text = ''
						option.title.Size = UDim2.new()
						option.main.Size = UDim2.new(1, 0, 0, 6)
					end
				end
			end})
			option.Text = option.text
		end

		local function createToggle(option, parent)
			option.hasInit = true
			option.onStateChanged = Signal.new();

			option.main = library:Create('Frame', {
				LayoutOrder = option.position,
				Size = UDim2.new(1, 0, 0, 0),
				BackgroundTransparency = 1,
				AutomaticSize = Enum.AutomaticSize.Y,
				Parent = parent
			})

			local tickbox
			local tickboxOverlay
			if option.style then
				tickbox = library:Create('ImageLabel', {
					Position = UDim2.new(0, 6, 0, 4),
					Size = UDim2.new(0, 12, 0, 12),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://3570695787',
					ImageColor3 = Color3.new(),
					Parent = option.main
				})

				library:Create('ImageLabel', {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -2, 1, -2),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://3570695787',
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					Parent = tickbox
				})

				library:Create('ImageLabel', {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -6, 1, -6),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://3570695787',
					ImageColor3 = Color3.fromRGB(40, 40, 40),
					Parent = tickbox
				})

				tickboxOverlay = library:Create('ImageLabel', {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, -6, 1, -6),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://3570695787',
					ImageColor3 = library.flags.menuAccentColor,
					Visible = option.state,
					Parent = tickbox
				})

				library:Create('ImageLabel', {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://5941353943',
					ImageTransparency = 0.6,
					Parent = tickbox
				})

				table.insert(library.theme, tickboxOverlay)
			else
				tickbox = library:Create('Frame', {
					Position = UDim2.new(0, 6, 0, 4),
					Size = UDim2.new(0, 12, 0, 12),
					BackgroundColor3 = library.flags.menuAccentColor,
					BorderColor3 = Color3.new(),
					Parent = option.main
				})

				tickboxOverlay = library:Create('ImageLabel', {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = option.state and 1 or 0,
					BackgroundColor3 = Color3.fromRGB(50, 50, 50),
					BorderColor3 = Color3.new(),
					Image = 'rbxassetid://4155801252',
					ImageTransparency = 0.6,
					ImageColor3 = Color3.new(),
					Parent = tickbox
				})

				library:Create('ImageLabel', {
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://2592362371',
					ImageColor3 = Color3.fromRGB(60, 60, 60),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = tickbox
				})

				library:Create('ImageLabel', {
					Size = UDim2.new(1, -2, 1, -2),
					Position = UDim2.new(0, 1, 0, 1),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://2592362371',
					ImageColor3 = Color3.new(),
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = Rect.new(2, 2, 62, 62),
					Parent = tickbox
				})

				table.insert(library.theme, tickbox)
			end

			option.interest = library:Create('Frame', {
				Position = UDim2.new(0, 0, 0, 0),
				Size = UDim2.new(1, 0, 0, 20),
				BackgroundTransparency = 1,
				Parent = option.main
			})

			option.title = library:Create('TextLabel', {
				Position = UDim2.new(0, 24, 0, 0),
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Text = option.text,
				TextColor3 =  option.state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(180, 180, 180),
				TextSize = 15,
				Font = Enum.Font.Code,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = option.interest
			})

			library.unloadMaid:GiveTask(option.interest.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					option:SetState(not option.state)
				end
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						if option.style then
							tickbox.ImageColor3 = library.flags.menuAccentColor
						else
							tickbox.BorderColor3 = library.flags.menuAccentColor
							tickboxOverlay.BorderColor3 = library.flags.menuAccentColor
						end
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end))

			makeTooltip(option.interest, option);

			library.unloadMaid:GiveTask(option.interest.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if option.style then
						tickbox.ImageColor3 = Color3.new()
					else
						tickbox.BorderColor3 = Color3.new()
						tickboxOverlay.BorderColor3 = Color3.new()
					end
				end
			end));

			function option:SetState(state, nocallback)
				state = typeof(state) == 'boolean' and state
				state = state or false
				library.flags[self.flag] = state
				self.state = state
				option.title.TextColor3 = state and Color3.fromRGB(210, 210, 210) or Color3.fromRGB(160, 160, 160)
				if option.style then
					tickboxOverlay.Visible = state
				else
					tickboxOverlay.BackgroundTransparency = state and 1 or 0
				end

				if not nocallback then
					task.spawn(self.callback, state);
				end

				option.onStateChanged:Fire(state);
				library.OnFlagChanged:Fire(self);
			end

			task.defer(function()
				option:SetState(option.state);
			end);

			setmetatable(option, {__newindex = function(t, i, v)
				if i == 'Text' then
					option.title.Text = tostring(v)
				else
					rawset(t, i, v);
				end
			end})
		end

		local function createButton(option, parent)
			option.hasInit = true

			option.main = option.sub and option:getMain() or library:Create('Frame', {
				LayoutOrder = option.position,
				Size = UDim2.new(1, 0, 0, 26),
				BackgroundTransparency = 1,
				Parent = parent
			})

			option.title = library:Create('TextLabel', {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, -5),
				Size = UDim2.new(1, -12, 0, 18),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderColor3 = Color3.new(),
				Text = option.text,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 15,
				Font = Enum.Font.Code,
				Parent = option.main
			})

			if (option.sub) then
				if (not option.parent.subInit) then
					option.parent.subInit = true;

					-- If we are a sub option then set some properties of parent

					option.parent.title.Size = UDim2.fromOffset(0, 18);

					option.parent.listLayout = library:Create('UIGridLayout', {
						Parent = option.parent.main,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						FillDirection = Enum.FillDirection.Vertical,
						VerticalAlignment = Enum.VerticalAlignment.Center,
						CellSize = UDim2.new(1 / (#option.main:GetChildren()-1), -8, 0, 18)
					});
				end;

				option.parent.listLayout.CellSize = UDim2.new(1 / (#option.parent.main:GetChildren()-1), -8, 0, 18);
			end;

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.title
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.title
			})

			library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 180, 180)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(253, 253, 253)),
				}),
				Rotation = -90,
				Parent = option.title
			})

			library.unloadMaid:GiveTask(option.title.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					option.callback()
					if library then
						library.flags[option.flag] = true
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						option.title.BorderColor3 = library.flags.menuAccentColor;
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end));

			makeTooltip(option.title, option);

			library.unloadMaid:GiveTask(option.title.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					option.title.BorderColor3 = Color3.new();
				end
			end));
		end

		local function createBind(option, parent)
			option.hasInit = true

			local Loop
			local maid = Maid.new()

			library.unloadMaid:GiveTask(function()
				maid:Destroy();
			end);

			if option.sub then
				option.main = option:getMain()
			else
				option.main = option.main or library:Create('Frame', {
					LayoutOrder = option.position,
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Parent = parent
				})

				option.title = library:Create('TextLabel', {
					Position = UDim2.new(0, 6, 0, 0),
					Size = UDim2.new(1, -12, 1, 0),
					BackgroundTransparency = 1,
					Text = option.text,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = Color3.fromRGB(210, 210, 210),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = option.main
				})
			end

			local bindinput = library:Create(option.sub and 'TextButton' or 'TextLabel', {
				Position = UDim2.new(1, -6 - (option.subpos or 0), 0, option.sub and 2 or 3),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.fromRGB(160, 160, 160),
				TextXAlignment = Enum.TextXAlignment.Right,
				Parent = option.main
			})

			if option.sub then
				bindinput.AutoButtonColor = false
			end

			local interest = option.sub and bindinput or option.main;
			local maid = Maid.new();

			local function formatKey(key)
				if (key:match('Mouse')) then
					key = key:gsub('Button', ''):gsub('Mouse', 'M');
				elseif (key:match('Shift') or key:match('Alt') or key:match('Control')) then
					key = key:gsub('Left', 'L'):gsub('Right', 'R');
				end;

				return key:gsub('Control', 'CTRL'):upper();
			end;

			local function formatKeys(keys)
				if (not keys) then return {}; end;
				local ret = {};

				for _, key in next, keys do
					table.insert(ret, formatKey(typeof(key) == 'string' and key or key.Name));
				end;

				return ret;
			end;

			local busy = false;

			makeTooltip(interest, option);

			library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' and not busy then
					busy = true;
					library.disableKeyBind = true;

					bindinput.Text = '[...]'
					bindinput.Size = UDim2.new(0, -TextService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)
					bindinput.TextColor3 = library.flags.menuAccentColor

					local displayKeys = {};
					local keys = {};

					maid.keybindLoop = RunService.Heartbeat:Connect(function()
						for _, key in next, UserInputService:GetKeysPressed() do
							local value = formatKey(key.KeyCode.Name);

							if (value == 'BACKSPACE') then
								maid.keybindLoop = nil;
								option:SetKeys('none');
								return;
							end;

							if (table.find(displayKeys, value)) then continue; end;
							table.insert(displayKeys, value);
							table.insert(keys, key.KeyCode);
						end;

						for _, mouseBtn in next, UserInputService:GetMouseButtonsPressed() do
							local value = formatKey(mouseBtn.UserInputType.Name);

							if (option.nomouse) then continue end;
							if (not table.find(whitelistedMouseinputs, mouseBtn.UserInputType)) then continue end;

							if (table.find(displayKeys, value)) then continue; end;

							table.insert(displayKeys, value);
							table.insert(keys, mouseBtn.UserInputType);
						end;

						bindinput.Text = '[' .. table.concat(displayKeys, '+') .. ']';

						if (#displayKeys == 3) then
							maid.keybindLoop = nil;
						end;
					end);

					task.wait(0.05);
					maid.onInputEnded = UserInputService.InputEnded:Connect(function(input)
						if(input.UserInputType ~= Enum.UserInputType.Keyboard and not input.UserInputType.Name:find('MouseButton')) then return; end;

						maid.keybindLoop = nil;
						maid.onInputEnded = nil;

						option:SetKeys(keys);
						library.disableKeyBind = false;
						task.wait(0.2);
						busy = false;
					end);
				end
			end));

			local function isKeybindPressed()
				local foundCount = 0;

				for _, key in next, UserInputService:GetKeysPressed() do
					if (table.find(option.keys, key.KeyCode)) then
						foundCount += 1;
					end;
				end;

				for _, key in next, UserInputService:GetMouseButtonsPressed() do
					if (table.find(option.keys, key.UserInputType)) then
						foundCount += 1;
					end;
				end;

				return foundCount == #option.keys;
			end;

			local debounce = false;

			function option:SetKeys(keys)
				if (typeof(keys) == 'string') then
					keys = {keys};
				end;

				keys = keys or {option.key ~= 'none' and option.key or nil};

				for i, key in next, keys do
					if (typeof(key) == 'string' and key ~= 'none') then
						local isMouse = key:find('MouseButton');

						if (isMouse) then
							keys[i] = Enum.UserInputType[key];
						else
							keys[i] = Enum.KeyCode[key];
						end;
					end;
				end;

				bindinput.TextColor3 = Color3.fromRGB(160, 160, 160)

				if Loop then
					Loop:Disconnect()
					Loop = nil;
					library.flags[option.flag] = false
					option.callback(true, 0)
				end

				self.keys = keys;

				if self.keys[1] == 'Backspace' or #self.keys == 0 then
					self.key = 'none'
					bindinput.Text = '[NONE]'

					if (#self.keys ~= 0) then
						visualizer:RemoveText(self.text);
					end;
				else
					if (self.parentFlag and self.key ~= 'none') then
						if (library.flags[self.parentFlag]) then
							visualizer:AddText(self.text);
						end;
					end;

					local formattedKey = formatKeys(self.keys);
					bindinput.Text = '[' .. table.concat(formattedKey, '+') .. ']';
					self.key = table.concat(formattedKey, '+');
				end

				bindinput.Size = UDim2.new(0, -TextService:GetTextSize(bindinput.Text, 16, Enum.Font.Code, Vector2.new(9e9, 9e9)).X, 0, 16)

				if (self.key == 'none') then
					maid.onKeyPress = nil;
					maid.onKeyRelease = nil;
				else
					maid.onKeyPress = library.OnKeyPress:Connect(function()
						if (library.disableKeyBind or #option.keys == 0 or debounce) then return end;
						if (not isKeybindPressed()) then return; end;

						debounce = true;

						if option.mode == 'toggle' then
							library.flags[option.flag] = not library.flags[option.flag]
							option.callback(library.flags[option.flag], 0)
						else
							library.flags[option.flag] = true

							if Loop then
								Loop:Disconnect();
								Loop = nil;
								option.callback(true, 0);
							end;

							Loop = library:AddConnection(RunService.Heartbeat, function(step)
								if not UserInputService:GetFocusedTextBox() then
									option.callback(nil, step)
								end
							end)
						end
					end);

					maid.onKeyRelease = library.OnKeyRelease:Connect(function()
						if (debounce and not isKeybindPressed()) then debounce = false; end;
						if (option.mode ~= 'hold') then return; end;

						local bindKey = option.key;
						if (bindKey == 'none') then return end;

						if not isKeybindPressed() then
							if Loop then
								Loop:Disconnect()
								Loop = nil;

								library.flags[option.flag] = false
								option.callback(true, 0)
							end
						end
					end);
				end;
			end;

			option:SetKeys();
		end

		local function createSlider(option, parent)
			option.hasInit = true

			if option.sub then
				option.main = option:getMain()
			else
				option.main = library:Create('Frame', {
					LayoutOrder = option.position,
					Size = UDim2.new(1, 0, 0, option.textpos and 24 or 40),
					BackgroundTransparency = 1,
					Parent = parent
				})
			end

			option.slider = library:Create('Frame', {
				Position = UDim2.new(0, 6, 0, (option.sub and 22 or option.textpos and 4 or 20)),
				Size = UDim2.new(1, -12, 0, 16),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderColor3 = Color3.new(),
				Parent = option.main
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.8,
				Parent = option.slider
			})

			option.fill = library:Create('Frame', {
				BackgroundColor3 = library.flags.menuAccentColor,
				BorderSizePixel = 0,
				Parent = option.slider
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.slider
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.slider
			})

			option.title = library:Create('TextBox', {
				Position = UDim2.new((option.sub or option.textpos) and 0.5 or 0, (option.sub or option.textpos) and 0 or 6, 0, 0),
				Size = UDim2.new(0, 0, 0, (option.sub or option.textpos) and 14 or 18),
				BackgroundTransparency = 1,
				Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix,
				TextSize = (option.sub or option.textpos) and 14 or 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.fromRGB(210, 210, 210),
				TextXAlignment = Enum.TextXAlignment[(option.sub or option.textpos) and 'Center' or 'Left'],
				Parent = (option.sub or option.textpos) and option.slider or option.main
			})
			table.insert(library.theme, option.fill)

			library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(115, 115, 115)),
					ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
				}),
				Rotation = -90,
				Parent = option.fill
			})

			if option.min >= 0 then
				option.fill.Size = UDim2.new((option.value - option.min) / (option.max - option.min), 0, 1, 0)
			else
				option.fill.Position = UDim2.new((0 - option.min) / (option.max - option.min), 0, 0, 0)
				option.fill.Size = UDim2.new(option.value / (option.max - option.min), 0, 1, 0)
			end

			local manualInput
			library.unloadMaid:GiveTask(option.title.Focused:connect(function()
				if not manualInput then
					option.title:ReleaseFocus()
					option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix
				end
			end));

			library.unloadMaid:GiveTask(option.title.FocusLost:connect(function()
				option.slider.BorderColor3 = Color3.new()
				if manualInput then
					if tonumber(option.title.Text) then
						option:SetValue(tonumber(option.title.Text))
					else
						option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. option.value .. option.suffix
					end
				end
				manualInput = false
			end));

			local interest = (option.sub or option.textpos) and option.slider or option.main
			library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.RightControl) then
						manualInput = true
						option.title:CaptureFocus()
					else
						library.slider = option
						option.slider.BorderColor3 = library.flags.menuAccentColor
						option:SetValue(option.min + ((input.Position.X - option.slider.AbsolutePosition.X) / option.slider.AbsoluteSize.X) * (option.max - option.min))
					end
				end
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						option.slider.BorderColor3 = library.flags.menuAccentColor
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end));

			makeTooltip(interest, option);

			library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if option ~= library.slider then
						option.slider.BorderColor3 = Color3.new();
					end;
				end;
			end));

			if (option.parent) then
				local oldParent = option.slider.Parent;

				option.parent.onStateChanged:Connect(function(state)
					option.slider.Parent = state and oldParent or nil;
				end);
			end;

			local tweenInfo = TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

			function option:SetValue(value, nocallback)
				value = value or self.value;

				value = library.round(value, option.float)
				value = math.clamp(value, self.min, self.max)

				if self.min >= 0 then
					TweenService:Create(option.fill, tweenInfo, {Size = UDim2.new((value - self.min) / (self.max - self.min), 0, 1, 0)}):Play();
				else
					TweenService:Create(option.fill, tweenInfo, {
						Size = UDim2.new(value / (self.max - self.min), 0, 1, 0),
						Position = UDim2.new((0 - self.min) / (self.max - self.min), 0, 0, 0)
					}):Play();
				end
				library.flags[self.flag] = value
				self.value = value
				option.title.Text = (option.text == 'nil' and '' or option.text .. ': ') .. string.format(option.float == 1 and '%d' or '%.02f', option.value) .. option.suffix
				if not nocallback then
					task.spawn(self.callback, value)
				end

				library.OnFlagChanged:Fire(self)
			end

			task.defer(function()
				if library then
					option:SetValue(option.value)
				end
			end)
		end

		local function createList(option, parent)
			option.hasInit = true

			if option.sub then
				option.main = option:getMain()
				option.main.Size = UDim2.new(1, 0, 0, 48)
			else
				option.main = library:Create('Frame', {
					LayoutOrder = option.position,
					Size = UDim2.new(1, 0, 0, option.text == 'nil' and 30 or 48),
					BackgroundTransparency = 1,
					Parent = parent
				})

				if option.text ~= 'nil' then
					library:Create('TextLabel', {
						Position = UDim2.new(0, 6, 0, 0),
						Size = UDim2.new(1, -12, 0, 18),
						BackgroundTransparency = 1,
						Text = option.text,
						TextSize = 15,
						Font = Enum.Font.Code,
						TextColor3 = Color3.fromRGB(210, 210, 210),
						TextXAlignment = Enum.TextXAlignment.Left,
						Parent = option.main
					})
				end
			end

			if(option.playerOnly) then
				library.OnLoad:Connect(function()
					option.values = {};

					for i,v in next, Players:GetPlayers() do
						if (v == LocalPlayer) then continue end;
						option:AddValue(v.Name);
					end;

					library.unloadMaid:GiveTask(Players.PlayerAdded:Connect(function(plr)
						option:AddValue(plr.Name);
					end));

					library.unloadMaid:GiveTask(Players.PlayerRemoving:Connect(function(plr)
						option:RemoveValue(plr.Name);
					end));
				end);
			end;

			local function getMultiText()
				local t = {};

				if (option.playerOnly and option.multiselect) then
					for i, v in next, option.values do
						if (option.value[i]) then
							table.insert(t, tostring(i));
						end;
					end;
				else
					for i, v in next, option.values do
						if (option.value[v]) then
							table.insert(t, tostring(v));
						end;
					end;
				end;

				return table.concat(t, ', ');
			end

			option.listvalue = library:Create('TextBox', {
				Position = UDim2.new(0, 6, 0, (option.text == 'nil' and not option.sub) and 4 or 22),
				Size = UDim2.new(1, -12, 0, 22),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderColor3 = Color3.new(),
				Active = false,
				ClearTextOnFocus = false,
				Text = ' ' .. (typeof(option.value) == 'string' and option.value or getMultiText()),
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = option.main
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.8,
				Parent = option.listvalue
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.listvalue
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.listvalue
			})

			option.arrow = library:Create('ImageLabel', {
				Position = UDim2.new(1, -16, 0, 7),
				Size = UDim2.new(0, 8, 0, 8),
				Rotation = 90,
				BackgroundTransparency = 1,
				Image = 'rbxassetid://4918373417',
				ImageColor3 = Color3.new(1, 1, 1),
				ScaleType = Enum.ScaleType.Fit,
				ImageTransparency = 0.4,
				Parent = option.listvalue
			})

			option.holder = library:Create('TextButton', {
				ZIndex = 4,
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderColor3 = Color3.new(),
				Text = '',
				TextColor3 = Color3.fromRGB(255,255, 255),
				AutoButtonColor = false,
				Visible = false,
				Parent = library.base
			})

			option.content = library:Create('ScrollingFrame', {
				ZIndex = 4,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
				ScrollBarThickness = 6,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				VerticalScrollBarInset = Enum.ScrollBarInset.Always,
				TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
				BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
				Parent = option.holder
			})

			library:Create('ImageLabel', {
				ZIndex = 4,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.holder
			})

			library:Create('ImageLabel', {
				ZIndex = 4,
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.holder
			})

			local layout = library:Create('UIListLayout', {
				Padding = UDim.new(0, 2),
				Parent = option.content
			})

			library:Create('UIPadding', {
				PaddingTop = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
				Parent = option.content
			})

			local valueCount = 0;

			local function updateHolder(newValueCount)
				option.holder.Size = UDim2.new(0, option.listvalue.AbsoluteSize.X, 0, 8 + ((newValueCount or valueCount) > option.max and (-2 + (option.max * 22)) or layout.AbsoluteContentSize.Y))
				option.content.CanvasSize = UDim2.new(0, 0, 0, 8 + layout.AbsoluteContentSize.Y)
			end;

			library.unloadMaid:GiveTask(layout.Changed:Connect(function() updateHolder(); end));
			local interest = option.sub and option.listvalue or option.main
			local focused = false;

			library.unloadMaid:GiveTask(option.listvalue.Focused:Connect(function() focused = true; end));
			library.unloadMaid:GiveTask(option.listvalue.FocusLost:Connect(function() focused = false; end));

			library.unloadMaid:GiveTask(option.listvalue:GetPropertyChangedSignal('Text'):Connect(function()
				if (not focused) then return end;
				local newText = option.listvalue.Text;

				if (newText:sub(1, 1) ~= ' ') then
					newText = ' ' .. newText;
					option.listvalue.Text = newText;
					option.listvalue.CursorPosition = 2;
				end;

				local search = string.lower(newText:sub(2));
				local matchedResults = 0;

				for name, label in next, option.labels do
					if (string.find(string.lower(name), search)) then
						matchedResults += 1;
						label.Visible = true;
					else
						label.Visible = false;
					end;
				end;

				updateHolder(matchedResults);
			end));

			library.unloadMaid:GiveTask(option.listvalue.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					if library.popup == option then library.popup:Close() return end
					if library.popup then
						library.popup:Close()
					end
					option.arrow.Rotation = -90
					option.open = true
					option.holder.Visible = true
					local pos = option.main.AbsolutePosition
					option.holder.Position = UDim2.new(0, pos.X + 6, 0, pos.Y + ((option.text == 'nil' and not option.sub) and 66 or 84))
					library.popup = option
					option.listvalue.BorderColor3 = library.flags.menuAccentColor
					option.listvalue:CaptureFocus();
					option.listvalue.CursorPosition = string.len(typeof(option.value) == 'string' and option.value or getMultiText() or option.value) + 2;

					if (option.multiselect) then
						option.listvalue.Text = ' ';
					end;
				end
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						option.listvalue.BorderColor3 = library.flags.menuAccentColor
					end
				end
			end));

			library.unloadMaid:GiveTask(option.listvalue.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if not option.open then
						option.listvalue.BorderColor3 = Color3.new()
					end
				end
			end));

			library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end));

			makeTooltip(interest, option);

			function option:AddValue(value, state)
				if self.labels[value] then return end
				state = state or (option.playerOnly and false)

				valueCount = valueCount + 1

				if self.multiselect then
					self.values[value] = state
				else
					if not table.find(self.values, value) then
						table.insert(self.values, value)
					end
				end

				local label = library:Create('TextLabel', {
					ZIndex = 4,
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Text = value,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextTransparency = self.multiselect and (self.value[value] and 1 or 0) or self.value == value and 1 or 0,
					TextColor3 = Color3.fromRGB(210, 210, 210),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = option.content
				})

				self.labels[value] = label

				local labelOverlay = library:Create('TextLabel', {
					ZIndex = 4,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 0.8,
					Text = ' ' ..value,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = library.flags.menuAccentColor,
					TextXAlignment = Enum.TextXAlignment.Left,
					Visible = self.multiselect and self.value[value] or self.value == value,
					Parent = label
				});

				table.insert(library.theme, labelOverlay)

				library.unloadMaid:GiveTask(label.InputBegan:connect(function(input)
					if input.UserInputType.Name == 'MouseButton1' then
						if self.multiselect then
							self.value[value] = not self.value[value]
							self:SetValue(self.value);
							self.listvalue.Text = ' ';
							self.listvalue.CursorPosition = 2;
							self.listvalue:CaptureFocus();
						else
							self:SetValue(value)
							self:Close()
						end
					end
				end));
			end

			for i, value in next, option.values do
				option:AddValue(tostring(typeof(i) == 'number' and value or i))
			end

			function option:RemoveValue(value)
				local label = self.labels[value]
				if label then
					label:Destroy()
					self.labels[value] = nil
					valueCount = valueCount - 1
					if self.multiselect then
						self.values[value] = nil
						self:SetValue(self.value)
					else
						table.remove(self.values, table.find(self.values, value))
						if self.value == value then
							self:SetValue(self.values[1] or '')

							if (not self.values[1]) then
								option.listvalue.Text = '';
							end;
						end
					end
				end
			end

			function option:SetValue(value, nocallback)
				if self.multiselect and typeof(value) ~= 'table' then
					value = {}
					for i,v in next, self.values do
						value[v] = false
					end
				end

				if (not value) then return end;

				self.value = self.multiselect and value or self.values[table.find(self.values, value) or 1];
				if (self.playerOnly and not self.multiselect) then
					self.value = Players:FindFirstChild(value);
				end;

				if (not self.value) then return end;

				library.flags[self.flag] = self.value;
				option.listvalue.Text = ' ' .. (self.multiselect and getMultiText() or tostring(self.value));

				for name, label in next, self.labels do
					local visible = self.multiselect and self.value[name] or self.value == name;
					label.TextTransparency = visible and 1 or 0;
					if label:FindFirstChild'TextLabel' then
						label.TextLabel.Visible = visible;
					end;
				end;

				if not nocallback then
					self.callback(self.value)
				end
			end

			task.defer(function()
				if library and not option.noload then
					option:SetValue(option.value)
				end
			end)

			function option:Close()
				library.popup = nil
				option.arrow.Rotation = 90
				self.open = false
				option.holder.Visible = false
				option.listvalue.BorderColor3 = Color3.new()
				option.listvalue:ReleaseFocus();
				option.listvalue.Text = ' ' .. (self.multiselect and getMultiText() or tostring(self.value));

				for _, label in next, option.labels do
					label.Visible = true;
				end;
			end

			return option
		end

		local function createBox(option, parent)
			option.hasInit = true

			option.main = library:Create('Frame', {
				LayoutOrder = option.position,
				Size = UDim2.new(1, 0, 0, option.text == 'nil' and 28 or 44),
				BackgroundTransparency = 1,
				Parent = parent
			})

			if option.text ~= 'nil' then
				option.title = library:Create('TextLabel', {
					Position = UDim2.new(0, 6, 0, 0),
					Size = UDim2.new(1, -12, 0, 18),
					BackgroundTransparency = 1,
					Text = option.text,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = Color3.fromRGB(210, 210, 210),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = option.main
				})
			end

			option.holder = library:Create('Frame', {
				Position = UDim2.new(0, 6, 0, option.text == 'nil' and 4 or 20),
				Size = UDim2.new(1, -12, 0, 20),
				BackgroundColor3 = Color3.fromRGB(50, 50, 50),
				BorderColor3 = Color3.new(),
				Parent = option.main
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.8,
				Parent = option.holder
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.holder
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.holder
			})

			local inputvalue = library:Create('TextBox', {
				Position = UDim2.new(0, 4, 0, 0),
				Size = UDim2.new(1, -4, 1, 0),
				BackgroundTransparency = 1,
				Text = '  ' .. option.value,
				TextSize = 15,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = true,
				ClearTextOnFocus = false,
				Parent = option.holder
			})

			library.unloadMaid:GiveTask(inputvalue.FocusLost:connect(function(enter)
				option.holder.BorderColor3 = Color3.new()
				option:SetValue(inputvalue.Text, enter)
			end));

			library.unloadMaid:GiveTask(inputvalue.Focused:connect(function()
				option.holder.BorderColor3 = library.flags.menuAccentColor
			end));

			library.unloadMaid:GiveTask(inputvalue.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						option.holder.BorderColor3 = library.flags.menuAccentColor
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end));

			makeTooltip(inputvalue, option);

			library.unloadMaid:GiveTask(inputvalue.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if not inputvalue:IsFocused() then
						option.holder.BorderColor3 = Color3.new();
					end;
				end;
			end));

			function option:SetValue(value, enter)
				if (value:gsub('%s+', '') == '') then
					value = '';
				end;

				library.flags[self.flag] = tostring(value);
				self.value = tostring(value);
				inputvalue.Text = self.value;
				self.callback(value, enter);

				library.OnFlagChanged:Fire(self);
			end
			task.defer(function()
				if library then
					option:SetValue(option.value)
				end
			end)
		end

		local function createColorPickerWindow(option)
			option.mainHolder = library:Create('TextButton', {
				ZIndex = 4,
				--Position = UDim2.new(1, -184, 1, 6),
				Size = UDim2.new(0, option.trans and 200 or 184, 0, 264),
				BackgroundColor3 = Color3.fromRGB(40, 40, 40),
				BorderColor3 = Color3.new(),
				AutoButtonColor = false,
				Visible = false,
				Parent = library.base
			})

			option.rgbBox = library:Create('Frame', {
				Position = UDim2.new(0, 6, 0, 214),
				Size = UDim2.new(0, (option.mainHolder.AbsoluteSize.X - 12), 0, 20),
				BackgroundColor3 = Color3.fromRGB(57, 57, 57),
				BorderColor3 = Color3.new(),
				ZIndex = 5;
				Parent = option.mainHolder
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.8,
				ZIndex = 6;
				Parent = option.rgbBox
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				ZIndex = 6;
				Parent = option.rgbBox
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				ZIndex = 6;
				Parent = option.rgbBox
			})

			local r, g, b = library.round(option.color);
			local colorText = table.concat({r, g, b}, ',');

			option.rgbInput = library:Create('TextBox', {
				Position = UDim2.new(0, 4, 0, 0),
				Size = UDim2.new(1, -4, 1, 0),
				BackgroundTransparency = 1,
				Text = colorText,
				TextSize = 14,
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Center,
				TextWrapped = true,
				ClearTextOnFocus = false,
				ZIndex = 6;
				Parent = option.rgbBox
			})

			option.hexBox = option.rgbBox:Clone()
			option.hexBox.Position = UDim2.new(0, 6, 0, 238)
			-- option.hexBox.Size = UDim2.new(0, (option.mainHolder.AbsoluteSize.X/2 - 10), 0, 20)
			option.hexBox.Parent = option.mainHolder
			option.hexInput = option.hexBox.TextBox;

			library:Create('ImageLabel', {
				ZIndex = 4,
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.mainHolder
			})

			library:Create('ImageLabel', {
				ZIndex = 4,
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.mainHolder
			})

			local hue, sat, val = Color3.toHSV(option.color)
			hue, sat, val = hue == 0 and 1 or hue, sat + 0.005, val - 0.005
			local editinghue
			local editingsatval
			local editingtrans

			local transMain
			if option.trans then
				transMain = library:Create('ImageLabel', {
					ZIndex = 5,
					Size = UDim2.new(1, 0, 1, 0),
					BackgroundTransparency = 1,
					Image = 'rbxassetid://2454009026',
					ImageColor3 = Color3.fromHSV(hue, 1, 1),
					Rotation = 180,
					Parent = library:Create('ImageLabel', {
						ZIndex = 4,
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.new(1, -6, 0, 6),
						Size = UDim2.new(0, 10, 1, -60),
						BorderColor3 = Color3.new(),
						Image = 'rbxassetid://4632082392',
						ScaleType = Enum.ScaleType.Tile,
						TileSize = UDim2.new(0, 5, 0, 5),
						Parent = option.mainHolder
					})
				})

				option.transSlider = library:Create('Frame', {
					ZIndex = 5,
					Position = UDim2.new(0, 0, option.trans, 0),
					Size = UDim2.new(1, 0, 0, 2),
					BackgroundColor3 = Color3.fromRGB(38, 41, 65),
					BorderColor3 = Color3.fromRGB(255, 255, 255),
					Parent = transMain
				})

				library.unloadMaid:GiveTask(transMain.InputBegan:connect(function(Input)
					if Input.UserInputType.Name == 'MouseButton1' then
						editingtrans = true
						option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
					end
				end));

				library.unloadMaid:GiveTask(transMain.InputEnded:connect(function(Input)
					if Input.UserInputType.Name == 'MouseButton1' then
						editingtrans = false
					end
				end));
			end

			local hueMain = library:Create('Frame', {
				ZIndex = 4,
				AnchorPoint = Vector2.new(0, 1),
				Position = UDim2.new(0, 6, 1, -54),
				Size = UDim2.new(1, option.trans and -28 or -12, 0, 10),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderColor3 = Color3.new(),
				Parent = option.mainHolder
			})

			library:Create('UIGradient', {
				Color = ColorSequence.new({
					ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
					ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 0, 255)),
					ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 0, 255)),
					ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 255, 0)),
					ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 255, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
				}),
				Parent = hueMain
			})

			local hueSlider = library:Create('Frame', {
				ZIndex = 4,
				Position = UDim2.new(1 - hue, 0, 0, 0),
				Size = UDim2.new(0, 2, 1, 0),
				BackgroundColor3 = Color3.fromRGB(38, 41, 65),
				BorderColor3 = Color3.fromRGB(255, 255, 255),
				Parent = hueMain
			})

			library.unloadMaid:GiveTask(hueMain.InputBegan:connect(function(Input)
				if Input.UserInputType.Name == 'MouseButton1' then
					editinghue = true
					local X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
					X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
					option:SetColor(Color3.fromHSV(1 - X, sat, val))
				end
			end));

			library.unloadMaid:GiveTask(hueMain.InputEnded:connect(function(Input)
				if Input.UserInputType.Name == 'MouseButton1' then
					editinghue = false
				end
			end));

			local satval = library:Create('ImageLabel', {
				ZIndex = 4,
				Position = UDim2.new(0, 6, 0, 6),
				Size = UDim2.new(1, option.trans and -28 or -12, 1, -74),
				BackgroundColor3 = Color3.fromHSV(hue, 1, 1),
				BorderColor3 = Color3.new(),
				Image = 'rbxassetid://4155801252',
				ClipsDescendants = true,
				Parent = option.mainHolder
			})

			local satvalSlider = library:Create('Frame', {
				ZIndex = 4,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(sat, 0, 1 - val, 0),
				Size = UDim2.new(0, 4, 0, 4),
				Rotation = 45,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				Parent = satval
			})

			library.unloadMaid:GiveTask(satval.InputBegan:connect(function(Input)
				if Input.UserInputType.Name == 'MouseButton1' then
					editingsatval = true
					local X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
					local Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
					X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
					Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
					option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
				end
			end));

			library:AddConnection(UserInputService.InputChanged, function(Input)
				if (not editingsatval and not editinghue and not editingtrans) then return end;

				if Input.UserInputType.Name == 'MouseMovement' then
					if editingsatval then
						local X = (satval.AbsolutePosition.X + satval.AbsoluteSize.X) - satval.AbsolutePosition.X
						local Y = (satval.AbsolutePosition.Y + satval.AbsoluteSize.Y) - satval.AbsolutePosition.Y
						X = math.clamp((Input.Position.X - satval.AbsolutePosition.X) / X, 0.005, 1)
						Y = math.clamp((Input.Position.Y - satval.AbsolutePosition.Y) / Y, 0, 0.995)
						option:SetColor(Color3.fromHSV(hue, X, 1 - Y))
					elseif editinghue then
						local X = (hueMain.AbsolutePosition.X + hueMain.AbsoluteSize.X) - hueMain.AbsolutePosition.X
						X = math.clamp((Input.Position.X - hueMain.AbsolutePosition.X) / X, 0, 0.995)
						option:SetColor(Color3.fromHSV(1 - X, sat, val))
					elseif editingtrans then
						option:SetTrans(1 - ((Input.Position.Y - transMain.AbsolutePosition.Y) / transMain.AbsoluteSize.Y))
					end
				end
			end)

			library.unloadMaid:GiveTask(satval.InputEnded:connect(function(Input)
				if Input.UserInputType.Name == 'MouseButton1' then
					editingsatval = false
				end
			end));

			option.hexInput.Text = option.color:ToHex();

			library.unloadMaid:GiveTask(option.rgbInput.FocusLost:connect(function()
				local color = Color3.fromRGB(unpack(option.rgbInput.Text:split(',')));
				return option:SetColor(color)
			end));

			library.unloadMaid:GiveTask(option.hexInput.FocusLost:connect(function()
				local color = Color3.fromHex(option.hexInput.Text);
				return option:SetColor(color);
			end));

			function option:updateVisuals(Color)
				hue, sat, val = Color:ToHSV();
				hue, sat, val = math.clamp(hue, 0, 1), math.clamp(sat, 0, 1), math.clamp(val, 0, 1);

				hue = hue == 0 and 1 or hue
				satval.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				if option.trans then
					transMain.ImageColor3 = Color3.fromHSV(hue, 1, 1)
				end
				hueSlider.Position = UDim2.new(1 - hue, 0, 0, 0)
				satvalSlider.Position = UDim2.new(sat, 0, 1 - val, 0)

				local color = Color3.fromHSV(hue, sat, val);
				local r, g, b = library.round(color);

				option.hexInput.Text = color:ToHex();
				option.rgbInput.Text = table.concat({r, g, b}, ',');
			end

			return option
		end

		local function createColor(option, parent)
			option.hasInit = true

			if option.sub then
				option.main = option:getMain()
			else
				option.main = library:Create('Frame', {
					LayoutOrder = option.position,
					Size = UDim2.new(1, 0, 0, 20),
					BackgroundTransparency = 1,
					Parent = parent
				})

				option.title = library:Create('TextLabel', {
					Position = UDim2.new(0, 6, 0, 0),
					Size = UDim2.new(1, -12, 1, 0),
					BackgroundTransparency = 1,
					Text = option.text,
					TextSize = 15,
					Font = Enum.Font.Code,
					TextColor3 = Color3.fromRGB(210, 210, 210),
					TextXAlignment = Enum.TextXAlignment.Left,
					Parent = option.main
				})
			end

			option.visualize = library:Create(option.sub and 'TextButton' or 'Frame', {
				Position = UDim2.new(1, -(option.subpos or 0) - 24, 0, 4),
				Size = UDim2.new(0, 18, 0, 12),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundColor3 = option.color,
				BorderColor3 = Color3.new(),
				Parent = option.main
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.6,
				Parent = option.visualize
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.visualize
			})

			library:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = option.visualize
			})

			local interest = option.sub and option.visualize or option.main

			if option.sub then
				option.visualize.Text = ''
				option.visualize.AutoButtonColor = false
			end

			library.unloadMaid:GiveTask(interest.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					if not option.mainHolder then
						createColorPickerWindow(option)
					end
					if library.popup == option then library.popup:Close() return end
					if library.popup then library.popup:Close() end
					option.open = true
					local pos = option.main.AbsolutePosition
					option.mainHolder.Position = UDim2.new(0, pos.X + 36 + (option.trans and -16 or 0), 0, pos.Y + 56)
					option.mainHolder.Visible = true
					library.popup = option
					option.visualize.BorderColor3 = library.flags.menuAccentColor
				end
				if input.UserInputType.Name == 'MouseMovement' then
					if not library.warning and not library.slider then
						option.visualize.BorderColor3 = library.flags.menuAccentColor
					end
					if option.tip then
						library.tooltip.Text = option.tip;
					end
				end
			end));

			makeTooltip(interest, option);

			library.unloadMaid:GiveTask(interest.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseMovement' then
					if not option.open then
						option.visualize.BorderColor3 = Color3.new();
					end;
				end;
			end));

			function option:SetColor(newColor, nocallback, noFire)
				newColor = newColor or Color3.new(1, 1, 1)
				if self.mainHolder then
					self:updateVisuals(newColor)
				end
				option.visualize.BackgroundColor3 = newColor
				library.flags[self.flag] = newColor
				self.color = newColor

				if not nocallback then
					task.spawn(self.callback, newColor)
				end

				if (not noFire) then
					library.OnFlagChanged:Fire(self);
				end;
			end

			if option.trans then
				function option:SetTrans(value, manual)
					value = math.clamp(tonumber(value) or 0, 0, 1)
					if self.transSlider then
						self.transSlider.Position = UDim2.new(0, 0, value, 0)
					end
					self.trans = value
					library.flags[self.flag .. 'Transparency'] = 1 - value
					task.spawn(self.calltrans, value)
				end
				option:SetTrans(option.trans)
			end

			task.defer(function()
				if library then
					option:SetColor(option.color)
				end
			end)

			function option:Close()
				library.popup = nil
				self.open = false
				self.mainHolder.Visible = false
				option.visualize.BorderColor3 = Color3.new()
			end
		end

		function library:AddTab(title, pos)
			local tab = {canInit = true, columns = {}, title = tostring(title)}
			table.insert(self.tabs, pos or #self.tabs + 1, tab)

			function tab:AddColumn()
				local column = {sections = {}, position = #self.columns, canInit = true, tab = self}
				table.insert(self.columns, column)

				function column:AddSection(title)
					local section = {title = tostring(title), options = {}, canInit = true, column = self}
					table.insert(self.sections, section)

					function section:AddLabel(text)
						local option = {text = text}
						option.section = self
						option.type = 'label'
						option.position = #self.options
						table.insert(self.options, option)

						if library.hasInit and self.hasInit then
							createLabel(option, self.content)
						else
							option.Init = createLabel
						end

						return option
					end

					function section:AddDivider(text, tip)
						local option = {text = text, tip = tip}
						option.section = self
						option.type = 'divider'
						option.position = #self.options
						table.insert(self.options, option)

						if library.hasInit and self.hasInit then
							createDivider(option, self.content)
						else
							option.Init = createDivider
						end

						return option
					end

					function section:AddToggle(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.state = typeof(option.state) == 'boolean' and option.state or false
						option.default = option.state;
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.type = 'toggle'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.subcount = 0
						option.tip = option.tip and tostring(option.tip)
						option.style = option.style == 2
						library.flags[option.flag] = option.state
						table.insert(self.options, option)
						library.options[option.flag] = option

						function option:AddColor(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddColor(subOption)
						end

						function option:AddBind(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddBind(subOption)
						end

						function option:AddList(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddList(subOption)
						end

						function option:AddSlider(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1

							subOption.parent = option;
							return section:AddSlider(subOption)
						end

						if library.hasInit and self.hasInit then
							createToggle(option, self.content)
						else
							option.Init = createToggle
						end

						return option
					end

					function section:AddButton(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.type = 'button'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.subcount = 0
						option.tip = option.tip and tostring(option.tip)
						table.insert(self.options, option)
						library.options[option.flag] = option

						function option:AddBind(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() option.main.Size = UDim2.new(1, 0, 0, 40) return option.main end
							self.subcount = self.subcount + 1
							return section:AddBind(subOption)
						end

						function option:AddColor(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() option.main.Size = UDim2.new(1, 0, 0, 40) return option.main end
							self.subcount = self.subcount + 1
							return section:AddColor(subOption)
						end

						function option:AddButton(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							subOption.parent = option;
							section:AddButton(subOption)

							return option;
						end;

						function option:SetText(text)
							option.title.Text = text;
						end;

						if library.hasInit and self.hasInit then
							createButton(option, self.content)
						else
							option.Init = createButton
						end

						return option
					end

					function section:AddBind(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.key = (option.key and option.key.Name) or option.key or 'none'
						option.nomouse = typeof(option.nomouse) == 'boolean' and option.nomouse or false
						option.mode = typeof(option.mode) == 'string' and ((option.mode == 'toggle' or option.mode == 'hold') and option.mode) or 'toggle'
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.type = 'bind'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.tip = option.tip and tostring(option.tip)
						table.insert(self.options, option)
						library.options[option.flag] = option

						if library.hasInit and self.hasInit then
							createBind(option, self.content)
						else
							option.Init = createBind
						end

						return option
					end

					function section:AddSlider(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.min = typeof(option.min) == 'number' and option.min or 0
						option.max = typeof(option.max) == 'number' and option.max or 0
						option.value = option.min < 0 and 0 or math.clamp(typeof(option.value) == 'number' and option.value or option.min, option.min, option.max)
						option.default = option.value;
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.float = typeof(option.value) == 'number' and option.float or 1
						option.suffix = option.suffix and tostring(option.suffix) or ''
						option.textpos = option.textpos == 2
						option.type = 'slider'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.subcount = 0
						option.tip = option.tip and tostring(option.tip)
						library.flags[option.flag] = option.value
						table.insert(self.options, option)
						library.options[option.flag] = option

						function option:AddColor(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddColor(subOption)
						end

						function option:AddBind(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddBind(subOption)
						end

						if library.hasInit and self.hasInit then
							createSlider(option, self.content)
						else
							option.Init = createSlider
						end

						return option
					end

					function section:AddList(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.values = typeof(option.values) == 'table' and option.values or {}
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.multiselect = typeof(option.multiselect) == 'boolean' and option.multiselect or false
						--option.groupbox = (not option.multiselect) and (typeof(option.groupbox) == 'boolean' and option.groupbox or false)
						option.value = option.multiselect and (typeof(option.value) == 'table' and option.value or {}) or tostring(option.value or option.values[1] or '')
						if option.multiselect then
							for i,v in next, option.values do
								option.value[v] = false
							end
						end
						option.max = option.max or 8
						option.open = false
						option.type = 'list'
						option.position = #self.options
						option.labels = {}
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.subcount = 0
						option.tip = option.tip and tostring(option.tip)
						library.flags[option.flag] = option.value
						table.insert(self.options, option)
						library.options[option.flag] = option

						function option:AddValue(value, state)
							if self.multiselect then
								self.values[value] = state
							else
								table.insert(self.values, value)
							end
						end

						function option:AddColor(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddColor(subOption)
						end

						function option:AddBind(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddBind(subOption)
						end

						if library.hasInit and self.hasInit then
							createList(option, self.content)
						else
							option.Init = createList
						end

						return option
					end

					function section:AddBox(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.value = tostring(option.value or '')
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.type = 'box'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.tip = option.tip and tostring(option.tip)
						library.flags[option.flag] = option.value
						table.insert(self.options, option)
						library.options[option.flag] = option

						if library.hasInit and self.hasInit then
							createBox(option, self.content)
						else
							option.Init = createBox
						end

						return option
					end

					function section:AddColor(option)
						option = typeof(option) == 'table' and option or {}
						option.section = self
						option.text = tostring(option.text)
						option.color = typeof(option.color) == 'table' and Color3.new(option.color[1], option.color[2], option.color[3]) or option.color or Color3.new(1, 1, 1)
						option.callback = typeof(option.callback) == 'function' and option.callback or function() end
						option.calltrans = typeof(option.calltrans) == 'function' and option.calltrans or (option.calltrans == 1 and option.callback) or function() end
						option.open = false
						option.default = option.color;
						option.trans = tonumber(option.trans)
						option.subcount = 1
						option.type = 'color'
						option.position = #self.options
						option.flag = (library.flagprefix or '') .. toCamelCase(option.flag or option.text)
						option.tip = option.tip and tostring(option.tip)
						library.flags[option.flag] = option.color
						table.insert(self.options, option)
						library.options[option.flag] = option

						function option:AddColor(subOption)
							subOption = typeof(subOption) == 'table' and subOption or {}
							subOption.sub = true
							subOption.subpos = self.subcount * 24
							function subOption:getMain() return option.main end
							self.subcount = self.subcount + 1
							return section:AddColor(subOption)
						end

						if option.trans then
							library.flags[option.flag .. 'Transparency'] = option.trans
						end

						if library.hasInit and self.hasInit then
							createColor(option, self.content)
						else
							option.Init = createColor
						end

						return option
					end

					function section:SetTitle(newTitle)
						self.title = tostring(newTitle)
						if self.titleText then
							self.titleText.Text = tostring(newTitle)
						end
					end

					function section:Init()
						if self.hasInit then return end
						self.hasInit = true

						self.main = library:Create('Frame', {
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderColor3 = Color3.new(),
							Parent = column.main
						})

						self.content = library:Create('Frame', {
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderColor3 = Color3.fromRGB(60, 60, 60),
							BorderMode = Enum.BorderMode.Inset,
							Parent = self.main
						})

						library:Create('ImageLabel', {
							Size = UDim2.new(1, -2, 1, -2),
							Position = UDim2.new(0, 1, 0, 1),
							BackgroundTransparency = 1,
							Image = 'rbxassetid://2592362371',
							ImageColor3 = Color3.new(),
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(2, 2, 62, 62),
							Parent = self.main
						})

						table.insert(library.theme, library:Create('Frame', {
							Size = UDim2.new(1, 0, 0, 1),
							BackgroundColor3 = library.flags.menuAccentColor,
							BorderSizePixel = 0,
							BorderMode = Enum.BorderMode.Inset,
							Parent = self.main
						}))

						local layout = library:Create('UIListLayout', {
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
							Padding = UDim.new(0, 2),
							Parent = self.content
						})

						library:Create('UIPadding', {
							PaddingTop = UDim.new(0, 12),
							Parent = self.content
						})

						self.titleText = library:Create('TextLabel', {
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.new(0, 12, 0, 0),
							Size = UDim2.new(0, TextService:GetTextSize(self.title, 15, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10, 0, 3),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderSizePixel = 0,
							Text = self.title,
							TextSize = 15,
							Font = Enum.Font.Code,
							TextColor3 = Color3.new(1, 1, 1),
							Parent = self.main
						})

						library.unloadMaid:GiveTask(layout.Changed:connect(function()
							self.main.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y + 16)
						end));

						for _, option in next, self.options do
							option.Init(option, self.content)
						end
					end

					if library.hasInit and self.hasInit then
						section:Init()
					end

					return section
				end

				function column:Init()
					if self.hasInit then return end
					self.hasInit = true

					self.main = library:Create('ScrollingFrame', {
						ZIndex = 2,
						Position = UDim2.new(0, 6 + (self.position * 239), 0, 2),
						Size = UDim2.new(0, 233, 1, -4),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						ScrollBarImageColor3 = Color3.fromRGB(),
						ScrollBarThickness = 4,
						VerticalScrollBarInset = Enum.ScrollBarInset.ScrollBar,
						ScrollingDirection = Enum.ScrollingDirection.Y,
						Visible = true
					})

					local layout = library:Create('UIListLayout', {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 12),
						Parent = self.main
					})

					library:Create('UIPadding', {
						PaddingTop = UDim.new(0, 8),
						PaddingLeft = UDim.new(0, 2),
						PaddingRight = UDim.new(0, 2),
						Parent = self.main
					})

					library.unloadMaid:GiveTask(layout.Changed:connect(function()
						self.main.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 14)
					end));

					for _, section in next, self.sections do
						if section.canInit and #section.options > 0 then
							section:Init()
						end
					end
				end

				if library.hasInit and self.hasInit then
					column:Init()
				end

				return column
			end

			function tab:Init()
				if self.hasInit then return end
				self.hasInit = true

				local size = TextService:GetTextSize(self.title, 18, Enum.Font.Code, Vector2.new(9e9, 9e9)).X + 10

				self.button = library:Create('TextLabel', {
					Position = UDim2.new(0, library.tabSize, 0, 22),
					Size = UDim2.new(0, size, 0, 30),
					BackgroundTransparency = 1,
					Text = self.title,
					TextColor3 = Color3.new(1, 1, 1),
					TextSize = 15,
					Font = Enum.Font.Code,
					TextWrapped = true,
					ClipsDescendants = true,
					Parent = library.main
				});

				library.tabSize = library.tabSize + size

				library.unloadMaid:GiveTask(self.button.InputBegan:connect(function(input)
					if input.UserInputType.Name == 'MouseButton1' then
						library:selectTab(self);
					end;
				end));

				for _, column in next, self.columns do
					if column.canInit then
						column:Init();
					end;
				end;
			end;

			if self.hasInit then
				tab:Init()
			end

			return tab
		end

		function library:AddWarning(warning)
			warning = typeof(warning) == 'table' and warning or {}
			warning.text = tostring(warning.text)
			warning.type = warning.type == 'confirm' and 'confirm' or ''

			local answer
			function warning:Show()
				library.warning = warning
				if warning.main and warning.type == '' then
					warning.main:Destroy();
					warning.main = nil;
				end
				if library.popup then library.popup:Close() end
				if not warning.main then
					warning.main = library:Create('TextButton', {
						ZIndex = 2,
						Size = UDim2.new(1, 0, 1, 0),
						BackgroundTransparency = 0.3,
						BackgroundColor3 = Color3.new(),
						BorderSizePixel = 0,
						Text = '',
						AutoButtonColor = false,
						Parent = library.main
					})

					warning.message = library:Create('TextLabel', {
						ZIndex = 2,
						Position = UDim2.new(0, 20, 0.5, -60),
						Size = UDim2.new(1, -40, 0, 40),
						BackgroundTransparency = 1,
						TextSize = 16,
						Font = Enum.Font.Code,
						TextColor3 = Color3.new(1, 1, 1),
						TextWrapped = true,
						RichText = true,
						Parent = warning.main
					})

					if warning.type == 'confirm' then
						local button = library:Create('TextLabel', {
							ZIndex = 2,
							Position = UDim2.new(0.5, -105, 0.5, -10),
							Size = UDim2.new(0, 100, 0, 20),
							BackgroundColor3 = Color3.fromRGB(40, 40, 40),
							BorderColor3 = Color3.new(),
							Text = 'Yes',
							TextSize = 16,
							Font = Enum.Font.Code,
							TextColor3 = Color3.new(1, 1, 1),
							Parent = warning.main
						})

						library:Create('ImageLabel', {
							ZIndex = 2,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = 'rbxassetid://2454009026',
							ImageColor3 = Color3.new(),
							ImageTransparency = 0.8,
							Parent = button
						})

						library:Create('ImageLabel', {
							ZIndex = 2,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = 'rbxassetid://2592362371',
							ImageColor3 = Color3.fromRGB(60, 60, 60),
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(2, 2, 62, 62),
							Parent = button
						})

						local button1 = library:Create('TextLabel', {
							ZIndex = 2,
							Position = UDim2.new(0.5, 5, 0.5, -10),
							Size = UDim2.new(0, 100, 0, 20),
							BackgroundColor3 = Color3.fromRGB(40, 40, 40),
							BorderColor3 = Color3.new(),
							Text = 'No',
							TextSize = 16,
							Font = Enum.Font.Code,
							TextColor3 = Color3.new(1, 1, 1),
							Parent = warning.main
						})

						library:Create('ImageLabel', {
							ZIndex = 2,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = 'rbxassetid://2454009026',
							ImageColor3 = Color3.new(),
							ImageTransparency = 0.8,
							Parent = button1
						})

						library:Create('ImageLabel', {
							ZIndex = 2,
							Size = UDim2.new(1, 0, 1, 0),
							BackgroundTransparency = 1,
							Image = 'rbxassetid://2592362371',
							ImageColor3 = Color3.fromRGB(60, 60, 60),
							ScaleType = Enum.ScaleType.Slice,
							SliceCenter = Rect.new(2, 2, 62, 62),
							Parent = button1
						})

						library.unloadMaid:GiveTask(button.InputBegan:connect(function(input)
							if input.UserInputType.Name == 'MouseButton1' then
								answer = true
							end
						end));

						library.unloadMaid:GiveTask(button1.InputBegan:connect(function(input)
							if input.UserInputType.Name == 'MouseButton1' then
								answer = false
							end
						end));
					else
						local button = library:Create('TextLabel', {
							ZIndex = 2,
							Position = UDim2.new(0.5, -50, 0.5, -10),
							Size = UDim2.new(0, 100, 0, 20),
							BackgroundColor3 = Color3.fromRGB(30, 30, 30),
							BorderColor3 = Color3.new(),
							Text = 'OK',
							TextSize = 16,
							Font = Enum.Font.Code,
							TextColor3 = Color3.new(1, 1, 1),
							Parent = warning.main
						})

						library.unloadMaid:GiveTask(button.InputEnded:connect(function(input)
							if input.UserInputType.Name == 'MouseButton1' then
								answer = true
							end
						end));
					end
				end
				warning.main.Visible = true
				warning.message.Text = warning.text

				repeat task.wait() until answer ~= nil;
				library.warning = nil;

				local answerCopy = answer;
				warning:Close();

				return answerCopy;
			end

			function warning:Close()
				answer = nil
				if not warning.main then return end
				warning.main.Visible = false
			end

			return warning
		end

		function library:Close()
			self.open = not self.open

			if self.main then
				if self.popup then
					self.popup:Close()
				end

				self.base.Enabled = self.open
			end

			library.tooltip.Position = UDim2.fromScale(10, 10);
		end

		function library:Init(silent)
			if self.hasInit then return end

			self.hasInit = true
			self.base = library:Create('ScreenGui', {IgnoreGuiInset = true, AutoLocalize = false, Enabled = not silent})
			self.dummyBox = library:Create('TextBox', {Visible = false, Parent = self.base});
			self.dummyModal = library:Create('TextButton', {Visible = false, Modal = true, Parent = self.base});

			self.unloadMaid:GiveTask(self.base);

			if RunService:IsStudio() then
				self.base.Parent = script.Parent.Parent
			elseif syn then
				if(gethui) then
					self.base.Parent = gethui();
				else
					pcall(syn.protect_gui, self.base);
					self.base.Parent = CoreGui;
				end;
			end

			self.main = self:Create('ImageButton', {
				AutoButtonColor = false,
				Position = UDim2.new(0, 100, 0, 46),
				Size = UDim2.new(0, 500, 0, 600),
				BackgroundColor3 = Color3.fromRGB(20, 20, 20),
				BorderColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Tile,
				Visible = true,
				Parent = self.base
			})

			local top = self:Create('Frame', {
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderColor3 = Color3.new(),
				Parent = self.main
			})

			self.titleLabel = self:Create('TextLabel', {
				Position = UDim2.new(0, 6, 0, -1),
				Size = UDim2.new(0, 0, 0, 20),
				BackgroundTransparency = 1,
				Text = tostring(self.title),
				Font = Enum.Font.Code,
				TextSize = 18,
				TextColor3 = Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = self.main
			})

			table.insert(library.theme, self:Create('Frame', {
				Size = UDim2.new(1, 0, 0, 1),
				Position = UDim2.new(0, 0, 0, 24),
				BackgroundColor3 = library.flags.menuAccentColor,
				BorderSizePixel = 0,
				Parent = self.main
			}))

			library:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2454009026',
				ImageColor3 = Color3.new(),
				ImageTransparency = 0.4,
				Parent = top
			})

			self.tabHighlight = self:Create('Frame', {
				BackgroundColor3 = library.flags.menuAccentColor,
				BorderSizePixel = 0,
				Parent = self.main
			})
			table.insert(library.theme, self.tabHighlight)

			self.columnHolder = self:Create('Frame', {
				Position = UDim2.new(0, 5, 0, 55),
				Size = UDim2.new(1, -10, 1, -60),
				BackgroundTransparency = 1,
				Parent = self.main
			})

			self.tooltip = self:Create('TextLabel', {
				ZIndex = 2,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				TextSize = 15,
				Size = UDim2.fromOffset(0, 0),
				Position = UDim2.fromScale(10, 10),
				Font = Enum.Font.Code,
				TextColor3 = Color3.new(1, 1, 1),
				Visible = true,
				Active = false,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = self.base,
				AutomaticSize = Enum.AutomaticSize.XY
			})

			self:Create('UISizeConstraint', {
				Parent = self.tooltip,
				MaxSize = Vector2.new(400, 1000),
				MinSize = Vector2.new(0, 0),
			});

			self:Create('Frame', {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(1, 10, 1, 0),
				Active = false,
				Style = Enum.FrameStyle.RobloxRound,
				Parent = self.tooltip
			})

			self:Create('ImageLabel', {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.fromRGB(60, 60, 60),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = self.main
			})

			self:Create('ImageLabel', {
				Size = UDim2.new(1, -2, 1, -2),
				Position = UDim2.new(0, 1, 0, 1),
				BackgroundTransparency = 1,
				Image = 'rbxassetid://2592362371',
				ImageColor3 = Color3.new(),
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(2, 2, 62, 62),
				Parent = self.main
			})

			library.unloadMaid:GiveTask(top.InputBegan:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					dragObject = self.main
					dragging = true
					dragStart = input.Position
					startPos = dragObject.Position
					if library.popup then library.popup:Close() end
				end
			end));

			library.unloadMaid:GiveTask(top.InputChanged:connect(function(input)
				if dragging and input.UserInputType.Name == 'MouseMovement' then
					dragInput = input
				end
			end));

			library.unloadMaid:GiveTask(top.InputEnded:connect(function(input)
				if input.UserInputType.Name == 'MouseButton1' then
					dragging = false
				end
			end));

			local titleTextSize = TextService:GetTextSize(self.titleLabel.Text, 18, Enum.Font.Code, Vector2.new(1000, 0));

			local searchLabel = library:Create('ImageLabel', {
				Position = UDim2.new(0, titleTextSize.X + 10, 0.5, -8),
				Size = UDim2.new(0, 16, 0, 16),
				BackgroundTransparency = 1,
				Image = 'rbxasset://textures/ui/Settings/ShareGame/icons.png',
				ImageRectSize = Vector2.new(16, 16),
				ImageRectOffset = Vector2.new(6, 106),
				ClipsDescendants = true,
				Parent = self.titleLabel
			});

			local searchBox = library:Create('TextBox', {
				BackgroundTransparency = 1,
				Position = UDim2.fromOffset(searchLabel.AbsolutePosition.X-80, 5),
				Size = UDim2.fromOffset(50, 15),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextXAlignment = Enum.TextXAlignment.Left,
				Parent = self.titleLabel,
				Text = '',
				PlaceholderText = 'Type something to search...',
				Visible = false
			});

			local searchContainer = library:Create('ScrollingFrame', {
				BackgroundTransparency = 1,
				Visible = false,
				Size = UDim2.fromScale(1, 1),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = library.columnHolder,
				BorderSizePixel = 0,
				ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100),
				ScrollBarThickness = 6,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				VerticalScrollBarInset = Enum.ScrollBarInset.Always,
				TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
				BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			});

			library:Create('UIListLayout', {
				Parent = searchContainer
			})

			local allFoundResults = {};
			local modifiedNames = {};

			local function clearFoundResult()
				for _, option in next, allFoundResults do
					option.main.Parent = option.originalParent;
				end;

				for _, option in next, modifiedNames do
					option.title.Text = option.text;
					option.main.Parent = option.originalParent;
				end;

				table.clear(allFoundResults);
				table.clear(modifiedNames);
			end;

			local sFind, sLower = string.find, string.lower;

			library.unloadMaid:GiveTask(searchBox:GetPropertyChangedSignal('Text'):Connect(function()
				local text = string.lower(searchBox.Text):gsub('%s', '');

				for _, v in next, library.options do
					if (not v.originalParent) then
						v.originalParent = v.main.Parent;
					end;
				end;

				clearFoundResult();

				for _, v in next, library.currentTab.columns do
					v.main.Visible = text == '' and true or false;
				end;

				if (text == '') then return; end;
				local matchedResults = false;

				for _, v in next, library.options do
					local main = v.main;

					if (v.text == 'Enable' or v.parentFlag) then
						if (v.type == 'toggle' or v.type == 'bind') then
							local parentName = v.parentFlag and 'Bind' or v.section.title;
							v.title.Text = string.format('%s [%s]', v.text, parentName);

							table.insert(modifiedNames, v);
						end;
					end;

					if (sFind(sLower(v.text), text) or sFind(sLower(v.flag), text)) then
						matchedResults = true;
						main.Parent = searchContainer;
						table.insert(allFoundResults, v);
					else
						main.Parent = v.originalParent;
					end;
				end;

				searchContainer.Visible = matchedResults;
			end));

			library.unloadMaid:GiveTask(searchLabel.InputBegan:Connect(function(inputObject)
				if(inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;
				searchBox.Visible = true;
				searchBox:CaptureFocus();
			end));

			library.unloadMaid:GiveTask(searchBox.FocusLost:Connect(function()
				if (searchBox.Text:gsub('%s', '') ~= '') then return end;
				searchBox.Visible = false;
			end));


			local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out);

			function self:selectTab(tab)
				if self.currentTab == tab then return end
				if library.popup then library.popup:Close() end
				clearFoundResult();
				searchBox.Visible = false;
				searchBox.Text = '';

				if self.currentTab then
					self.currentTab.button.TextColor3 = Color3.fromRGB(255, 255, 255)
					for _, column in next, self.currentTab.columns do
						column.main.Parent = nil;
						column.main.Visible = true;
					end
				end
				self.main.Size = UDim2.new(0, 16 + ((#tab.columns < 2 and 2 or #tab.columns) * 239), 0, 600)
				self.currentTab = tab
				tab.button.TextColor3 = library.flags.menuAccentColor;

				TweenService:Create(self.tabHighlight, tweenInfo, {
					Position = UDim2.new(0, tab.button.Position.X.Offset, 0, 50),
					Size = UDim2.new(0, tab.button.AbsoluteSize.X, 0, -1)
				}):Play();

				for _, column in next, tab.columns do
					column.main.Parent = self.columnHolder
				end
			end

			task.spawn(function()
				while library do
					local Configs = self:GetConfigs()
					for _, config in next, Configs do
						if config ~= 'nil' and not table.find(self.options.configList.values, config) then
							self.options.configList:AddValue(config)
						end
					end
					for _, config in next, self.options.configList.values do
						if config ~= 'nil' and not table.find(Configs, config) then
							self.options.configList:RemoveValue(config)
						end
					end
					task.wait(1);
				end
			end)

			for _, tab in next, self.tabs do
				if tab.canInit then
					tab:Init();
				end;
			end;

			self:AddConnection(UserInputService.InputEnded, function(input)
				if (input.UserInputType.Name == 'MouseButton1') and self.slider then
					self.slider.slider.BorderColor3 = Color3.new();
					self.slider = nil;
				end;
			end);

			self:AddConnection(UserInputService.InputChanged, function(input)
				if self.open then
					if input == dragInput and dragging and library.draggable then
						local delta = input.Position - dragStart;
						local yPos = (startPos.Y.Offset + delta.Y) < -36 and -36 or startPos.Y.Offset + delta.Y;

						dragObject:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), 'Out', 'Quint', 0.1, true);
					end;

					if self.slider and input.UserInputType.Name == 'MouseMovement' then
						self.slider:SetValue(self.slider.min + ((input.Position.X - self.slider.slider.AbsolutePosition.X) / self.slider.slider.AbsoluteSize.X) * (self.slider.max - self.slider.min));
					end;
				end;
			end);

			local configData = readFileAndDecodeIt(library.foldername .. '/' .. library.fileext);

			if (configData) then
				library.configVars = configData;
				library:LoadConfig(configData.config);

				library.OnLoad:Connect(function()
					library.options.configList:SetValue(library.loadedConfig or 'default');
				end);
			else
				print('[Script] [Config Loader] An error has occured', configData);
			end;

			self:selectTab(self.tabs[1]);

			if (not silent) then
				self:Close();
			else
				self.open = false;
			end;

			library.OnLoad:Fire();
			library.OnLoad:Destroy();
			library.OnLoad = nil;
		end;

		function library:SetTitle(text)
			if (not self.titleLabel) then
				return;
			end;

			self.titleLabel.Text = text;
		end;

		do -- // Load Basics
			local configWarning = library:AddWarning({type = 'confirm'})
			local messageWarning = library:AddWarning();

			function library:ShowConfirm(text)
				configWarning.text = text;
				return configWarning:Show();
			end;

			function library:ShowMessage(text)
				messageWarning.text = text;
				return messageWarning:Show();
			end

			local function showBasePrompt(text)
				local r, g, b = library.round(library.flags.menuAccentColor);

				local configName = text == 'create' and library.flags.configName or library.flags.configList;
				local trimedValue = configName:gsub('%s', '');

				if(trimedValue == '') then
					library:ShowMessage(string.format('Can not %s a config with no name !', text));
					return false;
				end;

				return library:ShowConfirm(string.format(
					'Are you sure you want to %s config <font color=\'rgb(%s, %s, %s)\'>%s</font>',
					text,
					r,
					g,
					b,
					configName
					));
			end;

			local joinDiscord;

			do -- // Utils
				function joinDiscord(code)
					for i = 6463, 6472 do -- // Just cause there is a 10 range port
						if(pcall(function()
								syn.request({
									Url = ('http://127.0.0.1:%s/rpc?v=1'):format(i),
									Method = 'POST',
									Headers = {
										['Content-Type'] = 'application/json',
										Origin = 'https://discord.com' -- // memery moment
									},
									Body = ('{"cmd":"INVITE_BROWSER","args":{"code":"%s"},"nonce":"%s"}'):format(code, string.lower(HttpService:GenerateGUID(false)))
								});
							end)) then
							print('found port', i);
							break;
						end;
					end;
				end;
			end;

			local maid = Maid.new();
			library.unloadMaid:GiveTask(function()
				maid:Destroy();
			end);

			local settingsTab       = library:AddTab('Settings', 100);
			local settingsColumn    = settingsTab:AddColumn();
			local settingsColumn1   = settingsTab:AddColumn();
			local settingsMain      = settingsColumn:AddSection('Main');
			local settingsMenu      = settingsColumn:AddSection('Menu');
			local configSection     = settingsColumn1:AddSection('Configs');
			local discordSection    = settingsColumn:AddSection('Discord');
			local BackgroundArray   = {};

			local Backgrounds = {
				Floral  = 5553946656,
				Flowers = 6071575925,
				Circles = 6071579801,
				Hearts  = 6073763717,
			};

			task.spawn(function()
				for i, v in next, Backgrounds do
					table.insert(BackgroundArray, 'rbxassetid://' .. v);
				end;

				ContentProvider:PreloadAsync(BackgroundArray);
			end);

			local lastShownNotifAt = 0;

			local function setCustomBackground()
				local imageURL = library.flags.customBackground;
				imageURL = imageURL:gsub('%s', '');

				if (imageURL == '') then return end;

				if (not isfolder('Aztup Hub V3/CustomBackgrounds')) then
					makefolder('Aztup Hub V3/CustomBackgrounds');
				end;

				local path = string.format('Aztup Hub V3/CustomBackgrounds/%s.bin', syn.crypt.hash(imageURL));

				if (not isfile(path)) then
					local suc, httpRequest = pcall(syn.request, {
						Url = imageURL,
					});

					if (not suc) then return library:ShowMessage('The url you have specified for the custom background is invalid.'); end;

					if (not httpRequest.Success) then return library:ShowMessage(string.format('Request failed %d', httpRequest.StatusCode)); end;
					local imgType = httpRequest.Headers['Content-Type']:lower();
					if (imgType ~= 'image/png' and imgType ~= 'image/jpeg') then return library:ShowMessage('Only PNG and JPEG are supported'); end;

					writefile(path, httpRequest.Body);
				end;

				library.main.Image = getsynasset(path);

				local acColor = library.flags.menuBackgroundColor;
				local r, g, b = acColor.R * 255, acColor.G * 255, acColor.B * 255;

				if (r <= 100 and g <= 100 and b <= 100 and tick() - lastShownNotifAt > 1) then
					lastShownNotifAt = tick();
					ToastNotif.new({text = 'Your menu accent color is dark custom background may not show.', duration = 20});
				end;
			end;

			settingsMain:AddBox({
				text = 'Custom Background',
				tip = 'Put a valid image link here',
				callback = setCustomBackground
			});

			library.OnLoad:Connect(function()
				local customBackground = library.flags.customBackground;
				if (customBackground:gsub('%s', '') == '') then return end;

				task.defer(setCustomBackground);
			end);

			do
				local scaleTypes = {};

				for _, scaleType in next, Enum.ScaleType:GetEnumItems() do
					table.insert(scaleTypes, scaleType.Name);
				end;

				settingsMain:AddList({
					text = 'Background Scale Type',
					values = scaleTypes,
					callback = function()
						library.main.ScaleType = Enum.ScaleType[library.flags.backgroundScaleType];
					end
				});
			end;

			settingsMain:AddButton({
				text = 'Unload Menu',
				nomouse = true,
				callback = function()
					library:Unload()
				end
			});

			settingsMain:AddBind({
				text = 'Unload Key',
				nomouse = true,
				callback = library.options.unloadMenu.callback
			});

			-- settingsMain:AddToggle({
			--     text = 'Remote Control'
			-- });

			settingsMenu:AddBind({
				text = 'Open / Close',
				flag = 'UI Toggle',
				nomouse = true,
				key = 'LeftAlt',
				callback = function() library:Close() end
			})

			settingsMenu:AddColor({
				text = 'Accent Color',
				flag = 'Menu Accent Color',
				color = Color3.fromRGB(18, 127, 253),
				callback = function(Color)
					if library.currentTab then
						library.currentTab.button.TextColor3 = Color
					end

					for _, obj in next, library.theme do
						obj[(obj.ClassName == 'TextLabel' and 'TextColor3') or (obj.ClassName == 'ImageLabel' and 'ImageColor3') or 'BackgroundColor3'] = Color
					end
				end
			})

			settingsMenu:AddToggle({
				text = 'Keybind Visualizer',
				state = true,
				callback = function(state)
					return visualizer:SetEnabled(state);
				end
			}):AddColor({
				text = 'Keybind Visualizer Color',
				callback = function(color)
					return visualizer:UpdateColor(color);
				end
			});

			settingsMenu:AddToggle({
				text = 'Rainbow Keybind Visualizer',
				callback = function(t)
					if (not t) then
						return maid.rainbowKeybindVisualizer;
					end;

					maid.rainbowKeybindVisualizer = task.spawn(function()
						while task.wait() do
							visualizer:UpdateColor(library.chromaColor);
						end;
					end);
				end
			})

			settingsMenu:AddList({
				text = 'Background',
				flag = 'UI Background',
				values = {'Floral', 'Flowers', 'Circles', 'Hearts'},
				callback = function(Value)
					if Backgrounds[Value] then
						library.main.Image = 'rbxassetid://' .. Backgrounds[Value]
					end
				end
			}):AddColor({
				flag = 'Menu Background Color',
				color = Color3.new(),
				trans = 1,
				callback = function(Color)
					library.main.ImageColor3 = Color
				end,
				calltrans = function(Value)
					library.main.ImageTransparency = 1 - Value
				end
			});

			settingsMenu:AddSlider({
				text = 'Tile Size',
				value = 90,
				min = 50,
				max = 500,
				callback = function(Value)
					library.main.TileSize = UDim2.new(0, Value, 0, Value)
				end
			})

			configSection:AddBox({
				text = 'Config Name',
				skipflag = true,
			})

			local function getAllConfigs()
				local files = {};

				for _, v in next, listfiles('Aztup Hub V3/configs') do
					if (not isfolder(v)) then continue; end;

					for _, v2 in next, listfiles(v) do
						local configName = v2:match('(%w+).config.json');
						if (not configName) then continue; end;

						local folderName = v:match('configs\\(%w+)');
						local fullConfigName = string.format('%s - %s', folderName, configName);

						table.insert(files, fullConfigName);
					end;
				end;

				return files;
			end;

			local function updateAllConfigs()
				for _, v in next, library.options.loadFromList.values do
					library.options.loadFromList:RemoveValue(v);
				end;

				for _, configName in next, getAllConfigs() do
					library.options.loadFromList:AddValue(configName);
				end;
			end

			configSection:AddList({
				text = 'Configs',
				skipflag = true,
				value = '',
				flag = 'Config List',
				values = library:GetConfigs(),
			})

			configSection:AddButton({
				text = 'Create',
				callback = function()
					if (showBasePrompt('create')) then
						library.options.configList:AddValue(library.flags.configName);
						library.options.configList:SetValue(library.flags.configName);
						library:SaveConfig(library.flags.configName);
						library:LoadConfig(library.flags.configName);

						updateAllConfigs();
					end;
				end
			})

			local btn;
			btn = configSection:AddButton({
				text = isGlobalConfigOn and 'Switch To Local Config' or 'Switch to Global Config';

				callback = function()
					isGlobalConfigOn = not isGlobalConfigOn;
					writefile(globalConfFilePath, tostring(isGlobalConfigOn));

					btn:SetText(isGlobalConfigOn and 'Switch To Local Config' or 'Switch to Global Config');
					library:ShowMessage('Note: Switching from Local to Global requires script relaunch.');
				end
			});

			configSection:AddButton({
				text = 'Save',
				callback = function()
					if (showBasePrompt('save')) then
						library:SaveConfig(library.flags.configList);
					end;
				end
			}):AddButton({
				text = 'Load',
				callback = function()
					if (showBasePrompt('load')) then
						library:UpdateConfig(); -- Save config before switching to new one
						library:LoadConfig(library.flags.configList);
					end
				end
			}):AddButton({
				text = 'Delete',
				callback = function()
					if (showBasePrompt('delete')) then
						local Config = library.flags.configList
						local configFilePath = library.foldername .. '/' .. Config .. '.config' .. library.fileext;

						if table.find(library:GetConfigs(), Config) and isfile(configFilePath) then
							library.options.configList:RemoveValue(Config)
							delfile(configFilePath);
						end
					end;
				end
			})

			configSection:AddList({
				text = 'Load From',
				flag = 'Load From List',
				values = getAllConfigs()
			});

			configSection:AddButton({
				text = 'Load From',
				callback = function()
					if (not showBasePrompt('load from')) then return; end;
					if (isGlobalConfigOn) then return library:ShowMessage('You can not load a config from another user if you are in global config mode.'); end;

					local folderName, configName = library.flags.loadFromList:match('(%w+) %p (.+)');
					local fullConfigName = string.format('%s.config.json', configName);

					if (isfile(library.foldername .. '/' .. fullConfigName)) then
						-- If there is already an existing config with this name then

						if (not library:ShowConfirm('There is already a config with this name in your config folder. Would you like to delete it? Pressing no will cancel the operation')) then
							return;
						end;
					end;

					local configData = readfile(string.format('Aztup Hub V3/configs/%s/%s', folderName, fullConfigName));
					writefile(string.format('%s/%s', library.foldername, fullConfigName), configData);

					library:LoadConfig(configName);
				end
			})

			configSection:AddToggle({
				text = 'Automatically Save Config',
				state = true,
				flag = 'saveConfigAuto',
				callback = function(toggle)
					-- This is required incase the game crash but we can move the interval to 60 seconds

					if(not toggle) then
						maid.saveConfigAuto = nil;
						library:UpdateConfig(); -- Make sure that we update config to save that user turned off automatically save config
						return;
					end;

					maid.saveConfigAuto = task.spawn(function()
						while true do
							task.wait(60);
							library:UpdateConfig();
						end;
					end);
				end,
			})

			local function saveConfigBeforeGameLeave()
				if (not library.flags.saveconfigauto) then return; end;
				library:UpdateConfig();
			end;

			library.unloadMaid:GiveTask(GuiService.NativeClose:Connect(saveConfigBeforeGameLeave));

			-- NativeClose does not fire on the Lua App
			library.unloadMaid:GiveTask(GuiService.MenuOpened:Connect(saveConfigBeforeGameLeave));

			library.unloadMaid:GiveTask(LocalPlayer.OnTeleport:Connect(function(state)
				if (state ~= Enum.TeleportState.Started and state ~= Enum.TeleportState.RequestedFromServer) then return end;
				saveConfigBeforeGameLeave();
			end));

			discordSection:AddButton({
				text = 'Join Discord',
				callback = function() return joinDiscord('gWCk7pTXNs') end
			});

			discordSection:AddButton({
				text = 'Copy Discord Invite',
				callback = function() return setclipboard('discord.gg/gWCk7pTXNs') end
			});
		end;
	end;

	warn(string.format('[Script] [Library] Loaded in %.02f seconds', tick() - libraryLoadAt));

	library.OnFlagChanged:Connect(function(data)
		local keybindExists = library.options[string.lower(data.flag) .. 'Bind'];
		if (not keybindExists or not keybindExists.key or keybindExists.key == 'none') then return end;

		local toggled = library.flags[data.flag];

		if (toggled) then
			visualizer:AddText(data.text);
		else
			visualizer:RemoveText(data.text);
		end
	end);

	return library;
end

function TextLogger()
	local library = library()

	local Services = Services()
	local Signal = Signal()
	local ToastNotif = ToastNotif()

	local UserInputService, TweenService, TextService, ReplicatedStorage, Players, HttpService = Services:Get('UserInputService', 'TweenService', 'TextService', 'ReplicatedStorage', 'Players', 'HttpService');
	local LocalPlayer = Players.LocalPlayer;

	local TextLogger = {};
	TextLogger.__index = TextLogger;

	TextLogger.Colors = {};
	TextLogger.Colors.Background = Color3.fromRGB(30, 30, 30);
	TextLogger.Colors.Border = Color3.fromRGB(155, 155, 155);
	TextLogger.Colors.TitleColor = Color3.fromRGB(255, 255, 255);

	local Text = {};

	-- // Text
	do
		Text.__index = Text;

		function Text.new(options)
			local self = setmetatable(options, Text);
			self._originalText = options.originalText or options.text;

			self.label = library:Create('TextLabel', {
				BackgroundTransparency = 1,
				Parent = self._parent._logs,
				Size = UDim2.new(1, 0, 0, 25),
				Font = Enum.Font.Roboto,
				TextColor3 = options.color or Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				RichText = true,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
				Text = self.text;
			});

			self:SetText(options.text);

			self.OnMouseEnter = Signal.new();
			self.OnMouseLeave = Signal.new();

			local index = #self._parent.logs + 1;
			local mouseButton2 = Enum.UserInputType.MouseButton2;
			local mouseHover = Enum.UserInputType.MouseMovement;

			self.label.InputBegan:Connect(function(inputObject, gpe)
				if (inputObject.UserInputType == mouseButton2 and not gpe) then
					local toolTip = self._parent._toolTip;

					self._parent._currentToolTip = self;
					self._parent._currentToolTipIndex = index;

					toolTip.Visible = true;
					toolTip:TweenSize(UDim2.fromOffset(150, #self._parent.params.buttons * 30), 'Out', 'Quad', 0.1, true);

					local mouse = UserInputService:GetMouseLocation();
					toolTip.Position = UDim2.fromOffset(mouse.X, mouse.Y);
				elseif (inputObject.UserInputType == mouseHover) then
					self.OnMouseEnter:Fire();
				end;
			end);

			self.label.InputEnded:Connect(function(inputObject)
				if (inputObject.UserInputType == mouseHover) then
					self.OnMouseLeave:Fire();
				end;
			end);

			table.insert(self._parent.logs, self);
			table.insert(self._parent.allLogs, {
				_originalText = self._originalText
			});

			local contentSize = self._parent._layout.AbsoluteContentSize;
			self._parent._logs.CanvasSize = UDim2.fromOffset(0, contentSize.Y);

			if (library.flags.chatLoggerAutoScroll) then
				self._parent._logs.CanvasPosition = Vector2.new(0, contentSize.Y);
			end;

			return self;
		end;

		function Text:Destroy()
			local logs = self._parent.logs;
			table.remove(logs, table.find(logs, self));
			self.label:Destroy();
		end;

		function Text:SetText(text)
			self.label.Text = text;
			local textSize = TextService:GetTextSize(self.label.ContentText, 20, Enum.Font.Roboto, Vector2.new(self._parent._logs.AbsoluteSize.X, math.huge));

			self.label.Size = UDim2.new(1, 0, 0, textSize.Y);
			self._parent:UpdateCanvas();
		end;
	end;

	local function setCameraSubject(subject)
		workspace.CurrentCamera.CameraSubject = subject;
	end;

	local function initChatLoggerPreset(chatLogger)
		library.unloadMaid:GiveTask(ReplicatedStorage.DefaultChatSystemChatEvents.OnMessageDoneFiltering.OnClientEvent:Connect(function(messageData)
			for i = 2, 10 do
				local l, s, n, f, a = debug.info(i, 'lsnfa');

				if (l or s or n or f or a) then
					task.spawn(function() Security:LogInfraction('omdf'); end);
					return;
				end;
			end;

			local player, message = originalFunctions.findFirstChild(Players, messageData.FromSpeaker), messageData.Message;
			if (not player or not message) then return end;

			chatLogger.OnPlayerChatted:Fire(player, message);
		end));

		local reported = {};

		chatLogger.OnClick:Connect(function(btnType, textData, textIndex)
			if (btnType == 'Copy Text') then
				setclipboard(textData.text);
			elseif (btnType == 'Copy Username') then
				setclipboard(textData.player.Name);
			elseif (btnType == 'Copy User Id') then
				setclipboard(tostring(textData.player.UserId));
			elseif (btnType == 'Spectate') then
				setCameraSubject(textData.player.Character);
				textData.tooltip.Text = 'Unspectate';
			elseif (btnType == 'Unspectate') then
				setCameraSubject(LocalPlayer.Character);
				textData.tooltip.Text = 'Spectate';
			elseif (btnType == 'Report User') then

			end;
		end);

		chatLogger.OnUpdate:Connect(function(updateType, vector)
			library.configVars['chatLogger' .. updateType] = tostring(vector);
		end);

		library.OnLoad:Connect(function()
			local chatLoggerSize = library.configVars.chatLoggerSize;
			chatLoggerSize = chatLoggerSize and Vector2.new(unpack(chatLoggerSize:split(',')));

			local chatLoggerPosition = library.configVars.chatLoggerPosition;
			chatLoggerPosition = chatLoggerPosition and Vector2.new(unpack(chatLoggerPosition:split(',')));

			if (chatLoggerSize) then
				chatLogger:SetSize(UDim2.fromOffset(chatLoggerSize.X, chatLoggerSize.Y));
			end;

			if (chatLoggerPosition) then
				chatLogger:SetPosition(UDim2.fromOffset(chatLoggerPosition.X, chatLoggerPosition.Y));
			end;

			chatLogger:UpdateCanvas();
		end);
	end;

	function TextLogger.new(params)
		params = params or {};
		params.buttons = params.buttons or {};
		params.title = params.title or 'No Title';

		local self = setmetatable({}, TextLogger);
		local screenGui = library:Create('ScreenGui', {IgnoreGuiInset = true, Enabled = false, AutoLocalize = false});

		self.params = params;
		self._gui = screenGui;
		self.logs = {};
		self.allLogs = {};

		self.OnPlayerChatted = Signal.new();
		self.OnClick = Signal.new();
		self.OnUpdate = Signal.new();

		local main = library:Create('Frame', {
			Name = 'Main',
			Active = true,
			Visible = true,
			Size = UDim2.new(0, 500, 0, 300),
			Position = UDim2.new(0.5, -250, 0.5, -150),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = TextLogger.Colors.Background,
			Parent = screenGui
		});

		self._main = main;

		local dragger = library:Create('Frame', {
			Parent = main,
			Active = true,
			BackgroundTransparency = 1,
			Size = UDim2.new(0, 50, 0, 50),
			Position = UDim2.new(1, 10, 1, 10),
			AnchorPoint = Vector2.new(1, 1)
		});

		library:Create('UICorner', {
			Parent = main,
			CornerRadius = UDim.new(0, 4),
		});

		library:Create('UIStroke', {
			Parent = main,
			Color = TextLogger.Colors.Border
		});

		local title = library:Create('TextButton', {
			Parent = main,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			TextColor3 = TextLogger.Colors.TitleColor,
			Font = Enum.Font.Roboto,
			Text = params.title,
			TextSize = 20
		});

		local dragStart;
		local startPos;
		local dragging;

		dragger.InputBegan:Connect(function(inputObject, gpe)
			if (inputObject.UserInputType == Enum.UserInputType.MouseButton1) then
				local dragStart = inputObject.Position;
				dragStart = Vector2.new(dragStart.X, dragStart.Y);

				local startPos = main.Size;

				repeat
					local mousePosition = UserInputService:GetMouseLocation();
					local delta = mousePosition - dragStart;

					main.Size = UDim2.new(0, startPos.X.Offset + delta.X, 0, (startPos.Y.Offset + delta.Y) - 36);

					task.wait();
				until (inputObject.UserInputState == Enum.UserInputState.End);

				self:UpdateCanvas();
				self.OnUpdate:Fire('Size', main.AbsoluteSize);
			end;
		end);

		title.InputBegan:Connect(function(inputObject, gpe)
			if (inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

			dragging = true;

			dragStart = inputObject.Position;
			startPos = main.Position;

			repeat
				task.wait();
			until inputObject.UserInputState == Enum.UserInputState.End;

			self.OnUpdate:Fire('Position', main.AbsolutePosition);
			dragging = false;

			self:UpdateCanvas();
		end);

		UserInputService.InputChanged:Connect(function(input, gpe)
			if (not dragging or input.UserInputType ~= Enum.UserInputType.MouseMovement) then return end;

			local delta = input.Position - dragStart;
			local yPos = startPos.Y.Offset + delta.Y;
			main:TweenPosition(UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, yPos), 'Out', 'Quint', 0.1, true);
		end);

		local titleBorder = library:Create('Frame', {
			Parent = title,
			Size = UDim2.new(1, 0, 1, 0),
			BackgroundTransparency = 1,
		});

		library:Create('UICorner', {
			Parent = titleBorder,
			CornerRadius = UDim.new(0, 4),
		});

		library:Create('UIStroke', {
			Parent = titleBorder,
			Color = TextLogger.Colors.Border
		});

		local logsContainer = library:Create('Frame', {
			Parent = main,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, -35),
			Position = UDim2.fromOffset(0, 35)
		});

		library:Create('UIPadding', {
			Parent = logsContainer,
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		});

		local logs = library:Create('ScrollingFrame', {
			Parent = logsContainer,
			ClipsDescendants = true,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BottomImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			MidImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			TopImage = 'rbxasset://textures/ui/Scroll/scroll-middle.png',
			ScrollBarThickness = 5,
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
		});

		self._layout = library:Create('UIListLayout', {
			Parent = logs,
			Padding = UDim.new(0, 5),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		});

		local toolTip = library:Create('Frame', {
			Parent = screenGui,
			BackgroundColor3 = TextLogger.Colors.Background,
			Size = UDim2.new(0, 150, 0, 0),
			ZIndex = 100,
			ClipsDescendants = true,
			Visible = false,
		});

		library:Create('UICorner', {
			Parent = toolTip,
			CornerRadius = UDim.new(0, 8),
		});

		library:Create('UIStroke', {
			Parent = toolTip,
			Color = TextLogger.Colors.Border,
		});

		library:Create('UIListLayout', {
			Parent = toolTip,
			Padding = UDim.new(0, 0),
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		});

		self._toolTip = toolTip;

		local function makeButton(btnName)
			local button = library:Create('TextButton', {
				Parent = toolTip,
				Size = UDim2.new(1, 0, 0, 30),
				BackgroundTransparency = 1,
				Font = Enum.Font.Roboto,
				Text = btnName,
				TextSize = 15,
				TextColor3 = TextLogger.Colors.TitleColor,
				ZIndex = 100
			});

			local textTweenIn = TweenService:Create(button, TweenInfo.new(0.1), {
				TextColor3 = Color3.fromRGB(200, 200, 200)
			});

			local textTweenOut = TweenService:Create(button, TweenInfo.new(0.1), {
				TextColor3 = Color3.fromRGB(255, 255, 255)
			});

			button.MouseEnter:Connect(function()
				textTweenIn:Play();
			end);

			button.MouseLeave:Connect(function()
				textTweenOut:Play();
			end);

			button.InputBegan:Connect(function(inputObject, gpe)
				if (gpe or inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

				self._currentToolTip.tooltip = button;
				self.OnClick:Fire(button.Text, self._currentToolTip, self._currentToolTipIndex);
			end);
		end;

		self._logs = logs;

		syn.protect_gui(screenGui);
		screenGui.Parent = game.CoreGui;

		UserInputService.InputBegan:Connect(function(input)
			local userInputType = input.UserInputType;

			if (userInputType == Enum.UserInputType.MouseButton1) then
				self._toolTip:TweenSize(UDim2.new(0, 150, 0, 0), 'Out', 'Quad', 0.1, true, function()
					self._toolTip.Visible = false;
				end);

				self._currentToolTip = nil;
				self._currentToolTipIndex = nil;
			end;
		end);

		for _, v in next, params.buttons do
			makeButton(v);
		end;

		if (params.preset == 'chatLogger') then
			initChatLoggerPreset(self);
		end;

		return self;
	end;

	function TextLogger:AddText(textData)
		textData._parent = self;
		local textObject = Text.new(textData);

		return textObject;
	end;

	function TextLogger:SetVisible(state)
		self._gui.Enabled = state;
	end;

	function TextLogger:UpdateCanvas()
		for _, v in next, self.logs do
			local textSize = TextService:GetTextSize(v.label.ContentText, 20, Enum.Font.Roboto, Vector2.new(self._logs.AbsoluteSize.X, math.huge));
			v.label.Size = UDim2.new(1, 0, 0, textSize.Y);
		end;

		local contentSize = self._layout.AbsoluteContentSize;

		self._logs.CanvasSize = UDim2.fromOffset(0, contentSize.Y);

		if (library.flags.chatLoggerAutoScroll) then
			self._logs.CanvasPosition = Vector2.new(0, contentSize.Y);
		end;
	end;

	function TextLogger:SetSize(size)
		self._main.Size = size;
		self:UpdateCanvas();
	end;

	function TextLogger:SetPosition(position)
		self._main.Position = position;
		self:UpdateCanvas();
	end;

	return TextLogger;
end

function ControlModule()
	local Services = Services()
	local ContextActionService, HttpService = Services:Get('ContextActionService', 'HttpService');

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

function Utility()
	SX_VM_CNONE();

	local Services = Services()
	local library = library()
	local Signal = Signal()

	local Players, UserInputService, HttpService, CollectionService = Services:Get('Players', 'UserInputService', 'HttpService', 'CollectionService');
	local LocalPlayer = Players.LocalPlayer;

	local Utility = {};

	Utility.onPlayerAdded = Signal.new();
	Utility.onCharacterAdded = Signal.new();
	Utility.onLocalCharacterAdded = Signal.new();

	local mathFloor = clonefunction(math.floor)
	local isDescendantOf = clonefunction(game.IsDescendantOf);
	local findChildIsA = clonefunction(game.FindFirstChildWhichIsA);
	local findFirstChild = clonefunction(game.FindFirstChild);

	local IsA = clonefunction(game.IsA);

	local getMouseLocation = clonefunction(UserInputService.GetMouseLocation);
	local getPlayers = clonefunction(Players.GetPlayers);

	local worldToViewportPoint = clonefunction(Instance.new(getServerConstant('Camera')).WorldToViewportPoint);

	function Utility:countTable(t)
		local found = 0;

		for i, v in next, t do
			found = found + 1;
		end;

		return found;
	end;

	function Utility:roundVector(vector)
		return Vector3.new(vector.X, 0, vector.Z);
	end;

	function Utility:getCharacter(player)
		local playerData = self:getPlayerData(player);
		if (not playerData.alive) then return end;

		local maxHealth, health = playerData.maxHealth, playerData.health;
		return playerData.character, maxHealth, (health / maxHealth) * 100, mathFloor(health), playerData.rootPart;
	end;

	function Utility:isTeamMate(player)
		local playerData, myPlayerData = self:getPlayerData(player), self:getPlayerData();
		local playerTeam, myTeam = playerData.team, myPlayerData.team;

		if(playerTeam == nil or myTeam == nil) then
			return false;
		end;

		return playerTeam == myTeam;
	end;

	function Utility:getRootPart(player)
		local playerData = self:getPlayerData(player);
		return playerData and playerData.rootPart;
	end;

	function Utility:renderOverload(data) end;

	local function castPlayer(origin, direction, rayParams, playerToFind)
		local distanceTravalled = 0;

		while true do
			distanceTravalled = distanceTravalled + direction.Magnitude;

			local target = workspace:Raycast(origin, direction, rayParams);

			if(target) then
				if(isDescendantOf(target.Instance, playerToFind)) then
					return false;
				elseif(target and target.Instance.CanCollide) then
					return true;
				end;
			elseif(distanceTravalled > 2000) then
				return false;
			end;

			origin = origin + direction;
		end;
	end;

	function Utility:getClosestCharacter(rayParams)
		rayParams = rayParams or RaycastParams.new();
		rayParams.FilterDescendantsInstances = {}

		local myCharacter = Utility:getCharacter(LocalPlayer);
		local myHead = myCharacter and findFirstChild(myCharacter, 'Head');
		if(not myHead) then return end;

		if(rayParams.FilterType == Enum.RaycastFilterType.Blacklist) then
			table.insert(rayParams.FilterDescendantsInstances, myHead.Parent);
		end;

		local camera = workspace.CurrentCamera;
		if(not camera) then return end;

		local mousePos = library.flags.useFOV and getMouseLocation(UserInputService);
		local lastDistance, lastPlayer = math.huge, {};

		local maxFov = library.flags.useFOV and library.flags.aimbotFOV or math.huge;
		local whitelistedPlayers = library.options.aimbotWhitelistedPlayers.values;

		for _, player in next, getPlayers(Players) do
			if(player == LocalPlayer or table.find(whitelistedPlayers, player.Name)) then continue end;

			local character, health = Utility:getCharacter(player);

			if(not character or health <= 0 or findChildIsA(character, 'ForceField')) then continue; end;
			if(library.flags.checkTeam and Utility:isTeamMate(player)) then continue end;

			local head = character and findFirstChild(character, 'Head');
			if(not head) then continue end;

			local newDistance = (myHead.Position - head.Position).Magnitude;
			if(newDistance > lastDistance) then continue end;

			if (mousePos) then
				local screenPosition, visibleOnScreen = worldToViewportPoint(camera, head.Position);
				screenPosition = Vector2.new(screenPosition.X, screenPosition.Y);

				if((screenPosition - mousePos).Magnitude > maxFov or not visibleOnScreen) then continue end;
			end;

			local isBehindWall = library.flags.visibilityCheck and castPlayer(myHead.Position, (head.Position - myHead.Position).Unit * 100, rayParams, head.Parent);
			if (isBehindWall) then continue end;

			lastPlayer = {Player = player, Character = character, Health = health};
			lastDistance = newDistance;
		end;

		return lastPlayer, lastDistance;
	end;

	function Utility:getClosestCharacterWithEntityList(entityList, rayParams, options)
		rayParams = rayParams or RaycastParams.new();
		rayParams.FilterDescendantsInstances = {}

		options = options or {};
		options.maxDistance = options.maxDistance or math.huge;

		local myCharacter = Utility:getCharacter(LocalPlayer);
		local myHead = myCharacter and findFirstChild(myCharacter, 'Head');
		if(not myHead) then return end;

		if(rayParams.FilterType == Enum.RaycastFilterType.Blacklist) then
			table.insert(rayParams.FilterDescendantsInstances, myHead.Parent);
		end;

		local camera = workspace.CurrentCamera;
		if(not camera) then return end;

		local mousePos = library.flags.useFOV and getMouseLocation(UserInputService);
		local lastDistance, lastPlayer = math.huge, {};
		local whitelistedPlayers = library.options.aimbotWhitelistedPlayers.values;

		local maxFov = library.flags.useFOV and library.flags.aimbotFOV or math.huge;

		for _, player in next, entityList do
			if(player == myCharacter or table.find(whitelistedPlayers, player.Name)) then continue end;

			local humanoid = findChildIsA(player, 'Humanoid');
			if (not humanoid or humanoid.Health <= 0) then continue end;

			local character = player;

			if(not character or findChildIsA(character, 'ForceField')) then continue; end;

			local head = character and findFirstChild(character, 'Head');
			if(not head) then continue end;

			local newDistance = (myHead.Position - head.Position).Magnitude;
			if(newDistance > lastDistance or newDistance > options.maxDistance) then continue end;

			if (mousePos) then
				local screenPosition, visibleOnScreen = worldToViewportPoint(camera, head.Position);
				screenPosition = Vector2.new(screenPosition.X, screenPosition.Y);

				if((screenPosition - mousePos).Magnitude > maxFov or not visibleOnScreen) then continue end;
			end;

			local isBehindWall = library.flags.visibilityCheck and castPlayer(myHead.Position, (head.Position - myHead.Position).Unit * 100, rayParams, head.Parent);
			if (isBehindWall) then continue end;

			lastPlayer = {Player = player, Character = character, Health = humanoid.Health};
			lastDistance = newDistance;
		end;

		return lastPlayer, lastDistance;
	end;

	function panic()
		library:Unload();
	end;

	local playersData = {};

	local function onCharacterAdded(player)
		local playerData = playersData[player];
		if (not playerData) then return end;

		local character = player.Character;
		if (not character) then return end;

		local localAlive = true;

		table.clear(playerData.parts);

		Utility.listenToChildAdded(character, function(obj)
			if (obj.Name == 'Humanoid') then
				playerData.humanoid = obj;
			elseif (obj.Name == 'HumanoidRootPart') then
				playerData.rootPart = obj;
			elseif (obj.Name == 'Head') then
				playerData.head = obj;
			end;
		end);

		if (player == LocalPlayer) then
			Utility.listenToDescendantAdded(character, function(obj)
				if (IsA(obj, 'BasePart')) then
					table.insert(playerData.parts, obj);

					local con;
					con = obj:GetPropertyChangedSignal('Parent'):Connect(function()
						if (obj.Parent) then return end;
						con:Disconnect();
						table.remove(playerData.parts, table.find(playerData.parts, obj));
					end);
				end;
			end);
		end;

		local function onPrimaryPartChanged()
			playerData.primaryPart = character.PrimaryPart;
			playerData.alive = not not playerData.primaryPart;
		end

		local hum = character:WaitForChild('Humanoid', 30);
		playerData.humanoid = hum;
		if (not playerData.humanoid) then return warn('[Utility] [onCharacterAdded] Player is missing humanoid ' .. player:GetFullName()) end;
		if (not player.Parent or not character.Parent) then return end;

		character:GetPropertyChangedSignal('PrimaryPart'):Connect(onPrimaryPartChanged);

		if (character.PrimaryPart) then
			onPrimaryPartChanged();
		end;

		playerData.character = character;
		playerData.alive = true;
		playerData.health = playerData.humanoid.Health;
		playerData.maxHealth = playerData.humanoid.MaxHealth;

		hum.Destroying:Connect(function()
			playerData.alive = false;
			localAlive = false;
		end);

		hum.Died:Connect(function()
			playerData.alive = false;
			localAlive = false;
		end);

		playerData.humanoid:GetPropertyChangedSignal('Health'):Connect(function()
			playerData.health = hum.Health;
		end);

		playerData.humanoid:GetPropertyChangedSignal('MaxHealth'):Connect(function()
			playerData.maxHealth = hum.MaxHealth;
		end);

		local function fire()
			if (not localAlive) then return end;
			Utility.onCharacterAdded:Fire(playerData);

			if (player == LocalPlayer) then
				Utility.onLocalCharacterAdded:Fire(playerData);
			end;
		end;

		if (library.OnLoad) then
			library.OnLoad:Connect(fire);
		else
			fire();
		end;
	end;

	local function onPlayerAdded(player)
		local playerData = {};

		playerData.player = player;
		playerData.team = player.Team;
		playerData.parts = {};

		playersData[player] = playerData;

		local function fire()
			Utility.onPlayerAdded:Fire(player);
		end;

		task.spawn(onCharacterAdded, player);

		player.CharacterAdded:Connect(function()
			onCharacterAdded(player);
		end);

		player:GetPropertyChangedSignal('Team'):Connect(function()
			playerData.team = player.Team;
		end);

		if (library.OnLoad) then
			library.OnLoad:Connect(fire);
		else
			fire();
		end;
	end;

	function Utility:getPlayerData(player)
		return playersData[player or LocalPlayer] or {};
	end;

	function Utility.listenToChildAdded(folder, listener, options)
		options = options or {listenToDestroying = false};

		local createListener = typeof(listener) == 'table' and listener.new or listener;

		assert(typeof(folder) == 'Instance', 'listenToChildAdded folder #1 listener has to be an instance');
		assert(typeof(createListener) == 'function', 'listenToChildAdded #2 listener has to be a function');

		local function onChildAdded(child)
			local listenerObject = createListener(child);

			if (options.listenToDestroying) then
				child.Destroying:Connect(function()
					local removeListener = typeof(listener) == 'table' and (function() local a = (listener.Destroy or listener.Remove); a(listenerObject) end) or listenerObject;

					if (typeof(removeListener) ~= 'function') then
						warn('[Utility] removeListener is not definded possible memory leak for', folder);
					else
						removeListener(child);
					end;
				end);
			end;
		end

		debug.profilebegin(string.format('Utility.listenToChildAdded(%s)', folder:GetFullName()));

		for _, child in next, folder:GetChildren() do
			task.spawn(onChildAdded, child);
		end;

		debug.profileend();

		return folder.ChildAdded:Connect(createListener);
	end;

	function Utility.listenToChildRemoving(folder, listener)
		local createListener = typeof(listener) == 'table' and listener.new or listener;

		assert(typeof(folder) == 'Instance', 'listenToChildRemoving folder #1 listener has to be an instance');
		assert(typeof(createListener) == 'function', 'listenToChildRemoving #2 listener has to be a function');

		return folder.ChildRemoved:Connect(createListener);
	end;

	function Utility.listenToDescendantAdded(folder, listener, options)
		options = options or {listenToDestroying = false};

		local createListener = typeof(listener) == 'table' and listener.new or listener;

		assert(typeof(folder) == 'Instance', 'listenToDescendantAdded folder #1 listener has to be an instance');
		assert(typeof(createListener) == 'function', 'listenToDescendantAdded #2 listener has to be a function');

		local function onDescendantAdded(child)
			local listenerObject = createListener(child);

			if (options.listenToDestroying) then
				child.Destroying:Connect(function()
					local removeListener = typeof(listener) == 'table' and (listener.Destroy or listener.Remove) or listenerObject;

					if (typeof(removeListener) ~= 'function') then
						warn('[Utility] removeListener is not definded possible memory leak for', folder);
					else
						removeListener(child);
					end;
				end);
			end;
		end

		debug.profilebegin(string.format('Utility.listenToDescendantAdded(%s)', folder:GetFullName()));

		for _, child in next, folder:GetDescendants() do
			task.spawn(onDescendantAdded, child);
		end;

		debug.profileend();

		return folder.DescendantAdded:Connect(onDescendantAdded);
	end;

	function Utility.listenToDescendantRemoving(folder, listener)
		local createListener = typeof(listener) == 'table' and listener.new or listener;

		assert(typeof(folder) == 'Instance', 'listenToDescendantRemoving folder #1 listener has to be an instance');
		assert(typeof(createListener) == 'function', 'listenToDescendantRemoving #2 listener has to be a function');

		return folder.DescendantRemoving:Connect(createListener);
	end;

	function Utility.listenToTagAdded(tagName, listener)
		for _, v in next, CollectionService:GetTagged(tagName) do
			task.spawn(listener, v);
		end;

		return CollectionService:GetInstanceAddedSignal(tagName):Connect(listener);
	end;

	function Utility.getFunctionHash(f)
		if (typeof(f) ~= 'function') then return error('getFunctionHash(f) #1 has to be a function') end;

		local constants = getconstants(f);
		local protos = getprotos(f);

		local total = HttpService:JSONEncode({constants, protos});

		return syn.crypt.hash(total);
	end;

	local function onPlayerRemoving(player)
		playersData[player] = nil;
	end;

	for _, player in next, Players:GetPlayers() do
		task.spawn(onPlayerAdded, player);
	end;

	Players.PlayerAdded:Connect(onPlayerAdded);
	Players.PlayerRemoving:Connect(onPlayerRemoving);

	function Utility.find(t, c)
		for i, v in next, t do
			if (c(v, i)) then
				return v, i;
			end;
		end;

		return nil;
	end;

	function Utility.map(t, c)
		local ret = {};

		for i, v in next, t do
			local val = c(v, i);
			if (val) then
				table.insert(ret, val);
			end;
		end;

		return ret;
	end;

	return Utility;
end

function EntityESP()
	SX_VM_CNONE();

	local library = library()
	local Utility = Utility()
	local Services = Services()

	local RunService, UserInputService, HttpService = Services:Get('RunService', 'UserInputService', 'HttpService');

	local EntityESP = {};

	local worldToViewportPoint = clonefunction(Instance.new('Camera').WorldToViewportPoint);
	local vectorToWorldSpace = CFrame.new().VectorToWorldSpace;
	local getMouseLocation = clonefunction(UserInputService.GetMouseLocation);

	local id = HttpService:GenerateGUID(false);
	local userId = '1234'

	local lerp = Color3.new().lerp;
	local flags = library.flags;

	local vector3New = Vector3.new;
	local Vector2New = Vector2.new;

	local mathFloor = math.floor;

	local mathRad = math.rad;
	local mathCos = math.cos;
	local mathSin = math.sin;
	local mathAtan2 = math.atan2;

	local showTeam;
	local allyColor;
	local enemyColor;
	local maxEspDistance;
	local toggleBoxes;
	local toggleTracers;
	local unlockTracers;
	local showHealthBar;
	local proximityArrows;
	local maxProximityArrowDistance;

	local scalarPointAX, scalarPointAY;
	local scalarPointBX, scalarPointBY;

	local labelOffset, tracerOffset;
	local boxOffsetTopRight, boxOffsetBottomLeft;

	local healthBarOffsetTopRight, healthBarOffsetBottomLeft;
	local healthBarValueOffsetTopRight, healthBarValueOffsetBottomLeft;

	local realGetRPProperty;

	local setRP;
	local getRPProperty;
	local destroyRP;

	local scalarSize = 20;

	if (not isSynapseV3) then
		local lineUpvalues = getupvalue(Drawing.new, 4).__index;
		local lineUpvalues2 = getupvalue(Drawing.new, 4).__newindex;

		-- destroyRP, getRPProperty = getupvalue(lineUpvalues, 3), getupvalue(lineUpvalues, 4);
		local realSetRP = getupvalue(lineUpvalues2, 4);
		local realDestroyRP = getupvalue(lineUpvalues, 3);
		realGetRPProperty = getupvalue(lineUpvalues, 4);

		assert(realSetRP);
		assert(realDestroyRP);
		assert(realGetRPProperty);

		setRP = function(object, p, v)
			local cache = object._cache;
			local cacheVal = cache[p];
			if (cacheVal == v) then return end;

			cache[p] = v;
			realSetRP(object.__OBJECT, p, v);
		end;

		getRPProperty = function(object, p)
			local cacheVal = object._cache[p];
			if (not cacheVal) then
				object._cache[p] = realGetRPProperty(object.__OBJECT, p);
				cacheVal = object._cache[p];
			end;

			return cacheVal;
		end;

		destroyRP = function(object)
			return realDestroyRP(object.__OBJECT);
		end;
	else
		getRPProperty = function(self, p, v)
			return self[p];
		end;

		setRP = function(self, p, v)
			self[p] = v;
		end;

		destroyRP = function(self)
			return self:Remove();
		end;

		realGetRPProperty = getRPProperty;
	end;

	local ESP_RED_COLOR, ESP_GREEN_COLOR = Color3.fromRGB(192, 57, 43), Color3.fromRGB(39, 174, 96)
	local TRIANGLE_ANGLE = mathRad(45);

	do --// Entity ESP
		EntityESP = {};
		EntityESP.__index = EntityESP;
		EntityESP.__ClassName = 'entityESP';

		EntityESP.id = 0;

		local emptyTable = {};

		function EntityESP.new(player)
			EntityESP.id += 1;

			local self = setmetatable({}, EntityESP);

			self._id = EntityESP.id;
			self._player = player;
			self._playerName = player.Name;

			self._triangle = Drawing.new('Triangle');
			self._triangle.Visible = true;
			self._triangle.Thickness = 0;
			self._triangle.Color = Color3.fromRGB(255, 255, 255);
			self._triangle.Filled = true;

			self._label = Drawing.new('Text');
			self._label.Visible = false;
			self._label.Center = true;
			self._label.Outline = true;
			self._label.Text = '';
			self._label.Font = Drawing.Fonts[library.flags.espFont];
			self._label.Size = library.flags.textSize;
			self._label.Color = Color3.fromRGB(255, 255, 255);

			self._box = Drawing.new('Quad');
			self._box.Visible = false;
			self._box.Thickness = 1;
			self._box.Filled = false;
			self._box.Color = Color3.fromRGB(255, 255, 255);

			self._healthBar = Drawing.new('Quad');
			self._healthBar.Visible = false;
			self._healthBar.Thickness = 1;
			self._healthBar.Filled = false;
			self._healthBar.Color = Color3.fromRGB(255, 255, 255);

			self._healthBarValue = Drawing.new('Quad');
			self._healthBarValue.Visible = false;
			self._healthBarValue.Thickness = 1;
			self._healthBarValue.Filled = true;
			self._healthBarValue.Color = Color3.fromRGB(0, 255, 0);

			self._line = Drawing.new('Line');
			self._line.Visible = false;
			self._line.Color = Color3.fromRGB(255, 255, 255);

			for i, v in next, self do
				if (typeof(v) == 'table' and rawget(v, '__OBJECT')) then
					rawset(v, '_cache', {});
				end;
			end;

			self._labelObject = isSynapseV3 and self._label or self._label.__OBJECT;

			return self;
		end;

		function EntityESP:Plugin()
			return emptyTable;
		end;

		function EntityESP:ConvertVector(...)
			-- if(flags.twoDimensionsESP) then
			-- return vector3New(...));
			-- else
			return vectorToWorldSpace(self._cameraCFrame, vector3New(...));
			-- end;
		end;

		function EntityESP:GetOffsetTrianglePosition(closestPoint, radiusOfDegree)
			local cosOfRadius, sinOfRadius = mathCos(radiusOfDegree), mathSin(radiusOfDegree);
			local closestPointX, closestPointY = closestPoint.X, closestPoint.Y;

			local sameBCCos = (closestPointX + scalarPointBX * cosOfRadius);
			local sameBCSin = (closestPointY + scalarPointBX * sinOfRadius);

			local sameACSin = (scalarPointAY * sinOfRadius);
			local sameACCos = (scalarPointAY * cosOfRadius)

			local pointX1 = (closestPointX + scalarPointAX * cosOfRadius) - sameACSin;
			local pointY1 = closestPointY + (scalarPointAX * sinOfRadius) + sameACCos;

			local pointX2 = sameBCCos - (scalarPointBY * sinOfRadius);
			local pointY2 = sameBCSin + (scalarPointBY * cosOfRadius);

			local pointX3 = sameBCCos - sameACSin;
			local pointY3 = sameBCSin + sameACCos;

			return Vector2New(mathFloor(pointX1), mathFloor(pointY1)), Vector2New(mathFloor(pointX2), mathFloor(pointY2)), Vector2New(mathFloor(pointX3), mathFloor(pointY3));
		end;

		function EntityESP:Update(t)
			local camera = self._camera;
			if(not camera) then return self:Hide() end;

			local character, maxHealth, floatHealth, health, rootPart = Utility:getCharacter(self._player);
			if(not character) then return self:Hide() end;

			rootPart = rootPart or Utility:getRootPart(self._player);
			if(not rootPart) then return self:Hide() end;

			local rootPartPosition = rootPart.Position;

			local labelPos, visibleOnScreen = worldToViewportPoint(camera, rootPartPosition + labelOffset);
			local triangle = self._triangle;

			local isTeamMate = Utility:isTeamMate(self._player);
			if(isTeamMate and not showTeam) then return self:Hide() end;

			local distance = (rootPartPosition - self._cameraPosition).Magnitude;
			if(distance > maxEspDistance) then return self:Hide() end;

			local espColor = isTeamMate and allyColor or enemyColor;
			local canView = false;

			if (proximityArrows and not visibleOnScreen and distance < maxProximityArrowDistance) then
				local vectorUnit;

				if (labelPos.Z < 0) then
					vectorUnit = -(Vector2.new(labelPos.X, labelPos.Y) - self._viewportSizeCenter).Unit; --PlayerPos-Center.Unit
				else
					vectorUnit = (Vector2.new(labelPos.X, labelPos.Y) - self._viewportSizeCenter).Unit; --PlayerPos-Center.Unit
				end;

				local degreeOfCorner = -mathAtan2(vectorUnit.X, vectorUnit.Y) - TRIANGLE_ANGLE;
				local closestPointToPlayer = self._viewportSizeCenter + vectorUnit * scalarSize --screenCenter+unit*scalar (Vector 2)

				local pointA, pointB, pointC = self:GetOffsetTrianglePosition(closestPointToPlayer, degreeOfCorner);

				setRP(triangle, 'PointA', pointA);
				setRP(triangle, 'PointB', pointB);
				setRP(triangle, 'PointC', pointC);

				setRP(triangle, 'Color', espColor);
				canView = true;
			end;

			setRP(triangle, 'Visible', canView);
			if (not visibleOnScreen) then return self:Hide(true) end;

			self._visible = visibleOnScreen;

			local label, box, line, healthBar, healthBarValue = self._label, self._box, self._line, self._healthBar, self._healthBarValue;
			local pluginData = self:Plugin();

			local text = '[' .. (pluginData.playerName or self._playerName) .. '] [' .. mathFloor(distance) .. ']\n[' .. mathFloor(health) .. '/' .. mathFloor(maxHealth) .. '] [' .. mathFloor(floatHealth) .. ' %]' .. (pluginData.text or '') .. ' [' .. userId .. ']';

			setRP(label, 'Visible', visibleOnScreen);
			setRP(label, 'Position', Vector2New(labelPos.X, labelPos.Y - realGetRPProperty(self._labelObject, 'TextBounds').Y));
			setRP(label, 'Text', text);
			setRP(label, 'Color', espColor);

			if(toggleBoxes) then
				local boxTopRight = worldToViewportPoint(camera, rootPartPosition + boxOffsetTopRight);
				local boxBottomLeft = worldToViewportPoint(camera, rootPartPosition + boxOffsetBottomLeft);

				local topRightX, topRightY = boxTopRight.X, boxTopRight.Y;
				local bottomLeftX, bottomLeftY = boxBottomLeft.X, boxBottomLeft.Y;

				setRP(box, 'Visible', visibleOnScreen);

				setRP(box, 'PointA', Vector2New(topRightX, topRightY));
				setRP(box, 'PointB', Vector2New(bottomLeftX, topRightY));
				setRP(box, 'PointC', Vector2New(bottomLeftX, bottomLeftY));
				setRP(box, 'PointD', Vector2New(topRightX, bottomLeftY));
				setRP(box, 'Color', espColor);
			else
				setRP(box, 'Visible', false);
			end;

			if(toggleTracers) then
				local linePosition = worldToViewportPoint(camera, rootPartPosition + tracerOffset);

				setRP(line, 'Visible', visibleOnScreen);

				setRP(line, 'From', unlockTracers and getMouseLocation(UserInputService) or self._viewportSize);
				setRP(line, 'To', Vector2New(linePosition.X, linePosition.Y));
				setRP(line, 'Color', espColor);
			else
				setRP(line, 'Visible', false);
			end;

			if(showHealthBar) then
				local healthBarValueHealth = (1 - (floatHealth / 100)) * 7.4;

				local healthBarTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetTopRight);
				local healthBarBottomLeft = worldToViewportPoint(camera, rootPartPosition + healthBarOffsetBottomLeft);

				local healthBarTopRightX, healthBarTopRightY = healthBarTopRight.X, healthBarTopRight.Y;
				local healthBarBottomLeftX, healthBarBottomLeftY = healthBarBottomLeft.X, healthBarBottomLeft.Y;

				local healthBarValueTopRight = worldToViewportPoint(camera, rootPartPosition + healthBarValueOffsetTopRight - self:ConvertVector(0, healthBarValueHealth, 0));
				local healthBarValueBottomLeft = worldToViewportPoint(camera, rootPartPosition - healthBarValueOffsetBottomLeft);

				local healthBarValueTopRightX, healthBarValueTopRightY = healthBarValueTopRight.X, healthBarValueTopRight.Y;
				local healthBarValueBottomLeftX, healthBarValueBottomLeftY = healthBarValueBottomLeft.X, healthBarValueBottomLeft.Y;

				setRP(healthBar, 'Visible', visibleOnScreen);
				setRP(healthBar, 'Color', espColor);

				setRP(healthBar, 'PointA', Vector2New(healthBarTopRightX, healthBarTopRightY));
				setRP(healthBar, 'PointB', Vector2New(healthBarBottomLeftX, healthBarTopRightY));
				setRP(healthBar, 'PointC', Vector2New(healthBarBottomLeftX, healthBarBottomLeftY));
				setRP(healthBar, 'PointD', Vector2New(healthBarTopRightX, healthBarBottomLeftY));

				setRP(healthBarValue, 'Visible', visibleOnScreen);
				setRP(healthBarValue, 'Color', lerp(ESP_RED_COLOR, ESP_GREEN_COLOR, floatHealth / 100));

				setRP(healthBarValue, 'PointA', Vector2New(healthBarValueTopRightX, healthBarValueTopRightY));
				setRP(healthBarValue, 'PointB', Vector2New(healthBarValueBottomLeftX, healthBarValueTopRightY));
				setRP(healthBarValue, 'PointC', Vector2New(healthBarValueBottomLeftX, healthBarValueBottomLeftY));
				setRP(healthBarValue, 'PointD', Vector2New(healthBarValueTopRightX, healthBarValueBottomLeftY));
			else
				setRP(healthBar, 'Visible', false);
				setRP(healthBarValue, 'Visible', false);
			end;
		end;

		function EntityESP:Destroy()
			if (not self._label) then return end;

			destroyRP(self._label);
			self._label = nil;

			destroyRP(self._box);
			self._box = nil;

			destroyRP(self._line);
			self._line = nil;

			destroyRP(self._healthBar);
			self._healthBar = nil;

			destroyRP(self._healthBarValue);
			self._healthBarValue = nil;

			destroyRP(self._triangle);
			self._triangle = nil;
		end;

		function EntityESP:Hide(bypassTriangle)
			if (not bypassTriangle) then
				setRP(self._triangle, 'Visible', false);
			end;

			if (not self._visible) then return end;
			self._visible = false;

			setRP(self._label, 'Visible', false);
			setRP(self._box, 'Visible', false);
			setRP(self._line, 'Visible', false);

			setRP(self._healthBar, 'Visible', false);
			setRP(self._healthBarValue, 'Visible', false);
		end;

		function EntityESP:SetFont(font)
			setRP(self._label, 'Font', font);
		end;

		function EntityESP:SetTextSize(textSize)
			setRP(self._label, 'Size', textSize);
		end;

		local function updateESP()
			local camera = workspace.CurrentCamera;
			EntityESP._camera = camera;
			if (not camera) then return end;

			EntityESP._cameraCFrame = EntityESP._camera.CFrame;
			EntityESP._cameraPosition = EntityESP._cameraCFrame.Position;

			local viewportSize = camera.ViewportSize;

			EntityESP._viewportSize = Vector2New(viewportSize.X / 2, viewportSize.Y - 10);
			EntityESP._viewportSizeCenter = viewportSize / 2;

			showTeam = flags.showTeam;
			allyColor = flags.allyColor;
			enemyColor = flags.enemyColor;
			maxEspDistance = flags.maxEspDistance;
			toggleBoxes = flags.toggleBoxes;
			toggleTracers = flags.toggleTracers;
			unlockTracers = flags.unlockTracers;
			showHealthBar = flags.showHealthBar;
			maxProximityArrowDistance = flags.maxProximityArrowDistance;
			proximityArrows = flags.proximityArrows;

			scalarSize = library.flags.proximityArrowsSize or 20;

			scalarPointAX, scalarPointAY = scalarSize, scalarSize;
			scalarPointBX, scalarPointBY = -scalarSize, -scalarSize;

			labelOffset = EntityESP:ConvertVector(0, 3.25, 0);
			tracerOffset = EntityESP:ConvertVector(0, -4.5, 0);

			boxOffsetTopRight = EntityESP:ConvertVector(2.5, 3, 0);
			boxOffsetBottomLeft = EntityESP:ConvertVector(-2.5, -4.5, 0);

			healthBarOffsetTopRight = EntityESP:ConvertVector(-3, 3, 0);
			healthBarOffsetBottomLeft = EntityESP:ConvertVector(-3.5, -4.5, 0);

			healthBarValueOffsetTopRight = EntityESP:ConvertVector(-3.05, 2.95, 0);
			healthBarValueOffsetBottomLeft = EntityESP:ConvertVector(3.45, 4.45, 0);
		end;

		updateESP();
		RunService:BindToRenderStep(id, Enum.RenderPriority.Camera.Value, updateESP);
	end;

	return EntityESP;
end

function createBaseESP()
	SX_VM_CNONE();
	local Maid = Maid()
	local Services = Services()

	local toCamelCase = toCamelCase()
	local library = library()

	local Players, CorePackages, HttpService = Services:Get('Players', 'CorePackages', 'HttpService');
	local LocalPlayer = Players.LocalPlayer;

	local NUM_ACTORS = 8;

--[[
	We'll add an example cuz I have no brain

	local chestsESP = createBaseESP('chests'); -- This is the base ESP it returns a class with .new, .Destroy, :UpdateAll, :UnloadAll, and some other stuff

	-- Listen to chests childAdded through Utility.listenToChildAdded and then create an espObject for that chest
	-- chestsESP.new only accepts BasePart or CFrame
	-- It has a lazy parameter allowing it to not update the get the position everyframe only get the screen position
	-- Also a color parameter

	Utility.listenToChildAdded(workspace.Chests, function(obj)
		local espObject = chestsESP.new(obj, 'Normal Chest', color, isLazy);

		obj.Destroying:Connect(function()
			espObject:Destroy();
		end);
	end);

	local function updateChestESP(toggle)
		if (not toggle) then
			maid.chestESP = nil;
			chestsESP:UnloadAll();
			return;
		end;

		maid.chestESP = RunService.Stepped:Connect(function()
			chestsESP:UpdateAll();
		end);
	end;

	-- UI Lib functions
	:AddToggle({text = 'Enable', flag = 'chests', callback = updateChestESP});
	:AddToggle({text = 'Show Distance', textpos = 2, flag = 'Chests Show Distance'});
	:AddToggle({text = 'Show Normal Chest'}):AddColor({text = 'Normal Chest Color'}); -- Filer for if you want to see that chest and select the color of it
]]

	local playerScripts = LocalPlayer:WaitForChild('PlayerScripts')

	local playerScriptsLoader = playerScripts:FindFirstChild('PlayerScriptsLoader');
	local actors = {};

	local readyCount = 0;
	local broadcastEvent = Instance.new('BindableEvent');

	local gameName = 'Baby im CuCu'

	if (not playerScriptsLoader and gameName == 'Apocalypse Rising 2') then
		playerScriptsLoader = playerScripts:FindFirstChild('FreecamDelete');
	end;

	if (playerScriptsLoader) then
		for _ = 1, NUM_ACTORS do
			local commId, commEvent;

			if (isSynapseV3) then
				commEvent = {
					_event = Instance.new('BindableEvent'),

					Connect = function(self, f)
						return self._event.Event:Connect(f)
					end,

					Fire = function(self, ...)
						self._event:Fire(...);
					end
				};
			else
				commId, commEvent = getgenv().syn.create_comm_channel();
			end;

			local clone = playerScriptsLoader:Clone();
			local actor = Instance.new('Actor');
			clone.Parent = actor;

			local playerModule = CorePackages.InGameServices.MouseIconOverrideService:Clone();
			playerModule.Name = 'PlayerModule';
			playerModule.Parent = actor;

			if (not isSynapseV3) then
				syn.protect_gui(actor);
			end;

			actor.Parent = LocalPlayer.PlayerScripts;

			local connection;

			connection = commEvent:Connect(function(data)
				if (data.updateType == 'ready') then
					commEvent:Fire({updateType = 'giveEvent', event = broadcastEvent, gameName = gameName});
					actor:Destroy();

					readyCount += 1;

					connection:Disconnect();
					connection = nil;
				end;
			end);

			originalFunctions.runOnActor(actor, createBaseESPParallel(), commId or commEvent);
			table.insert(actors, {
				actor = actor,
				commEvent = commEvent
			});
		end;

		print('Waiting for actors');
		repeat task.wait(); until readyCount >= NUM_ACTORS;
		print('All actors have been loaded');
	else
		local commId, commEvent = getgenv().syn.create_comm_channel();

		local connection;
		connection = commEvent:Connect(function(data)
			if (data.updateType == 'ready') then
				connection:Disconnect();
				connection = nil;

				commEvent:Fire({updateType = 'giveEvent', event = broadcastEvent});
			end;
		end);

		loadstring(createBaseESPParallel())(commId);

		table.insert(actors, {commEvent = commEvent});
		readyCount = 1;
	end;

	local count = 1;

	local function createBaseEsp(flag, container)
		container = container or {};
		local BaseEsp = {};

		BaseEsp.ClassName = 'BaseEsp';
		BaseEsp.Flag = flag;
		BaseEsp.Container = container;
		BaseEsp.__index = BaseEsp;

		local whiteColor = Color3.new(1, 1, 1);

		local maxDistanceFlag = BaseEsp.Flag .. 'MaxDistance';
		local showHealthFlag = BaseEsp.Flag .. 'ShowHealth';
		local showESPFlag = BaseEsp.Flag;

		function BaseEsp.new(instance, tag, color, isLazy)
			assert(instance, '#1 instance expected');
			assert(tag, '#2 tag expected');

			local isCustomInstance = false;

			if (typeof(instance) == 'table' and rawget(instance, 'code')) then
				isCustomInstance = true;
			end;

			color = color or whiteColor;

			local self = setmetatable({}, BaseEsp);
			self._tag = tag;

			local displayName = tag;

			if (typeof(tag) == 'table') then
				displayName = tag.displayName;
				self._tag = tag.tag;
			end;

			self._instance = instance;
			self._text = displayName;
			self._color = color;
			self._showFlag = toCamelCase('Show ' .. self._tag);
			self._colorFlag = toCamelCase(self._tag .. ' Color');
			self._colorFlag2 = BaseEsp.Flag .. 'Color';
			self._showDistanceFlag = BaseEsp.Flag .. 'ShowDistance';
			self._isLazy = isLazy;
			self._actor = actors[(count % readyCount) + 1];
			self._id = count;
			self._maid = Maid.new();

			count += 1;

			if (isLazy and not isCustomInstance) then
				self._instancePosition = instance.Position;
			end;

			self._maxDistanceFlag = maxDistanceFlag;
			self._showHealthFlag = showHealthFlag;

			if (isCustomInstance) then
				self._isCustomInstance = true;
				self._code = instance.code;
				self._vars = instance.vars;
			end;

			local smallData = table.clone(self);
			smallData._actor = nil;
			self._actor.commEvent:Fire({
				updateType = 'new',
				data = smallData,
				isCustomInstance = isCustomInstance,
				showFlag = showESPFlag
			});


			return self;
		end;

		function BaseEsp:Unload() end;
		function BaseEsp:BaseUpdate() end;
		function BaseEsp:UpdateAll() end;
		function BaseEsp:Update() end;
		function BaseEsp:UnloadAll() end;
		function BaseEsp:Disable() end;

		function BaseEsp:Destroy()
			self._maid:Destroy();
			self._actor.commEvent:Fire({
				updateType = 'destroy',
				id = self._id
			});
		end;

		return BaseEsp;
	end;

	library.OnFlagChanged:Connect(function(data)
		broadcastEvent:Fire({
			type = data.type,
			flag = data.flag,
			color = data.color,
			state = data.state,
			value = data.value
		});
	end);

	return createBaseEsp;
end

function prettyPrint()
	-- Thanks corewave
	type = typeof or type
	local str_types = {
		['boolean'] = true,
		['userdata'] = true,
		['table'] = true,
		['function'] = true,
		['number'] = true,
		['nil'] = true
	}

	local function count_table(t)
		local c = 0
		for i, v in next, t do
			c = c + 1
		end

		return c
	end

	local function string_ret(o, typ)
		local ret, mt, old_func
		if not (typ == 'table' or typ == 'userdata') then
			return tostring(o)
		end
		mt = (getrawmetatable or getmetatable)(o)
		if not mt then 
			return tostring(o)
		end

		old_func = rawget(mt, '__tostring')
		rawset(mt, '__tostring', nil)
		ret = tostring(o)
		rawset(mt, '__tostring', old_func)
		return ret
	end

	local function format_value(v)
		local typ = type(v)

		if str_types[typ] then
			return string_ret(v, typ)
		elseif typ == 'string' then
			return '"'..v..'"'
		elseif typ == 'Instance' then
			return v.GetFullName(v)
		else
			return typ..'.new(' .. tostring(v) .. ')'
		end
	end

	local function serialize_table(t, p, c, s)
		local str = ""
		local n = count_table(t)
		local ti = 1
		local e = n > 0

		c = c or {}
		p = p or 1
		s = s or string.rep

		local function localized_format(v, is_table)
			return is_table and (c[v][2] >= p) and serialize_table(v, p + 1, c, s) or format_value(v)
		end

		c[t] = {t, 0}

		for i, v in next, t do
			local typ_i, typ_v = type(i) == 'table', type(v) == 'table'
			c[i], c[v] = (not c[i] and typ_i) and {i, p} or c[i], (not c[v] and typ_v) and {v, p} or c[v]
			str = str .. s('  ', p) .. '[' .. localized_format(i, typ_i) .. '] = '  .. localized_format(v, typ_v) .. (ti < n and ',' or '') .. '\n'
			ti = ti + 1
		end

		return ('{' .. (e and '\n' or '')) .. str .. (e and s('  ', p - 1) or '') .. '}'
	end

	if (debugMode) then
		getgenv().prettyPrint = serialize_table;
	end;

	return serialize_table
end

function findPlayer()
	local Services = Services()
	local Players = Services:Get('Players');

	return function (playerName)
		for _, v in next, Players:GetPlayers() do
			if(v.Name:lower():sub(1, #playerName) == playerName:lower()) then
				return v;
			end;
		end;
	end;
end

function getImageSize()
	local Buffer = {};

	Buffer.ClassName = 'Buffer';
	Buffer.__index = Buffer;

	function Buffer.new(data)
		local self = setmetatable({}, Buffer);

		self._data = data;
		self._pos = 0;

		return self;
	end;

	function Buffer:read(num)
		local data = self._data:sub(self._pos + 1, self._pos + num);
		self._pos = self._pos + num;

		return data;
	end;

	local function read(str)
		return str:sub(1,1):byte() * 16777216 + str:sub(2,2):byte() * 65536 + str:sub(3,3):byte() * 256 + str:sub(4,4):byte();
	end;

	local function getImageSize(imageData)
		local buffer = Buffer.new(imageData);

		buffer:read(1);

		if(buffer:read(3) == 'PNG') then
			buffer:read(12);

			local width = read(buffer:read(4));
			local height = read(buffer:read(4));

			return Vector2.new(width, height);
		end;

		buffer:read(-4);

		if (buffer:read(4) == "GIF8") then
			buffer:read(2);

			local width = buffer:read(1):byte()+buffer:read(1):byte()*256;
			local height = buffer:read(1):byte()+buffer:read(1):byte()*256;

			return Vector2.new(width, height);
		end;
	end;

	return getImageSize;
end

function AltManagerAPI()
	-- DOCUMENTATION: https://ic3w0lf22.gitbook.io/roblox-account-manager/

	local Account = {} Account.__index = Account

	local WebserverSettings = {
		Port = '7963',
		Password = ''
	}

	function WebserverSettings:SetPort(Port) self.Port = Port end
	function WebserverSettings:SetPassword(Password) self.Password = Password end

	local HttpService = game:GetService'HttpService'
	local Request = syn.request;

	local function GET(Method, Account, ...)
		local Arguments = {...}
		local Url = 'http://localhost:' .. WebserverSettings.Port .. '/' .. Method .. '?Account=' .. Account

		for Index, Parameter in pairs(Arguments) do
			Url = Url .. '&' .. Parameter
		end

		if WebserverSettings.Password and #WebserverSettings.Password >= 6 then
			Url = Url .. '&Password=' .. WebserverSettings.Password
		end

		local Response = Request {
			Method = 'GET',
			Url = Url
		}

		if Response.StatusCode ~= 200 then return false end

		return Response.Body
	end

	local function POST(Method, Account, Body, ...)
		local Arguments = {...}
		local Url = 'http://localhost:' .. WebserverSettings.Port .. '/' .. Method .. '?Account=' .. Account

		for Index, Parameter in pairs(Arguments) do
			Url = '&' .. Url .. Parameter
		end

		if WebserverSettings.Password and #WebserverSettings.Password >= 6 then
			Url = Url .. '&Password=' .. WebserverSettings.Password
		end

		local Response = Request {
			Method = 'POST',
			Url = Url,
			Body = Body
		}

		if Response.StatusCode ~= 200 then return false end

		return Response.Body
	end

	function Account.new(Username, SkipValidation)
		local self = {} setmetatable(self, Account)

		local IsValid = SkipValidation or GET('GetCSRFToken', Username)

		if not IsValid or IsValid == 'Invalid Account' then return false end

		self.Username = Username

		return self
	end

	function Account:GetCSRFToken() return GET('GetCSRFToken', self.Username) end

	function Account:BlockUser(Argument)
		if typeof(Argument) == 'string' then
			return GET('BlockUser', self.Username, 'UserId=' .. Argument)
		elseif typeof(Argument) == 'Instance' and Argument:IsA'Player' then
			return self:BlockUser(tostring(Argument.UserId))
		elseif typeof(Argument) == 'number' then
			return self:BlockUser(tostring(Argument))
		end
	end
	function Account:UnblockUser(Argument)
		if typeof(Argument) == 'string' then
			return GET('UnblockUser', self.Username, 'UserId=' .. Argument)
		elseif typeof(Argument) == 'Instance' and Argument:IsA'Player' then
			return self:BlockUser(tostring(Argument.UserId))
		elseif typeof(Argument) == 'number' then
			return self:BlockUser(tostring(Argument))
		end
	end
	function Account:GetBlockedList() return GET('GetBlockedList', self.Username) end
	function Account:UnblockEveryone() return GET('UnblockEveryone', self.Username) end

	function Account:GetAlias() return GET('GetAlias', self.Username) end
	function Account:GetDescription() return GET('GetDescription', self.Username) end
	function Account:SetAlias(Alias) return POST('SetAlias', self.Username, Alias) end
	function Account:SetDescription(Description) return POST('SetDescription', self.Username, Description) end
	function Account:AppendDescription(Description) return POST('AppendDescription', self.Username, Description) end

	function Account:GetField(Field) return GET('GetField', self.Username, 'Field=' .. HttpService:UrlEncode(Field)) end
	function Account:SetField(Field, Value) return GET('SetField', self.Username, 'Field=' .. HttpService:UrlEncode(Field), 'Value=' .. HttpService:UrlEncode(tostring(Value))) end
	function Account:RemoveField(Field) return GET('RemoveField', self.Username, 'Field=' .. HttpService:UrlEncode(Field)) end

	function Account:SetServer(PlaceId, JobId) return GET('SetServer', self.Username, 'PlaceId=' .. PlaceId, 'JobId=' .. JobId) end
	function Account:SetRecommendedServer(PlaceId) return GET('SetServer', self.Username, 'PlaceId=' .. PlaceId) end

	function Account:ImportCookie(Token) return GET('ImportCookie', 'Cookie=' .. Token) end
	function Account:GetCookie() return GET('GetCookie', self.Username) end
	function Account:LaunchAccount(PlaceId, JobId, FollowUser, JoinVip) -- if you want to follow someone, PlaceId must be their user id
		return GET('LaunchAccount', self.Username, 'PlaceId=' .. PlaceId, JobId and ('JobId=' .. JobId), FollowUser and 'FollowUser=true', JoinVip and 'JoinVIP=true')
	end

	return Account, WebserverSettings
end

function BlockUtils()
	local Services = Services()
	local library = library()
	local AltManagerAPI = AltManagerAPI()
	local Players, GuiService, HttpService, StarterGui, VirtualInputManager, CoreGui = Services:Get('Players', 'GuiService', 'HttpService', 'StarterGui', 'VirtualInputManager', 'CoreGui');
	local LocalPlayer = Players.LocalPlayer;

	local BlockUtils = {};
	local IsFriendWith = LocalPlayer.IsFriendsWith;

	local apiAccount;

	task.spawn(function()
		apiAccount = AltManagerAPI.new(LocalPlayer.Name);
	end);

	local function isFriendWith(userId)
		local suc, data = pcall(IsFriendWith, LocalPlayer, userId);

		if (suc) then
			return data;
		end;

		return true;
	end;

	function BlockUtils:BlockUser(userId)
		if(library.flags.useAltManagerToBlock and apiAccount) then
			apiAccount:BlockUser(userId);

			local blockedListRetrieved, blockList = pcall(HttpService.JSONDecode, HttpService, apiAccount:GetBlockedList());
			if(blockedListRetrieved and typeof(blockList) == 'table' and blockList.success and blockList.total >= 20) then
				apiAccount:UnblockEveryone();
			end;
		else
			library.base.Enabled = false;

			local blockedUserIds = StarterGui:GetCore('GetBlockedUserIds');
			local playerToBlock = Instance.new('Player');
			playerToBlock.UserId = tonumber(userId);

			local lastList = #blockedUserIds;
			GuiService:ClearError();

			repeat
				StarterGui:SetCore('PromptBlockPlayer', playerToBlock);

				local confirmButton = CoreGui.RobloxGui.PromptDialog.ContainerFrame:FindFirstChild('ConfirmButton');
				if (not confirmButton) then break end;

				local btnPosition = confirmButton.AbsolutePosition + Vector2.new(40, 40);

				VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, false, game, 1);
				task.wait();
				VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, true, game, 1);
				task.wait();
			until #StarterGui:GetCore('GetBlockedUserIds') ~= lastList;

			task.wait(0.2);

			library.base.Enabled = true;
		end;
	end;

	function BlockUtils:UnblockUser()

	end;

	function BlockUtils:BlockRandomUser()
		for _, v in next, Players:GetPlayers() do
			if (v ~= LocalPlayer and not isFriendWith(v.UserId)) then
				self:BlockUser(v.UserId);
				break;
			end;
		end;
	end;

	return BlockUtils;
end

local library = library;

local ToastNotif = ToastNotif()
local TextLogger = TextLogger()
local EntityESP = EntityESP()
local ControlModule = ControlModule()

local createBaseESP = createBaseESP()
local toCamelCase = toCamelCase()
local prettyPrint = prettyPrint()
local findPlayer = findPlayer()
local getImageSize = getImageSize()

local Services = Services()
local Utility = Utility()
local Maid = Maid()
local BlockUtils = BlockUtils()

local column1, column2 = unpack(library.columns);

local disableenvprotection = disableenvprotection or function() end;
local enableenvprotection = enableenvprotection or function() end;

local Players, Lighting, RunService, UserInputService, ReplicatedStorage, CoreGui, NetworkClient = Services:Get(
	'Players',
	'Lighting',
	'RunService',
	'UserInputService',
	'ReplicatedStorage',
	'CoreGui',
	'NetworkClient'
);

local TeleportService, GuiService, CollectionService, HttpService, VirtualInputManager, MemStorageService, TweenService, StarterGui = Services:Get(
	'TeleportService',
	'GuiService',
	'CollectionService',
	'HttpService',
	'VirtualInputManager',
	'MemStorageService',
	'TweenService',
	'StarterGui'
);

local Heartbeat = RunService.Heartbeat;

local LocalPlayer = Players.LocalPlayer;
local Mouse = LocalPlayer:GetMouse();

local FindFirstChild = game.FindFirstChild;
local IsA = game.IsA;
local IsDescendantOf = game.IsDescendantOf;

local startMenu;
local ranSince = tick();

repeat
	startMenu = LocalPlayer and LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StartMenu');
	task.wait();
until startMenu or tick() - ranSince >= 10 or LocalPlayer.Character;

if(tick() - ranSince >= 10) then
	print('[Rogue Lineage Anti Bug] Timeout excedeed!');
	while true do
		TeleportService:Teleport(3016661674);
		task.wait(5);
	end;
else
	print('[Rogue Lineage Anti Bug] Timeout not excedeed!')
end;

local isGaia = game.PlaceId == 5208655184;
local spawnLocations = {};

local fly;
local wipe;
local noFog;
local noClip;
local maxZoom;
local respawn;
local infMana;
local antiFire;
local autoSell;
local spamClick;
local autoSmelt;
local speedHack;
local noInjuries;
local noClipXray;
local fullBright;
local instantLog;
local manaAdjust;
local autoPickup;
local setLocation;
local toggleMobEsp;
local toggleNpcEsp;
local toggleBagEsp;
local streamerMode;
local infiniteJump;
local clickDestroy;
local autoPickupBag;
local spellStacking;
local spectatePlayer;
local setOverlayUrl;
local showCollectorPickupUI;
local antiHystericus;
local removeKillBricks;
local toggleTrinketEsp;
local collectorAutoFarm;
local toggleIngredientsEsp;
local toggleSpellAdjust;
local toggleSpellAutoCast;
local buildAutoPotion;
local buildAutoCraft;
local manaViewer;
local manaHelper;
local disableAmbientColors;
local autoPickupIngredients;
local aaGunCounter;
local showManaOverlay;
local goToGround;
local pullToGround;
local attachToBack;
local noStun;
local showCastZone;
local temperatureLock;
local daysFarm;
local allowFood;
local serverHop;
local gachaBot;
local scroomBot;
local loadSound;
local satan;
local spellStack;
local spellCounter;

local Trinkets = {};
local spellValues = {};
local Ingredients = {"Acorn Light","Glow Scroom","Lava Flower","Canewood","Moss Plant","Freeleaf","Trote","Scroom","Zombie Scroom","Potato","Tellbloom","Polar Plant","Strange Tentacle","Vile Seed","Ice Jar","Dire Flower","Crown Flower","Bloodthorn","Periascroom","Orcher Leaf","Uncanny Tentacle","Creely","Desert Mist","Snow Scroom"};

local trinkets = {};
local ingredients = {};
local mobs = {};
local npcs = {};
local bags = {};
local queue = {};

local Bots;

do -- // Download Assets
	local assetsList = {'IllusionistJoin.mp3', 'IllusionistLeft.mp3', 'IllusionistSpectateEnd.mp3', 'IllusionistSpectateStart.mp3', 'ModeratorJoin.mp3', 'ModeratorLeft.mp3'};
	local assets = {};

	local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz' or 'https://aztupscripts.xyz';

	for i, v in next, assetsList do
		if(not isfile(string.format('Aztup Hub V3/%s', v))) then
			print('Downloading', v, '...');
			writefile(string.format('Aztup Hub V3/%s', v), game:HttpGet(string.format('%s/%s', apiEndpoint, v)));
		end;

		assets[v] = getsynasset(string.format('Aztup Hub V3/%s', v));
	end;

	function loadSound(soundName)
		local sound = Instance.new('Sound');
		sound.SoundId = assets[soundName];
		sound.Volume = 1;
		sound.Parent = game:GetService('CoreGui');

		sound:Play();

		task.delay(4, function()
			sound:Destroy();
		end);
	end;
end;

do -- // Mod Ban Analytics
	local disconnectedPlayers = {};
	local sentUserIds = false;

	local function onPlayerRemoving(plr)
		disconnectedPlayers[plr.UserId] = tick();
	end;

	GuiService.ErrorMessageChanged:Connect(function(msg)
		print(msg);

		if(string.find(msg, 'banned from the game') and not string.find(msg, 'Incident ID') and not sentUserIds) then
			print('[Moderator Detection] Sending report ...');

			sentUserIds = true;
			local userIds = {};

			for i, v in next, Players:GetPlayers() do
				if(not v:IsFriendsWith(LocalPlayer.UserId) and v.UserId ~= LocalPlayer.UserId) then
					table.insert(userIds, v.UserId);
				end;
			end;

			for userId, userLeftAt in next, disconnectedPlayers do
				if(tick() - userLeftAt <= 120) then
					table.insert(userIds, userId);
				else
					print(string.format('[Moderator Detection] Removed %s from the list', userId));
					userIds[userId] = nil;
				end;
			end;

			print(syn.request({
				Url = 'https://aztupscripts.xyz/api/v1/moderatorDetection',
				Method = 'POST',
				Headers = {
					['Content-Type'] = 'application/json',
					Authorization = websiteScriptKey
				},
				Body = HttpService:JSONEncode({
					userIds = userIds
				})
			}).Body)
		end;
	end);

	Players.PlayerRemoving:Connect(onPlayerRemoving);
end;

local function fromHex(str)
	return (str:gsub('..', function (cc)
		return string.char(tonumber(cc, 16));
	end));
end;

-- Y am I hardcoding this?

local cipherIV = fromHex('f25cbb355f61317ce02de60cb81168ea');
local cipherKey = fromHex('90cf0e772789b4a244076a352cce2fa3eb1a18898dc4612c14fbd033f3320b2c');

local chatLogger = TextLogger.new({
	title = 'Chat Logger',
	preset = 'chatLogger',
	buttons = {'Spectate', 'Copy Username', 'Copy User Id', 'Copy Text', 'Report User'}
});

do -- // Functions
	local tango;
	local fallDamage;
	local dodge;
	local manaCharge;
	local dialog;
	local dolorosa;
	local changeArea;

	local getTrinketType;
	local ingredientsFolder;

	local solveCaptcha;

	local isPrivateServer = ReplicatedStorage:FindFirstChild('ServerType') and ReplicatedStorage.ServerType.Value ~= 'Normal';

	-- LocalPlayer:Kick();
	-- game:GetService('GuiService'):ClearError();

	local collectorUI;
	local apiEndpoint = USE_INSECURE_ENDPOINT and 'http://test.aztupscripts.xyz/api/v1/' or 'https://aztupscripts.xyz/api/v1/';

	local moderatorIds = syn.request({
		Url = string.format('%smoderatorDetection', apiEndpoint),
		Headers = {['X-API-Key'] = websiteScriptKey}
	}).Body;

	moderatorIds = syn.crypto.custom.decrypt(
		'aes-cbc',
		syn.crypt.base64.encode(moderatorIds),
		cipherKey,
		cipherIV
	);

	local injuryObjects = {'Careless', 'PsychoInjury', 'MindWarp', 'NoControl', 'Maniacal', 'BrokenLeg', 'BrokenArm', 'VisionBlur'};

	local noclipBlocks = {};
	local killBricks = {};
	local trinketsData = {};
	local playerClassesList = {};
	local playerClasses = {};
	local remotes = {};
	local allMods = {};
	local illusionists = {};

	local autoCraftUtils = {};

	local trinketEspBase = createBaseESP('trinketEsp', trinkets);
	local ingredientEspBase = createBaseESP('ingredientEsp', ingredients);
	local mobEspBase = createBaseESP('mobEsp', mobs);
	local npcEspBase = createBaseESP('npcEsp', npcs);
	local bagEspBase = createBaseESP('bagEsp', bags);

	local moderatorInGame = false;
	local sprinting = false;
	local playerGotManualKick = false;

	local artefactOrderList;

	local findServer;
	local oldFireServer;

	local maid = Maid.new();

	local rayParams = RaycastParams.new();
	rayParams.FilterDescendantsInstances = {workspace.Live};
	rayParams.FilterType = Enum.RaycastFilterType.Blacklist;

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
		return ToastNotif.new({text = title .. ' - ' .. text})
	end;

	local function spawnLocalCharacter()
		if(not LocalPlayer.Character) then
			library.base.Enabled = false;

			local startMenu = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('StartMenu');
			local finish = startMenu.Choices.Play

			repeat
				local btnPosition = finish.AbsolutePosition + Vector2.new(40, 40);
				local overlay = finish.Parent and finish.Parent.Parent and finish.Parent.Parent:FindFirstChild('Overlay');
				if (not overlay) then task.wait(); continue end;

				VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, true, game, 1);
				task.wait();
				VirtualInputManager:SendMouseButtonEvent(btnPosition.X, btnPosition.Y, 0, false, game, 1);
				task.wait();
			until LocalPlayer.Character;

			library.base.Enabled = true;
		end;

		return LocalPlayer.Character;
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
					if(typeof(v) == 'function' and islclosure(v) and not is_synapse_function(v) and table.find(getconstants(v), 'plum')) then
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

		hookfunction(Instance.new('Part').BreakJoints,newcclosure(function() end));

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
			elseif(self == fallDamage and (library.flags.noFallDamage or library.flags.collectorAutoFarm) and not checkcaller()) then
				return warn('Fall Damage -> Attempt');
			elseif(self.Name == 'LeftClick') then
				if(library.flags.antiBackfire) then
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
				if(library.flags.antiBackfire) then
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
			elseif(self == changeArea and library.flags.temperatureLock) then
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

					if (library.flags.silentAim) then
						local target = Utility:getClosestCharacter(rayParams);
						target = target and target.Character;

						local cam = workspace.CurrentCamera;
						local worldToViewportPoint = cam.WorldToViewportPoint;
						local viewportPointToRay = cam.ViewportPointToRay;

						if (target and target.PrimaryPart) then
							local pos = worldToViewportPoint(cam, target.PrimaryPart.Position);

							mouseT.Hit = target.PrimaryPart.CFrame;
							mouseT.Target = target.PrimaryPart;
							mouseT.X = pos.X;
							mouseT.Y = pos.Y;
							mouseT.UnitRay = viewportPointToRay(cam, pos.X, pos.Y, 1)
							mouseT.Hit = target.PrimaryPart.CFrame;
						end;
					end;

					if library.flags.spellStack then
						--Wait until keypress?
						--Make it a table queue sort of thing that removes oldest first?
						print("HOLDING FIRE")
						local info = {currentTime = tick(), fired = false};
						table.insert(queue,info);

						spellCounter.Text = string.format('Spell Counter: %d', Utility:countTable(queue));
						repeat
							task.wait();
						until info.fired or tick()-info.currentTime >= 2;

						for i,v in next, queue do 
							if v.currentTime == info.currentTime then

								queue[i] = nil;
								break;
							end
						end

						table.foreach(queue,warn)

						spellCounter.Text = string.format('Spell Counter: %d', Utility:countTable(queue));
						warn("FIRING")
					end

					return mouseT;
				end;
			end)

		end;

		onCharacterAdded(LocalPlayer.Character);
		LocalPlayer.CharacterAdded:Connect(onCharacterAdded);

		local cachedRemotes = {};

		oldIndex = hookmetamethod(game, '__index', function(self, p)
			SX_VM_CNONE();
			if(not tango) then
				return oldIndex(self, p);
			end;

			-- if(string.find(debug.traceback(), 'KeyHandler')) then
			--     warn('kay handler call __index', self, p);
			-- end;

			if(p == 'MouseButton1Click' and IsA(self, 'GuiButton') and library.flags.autoBard) then
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
			SX_VM_CNONE();
			-- local Character = oldIndex(LocalPlayer, 'Character');
			-- local CharacterHandler = Character and FindFirstChild(Character, 'CharacterHandler') or self;

			-- if(string.find(debug.traceback(), 'KeyHandler')) then
			-- warn('kay handler call __newindex', self, p, v);
			-- end;

			if(p == 'Parent' and IsA(self, 'Script') and oldIndex(self, 'Name') == 'CharacterHandler' and IsDescendantOf(self, LocalPlayer.Character)) then
				return warn('Ban Attempt -> Character Nil');
			elseif(tango and not checkcaller()) then -- // stuff that only triggers once ac is bypassed
				if(p == 'WalkSpeed' and IsA(self, 'Humanoid') and library.flags.speedHack) then
					return;
				elseif((p == 'Ambient' or p == 'Brightness') and self == Lighting and library.flags.fullbright) then
					return;
				elseif((p == 'FogEnd' or p == 'FogStart') and self == Lighting and library.flags.noFog) then
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
			SX_VM_CNONE();
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
			maid.charChildRemovedMana = character.ChildRemoved:Connect(function(obj)
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

	do -- // Chat Logger
		local function containBlacklistedWord(text)
			text = string.lower(text);
			local blacklistedWords = {'cheater', 'hacker', 'exploiter', 'hack', 'cheat', 'exploit', 'report', string.lower(LocalPlayer.Name)}
			for i, v in next, blacklistedWords do
				if(string.find(text, v)) then
					return true;
				end;
			end;

			return false;
		end;

		local function addText(player, ignName, message)
			local time = os.date('%H:%M:%S')
			local prefixBase = string.format('[%s] [%s] - %s', time, ignName or 'Unknwon', message);
			local prefixHover = string.format('[%s] [%s] - %s', time, player == LocalPlayer and 'You' or player.Name, message);
			local color = Color3.fromRGB(255, 255, 255);

			local originalText = string.format('[%s] [%s] [%s] %s', time, player.Name, ignName, message); -- Better version for report system

			if(illusionists[player]) then
				color = Color3.fromRGB(230, 126, 34);
			end;

			if(allMods[player] or not player.Character or containBlacklistedWord(message)) then
				color = Color3.fromRGB(231, 76, 60);

				if(not player.Character) then
					prefixBase = '[Not Spawned In] ' .. prefixBase;
					prefixHover = '[Not Spawned In] ' .. prefixHover;
				end;
			end;

			local textObject = chatLogger:AddText({
				color = color,
				player = player,
				text = prefixBase,
				originalText = originalText, -- Used for report system cause Rogue is special with mouseenter and mouseleave
			});

			textObject.OnMouseEnter:Connect(function()
				textObject:SetText(prefixHover);
			end);

			textObject.OnMouseLeave:Connect(function()
				textObject:SetText(prefixBase);
			end);
		end;

		chatLogger.OnPlayerChatted:Connect(function(player, message)
			if (not player or not message) then return end;

			local firstName, lastName = getPlayerStats(player);
			local playerFullName = firstName .. (lastName ~= "" and " " .. lastName or "");

			addText(player, playerFullName, message);
		end);
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
				overlapParams.FilterType = Enum.RaycastFilterType.Whitelist;
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

	do -- // Collector Auto Farm
		local collectorData;

		local function getCollectorDoors()
			local doors = {};

			for i, v in next, workspace:GetChildren() do
				if(v.Name == 'Part' and v:FindFirstChild('Exit')) then
					table.insert(doors, v);
				end;
			end;

			return doors;
		end;

		local function getCollectorDoor(collector)
			local lastDoor, lastDistance = nil, math.huge;

			for i, v in next, getCollectorDoors() do
				if((v.Position - collector.PrimaryPart.Position).Magnitude < lastDistance) then
					lastDistance = (v.Position - collector.PrimaryPart.Position).Magnitude;
					lastDoor = v;
				end;
			end;

			return lastDoor;
		end;

		local buttons = {};

		local dragging = false;
		local draggingBtn;
		local frame;

		local success, savedOrderData = pcall(readfile, 'Aztup Hub V3/RogueLineageCollectorBotList.json');

		if(success) then
			success, savedOrderData = pcall(function()
				return HttpService:JSONDecode(savedOrderData);
			end);
		end;

		artefactOrderList = success and savedOrderData or {
			'Azael Horn',
			'Staff of Pain',
			'Mask of Baima',
			'Phoenix Bloom',
			'Pocket Watch',
			'Heirloom',
			'Dienis Locket',
			'Unwavering Focus'
		};

		local function createComponent(c, p)
			local obj = Instance.new(c)
			obj.Name = tostring({}):gsub("table: ", ""):gsub("0x", "")
			for i, v in next, p do
				if i ~= "Parent" then
					if typeof(v) == "Instance" then
						v.Parent = obj
					else
						obj[i] = v
					end
				end
			end
			obj.Parent = p.Parent
			return obj
		end;

		do -- // render button
			collectorUI = createComponent('ScreenGui', {
				Parent = CoreGui,
				Enabled = false,
			});

			frame = createComponent('Frame', { -- // main frame
				Parent = collectorUI,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.9, 0, 0.5, 0),
				Size = UDim2.new(0, 300, 0, 350),
				BackgroundColor3 = Color3.fromRGB(42, 42, 42),

				createComponent('UICorner', {
					CornerRadius = UDim.new(0, 8)
				}),

				createComponent('Frame', { -- // border
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(1, 5, 1, 5),
					BackgroundColor3 = Color3.fromRGB(0, 0, 0),
					ZIndex = 0,

					createComponent('UICorner', {
						CornerRadius = UDim.new(0, 8)
					})
				}),

				createComponent('TextLabel', { -- // title
					Font = Enum.Font.Garamond,
					Text = 'Aztup Hub V3 Collector Auto Farm Order List',
					TextSize = 25,
					TextWrapped = true,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextStrokeTransparency = 0.85,
					Size = UDim2.new(1, 0, 0, 55),
					TextStrokeColor3 = Color3.fromRGB(0, 0, 0),

					createComponent('Frame', {
						BackgroundColor3 = Color3.fromRGB(2, 255, 137),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 2),
						Position = UDim2.new(0, 0, 1, 0)
					})
				})
			})
		end;

		local function positionButtons()
			for i,v in next, buttons do
				v.Size = UDim2.new(1, 0, 0, 25);
				v.LayoutOrder = i;
				v.Position = UDim2.new(0.5, 0, 0, 80 + (i - 1) * 25);
			end;
		end;

		local function dragger(container)
			local dragging;
			local dragInput;
			local dragStart;
			local startPos;

			local function update(input)
				local delta = input.Position - dragStart
				container.Position = UDim2.new(
					0.5,
					0,
					startPos.Y.Scale,
					math.clamp(startPos.Y.Offset + delta.Y, 80, frame.AbsoluteSize.Y - 20)
				);
			end

			container.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					dragging = true
					dragStart = input.Position
					startPos = container.Position

					input.Changed:Connect(function()
						if (input.UserInputState == Enum.UserInputState.End) then
							dragging = false
							positionButtons();
						end
					end)
				end
			end)

			container.InputChanged:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					dragInput = input
				end
			end)

			UserInputService.InputChanged:Connect(function(input)
				if input == dragInput and dragging then
					update(input)
				end
			end)
		end;

		local function update(btn)
			if(not dragging) then
				draggingBtn, dragging = btn, true;
				btn.ZIndex = 999;

				repeat
					task.wait();
				until not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1);

				positionButtons();
				dragging, draggingBtn = false, nil;
				btn.ZIndex = 1;
			end;
		end;

		local function renderBtn()
			for i, v in next, artefactOrderList do
				local button = createComponent('TextButton', {
					Parent = frame,
					Active = true,
					Text = v,
					BackgroundTransparency = 1,
					TextColor3 = Color3.fromRGB(255, 255, 255),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Font = Enum.Font.Garamond,
					AutoButtonColor = false,
					TextScaled = true
				});

				table.insert(buttons, button);
				dragger(button);
			end;

			positionButtons();
		end;

		renderBtn();

		local tweenInfo = TweenInfo.new(0.2);

		do -- // Buttons Render
			for i, v in next, buttons do
				local tweenIn = TweenService:Create(v, tweenInfo, {TextColor3 = Color3.fromRGB(176, 176, 176)});
				local tweenOut = TweenService:Create(v, tweenInfo, {TextColor3 = Color3.fromRGB(255, 255, 255)});

				v.MouseButton1Down:Connect(function()
					update(v);
				end);

				v.MouseEnter:Connect(function()
					tweenIn:Play();
					if(dragging and v ~= draggingBtn) then
						local oldLayout = v.LayoutOrder;

						v.LayoutOrder = draggingBtn.LayoutOrder;
						draggingBtn.LayoutOrder = oldLayout;

						table.sort(buttons, function(a, b)
							return a.LayoutOrder < b.LayoutOrder;
						end);

						positionButtons();
					end;
				end);

				v.MouseLeave:Connect(function()
					tweenOut:Play();
				end);
			end;
		end;

		task.spawn(function()
			while true do
				local newOrderList = {};

				for i, v in next, buttons do
					newOrderList[i] = v.Text;
				end;

				artefactOrderList = newOrderList;

				writefile('Aztup Hub V3/RogueLineageCollectorBotList.json', HttpService:JSONEncode(newOrderList));
				task.wait(1);
			end;
		end);

		local function getBestChoice(choices)
			local order = artefactOrderList;
			local foundChoice, foundChoicePosition = nil, 9999;

			for i, v in next, choices do
				for i2, v2 in next, order do
					if(v2 == v and i2 <= foundChoicePosition) then
						foundChoicePosition = i2;
						foundChoice = v2;
					end;
				end;
			end;

			return foundChoice;
		end;

		local function isDangerousPlayer(v)
			return v:FindFirstChild('Pebble') or v:FindFirstChild('Dagger Throw') or v:FindFirstChild('Autumn Rain') or v:FindFirstChild('Shadow Fan') or v:FindFirstChild('Triple Dagger Throw') or v:FindFirstChild('Justice Spears') or v:FindFirstChild('Augimas') or v:FindFirstChild('Perflora');
		end;

		function showCollectorPickupUI(toggle)
			collectorUI.Enabled = toggle;
		end;

		function collectorAutoFarm(toggle)
			if(not toggle or isPrivateServer or isGaia) then
				return;
			end;

			local function onConnectionLost()
				if (playerGotManualKick) then return end;

				while true do
					if (library.flags.automaticallyRejoin) then
						print('[Automatic Rejoin] Player got disconneted');
						findServer();
					end;

					task.wait(10);
				end;
			end;

			if (not NetworkClient:FindFirstChild('ClientReplicator')) then
				return onConnectionLost();
			else
				NetworkClient.ChildRemoved:Connect(onConnectionLost);
			end;

			task.wait(2.5);

			local live = workspace:WaitForChild('Live');
			if (moderatorInGame) then return findServer() end;

			local function runPanicCheck(playerPosition)
				if (moderatorInGame) then
					findServer();
					return task.wait(9e9);
				end;

				local entities = live:GetChildren();

				for i, v in next, Players:GetPlayers() do
					local character = v.Character;
					if (character and not table.find(entities, character)) then
						table.insert(entities, character);
					end;
				end;

				for i, v in next, entities do
					local playerRootPart = v:FindFirstChild('HumanoidRootPart');
					if(not playerRootPart or v.Name == LocalPlayer.Name) then continue end;

					local dangerousPlayer = isDangerousPlayer(v);
					local playerDistance = (Utility:roundVector(playerRootPart.Position) - Utility:roundVector(playerPosition)).Magnitude;
					local maxPlayerDistance = dangerousPlayer and math.huge or 300;

					if(playerDistance <= maxPlayerDistance) then
						print('Entity too close panicking', (playerRootPart.Position - playerPosition).Magnitude, v.Name, dangerousPlayer);
						findServer();
						return task.wait(9e9);
					end;
				end;
			end;

			if(MemStorageService:HasItem('lastPlayerPosition')) then
				local playerPosition = Vector3.new(unpack(MemStorageService:GetItem('lastPlayerPosition'):split(',')));
				print('Last player position', playerPosition);

				runPanicCheck(playerPosition);
			else
				print('No last player position saving current one');
			end;

			local character = spawnLocalCharacter();

			LocalPlayer.CharacterAdded:Connect(function(newCharacter)
				kickPlayer('You were killed, please DM Aztup and sent him a clip if you have any, dont do that if you just pressed the menu button');
				task.wait(1);

				while true do end;
			end);

			local dangerConnection;
			dangerConnection = character.ChildAdded:Connect(function(obj)
				if (obj.Name == 'Danger') then
					if (library.base.Enabled) then
						library:Close();
					end;

					ToastNotif:DestroyAll();
					library.options.chatLogger:SetState(false);
				end;
			end);

			task.wait(0.1);

			if(not MemStorageService:HasItem('collectorLocationTP')) then
				MemStorageService:SetItem('collectorLocationTP', math.random(1, 2) == 1 and '20' or '-20');
			end;

			local rootPart = character and character:WaitForChild('HumanoidRootPart', 10);
			local humanoid = character and character:WaitForChild('Humanoid', 10);

			if (not rootPart or not humanoid) then
				findServer();
				return;
			end;

			local lastNotificationSentAt = 0;

			repeat
				--print('[Collector Auto Farm] Waiting for collector to be grabbed ...');
				local lastDistance = math.huge;

				for i, v in next, workspace.NPCs:GetChildren() do
					if(v.Name == 'Collector' and (v.PrimaryPart.Position - rootPart.Position).Magnitude <= 500) then
						lastDistance = (v.PrimaryPart.Position - rootPart.Position).Magnitude;
						collectorData = {door = getCollectorDoor(v), collector = v, distance = lastDistance};
						break;
					end;
				end;

				if(not collectorData and tick() - lastNotificationSentAt > 1) then
					lastNotificationSentAt = tick();
					ToastNotif.new({
						text = 'You must be at the collector',
						duration = 1
					});
				end;

				if(not library.flags.collectorAutoFarm) then return end;
				task.wait();
			until collectorData;

			local collectorRoot = collectorData.collector:WaitForChild('HumanoidRootPart', 10);
			if (not collectorRoot) then
				return findServer();
			end;

			local params = RaycastParams.new();
			params.FilterType = Enum.RaycastFilterType.Whitelist;
			params.FilterDescendantsInstances = getCollectorDoors();

			runPanicCheck(rootPart.Position);
			MemStorageService:SetItem('lastPlayerPosition', tostring(rootPart.Position));

			local ranSince = tick();

			local function isDoorHere()
				local rayResult = workspace:Raycast(collectorRoot.Position + Vector3.new(0, 5, 0), collectorRoot.CFrame.LookVector * 250, params);
				local instance = rayResult and rayResult.Instance;

				if (not instance) then
					return false;
				elseif(not instance.CanCollide) then
					return false;
				end;

				return true;
			end;

			if (library.flags.rollOutOfFf) then
				local lastCFrame = rootPart.CFrame;
				local lastPosition = lastCFrame.Position;
				local lastDodgeAt = tick();

				repeat
					if (tick() - lastDodgeAt > 1) then
						lastDodgeAt = tick();
						VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Q, false, game);
					end;
					task.wait();
				until rootPart:FindFirstChild('DodgeVel');

				task.wait(0.2);
				repeat task.wait() until not rootPart:FindFirstChild('DodgeVel');

				warn('dash finished ?!');
				task.wait(0.2 + math.random() * 1);

				local moveToFinished = false;

				task.spawn(function()
					while (not moveToFinished) do
						humanoid:MoveTo(lastPosition);
						task.wait(1);
					end;
				end);

				humanoid.MoveToFinished:Wait();
				moveToFinished = true;
			end;

			repeat -- // Wait for collector door to show ?
				local inDanger = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger');

				if(not rootPart.Parent and not inDanger) then
					kickPlayer('You died, disconecting to prevent losing lives');
					return;
				end;

				runPanicCheck(rootPart.Position);

				if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('ForceField') and not library.flags.rollOutOfFf) then
					LocalPlayer.Character:FindFirstChildWhichIsA('ForceField'):Destroy();
				end;

				task.wait();
			until not isDoorHere() or tick() - ranSince >= library.flags.collectorBotWaitTime;

			if(isDoorHere()) then
				while true do
					if(LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger')) then
						ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
						findServer();

						task.wait(5);
					end;

					task.wait();
				end;
			end;

			dangerConnection:Disconnect();
			dangerConnection = nil;

			local artifactPickedUp;
			local choices;

			local function handleDialog(data)
				task.wait(1);

				if(data.choices) then
					print('[Collector Auto Farm] Picking Up Artifact');

					local artefactChoice = getBestChoice(data.choices);

					artifactPickedUp = artefactChoice;
					choices = data.choices;

					dialog:FireServer({choice = artefactChoice});
				else
					print('[Collector Bot] Exited!');
					dialog:FireServer({exit = true});
					task.wait(2);

					repeat
						task.wait();
					until LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger');

					if(artifactPickedUp) then
						kickPlayer('You got a ' .. artifactPickedUp);

						task.spawn(function()
							pcall(function()
								syn.request({
									Url = '',
									Method = 'POST',
									Headers = {
										['Content-Type'] = 'application/json'
									},

									Body = HttpService:JSONEncode({
										content = 'Collector Bot',
										embeds = {{
											timestamp = DateTime.now():ToIsoDate(),
											title = 'Collector has been collected :tada:',
											color = 1345023,
											fields = {
												{
													name = 'Artifact Chosen',
													value = artifactPickedUp,
												},
												{
													name = 'Options',
													value = '['.. table.concat(choices or {'DM', 'Aztup'}, ', ') .. ']',
												},
											}
										}}
									})
								});
							end);
						end);

						task.spawn(function()
							syn.request({
								Url = library.flags.webhookUrl,
								Method = 'POST',
								Headers = {
									['Content-Type'] = 'application/json'
								},

								Body = HttpService:JSONEncode({
									content = '@everyone',
									embeds = {{
										timestamp = DateTime.now():ToIsoDate(),
										title = 'Collector has been collected :tada:',
										color = 1345023,
										fields = {
											{
												name = 'Artifact Chosen',
												value = artifactPickedUp,
											},
											{
												name = 'Username',
												value = LocalPlayer.Name,
											},
											{
												name = 'Options',
												value = '['.. table.concat(choices or {'DM', 'Aztup'}, ', ') .. ']',
											}
										}
									}}
								})
							});
						end);

						artifactPickedUp = nil;
					else
						ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
						task.wait(2);
						return findServer();
					end;
				end;
			end;

			dialog.OnClientEvent:Connect(handleDialog);
			task.wait(2.5);

			rootPart.CFrame = collectorRoot.CFrame:ToWorldSpace(CFrame.new(0, 0, -5));
			workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, workspace.CurrentCamera.CFrame.Position + collectorRoot.Position);

			print('[Collector Auto Farm] Collector is ready!');

			if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Immortal')) then
				LocalPlayer.Character.Immortal:Destroy();
			end;

			local function toggleGUI(state)
				local playerGui = LocalPlayer and LocalPlayer:FindFirstChild('PlayerGui');
				if(playerGui) then
					for i, v in next, playerGui:GetChildren() do
						if(v:IsA('ScreenGui') and v.Name ~= 'DialogueGui' and v.Name ~= 'Captcha' and v.Name ~= 'CaptchaLoading') then
							v.Enabled = false;
						end;
					end;
				end;

				for i, v in next, game:GetService('CoreGui'):GetChildren() do
					if(v:IsA('ScreenGui')) then
						v.Enabled = state;
					end;
				end;

				library.base.Enabled = state;
			end;

			toggleGUI(false);

			local elapsedTime = tick();

			repeat
				print('Clicking Click Detector Distance', (rootPart.Position - collectorRoot.Position).Magnitude);

				workspace.CurrentCamera.CameraSubject = collectorRoot;

				local pos = workspace.CurrentCamera:WorldToViewportPoint(collectorRoot.Position);

				VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 1)
				task.wait();
				VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 1)

				task.wait(0.25);
			until LocalPlayer.PlayerGui:FindFirstChild('CaptchaLoad') or tick() - elapsedTime >= 8;
			-- // No need to add anything else since the auto dialog will serverhop as soon as collector gives exit

			if (tick() - elapsedTime >= 5) then
				ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
				task.wait(2);
				return findServer();
			end;

			repeat
				task.wait();
			until LocalPlayer.PlayerGui:FindFirstChild('Captcha');

			local lastWebhookSentAt = 0;
			local lastWebhookSentAt2 = 0;
			local lastWebhookSentAt3 = 0;

			repeat
				local captchaGUI = LocalPlayer.PlayerGui:FindFirstChild('Captcha');
				local choices = captchaGUI and captchaGUI:FindFirstChild('MainFrame') and captchaGUI.MainFrame:FindFirstChild('Options');
				choices = choices and choices:GetChildren();
				local union = captchaGUI and captchaGUI:FindFirstChild('MainFrame') and captchaGUI.MainFrame:FindFirstChild('Viewport') and captchaGUI.MainFrame.Viewport:FindFirstChild('Union');

				if(choices and union) then
					local captchaAnswer = solveCaptcha(union);
					if(tick() - lastWebhookSentAt > 0.1) then
						lastWebhookSentAt = tick();
					end;

					for i, v in next, choices do
						if(v.Name == captchaAnswer) then
							if(tick() - lastWebhookSentAt2 > 0.1) then
								lastWebhookSentAt2 = tick();
							end;

							local position = v.AbsolutePosition + Vector2.new(40, 40);
							VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1);
							task.wait();
							VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1);

							break;
						end;
					end;
				else
					if(tick() - lastWebhookSentAt3 > 0.1) then
						lastWebhookSentAt3 = tick();
					end;
				end;

				task.wait();
			until not LocalPlayer.PlayerGui:FindFirstChild('Captcha');

			if(LocalPlayer.PlayerGui:FindFirstChild('CaptchaDisclaimer')) then
				task.wait(5);
			end;
		end;
	end;

	do -- // Set Trinkets
		Trinkets = {
			{
				["MeshId"] = "5204003946";
				["Name"] = "Goblet";
			};
			{
				["MeshId"] = "5196776695";
				["Name"] = "Ring";
			};
			{
				["MeshId"] = "5196782997";
				["Name"] = "Old Ring";
			};
			{
				["Name"] = "Emerald";
			};
			{
				["Name"] = "Ruby";
			};
			{
				["Name"] = "Sapphire";
			};
			{
				["Name"] = "Diamond";
			};
			{
				["Name"] = "Rift Gem";
				["Rare"] = true;
			};
			{
				["Name"] = "Fairfrozen";
				["Rare"] = true;
			};
			{
				["MeshId"] = "5204453430";
				["Name"] = "Ninja Scroll";
			};
			{
				["Name"] = "Old Amulet";
				["MeshId"] = "5196577540";
			};
			{
				["Name"] = "Amulet";
				["MeshId"] = "5196551436";
			};
			{
				["Name"] = "Idol Of The Forgotten";
				["ParticleEmitter"] = true;
			};
			{
				["Name"] = "Opal";
				["VertexColor"] = Vector3.new(1, 1, 1);
				["MeshType"] = "Sphere";
			},
			{
				Name = "Candy";
				MeshId = '4103271893'
			},
			{
				["Texture"] = "20443483";
				["Name"] = "Ya'alda";
				["Rare"] = true;
			};
			{
				["Texture"] = "1536547385";
				["Name"] = "Pheonix Down";
				["Rare"] = true;
			};
			{
				["Texture"] = "20443483";
				["ParticleEmitter"] = true;
				["PointLight"] = true;
				["Name"] = "Ice Essence";
				["Rare"] = true;
			};
			{
				["Name"] = "White King's Amulet";
				["Rare"] = true;
			};
			{
				["Name"] = "Lannis Amulet";
				["Rare"] = true;
			};
			{
				["Name"] = "Night Stone";
				["Rare"] = true;
			};
			{
				["Name"] = "Philosopher's Stone";
				["Rare"] = true;
			};
			{
				["Name"] = "Spider Cloak";
				["Rare"] = true;
			};
			{
				["Name"] = "Howler Friend";
				["Rare"] = true;
				["MeshId"] = "2520762076";
			};
			{
				["Name"] = "Scroom Key";
				["Rare"] = true;
			},
			{
				Name = 'Mysterious Artifact',
				Rare = true
			}
		};

		for i, v in next, Trinkets do
			trinketsData[v.Name] = v;
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

	do -- // Server Hop
		local serverInfo = not isGaia and ReplicatedStorage:WaitForChild('ServerInfo'):GetChildren() or {};

		do -- // Server Hop Khei
			if(not isGaia and not isPrivateServer) then
				repeat
					serverInfo = ReplicatedStorage:WaitForChild('ServerInfo'):GetChildren();
					task.wait();
				until #serverInfo >= 2;
			end;
		end;

		function findServer(bypassKhei)
			if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
				repeat
					task.wait();
				until not LocalPlayer.Character:FindFirstChild('Danger');
			end;

			task.delay(5, function()
				if (not NetworkClient:FindFirstChild('ClientReplicator') and library.flags.automaticallyRejoin) then
					TeleportService:Teleport(3016661674);
				else
					findServer(bypassKhei);
				end;
			end);

			if(not isGaia and not bypassKhei) then
				print('[Server Hop] Finding server ...');

				if(LocalPlayer.Character) then
					ReplicatedStorage.Requests.ReturnToMenu:InvokeServer();
					task.wait(2);
				end;

				local chosenServer = serverInfo[Random.new():NextInteger(1, #serverInfo)];
				local teleportHandler;

				teleportHandler = LocalPlayer.OnTeleport:Connect(function(state)
					if(state == Enum.TeleportState.Failed) then
						print('[Server Hop] Teleport failed');

						teleportHandler:Disconnect();
						teleportHandler = nil;

						findServer();
					end;
				end);

				print('Going to', chosenServer.Name);
				ReplicatedStorage.Requests.JoinPublicServer:FireServer(chosenServer.Name);
			else
				BlockUtils:BlockRandomUser();
				TeleportService:Teleport(3016661674);
			end;
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

	do -- // Mana Helper
		local manaHelperRows = {};

		local manaTextGui = library:Create('ScreenGui', {
			Enabled = true,
		});

		local manaText = library:Create('TextLabel', {
			Parent = manaTextGui,
			BackgroundTransparency = 1,
			Text = '0 %',
			Visible = false,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.new(0, 1, 0, 1),
		});

		local manaHelperGUI = library:Create('ScreenGui', {
			Enabled = false,
		});

		local castZoneGui = library:Create('ScreenGui', {
			Enabled = false
		});

		local snapCastValue = library:Create('Frame', {
			Parent = castZoneGui,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(52, 152, 219),
		});

		local normalCastValue = library:Create('Frame', {
			Parent = castZoneGui,
			BackgroundTransparency = 0.5,
			BorderSizePixel = 0,
			BackgroundColor3 = Color3.fromRGB(231, 76, 60),
		});

		for i = 0, 10 do
			local container = Instance.new('Frame');
			container.Parent = manaHelperGUI;
			container.BorderSizePixel = 0;
			container.Size = UDim2.new(0, 28, 0, 2);
			container.BackgroundColor3 = Color3.fromRGB(255, 0, 4);

			local text = Instance.new('TextLabel');
			text.Size = UDim2.new(1, 0, 1, 0);
			text.TextColor3 = Color3.fromRGB(255, 255, 255);
			text.Parent = container;
			text.Position = UDim2.new(0, 50, 0, 0);
			text.BackgroundTransparency = 1;
			text.TextStrokeTransparency = 0;
			text.Text = string.format('%d %%', i * 10)

			if(i == 0 or i == 10) then
				container.Parent = nil
			end;

			table.insert(manaHelperRows, container);
		end;

		if(gethui) then
			manaTextGui.Parent = gethui();
			manaHelperGUI.Parent = gethui();
			castZoneGui.Parent = gethui();
		else
			syn.protect_gui(manaTextGui);
			manaTextGui.Parent = CoreGui;

			syn.protect_gui(manaHelperGUI);
			manaHelperGUI.Parent = CoreGui;

			syn.protect_gui(castZoneGui);
			castZoneGui.Parent = CoreGui;
		end;

		local manaOverlay = Drawing.new('Image');
		manaOverlay.Visible = false;

		function showCastZone(toggle)
			castZoneGui.Enabled = toggle;
			if(not toggle) then
				maid.showCastZone = nil;
				return;
			end;

			local function hideCastZones()
				normalCastValue.Visible = false;
				snapCastValue.Visible = false;
			end

			maid.showCastZone = RunService.RenderStepped:Connect(function()
				local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
				if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return hideCastZones() end;

				local manaGui = playerGui.StatGui.LeftContainer.Mana;

				local tool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
				if(not tool) then return hideCastZones() end;

				local values = spellValues[tool.Name];
				if(not values) then return hideCastZones() end;

				local hasSnap = values[2];

				if(hasSnap) then
					local min, max = values[2].min, values[2].max;

					snapCastValue.Visible = true;
					snapCastValue.Size = UDim2.new(0, manaGui.AbsoluteSize.X, 0, manaGui.AbsoluteSize.Y * (max - min) / 100);
					snapCastValue.Position = UDim2.new(0, manaGui.AbsolutePosition.X, 0, manaGui.AbsolutePosition.Y) + UDim2.new(0, 0, 0, manaGui.AbsoluteSize.Y - manaGui.AbsoluteSize.Y * max  / 100);
				else
					snapCastValue.Visible = false;
				end;

				local min, max = values[1].min, values[1].max;

				normalCastValue.Visible = true;
				normalCastValue.Size = UDim2.new(0, manaGui.AbsoluteSize.X, 0, manaGui.AbsoluteSize.Y * (max - min) / 100);
				normalCastValue.Position = UDim2.new(0, manaGui.AbsolutePosition.X, 0, manaGui.AbsolutePosition.Y) + UDim2.new(0, 0, 0, manaGui.AbsoluteSize.Y - manaGui.AbsoluteSize.Y * max  / 100);
			end);

		end;

		function manaViewer(toggle)
			manaText.Visible = toggle;
			if(not toggle) then
				maid.manaViewer = nil;
				return;
			end;

			maid.manaViewer = RunService.RenderStepped:Connect(function()
				local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
				if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return end;

				local manaGui = playerGui.StatGui.LeftContainer.Mana;

				local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
				if(not mana) then return end;

				manaText.Position = UDim2.new(0, manaGui.AbsolutePosition.X + 14, -0.020, manaGui.AbsolutePosition.Y);
				manaText.Text = string.format('%d %%', mana.Value)
			end);
		end;

		function manaHelper(toggle)
			manaHelperGUI.Enabled = toggle;
			if(not toggle) then
				maid.manaHelper = nil;
			end;

			maid.manaHelper = RunService.RenderStepped:Connect(function()
				local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
				if(not playerGui or not playerGui:FindFirstChild('StatGui') or not playerGui.StatGui:FindFirstChild('LeftContainer')) then return end;


				local mana = playerGui.StatGui.LeftContainer.Mana;
				local size = (mana.AbsoluteSize.Y);
				local position = (mana.AbsolutePosition).Y;
				local rowSize = size / 10;

				for i, v in next, manaHelperRows do
					v.Position = UDim2.new(0, mana.AbsolutePosition.X, 0, position + size - rowSize * (i - 1));
				end;
			end);
		end;

		function showManaOverlay(toggle)
			manaOverlay.Visible = toggle;

			if(not toggle) then
				maid.manaOverlay = nil;
				return;
			end;

			maid.manaOverlay = RunService.RenderStepped:Connect(function()
				local playerGui = LocalPlayer:FindFirstChild('PlayerGui');
				if(not playerGui or not playerGui:FindFirstChild('StatGui')) then return end;

				local mana = playerGui.StatGui.LeftContainer.Mana;

				manaOverlay.Size = Vector2.new(library.flags.overlayScaleX, library.flags.overlayScaleY)
				manaOverlay.Position = mana.AbsolutePosition - Vector2.new(library.flags.overlayOffsetX, library.flags.overlayOffsetY);
			end);
		end;

		function spellStack(t)
			if not t then maid.spellStack = nil; table.clear(queue); return; end

			maid.spellStack = UserInputService.InputBegan:Connect(function(input,gameProcessed)
				if (input.KeyCode ~= Enum.KeyCode[library.options.spellStackKeybind.key] or gameProcessed) then return end;

				local youngest = tick();
				local found;
				for i,v in next, queue do 
					if v.currentTime > youngest or v.fired then continue; end

					found = i;
					youngest = v.currentTime;
				end

				queue[found].fired = true;
			end)
		end

		function setOverlayUrl(url, enter)
			local suc, requestData = pcall(syn.request, {Url = url})
			local imgData = suc and requestData.Body;
			if (not suc) then return end;

			local imgSize = getImageSize(imgData);

			manaOverlay.Data = imgData;

			if (enter) then
				manaOverlay.Size = imgSize;
				library.options.overlayScaleX:SetValue(imgSize.X);
				library.options.overlayScaleY:SetValue(imgSize.Y);
			end;
		end;
	end;

	do -- // AA Gun Counter
		local aaGunCounterGUI = library:Create('ScreenGui', {
			Enabled = false;
		});

		if(gethui) then
			aaGunCounterGUI.Parent = gethui();
		else
			syn.protect_gui(aaGunCounterGUI);
			aaGunCounterGUI.Parent = CoreGui;
		end;

		local aaGunCounterText = library:Create('TextLabel', {
			Parent = aaGunCounterGUI,
			RichText = true,
			TextSize = 25,
			Text = '',
			BackgroundTransparency = 1,
			Position = UDim2.new(0.5, 0, 0, 50),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.new(0, 200, 0, 50),
			Font = Enum.Font.SourceSansSemibold,
			TextColor3 = Color3.fromRGB(255, 255, 255)
		});

		local params = RaycastParams.new();
		params.FilterType = Enum.RaycastFilterType.Blacklist;
		params.FilterDescendantsInstances = {workspace.Live, workspace:FindFirstChild('NPCs') or Instance.new('Folder'), workspace:FindFirstChild('AreaMarkers') or Instance.new('Folder')};

		local flying        = false;
		local lastFly       = tick();
		local onGroundAt    = tick();
		local flyStartedAt  = lastFly;

		function aaGunCounter(toggle)
			aaGunCounterGUI.Enabled = toggle;

			if(not toggle) then
				maid.aaGunCounter = nil;
				return;
			end;

			maid.aaGunCounter = RunService.RenderStepped:Connect(function()
				local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
				if(not rootPart) then return end;

				local isOnGround = workspace:Raycast(rootPart.Position, Vector3.new(0, -10, 0), params)
				if(not isOnGround) then
					if(not flying) then
						flyStartedAt = tick();
					end;
					flying = true;
					lastFly = tick();
				else
					if(flying) then
						onGroundAt = tick();
					end;
					flying = false;
				end;

				local timeSinceLastFly = tick() - flyStartedAt;
				local timeOnGround = tick() - onGroundAt;
				local shouldFly = (timeOnGround >= 6 and (flying and timeSinceLastFly < 5 or not flying and true));

				local red, green = 'rgb(255, 0, 0)', 'rgb(0, 255, 0)'
				local onGroundText = string.format('<font color="%s"> %s </font>', isOnGround and green or red, isOnGround and 'Yes' or 'No')
				local timeOnGroundText = string.format('<font color="%s"> %.01f </font>', flying and red or green, flying and -timeSinceLastFly or timeOnGround);
				local canFlyText = string.format('<font color="%s"> %s </font>', shouldFly and green or red, shouldFly and 'Yes' or 'No');

				aaGunCounterText.Text = string.format('On Ground: %s\nTime on ground: %s\nCan Fly (Recommended): %s', onGroundText, timeOnGroundText, canFlyText);
			end);
		end;
	end;

	do -- // Auto Potions + Auto Smithing
		local potions = {
			['Health Potion'] = {
				['Lava Flower'] = 1;
				['Scroom'] = 2;
			},

			['Bone Growth Potion'] = {
				['Trote'] = 1,
				['Strange Tentacle'] = 1,
				['Uncanny Tentacle'] = 1
			},

			['Switch Witch'] = {
				['Dire Flower'] = 1,
				['Glow Shroom'] = 2
			},

			['Silver Sun'] = {
				['Desert Mist'] = 1,
				['Free Leaf'] = 1,
				['Polar Plant'] = 1
			},

			['Lordsbane'] = {
				['Crown Flower'] = 3
			},

			['Liquid Wisdom'] = {
				['Desert Mist'] = 1,
				['Periashroom'] = 1,
				['Crown Flower'] = 1,
				['Freeleaf'] = 1
			},

			['Ice Protection'] = {
				['Snow Scroom'] = 2,
				['Trote'] = 1,
			},

			['Kingsbane'] = {
				['Crown Flower'] = 1,
				['Vile Seed'] = 2,
			},

			['Feather Feet'] = {
				['Creely'] = 1,
				['Dire Flower'] = 1,
				['Polar Plant'] = 1
			},

			['Fire Protection Potion'] = {
				['Trote'] = 1,
				['Scroom'] = 2
			},

			['Tespian Elixir'] = {
				['Lava Flower'] = 1,
				['Scroom'] = 1,
				['Moss Plant'] = 2
			},

			['Slateskin'] = {
				['Petrii Flower'] = 1,
				['Stone Scroom'] = 1,
				['Coconut'] = 1
			},

			['Mind Mend'] = {
				['Grass Stem'] = 1,
				['Crystal Lotus'] = 1,
				['Winter Blossom'] = 1
			},

			['Clot Control'] = {
				['Coconut'] = 1,
				['Grass Stem'] = 1,
				['Petri Flower'] = 1
			},

			['Maidensbane'] = {
				['Stone Scroom'] = 1,
				['Fen Bloom'] = 1,
				['Foul Root'] = 1,
			},

			['Sooth Sight'] = {
				['Grass Stem'] = 2,
				['Crystal Lotus'] = 1
			},

			['Crystal Extract'] = {
				['Crystal Root'] = 1,
				['Crystal Lotus'] = 1,
				['Winter Blossom'] = 1
			},

			['Soothing Frost'] = {
				['Winter Blossom'] = 1,
				['Snowshroom'] = 2
			},
		};

		local swords = {
			['Bronze Sword'] = {
				['Copper Bar'] = 1,
				['Tin Bar'] = 2
			},

			['Bronze Dagger'] = {
				['Copper Bar'] = 1,
				['Tin Bar'] = 1
			},

			['Bronze Spear'] = {
				['Tin Bar'] = 1,
				['Copper Bar'] = 2
			},

			['Steel Sword'] = {
				['Iron Bar'] = 2,
				['Copper Bar'] = 1
			},

			['Steel Dagger'] = {
				['Iron Bar'] = 1,
				['Copper Bar'] = 1
			},

			['Steel Spear'] = {
				['Iron Bar'] = 1,
				['Copper Bar'] = 2
			},

			['Mythril Sword'] = {
				['Copper Bar'] = 1,
				['Iron Bar'] = 2,
				['Mythril Bar'] = 1
			},

			['Mythril Dagger'] = {
				['Copper Bar'] = 1,
				['Iron Bar'] = 1,
				['Mythril Bar'] = 1
			},

			['Mythril Spear'] = {
				['Copper Bar'] = 2,
				['Iron Bar'] = 1,
				['Mythril Bar'] = 1
			}
		}

		local stations = workspace:FindFirstChild("Stations");

		local function GrabStation(type)
			if typeof(type) ~= "string" then
				return error(string.format("Expected type string got <%s>",typeof(type)))
			elseif(not stations) then
				return warn('[Auto Potion] No Stations');
			end

			for i,v in next, stations:GetChildren() do
				if (v.Timer.Position-LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= 15 and string.find(v.Name, type) then
					return v;
				end;
			end;
		end

		local function hasMaterials(items, item)
			local recipe = items[item];
			local count = setmetatable({}, {__index = function() return 0 end});

			assert(recipe);

			for i, v in next, LocalPlayer.Backpack:GetChildren() do
				if(recipe[v.Name]) then
					local quantity = v:FindFirstChild('Quantity');
					quantity = quantity and quantity.Value or 1;

					count[v.Name] = count[v.Name] + quantity;
				end;
			end;

			for i, v in next, recipe do
				if(count[i] < v) then
					return false;
				end;
			end;

			return recipe;
		end;

		autoCraftUtils.hasMaterials = function(craftType, item)
			return hasMaterials(craftType == 'Alchemy' and potions or swords, item);
		end;

		local function addItemsToStation(items, station, part, partToClick, partToClean)
			if(station.Contents.Value ~= '[]') then
				repeat
					fireclickdetector(station[partToClean].ClickEmpty);
					task.wait(0.1);
				until station.Contents.Value == '[]';

				task.wait(0.1);
			end;

			for name, count in next, items do
				for i = 1, count do
					local k = LocalPlayer.Backpack:FindFirstChild(name);
					if(not k) then return; end;

					k.Parent = LocalPlayer.Character;
					task.wait(0.1);

					local remote = k:FindFirstChildWhichIsA('RemoteEvent');

					if(remote) then
						local content = station.Contents.Value;

						repeat
							remote:FireServer(station[part].CFrame,station[part]);
							task.wait(0.1);
						until station.Contents.Value ~= content;

						k.Parent = LocalPlayer.Backpack;
						task.wait(0.1);
					else
						k:Activate();

						repeat
							task.wait(0.5);
						until not k.Parent;
					end;
				end;
			end;

			repeat
				fireclickdetector(station[partToClick].ClickConcoct);
				task.wait(0.1);
			until station.Contents.Value == '[]';
		end;

		local function craft(stationType, itemToCraft)
			local station = GrabStation(stationType);
			local items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

			if(not station) then return ToastNotif.new({text = 'You must be near a cauldron/furnace !'}) end;
			if(not items) then return ToastNotif.new({text = 'Some Ingredients are missing !'}) end;

			if(stationType == 'Smithing') then
				ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
					return {
						Hit = station.Material.CFrame,
						Target = station.Material,
						UnitRay = Mouse.UnitRay,
						X = Mouse.X,
						Y = Mouse.Y
					}
				end;
			end;

			if (stationType == 'Alchemy') then
				repeat
					addItemsToStation(items, station, 'Water', 'Ladle', 'Bucket');
					items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

					task.wait(0.5);
				until not items;
			elseif (stationType == 'Smithing') then
				repeat
					addItemsToStation(items, station, 'Material', 'Hammer', 'Trash');
					items = hasMaterials(stationType == 'Alchemy' and potions or swords, itemToCraft);

					task.wait(0.5);
				until not items;
			end;

			task.wait(2);

			ReplicatedStorage.Requests.GetMouse.OnClientInvoke = function()
				return {
					Hit = Mouse.Hit,
					Target = Mouse.Target,
					UnitRay = Mouse.UnitRay,
					X = Mouse.X,
					Y = Mouse.Y
				}
			end;
		end;

		autoCraftUtils.craft = craft;

		function buildAutoPotion(window)
			local list = {};

			for i, v in next, potions do
				table.insert(list, i);
			end;

			window:AddList({text = 'Auto Potion', skipflag = true, noload = true, values = list, callback = function(name) craft('Alchemy', name) end});
		end;

		function buildAutoCraft(window)
			local list = {};

			for i, v in next, swords do
				table.insert(list, i);
			end;

			window:AddList({text = 'Auto Craft', skipflag = true, noload = true, values = list, callback = function(name) craft('Smithing', name) end});
		end;
	end;

	local chatFocused = false;

	UserInputService.TextBoxFocused:Connect(function()
		chatFocused = true;
	end);

	UserInputService.TextBoxFocusReleased:Connect(function()
		chatFocused = false;
	end);

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
		if(not library.flags.noClipDisableValues['Disable On Water']) then
			return;
		end;

		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
		if(not head) then return end;

		local min = head.Position - (0.5 * head.Size);
		local max = head.Position + (0.5 * head.Size);

		local region = Region3.new(min, max):ExpandToGrid(4);

		local material = workspace.Terrain:ReadVoxels(region,4)[1][1][1];

		return material == Enum.Material.Water;
	end;

	local function isKnocked()
		if(not library.flags.noClipDisableValues['Disable When Knocked']) then
			return;
		end;

		local head = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Head');
		if(head and head:FindFirstChild('Bone')) then
			return true;
		end;
	end;

	local function getCurrentNpc(whitelist)
		local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
		if(not rootPart) then return end;

		for _, npc in next, (workspace:FindFirstChild('NPCs') or Instance.new('Folder')):GetChildren() do
			local npcRoot = npc.PrimaryPart;
			if(npcRoot and table.find(whitelist, npc.Name) and (rootPart.Position - npcRoot.Position).Magnitude <= 15) then
				return npc;
			end;
		end;
	end;

	local function getPlayerClass(player)
		if(playerClasses[player] and tick() - playerClasses[player].lastUpdate <= 5) then
			return playerClasses[player].name;
		end;

		local allFounds = {};
		local playerBackpack = player:FindFirstChild('Backpack');
		if(not playerBackpack) then
			return 'Freshie';
		end;

		for i, v in next, playerClassesList do
			for i2, v2 in next, v.Active do
				local alternative = tostring(v2):gsub("%s", "");
				if(i2 ~= "Level" and (playerBackpack:FindFirstChild(v2) or playerBackpack:FindFirstChild(alternative))) then
					table.insert(allFounds, {Level = -1, Name = i});
					break;
				end;
			end;

			for i2, v2 in next, v.Classes do
				for i3, v3 in next, v2 do
					local alternative = tostring(v3):gsub("%s", "");
					if(i3 ~= "Level" and (playerBackpack:FindFirstChild(v3) or playerBackpack:FindFirstChild(alternative))) then
						table.insert(allFounds, {Level = v2.Level, Name = i2});
						break;
					end;
				end;
			end
		end;

		local foundClass, foundClassLevel = nil, -1;
		for i, v in next, allFounds do
			if(v.Level >= foundClassLevel) then
				foundClass = v;
				foundClassLevel = v.Level;
			end;
		end;

		playerClasses[player] = {
			lastUpdate = tick();
			name = foundClass and foundClass.Name or 'Freshie'
		};

		if(not foundClass) then
			return 'Freshie';
		end;

		return foundClass.Name;
	end;

	local playerRaces = {};
	local raceColors = {};

	do -- // Grab Race Data
		if(ReplicatedStorage:FindFirstChild('Info') and ReplicatedStorage.Info:FindFirstChild('Races')) then
			for i, v in next, ReplicatedStorage.Info.Races:GetChildren() do
				table.insert(raceColors, {tostring(v.EyeColor.Value), tostring(v.SkinColor.Value), v.Name})
			end;
		end;
	end;

	local function getPlayerRace(player)
		if(playerRaces[player] and tick() - playerRaces[player].lastUpdateAt <= 5) then
			return playerRaces[player].name;
		end;

		local head = player.Character and player.Character:FindFirstChild('Head');
		local face = head and head:FindFirstChild('RLFace');
		local scroomHead = player.Character and player.Character:FindFirstChild('ScroomHead');

		local raceFound = 'Unknown'

		if(not face) then return raceFound end;

		if(scroomHead) then
			if(scroomHead.Material.Name == 'DiamondPlate') then
				raceFound = 'Metascroom';
			else
				raceFound = 'Scroom';
			end;
		end;

		if(raceFound == 'Unknown') then
			for i2, v2 in next, raceColors do
				local eyeColor, skinColor, raceName = v2[1], v2[2], v2[3];

				if(tostring(head.Color) == skinColor and tostring(face.Color3) == eyeColor) then
					raceFound = raceName;
				end;
			end;
		end;


		playerRaces[player] = {
			lastUpdateAt = tick(),
			name = raceFound
		};

		return raceFound;
	end;

	local function chargeManaUntil(amount)
		local character = LocalPlayer.Character;
		if(not character or character:FindFirstChildWhichIsA('ForceField') or not canUseMana()) then return warn('Cant charge mana cuz cant use mana', canUseMana()) end;

		local playerMana = character and character:FindFirstChild('Mana');
		if(character:FindFirstChild('Charge')) then
			dechargeMana();
			task.wait(0.2);
		end;

		if(not playerMana or sprinting) then
			return;
		end;

		if(playerMana.Value < amount) then
			--print('[Mana Adjust] Charge Mana');

			repeat
				chargeMana();
				task.wait(0.1);
			until playerMana.Value > math.clamp(amount, 0, 98) or sprinting;

			--print('[Mana Adjust] Decharge Mana');

			if (character:FindFirstChild('Charge')) then
				dechargeMana();
				task.wait(0.3);
			end;
		end;
	end;

	do -- // Bots
		local function runSafetyCheck(serverHop)
			local playerRangeCheck = library.flags.playerRangeCheck;

			if(moderatorInGame) then
				if(serverHop) then
					kickPlayer('Moderator In Game');
					return findServer(true), true, task.wait(9e9);
				else
					return true, 'Mod In Game';
				end;
			end;

			if(Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
				if(serverHop) then
					kickPlayer('Illusionist In Game');
					return findServer(true), true, task.wait(9e9);
				else
					return true, 'Illusionist In Game';
				end;
			end;

			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if(not rootPart) then return end;

			if(_G.forcePanic) then
				if(serverHop) then
					kickPlayer('Forced Panic');
					return findServer(true), true, task.wait(9e9);
				else
					return true, 'Forced Panic';
				end;
			end;

			for i, v in next, Players:GetPlayers() do
				local plrRoot = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
				if(v == LocalPlayer or not plrRoot) then continue end;

				local playerDistance = rootPart and (plrRoot.Position - rootPart.Position).Magnitude;
				if(playerDistance <= playerRangeCheck) then
					if(serverHop) then
						kickPlayer(string.format('Player Too Close (%s) [%d] Studs', v.Name, playerDistance));
						return findServer(true), true, task.wait(9e9);
					else
						return true, string.format('Player Too Close (%s) [%d] Studs', v.Name, playerDistance);
					end;
				end;
			end;
		end;

		local function runSmallSafetyCheck(cf, playerDistanceCheck, ignoreY)
			local illusionistObserving, playerTooClose = false, false;
			local rangeCheck = playerDistanceCheck or 500;

			for i, v in next, Players:GetPlayers() do
				local rootPart = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
				if(not rootPart or v == LocalPlayer) then continue end;

				if(v.Character:FindFirstChild('Observing')) then
					illusionistObserving = true;
				end;

				if((Utility:roundVector(rootPart.Position) - Utility:roundVector(cf.p)).Magnitude <= rangeCheck) then
					playerTooClose = true;
					break;
				end;
			end;

			return illusionistObserving, playerTooClose;
		end;

		local function findClosest(currentPosition, positions)
			local closest, distance = nil, math.huge;
			local index = 0;

			for i, v in next, positions do
				local newDistance = (currentPosition - v.position).Magnitude;
				if(newDistance < distance) then
					closest, distance = v.position, newDistance;
					index = i;
				end;
			end;

			return closest, distance, index;
		end;

		local function setFeatureState(names, state)
			for _, name in next, names do
				if(library.flags[name] ~= state) then
					library.options[name]:SetState(state);
				end;
			end;
		end;

		local function disableBeds()
			local bed = workspace:FindFirstChild('Bed', true);
			if(not bed) then return end;

			for i, v in next, bed.Parent:GetChildren() do
				if(v.Name == 'Bed') then
					v.CanTouch = false;
				end;
			end;
		end;

		local function tweenTeleport(rootPart, position)
			local distance = (rootPart.Position - position).Magnitude;
			local tween = TweenService:Create(rootPart, TweenInfo.new(distance / 150, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(position)
			});

			tween:Play();
			tween.Completed:Wait();
		end;

		local function getClosestTrinkets(rootPart)
			local allTrinkets = {};

			for i, v in next, workspace:GetChildren() do
				if(v:IsA('BasePart') and v:FindFirstChildWhichIsA('ClickDetector', true) and (v.Position - rootPart.Position).Magnitude <= 500) then
					runSafetyCheck(true);

					local distance = (v.Position - rootPart.Position).Magnitude;
					table.insert(allTrinkets, {distance = distance, object = v});
				end;
			end;

			table.sort(allTrinkets, function(a, b)
				return a.distance < b.distance;
			end);

			return allTrinkets;
		end;

		local function createBot(tpLocations)
			runSafetyCheck(true);

			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

			if(not LocalPlayer.Character) then
				local startMenu = LocalPlayer:WaitForChild('PlayerGui'):WaitForChild('StartMenu');
				local finish = startMenu:WaitForChild('Finish');

				finish:FireServer();

				repeat
					rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
					task.wait();
				until rootPart;
			end;

			runSafetyCheck(true);
			setFeatureState({'autoPickup', 'antiFire', 'removeKillBricks', 'noFallDamage'}, true);
			disableBeds();

			local _, distance = findClosest(rootPart.Position, tpLocations);
			if(distance >= 20) then
				repeat
					_, distance = findClosest(rootPart.Position, tpLocations);
					ToastNotif.new({
						text = 'You are too far away from the points',
						duration = 2.5
					});
					task.wait(5);
				until distance <= 20;
			end;

			local bodyVelocity = Instance.new('BodyVelocity');
			CollectionService:AddTag(bodyVelocity, 'AllowedBM');

			bodyVelocity.Velocity = Vector3.new();
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
			bodyVelocity.Parent = rootPart;

			local aaGunPart = Instance.new('Part');

			aaGunPart.Anchored = true;
			aaGunPart.Transparency = debugMode and 0 or 1;
			aaGunPart.Size = Vector3.new(10, 0.1, 10);
			aaGunPart.Parent = workspace;

			local trinketPickedUp = {};

			RunService.Stepped:Connect(function()
				aaGunPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0);

				if(LocalPlayer.Character:FindFirstChild('Frostbitten')) then
					LocalPlayer.Character.Frostbitten:Destroy();
				end;

				if(LocalPlayer.Character:FindFirstChild('DamageMPStack')) then
					LocalPlayer.Character.DamageMPStack:Destroy();
				end;
			end);

			if((tpLocations[1].position - rootPart.Position).Magnitude > 20) then
				local _, _, index = findClosest(rootPart.Position, tpLocations);

				for i = index, 1, -1 do
					local tpData = tpLocations[i];

					runSafetyCheck(true);
					tweenTeleport(rootPart, tpData.position);

					local ranAt = tick();

					repeat
						runSafetyCheck(true);
						task.wait();
					until tick() - ranAt >= tpData.delay;
				end;

				findServer(true);
				return;
			end;

			for i, v in next, tpLocations do
				runSafetyCheck(true);
				tweenTeleport(rootPart, v.position);

				local ranAt = tick();

				repeat
					runSafetyCheck(true);
					task.wait();
				until tick() - ranAt >= v.delay;

				local trinkets = getClosestTrinkets(rootPart);

				for i, v in next, trinkets do
					if(trinketPickedUp[v.object]) then
						continue;
					end;

					local trinketType = getTrinketType(v.object);
					if((trinketType.Name == 'Phoenix Down' and library.flags.dontPickupPhoenixDown) or (trinketType.Name == 'Ninja Scroll' and library.flags.dontPickupScrolls)) then
						if(v.object:FindFirstChildWhichIsA('ClickDetector', true)) then
							v.object:FindFirstChildWhichIsA('ClickDetector', true):Destroy();
						end;

						trinketPickedUp[v.object] = true;
						continue;
					end;

					local pickedUpAt = tick();
					repeat task.wait() until not v.object.Parent or tick() - pickedUpAt >= 5;

					trinketPickedUp[v.object] = true;
					task.wait(0.1);
				end;
			end;

			if(not rootPart.Parent) then
				return kickPlayer('You got killed, stopped bot.');
			end;

			findServer(true);
		end;

		local function findPlayerInZone(zonePosition, zoneSize)
			local castPart = Instance.new('Part');
			castPart.Anchored = true;
			castPart.Transparency = 1;
			castPart.CanCollide = false;
			castPart.Size = zoneSize; -- Vector3.new(1000, 0, 1000);
			castPart.Position = zonePosition; -- Vector3.new(-1171.661, 702.853, 201.261);
			castPart.Parent = workspace;

			local params = RaycastParams.new();
			params.FilterType = Enum.RaycastFilterType.Whitelist;
			params.FilterDescendantsInstances = {castPart};

			for i, v in next, Players:GetPlayers() do
				local rootPart = v.Character and v.Character:FindFirstChild('HumanoidRootPart');

				if (rootPart and workspace:Raycast(rootPart.Position, Vector3.new(0, 10000, 0), params) and v ~= LocalPlayer) then
					return true;
				end;
			end;
		end;

		function scroomBot(toggle)
			if(not toggle) then return end;

			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			local target = library.flags.scroomBotTargetPlayer;

			repeat
				task.wait(1);

				if(getPlayerRace(LocalPlayer) ~= 'Scroom') then
					ToastNotif.new({text = 'Scroom Bot - You must be a scroom !', duration = 5});
					continue;
				end;

				local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
				local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
				if(not rootPart or not humanoid) then continue end;

				local statGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StatGui');
				if(not statGui) then continue end;

				local lives = tonumber(statGui.Container.Health.Lives.Roller.Char.Text)
				if(not lives) then continue end;

				warn('[Scroom Bot] Scroom has', lives, 'lives');

				if(lives == 0) then
					warn('[Scroom Bot] No more lives !');

					local function moveTo(pos)
						local moveToFinished = false;
						coroutine.wrap(function()
							humanoid.MoveToFinished:Wait();
							moveToFinished = true;
						end)();

						repeat
							print('[Scroom Bot] Waiting for moveToFinished');
							humanoid:MoveTo(pos);
							task.wait();
						until moveToFinished;
					end;

					moveTo(Vector3.new(-7172.99316, 274.759491, 2772.82275));
					moveTo(Vector3.new(-7144.06201, 274.759338, 2771.50513));

					print('[Scroom Bot] Ready to talk to Ferryman');

					local npc = getCurrentNpc({'Ferryman'});
					fireclickdetector(npc.ClickDetector);

					task.wait(1);
					local choices = {'New Character\n(free)', 'My son.', 'exit'};
					for i, v in next, choices do
						if(v == 'exit') then
							dialog:FireServer({exit = true});
						else
							dialog:FireServer({choice = v});
						end;

						task.wait(1);
					end;

					LocalPlayer.CharacterAdded:Wait();
					continue;
				end;

				if(not target.Character or (target.Character.PrimaryPart.Position - rootPart.Position).Magnitude > 100) then
					ToastNotif.new({text = 'Scroom Bot - Player is too far away (Maximum 100 studs)', duration = 5});
					continue;
				end;

				local tween = TweenService:Create(rootPart, TweenInfo.new((rootPart.Position - target.Character.PrimaryPart.Position).Magnitude / 200), {
					CFrame = CFrame.new(target.Character.PrimaryPart.Position)
				});

				tween:Play();
				tween.Completed:Wait();

				if(LocalPlayer.Character:FindFirstChildWhichIsA('ForceField')) then
					LocalPlayer.Character:FindFirstChildWhichIsA('ForceField'):Destroy();
				end;

				task.wait(0.1);
				local id = HttpService:GenerateGUID(false):sub(1, 8);

				repeat
					if(library.flags.scroomBotGripMode and humanoid.Health >= 10) then
						fallDamage:FireServer({math.random(), 2});
					end;
					print('[Scroom Bot] Waiting for player to die ...', id);

					task.wait(1);
				until humanoid.Health <= 0 or not library.flags.scroomBot;

				warn('[Scroom Bot] Player is dead, waiting for new character to spawn ...');
				LocalPlayer.CharacterAdded:Wait();
				warn('[Scroom Bot] New character has spawned');
			until not library.flags.scroomBot;
		end;

		function daysFarm(toggle)
			local humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if(not toggle) then
				maid.daysFarm = nil;
				maid.daysFarmNoClip = nil;
				return;
			end;

			if(not LocalPlayer.Character) then
				spawnLocalCharacter();
				task.wait(1);
			end;

			repeat
				task.wait();
			until LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			humanoidRootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

			maid.daysFarm = RunService.Heartbeat:Connect(function()
				local _, playerTooClose = runSmallSafetyCheck(humanoidRootPart.CFrame,library.flags.daysFarmRange);

				if(playerTooClose or moderatorInGame) then
					maid.daysFarm = nil;
					task.wait(1);
					kickPlayer(moderatorInGame and 'Mod In Game' or 'Player Too Close');
					findServer();
				end;
			end);
		end;

		function gachaBot(toggle)
			if(not toggle or not isGaia) then return end;

			if(moderatorInGame) then
				kickPlayer('Mod In Game');
				return findServer();
			end;

			local character = spawnLocalCharacter();

			local rootPart = character and character:WaitForChild('HumanoidRootPart');
			if(not rootPart) then return ToastNotif.new({text = 'no hrp?'}) and findServer(); end;

			local npc = workspace.NPCs:FindFirstChild('Xenyari');
			local npcRootPart = npc and npc:FindFirstChild('Head');
			local clickDetector = npc and npc:FindFirstChildWhichIsA('ClickDetector');

			if (not npc or not npcRootPart or not clickDetector) then
				kickPlayer('Please dm Aztup!');
				return findServer();
			end;

			local distanceFromNPC = (npcRootPart.Position - rootPart.Position).Magnitude;

			if (distanceFromNPC > 10) then
				repeat
					ToastNotif.new({text = 'You are too far away from Xenyari', duration = 1});
					distanceFromNPC = (npcRootPart.Position - rootPart.Position).Magnitude;
					task.wait(1);
				until distanceFromNPC < 10;
			end;

			local getPlayerDays = (function()
				for i, v in next, getconnections(ReplicatedStorage.Requests.DaysSurvivedChanged.OnClientEvent) do
					return getupvalue(v.Function, 2);
				end;
			end);

			local playerDays = getPlayerDays();

			repeat
				playerDays = getPlayerDays();
				task.wait(0.1);
			until playerDays;

			ReplicatedStorage.Requests.DaysSurvivedChanged.OnClientEvent:Connect(function(days)
				playerDays = days;
			end);

			if (MemStorageService:HasItem('gachaBotLives')) then
				repeat
					print('running safety check and waiting for lives to change!', playerDays, tonumber(MemStorageService:GetItem('gachaBotLives')));

					local _, playerTooClose = runSmallSafetyCheck(rootPart.CFrame, 2500);

					if (playerTooClose) then
						if (character:FindFirstChild('Danger')) then
							repeat
								task.wait(0.1);
							until not character:FindFirstChild('Danger');
						end;

						kickPlayer('Player too close');
						findServer();
					elseif (character:FindFirstChildWhichIsA('ForceField')) then
						character:FindFirstChildWhichIsA('ForceField'):Destroy();
					end;

					task.wait(0.1);
				until playerDays ~= tonumber(MemStorageService:GetItem('gachaBotLives'));
			else
				MemStorageService:SetItem('gachaBotLives', tostring(playerDays));
			end;

			dialog.OnClientEvent:Connect(function(dialogData)
				task.wait(1);

				if (not dialogData.choices) then
					dialog:FireServer({exit = true});
					task.wait(1);
					kickPlayer('Hopping');
					findServer();
				elseif (dialogData.choices) then
					MemStorageService:SetItem('gachaBotLives', tostring(playerDays));
					dialog:FireServer({choice = dialogData.choices[1]});
				end;
			end);

			library.base.Enabled = false;

			repeat
				local rootPosition = workspace.CurrentCamera:WorldToViewportPoint(npcRootPart.Position);

				VirtualInputManager:SendMouseButtonEvent(rootPosition.X, rootPosition.Y, 0, false, game, 1);
				task.wait();
				VirtualInputManager:SendMouseButtonEvent(rootPosition.X, rootPosition.Y, 0, true, game, 1);
				task.wait(0.25);
			until LocalPlayer.PlayerGui:FindFirstChild('CaptchaLoad') or LocalPlayer.PlayerGui:FindFirstChild('Captcha');
			-- // Waiting for npc answer or waiting for captcha

			repeat task.wait() until LocalPlayer.PlayerGui:FindFirstChild('Captcha');

			repeat
				local captchaGUI = LocalPlayer.PlayerGui:FindFirstChild('Captcha');
				local choices = captchaGUI and captchaGUI.MainFrame.Options:GetChildren();
				local union = captchaGUI and captchaGUI.MainFrame.Viewport.Union;

				if(choices and union) then
					local captchaAnswer = solveCaptcha(union);

					for i, v in next, choices do
						if(v.Name == captchaAnswer) then
							local position = v.AbsolutePosition + Vector2.new(40, 40);
							VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, true, game, 1);
							task.wait();
							VirtualInputManager:SendMouseButtonEvent(position.X, position.Y, 0, false, game, 1);

							break;
						end;
					end;
				end;

				task.wait(1);
			until not LocalPlayer.PlayerGui:FindFirstChild('Captcha');

			library.base.Enabled = true;
		end;

		function blackSmithBot(toggle)
			if (not toggle) then return end;

			local character = spawnLocalCharacter();
			local rootPart = character and character:WaitForChild('HumanoidRootPart');

			local locations = {
				Vector3.new(-1066.6357421875, 583.36157226563, -421.35971069336)
			};

			local boxes = {};
			setFeatureState({'antiFire', 'removeKillBricks', 'noFallDamage'}, true);

			for i = 1, #locations do
				local box = Drawing.new('Square');
				box.Size = Vector2.new(50, 50);
				box.Thickness = 5;
				box.Color = Color3.fromRGB(255, 255, 255);

				local text = Drawing.new('Text');
				text.Size = 20;
				text.Center = false;
				text.Text = string.format('Blacksmith Point %d', i);
				text.Color = Color3.fromRGB(255, 255, 255);

				table.insert(boxes, {box, text});
			end;

			RunService.Heartbeat:Connect(function()
				for i, location in next, locations do
					local box, text = unpack(boxes[i]);
					local screenPosition, visible = workspace.CurrentCamera:WorldToViewportPoint(location);

					box.Visible = visible;
					text.Visible = visible;

					box.Position = Vector2.new(screenPosition.X, screenPosition.Y) - box.Size / 2;
					text.Position = Vector2.new(screenPosition.X, screenPosition.Y) - box.Size;
				end;
			end);

			local function getChosenLocation()
				for i, v in next, locations do
					if ((rootPart.Position - v).Magnitude < 10) then
						return i, v;
					end;
				end;
			end;

			local chosenLocationIndex, chosenLocation = getChosenLocation();

			if (not chosenLocation) then
				repeat
					ToastNotif.new({text = 'You must be on one of the blacksmith points', duration = 1});

					chosenLocationIndex, chosenLocation = getChosenLocation();
					task.wait(1);
				until chosenLocation;
			end;

			local bodyVelocity = Instance.new('BodyVelocity');
			CollectionService:AddTag(bodyVelocity, 'AllowedBM');

			bodyVelocity.Velocity = Vector3.new();
			bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
			bodyVelocity.Parent = rootPart;

			local aaGunPart = Instance.new('Part');

			aaGunPart.Anchored = true;
			aaGunPart.Transparency = debugMode and 0 or 1;
			aaGunPart.Size = Vector3.new(10, 0.1, 10);
			aaGunPart.Parent = workspace;

			local function getPickaxes()
				local pickaxes = {};

				for i, v in next, LocalPlayer.Backpack:GetChildren() do
					if (v.Name == 'Pickaxe') then
						table.insert(pickaxes, v);
					end;
				end;

				return pickaxes;
			end;

			local pickaxes = getPickaxes();

			if (#pickaxes <= 1) then
				repeat
					ToastNotif.new({text = 'You must have atleast 1 pickaxe.', duration = 1})
					pickaxes = getPickaxes();

					task.wait(1);
				until #pickaxes >= 1;
			end;

			RunService.Stepped:Connect(function()
				aaGunPart.CFrame = rootPart.CFrame * CFrame.new(0, -3.5, 0);

				if(character:FindFirstChild('Frostbitten')) then
					character.Frostbitten:Destroy();
				end;

				if(character:FindFirstChild('DamageMPStack')) then
					character.DamageMPStack:Destroy();
				end;
			end);

			local function mineOres(ores)
				for i, v in next, ores do
					local isBlacklisted = v:FindFirstChild('Blacklist') and v.Blacklist:FindFirstChild(LocalPlayer.Name);

					if ((v.Position - rootPart.Position).Magnitude < 10 and v.Transparency == 0 and not isBlacklisted and (not library.flags.skipIllusionistServer or Utility:countTable(illusionists) <= 0)) then
						local startedAt = tick();

						repeat
							local pickaxe = table.remove(pickaxes, 1);

							pickaxe.Parent = LocalPlayer.Character;
							pickaxe:Activate();

							task.wait(0.05);
							pickaxe.Parent = LocalPlayer.Backpack;

							table.insert(pickaxes, pickaxe);
						until v.Transparency ~= 0 or tick() - startedAt >= 2;
					end;
				end;
			end;

			local function getOres(getCookedOre)
				local totalOres = {};
				local closest = 0;

				for i, v in next, LocalPlayer.Backpack:GetChildren() do
					if (v:FindFirstChild('Ore') or (getCookedOre and v:FindFirstChild('OreBar'))) then
						totalOres[v.Name] = (totalOres[v.Name] or 0) + 1
					end;
				end;

				for i, v in next, totalOres do
					if (v > closest) then
						closest = v;
					end;
				end;

				return closest;
			end;

			local function getDaggers()
				local counter = 0;

				for i, v in next, LocalPlayer.Backpack:GetChildren() do
					if (v:FindFirstChild('Smithed')) then
						counter = counter + 1;
					end;
				end;

				return counter;
			end;

			local playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703));
			task.wait(5);

			if (playerTooClose) then
				kickPlayer('Player too close.');
				return findServer();
			elseif (Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
				kickPlayer('Illusionist in server.');
				return findServer();
			elseif (moderatorInGame) then
				kickPlayer('Mod in game.');
				return findServer();
			end;

			LocalPlayer.CharacterAdded:Connect(function()
				kickPlayer('You got killed, stopping bot');
				function findServer() end;
				task.wait(1);
				while true do end;
			end);

			local forceField = LocalPlayer.Character:FindFirstChildWhichIsA('ForceField');
			if (forceField) then
				forceField:Destroy();
				task.wait(1);
			end;

			local amountOfOres = getOres();
			local amountOfCookedOres = getOres(true);
			local leftClick = LocalPlayer.Character.CharacterHandler.Remotes.LeftClick;
			local rightClick = LocalPlayer.Character.CharacterHandler.Remotes.RightClick;

			if (chosenLocationIndex == 1) then
				local ores = workspace.Ores:GetChildren();
				local oresLocation = Vector3.new(-1047.0006103516, 185.89465332031, -51.419830322266);

				local foundOres = {};

				for i, v in next, ores do
					local isBlacklisted = v:FindFirstChild('Blacklist') and v.Blacklist:FindFirstChild(LocalPlayer.Name);

					if ((v.Position - oresLocation).Magnitude < 500 and v.Transparency == 0 and not isBlacklisted) then
						table.insert(foundOres, v);
					end;
				end;

				if (#foundOres <= 0) then
					kickPlayer('No ores.');
					return findServer();
				end;

				tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
				tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
				tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
				tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, -59.241));
				mineOres(ores);
				tweenTeleport(rootPart, Vector3.new(-1047.738, 185.895, -154.77));
				mineOres(ores);
				tweenTeleport(rootPart, Vector3.new(-1057.99, 185.895, -151.683));
				mineOres(ores);
				tweenTeleport(rootPart, Vector3.new(-1045.891, 185.895, -153.512));
				tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, -59.241));
				tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
				tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
				tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
			end;

			if (amountOfOres >= 25 or MemStorageService:HasItem('wasCookingOres')) then
				local remoteSmithing = LocalPlayer.Backpack:FindFirstChild('Remote Smithing');
				if (not remoteSmithing) then return kickPlayer('Bot, stopped, due to max amount of ores and no remote smithing') end;

				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(20, 0, 0));
				MemStorageService:SetItem('wasCookingOres', 'true');

				remoteSmithing.Parent = LocalPlayer.Character;
				task.wait(1);
				rightClick:FireServer({math.random(1, 10), math.random()});

				setFeatureState({'autoSmelt'}, true);

				repeat
					playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703))
					amountOfOres = getOres();

					task.wait(0.1);
				until playerTooClose or amountOfOres <= 0;

				if (amountOfOres <= 0) then
					MemStorageService:RemoveItem('wasCookingOres');
				end;

				remoteSmithing.Parent = LocalPlayer.Backpack;

				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 0));
				task.wait(0.1);
				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(-20, 0, 0));
				task.wait(0.1);
				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, -10, 0));

				setFeatureState({'autoSmelt'}, false);
				task.wait(0.5);

				if (playerTooClose) then
					kickPlayer('Player was too close aborted, smelt ores');
					return findServer();
				end;
			end;

			local craftItem;
			local itemToCrafts = {'Bronze Dagger', 'Steel Dagger', 'Mythril Dagger'};

			for i, v in next, itemToCrafts do
				if (autoCraftUtils.hasMaterials('Smithing', v)) then
					craftItem = v;
				end;
			end;

			if (amountOfCookedOres >= 50 or MemStorageService:HasItem('wasDoingCrafting')) then
				local remoteSmithing = LocalPlayer.Backpack:FindFirstChild('Remote Smithing');
				if (not remoteSmithing) then return kickPlayer('Bot, stopped, due to max amount of ores and no remote smithing') end;

				MemStorageService:SetItem('wasDoingCrafting', 'true');

				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0, 20));
				remoteSmithing.Parent = LocalPlayer.Character;

				task.wait(1);
				leftClick:FireServer({math.random(1, 10), math.random()});
				task.wait(1);
				remoteSmithing.Parent = LocalPlayer.Backpack;

				local craftEnded = false;

				task.spawn(function()
					autoCraftUtils.craft('Smithing', craftItem);
					craftEnded = true;
					MemStorageService:RemoveItem('wasDoingCrafting');
				end);

				repeat
					playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703))
					task.wait(0.1);
				until playerTooClose or craftEnded;

				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 10, 0));
				task.wait(0.1);
				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0, -20));
				task.wait(0.1);
				rootPart.CFrame = CFrame.new(rootPart.Position + Vector3.new(0, -10, 0));

				task.wait(0.5);

				if (playerTooClose) then
					kickPlayer('Player was too close aborted, smelt ores');
					return findServer();
				end;
			end;

			local amountOfDaggers = getDaggers();

			if (amountOfDaggers >= 50) then
				local playerTooClose = findPlayerInZone(Vector3.new(-1357.403, 702.853, 170.2), Vector3.new(1371.484, 9.368, 1504.703));

				if (playerTooClose) then
					kickPlayer('Player too close, cant sell daggers');
					return findServer();
				elseif (Utility:countTable(illusionists) > 0 and library.flags.skipIllusionistServer) then
					kickPlayer('Illu in server, cant sell daggers');
					return findServer();
				end;

				if (chosenLocationIndex == 1) then
					tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));
					tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
					tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
					tweenTeleport(rootPart, Vector3.new(-1048.018, 185.895, -48.932));
					tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, 205.667));
					tweenTeleport(rootPart, Vector3.new(-1041.21, 168.84, 227.411));
					tweenTeleport(rootPart, Vector3.new(-1107.443, 168.84, 253.837));
					tweenTeleport(rootPart, Vector3.new(-1169.846, 162.282, 290.529));
					tweenTeleport(rootPart, Vector3.new(-1169.846, 145.626, 291.5));
					tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 290.529));
					tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 253.283));
					tweenTeleport(rootPart, Vector3.new(-1237.223, 146.004, 254.742));

					-- talk to npc

					repeat
						task.wait(0.1);
						local merchant = getCurrentNpc({'Merchant', 'Pawnbroker'});
						if (not merchant) then warn('no npc very sad') continue end;

						fireclickdetector(merchant.ClickDetector);
						task.wait(1);
						dialog:FireServer({choice = 'Can I sell in bulk?'})
						task.wait(1);
						dialog:FireServer({choice = 'Weapons.'});
						task.wait(1);
						dialog:FireServer({choice = 'It\'s a deal.'});
						task.wait(1);
						dialog:FireServer({exit = true});

						amountOfDaggers = getDaggers();
						warn('daggers:', amountOfDaggers)
					until amountOfDaggers <= 0;

					tweenTeleport(rootPart, Vector3.new(-1237.223, 146.004, 254.742));
					tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 253.283));
					tweenTeleport(rootPart, Vector3.new(-1250.748, 146.004, 290.529));
					tweenTeleport(rootPart, Vector3.new(-1169.846, 145.626, 291.5));
					tweenTeleport(rootPart, Vector3.new(-1169.846, 162.282, 290.529));
					tweenTeleport(rootPart, Vector3.new(-1107.443, 168.84, 253.837));
					tweenTeleport(rootPart, Vector3.new(-1041.21, 168.84, 227.411));
					tweenTeleport(rootPart, Vector3.new(-1047.197, 185.895, 205.667));
					tweenTeleport(rootPart, Vector3.new(-1048.018, 185.895, -48.932));
					tweenTeleport(rootPart, Vector3.new(-1047.000, 589.257, -51.419));
					tweenTeleport(rootPart, Vector3.new(-1066.703, 589.257, -399.340));
					tweenTeleport(rootPart, Vector3.new(-1067.231, 583.361, -419.418));

					task.wait(0.5);

					kickPlayer('Sold daggers wooo');
					return findServer();
				end;

				-- setFeatureState({'blacksmithBot'}, false);
				-- return kickPlayer('Finished farming, you can now sell your daggers');
			end;

			task.wait(0.5);

			kickPlayer('Finished lotting.');
			return findServer();
		end;

		local botPoints = {};
		local botPointsUI = {};

		local botPointsParts = {};
		local botPointsLines = {};

		function addPoint(position, delay, waitForTrinkets)
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			position = position or (rootPart and rootPart.Position);
			if(not position) then return end;

			local roundPosition = Vector3.new(math.floor(position.X), math.floor(position.Y), math.floor(position.Z));
			local brickColor = BrickColor.palette(((#botPoints*5) % 100)+1);

			waitForTrinkets = waitForTrinkets or false;

			local pointData = {};
			pointData.position = position;
			pointData.delay = delay or 0;
			pointData.waitForTrinkets = waitForTrinkets;

			table.insert(botPoints, pointData);

			local point = Instance.new('Part');

			point.Size = Vector3.new(1, 1, 1);
			point.Parent = workspace;
			point.Shape = Enum.PartType.Ball;
			point.Anchored = true;
			point.CanCollide = false;
			point.Material = Enum.Material.SmoothPlastic;
			point.CFrame = CFrame.new(position);
			point.BrickColor = brickColor;

			local label = Bots:AddLabel(string.format('Point %d | %s', #botPoints, tostring(roundPosition)));
			label.main.TextColor3 = brickColor.Color;
			label.main.InputBegan:Connect(function(inputObject)
				if(inputObject.UserInputType ~= Enum.UserInputType.MouseButton1) then return end;

				repeat
					workspace.CurrentCamera.CameraSubject = point;
					Heartbeat:Wait();
				until inputObject.UserInputState == Enum.UserInputState.End;

				workspace.CurrentCamera.CameraSubject = LocalPlayer.Character;
			end);

			table.insert(botPointsUI, label);
			table.insert(botPointsUI, Bots:AddSlider({text = 'Delay', textpos = 2, value = pointData.delay, min = 0, max = 15, callback = function(val) pointData.delay = val end}));
			table.insert(botPointsUI, Bots:AddToggle({text = 'Wait For Trinkets', state = waitForTrinkets, callback = function(val) pointData.waitForTrinkets = val end}));
			table.insert(botPointsParts, point);

			refreshPoints();
		end;

		function clearPointsPrompt()
			if (library:ShowConfirm('Are you sure ?')) then clearPoints() end;
		end;

		function refreshPoints()
			if(#botPointsParts >= 2) then
				for i, v in next, botPointsLines do
					v:Destroy();
				end;

				table.clear(botPointsLines);

				local params = RaycastParams.new();
				params.FilterType = Enum.RaycastFilterType.Whitelist;
				params.FilterDescendantsInstances = isGaia and {workspace.Map} or {};

				for i = 1, #botPointsParts do
					local pointA, pointB = botPointsParts[i], botPointsParts[i + 1];

					if(pointA and pointB) then
						local line = Instance.new('Part');

						line.Size = Vector3.new(0.5, 0.5, (pointA.Position-pointB.Position).Magnitude);
						line.Parent = workspace;
						line.Material = Enum.Material.SmoothPlastic;
						line.Color = workspace:Raycast(pointA.Position, (pointB.Position - pointA.Position).Unit*line.Size.Z, params) and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(255, 255, 0);
						line.Anchored = true;
						line.CanCollide = false;
						line.CFrame = CFrame.new(pointA.Position, pointB.Position) * CFrame.new(0, 0, -(pointA.Position-pointB.Position).Magnitude/2);

						table.insert(botPointsLines, line);
					end;
				end;
			end;
		end;

		function clearPoints()
			for i, v in next, botPointsUI do
				for i2, v2 in next, v do
					if(typeof(v2) == 'Instance') then
						v2:Destroy();
					end;
				end;
			end;

			for i, v in next, botPointsLines do
				v:Destroy();
			end;

			for i, v in next, botPointsParts do
				v:Destroy();
			end;

			table.clear(botPointsLines);
			table.clear(botPointsParts);
			table.clear(botPoints);
			table.clear(botPointsUI);
		end;

		local canceled = false;

		function previewBot()
			if(#botPoints <= 0) then return end;
			canceled = false;

			local part = Instance.new('Part');
			part.Size = Vector3.new(5, 5, 5);
			part.Anchored = true;
			part.Shape =  Enum.PartType.Ball;
			part.Parent = workspace;
			part.Color = Color3.fromRGB(255, 0, 0);
			part.CanCollide = false;
			part.Material = Enum.Material.SmoothPlastic;
			part.CFrame = CFrame.new(botPoints[1].position);

			workspace.CurrentCamera.CameraSubject = part;

			local function startPointLoop(n1, n2, n3)
				for i = n1, n2, n3 or 1 do
					local v = botPoints[i];
					if(canceled) then break end;

					local tween = TweenService:Create(part, TweenInfo.new((part.Position - v.position).Magnitude / 150, Enum.EasingStyle.Linear), {
						CFrame = CFrame.new(v.position)
					});

					local completed = false;

					tween.Completed:Connect(function() completed = true end);
					tween:Play();

					repeat task.wait() until completed or canceled;
					local startedAt = tick();
					repeat task.wait() until tick() - startedAt > v.delay or canceled;

					if(canceled) then
						tween:Cancel();
					end;
				end;
			end;

			startPointLoop(1, #botPoints);
			startPointLoop(#botPoints, 1, -1);

			task.wait(1);
			part:Destroy();
			workspace.CurrentCamera.CameraSubject = LocalPlayer.Character;
		end;

		function cancelPreview()
			canceled = true;
		end;

		function saveBot()
			if(isfile(library.flags.fileName .. '.json')) then
				library:ShowMessage('A file with this name already exists!');
				return;
			end;

			local saveData = {};

			for i, v in next, botPoints do
				table.insert(saveData, {
					position = tostring(v.position),
					delay = v.delay,
					waitForTrinkets = v.waitForTrinkets
				});
			end;

			writefile(library.flags.fileName .. '.json', HttpService:JSONEncode(saveData));
			library:ShowMessage('Path has been saved under synapsex/workspace/' .. library.flags.fileName .. '.json');
		end;

		function loadBot()
			if (library:ShowConfirm('Are you sure ? (This will clear your current path)')) then
				xpcall(function()
					local suc, file = pcall(readfile, library.flags.fileName .. '.json');
					if(not suc) then
						return library:ShowMessage('File not found');
					end;

					local pointsData = HttpService:JSONDecode(file);

					clearPoints();

					for i, v in next, pointsData do
						v.position = Vector3.new(unpack(v.position:split(',')));
						addPoint(v.position, v.delay, v.waitForTrinkets);
					end;

					library:ShowMessage('Path loaded');
				end, function()
					library:ShowMessage('An error has occured!');
				end);
			end;
		end;

		function removeLastPoint()
			if(#botPoints <= 0) then return end;
			table.remove(botPoints, #botPoints);
			table.remove(botPointsParts, #botPointsParts):Destroy();

			if(#botPointsLines > 0) then
				table.remove(botPointsLines, #botPointsLines):Destroy();
			end;

			for i = 1, 3 do
				for i, v in next, table.remove(botPointsUI, #botPointsUI) or {} do
					if(typeof(v) == 'Instance') then
						v:Destroy();
					end;
				end;
			end;
		end;

		function startBot()
			local suc, file = pcall(readfile, library.flags.fileName .. '.json');

			if(not suc) then
				return library:ShowMessage('Failed to start bot, file not found');
			end;

			local pointsData = HttpService:JSONDecode(file);
			clearPoints();

			for i, v in next, pointsData do
				v.position = Vector3.new(unpack(v.position:split(',')));
				addPoint(v.position, v.delay, v.waitForTrinkets);
			end;

			MemStorageService:SetItem('botStarted', 'true');
			createBot(pointsData);
		end;

		function startBotPrompt()
			if (library:ShowConfirm('Are you sure you want to start the bot ?')) then
				startBot();
			end;
		end;

		library.OnLoad:Connect(function()
			if(MemStorageService:HasItem('botStarted')) then
				startBot();
			end;
		end);
	end;

	function noClip(toggle)
		if(not toggle) then return end;

		library.options.fly:SetState(true);
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
		until not library.flags.noClip;
		local Humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid");

		library.options.fly:SetState(false);
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
		until not library.flags.noInjuries;
	end;

	function noFog(toggle)
		if(not toggle) then return end;
		local oldFogStart, oldFogEnd = Lighting.FogStart, Lighting.FogEnd;

		repeat
			Lighting.FogStart = 99999;
			Lighting.FogEnd = 99999;
			task.wait();
		until not library.flags.noFog;

		Lighting.FogStart, Lighting.FogEnd = oldFogStart, oldFogEnd;
	end;

	function noClipXray(toggle)
		if(not toggle) then return end;

		repeat
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');

			if(rootPart) then
				local region = Region3.new(rootPart.Position - Vector3.new(1, 0, 1), rootPart.Position + Vector3.new(1, 0, 1));
				local parts = workspace:FindPartsInRegion3WithIgnoreList(region, {workspace.Live, workspace.MonsterSpawns})

				for i, v in next, noclipBlocks do
					noclipBlocks[i].Transparency = 0;
					table.remove(noclipBlocks, i);
				end;

				for _, part in next, parts do
					if(part.Transparency == 0) then
						table.insert(noclipBlocks, part);
						part.Transparency = 0.5;
					end;
				end;
			end;
			task.wait();
		until not library.flags.noClipXray;

		for i, v in next, noclipBlocks do
			noclipBlocks[i].Transparency = 0;
			table.remove(noclipBlocks, i);
		end;
	end;

	function speedHack(toggle)
		if(not toggle) then
			maid.speedHack = nil;
			maid.speedHackBV = nil;
			return;
		end;

		maid.speedHack = RunService.Heartbeat:Connect(function()
			local rootPart = LocalPlayer.Character and LocalPlayer.Character.PrimaryPart;
			if (not rootPart) then return end;

			local camera = workspace.CurrentCamera;
			if (not camera) then return end;
			if(library.flags.fly) then
				maid.speedHackBV = nil;
				return;
			end;

			maid.speedHackBV = (maid.speedHackBV and maid.speedHackBV.Parent and maid.speedHackBV) or Instance.new('BodyVelocity');

			maid.speedHackBV.Parent = rootPart;
			maid.speedHackBV.MaxForce = Vector3.new(100000, 0, 100000);
			maid.speedHackBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.speedhackSpeed);
		end);
	end;

	function fly(toggle)
		if(not toggle) then
			maid.fly = nil;
			maid.flyBV = nil;
			return;
		end;

		maid.fly = RunService.Heartbeat:Connect(function()
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if (not rootPart) then return end;

			local camera = workspace.CurrentCamera;
			if (not camera) then return end;

			maid.flyBV = (maid.flyBV and maid.flyBV.Parent and maid.flyBV) or Instance.new('BodyVelocity');

			maid.flyBV.Parent = rootPart;
			maid.flyBV.MaxForce = Vector3.new(math.huge, math.huge, math.huge);
			maid.flyBV.Velocity = camera.CFrame:VectorToWorldSpace(ControlModule:GetMoveVector() * library.flags.flySpeed);
		end);
	end;

	function antiFire(toggle)
		if(not toggle) then return end;

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
		until not library.flags.antiFire;
	end;

	function allowFood()
		if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('NoEat')) then
			LocalPlayer.Character.NoEat:Destroy();
		end;
	end;

	local oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;

	function fullBright(toggle)
		if(not toggle) then
			maid.fullBright = nil;
			Lighting.Ambient, Lighting.Brightness = oldAmbient, oldBritghtness;
			return
		end;

		oldAmbient, oldBritghtness = Lighting.Ambient, Lighting.Brightness;
		maid.fullBright = Lighting:GetPropertyChangedSignal('Ambient'):Connect(function()
			Lighting.Ambient = Color3.fromRGB(255, 255, 255);
			Lighting.Brightness = 1;
		end);
		Lighting.Ambient = Color3.fromRGB(255, 255, 255);
	end;

	function infiniteJump(toggle)
		if(not toggle) then return end;

		repeat
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if(rootPart and UserInputService:IsKeyDown(Enum.KeyCode.Space) and not chatFocused) then
				rootPart.Velocity = Vector3.new(rootPart.Velocity.X, library.flags.infiniteJumpHeight, rootPart.Velocity.Z);
			end;
			task.wait(0.1);
		until not library.flags.infiniteJump;
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

	function spamClick(toggle)
		if(not toggle) then
			maid.spamClick = nil;
			return
		end;

		local lastClick = tick();

		maid.spamClick = RunService.RenderStepped:Connect(function()
			if(tick() - lastClick < 0.13) then return end;
			if(not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild('CharacterHandler')) then return end;
			lastClick = tick();

			LocalPlayer.Character.CharacterHandler.Remotes.LeftClick:FireServer({math.random(1, 10), math.random()});
		end);
	end;

	function clickDestroy()
		if(Mouse.Target and not Mouse.Target:IsA('Terrain')) then
			Mouse.Target:Destroy();
		end;
	end;

	function instantLog()
		repeat
			task.wait();
		until LocalPlayer.Character and not LocalPlayer.Character:FindFirstChild('Danger');

		LocalPlayer:Kick('Logged Out Closing Roblox...');
		delay(5, function()
			game:Shutdown();
		end);
	end;

	function respawn()
		if (library:ShowConfirm('Are you sure you want to respawn ?')) then
			local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid');
			if(not humanoid) then return end;

			humanoid.Health = 0;
		end;
	end;

	function chatLoggerSetEnabled(state)
		chatLogger:SetVisible(state);
	end;

	function removeKillBricks(toggle)
		if(not toggle) then
			maid.removeKillBricks = nil;
		else
			maid.removeKillBricks = RunService.Heartbeat:Connect(function()
				local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
				if(not rootPart) then return end;

				local inDanger = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger');

				if(rootPart.Position.Y <= -550 and not library.flags.fly and inDanger) then
					library.options.fly:SetState(true);
					ToastNotif.new({
						text = 'You were about to die, so script automatically enabled fly to prevent you from dying :sungl:'
					});
				end;
			end);
		end;

		for i,v in next, killBricks do
			v.Parent = not toggle and workspace or nil;
		end;
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

	function attachToBack()
		local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		if(not rootPart) then return end;

		for i, v in next, Players:GetPlayers() do
			local plrRoot = v.Character and v.Character:FindFirstChild('HumanoidRootPart');
			if(not plrRoot or v == LocalPlayer) then continue end;

			if((plrRoot.Position - rootPart.Position).Magnitude <= 50) then
				rootPart.CFrame = CFrame.new(plrRoot.Position - plrRoot.CFrame.LookVector * 2, plrRoot.Position);
				break;
			end;
		end
	end;

	function disableAmbientColors(t)
		if(not t) then
			maid.disableAmbientColors = nil;
			task.wait();
			Lighting.areacolor.Enabled = true;
			return;
		end;

		maid.disableAmbientColors = RunService.Heartbeat:Connect(function()
			if(not Lighting:FindFirstChild('areacolor')) then return end;
			Lighting.areacolor.Enabled = false;
		end);
	end;

	function streamerMode(toggle)
		local defaultCharName;

		local function updateStreamerMode(value)
			local statGui = LocalPlayer:FindFirstChild('PlayerGui') and LocalPlayer.PlayerGui:FindFirstChild('StatGui');
			local container = statGui and statGui:FindFirstChild('Container');
			local characterName = container and container:FindFirstChild('CharacterName');
			local characterNameShadow = characterName and characterName:FindFirstChild('Shadow');

			if(not defaultCharName and characterName) then
				defaultCharName = characterName.Text;
			end;

			local leaderstats = LocalPlayer and LocalPlayer:FindFirstChild('leaderstats');
			local hidden =  leaderstats and leaderstats:FindFirstChild('Hidden');

			local deadContainer = statGui and statGui:FindFirstChildOfClass('TextLabel');

			if (hidden) then
				hidden.Value = value;
			end;

			if(characterName and characterNameShadow) then
				characterName.Text = value and "" or defaultCharName;
				characterNameShadow.Text = value and "" or defaultCharName;
			end;

			if(deadContainer) then
				deadContainer.Visible = not value;
			end;
		end;

		repeat
			updateStreamerMode(true)
			task.wait();
		until not library.flags.streamerMode;

		updateStreamerMode(false);
	end;

	function spellStacking(toggle)
		if(not toggle) then
			maid.spellStacking = nil;
			return;
		end;

		maid.spellStacking = RunService.RenderStepped:Connect(function()
			local Character = LocalPlayer.Character;
			if (not Character) then return end;

			local activeCast = Character:FindFirstChild('ActiveCast') or Character:FindFirstChild('VampiriusCast');
			local boosts = Character and Character:FindFirstChild('Boosts');

			if(activeCast) then
				activeCast:Destroy();
			end;

			if(boosts) then
				for i, v in next, boosts:GetChildren() do
					if(v.Name == "SpeedBoost" and v.Value <= 0) then
						v:Destroy();
					end;
				end;
			end;
		end);
	end;

	function antiHystericus(toggle)
		local antiHystericusList = {'NoControl', 'Confused'};
		if(not toggle) then return end;

		repeat
			task.wait();
			if(not LocalPlayer.Character) then continue end;

			removeGroup(LocalPlayer.Character, antiHystericusList);
		until not library.flags.antiHystericus;
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

	do
		Utility.listenToChildAdded(workspace, function(obj)
			if(obj.Name == 'PortableFurnace' and obj:IsA('Model')) then
				table.insert(allFurnaces, obj);
				obj.Destroying:Connect(function()
					table.remove(allFurnaces, table.find(allFurnaces, obj));
				end);
			end;
		end);
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

	function manaAdjust(toggle)
		if(not toggle) then
			if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Charge')) then
				dechargeMana();
			end;

			return;
		end;

		repeat
			task.wait();
			local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
			if(currentTool and spellValues[currentTool.Name] and library.flags.spellAdjust) then continue; end;

			chargeManaUntil(library.flags.manaAdjustAmount);
		until not library.flags.manaAdjust;
	end;

	function wipe()
		if (library:ShowConfirm('Are you sure you want to wipe your account ?')) then
			fallDamage:FireServer({math.random(), 3})
			task.wait(1);
			if(LocalPlayer.Character:FindFirstChild('Head')) then
				LocalPlayer.Character.Head:Destroy();
			end;
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

	function toggleMobEsp(toggle)
		if(not toggle) then
			maid.mobEsp = nil;
			mobEspBase:Disable();
			return;
		end;

		maid.mobEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
			debug.profilebegin('Mob Esp Update');
			mobEspBase:UpdateAll();
			debug.profileend();
		end);
	end;

	function toggleNpcEsp(toggle)
		if(not toggle) then
			maid.npcEsp = nil;
			npcEspBase:Disable();
			return;
		end;

		maid.npcEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
			debug.profilebegin('Npc Esp Update');
			npcEspBase:UpdateAll();
			debug.profileend();
		end);
	end;

	function toggleBagEsp(toggle)
		if(not toggle) then
			maid.bagEsp = nil;
			bagEspBase:Disable();
			return;
		end;

		maid.bagEsp = workspace.CurrentCamera:GetPropertyChangedSignal('CFrame'):Connect(function()
			debug.profilebegin('Bag Esp Update');
			bagEspBase:UpdateAll();
			debug.profileend();
		end);
	end;

	function toggleSpellAutoCast(toggle)
		if(not toggle) then
			maid.spellCast = nil;
			return;
		end;

		local lastCast = 0;

		maid.spellCast = RunService.RenderStepped:Connect(function()
			if(tick() - lastCast <= 2.5 and not library.flags.spellStacking) then return end;

			local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
			if(not currentTool) then return end;

			local amounts = spellValues[currentTool.Name];
			if(not amounts) then return end;

			local useSnap = library.flags[toCamelCase(currentTool.Name .. ' Use Snap')];
			amounts = amounts[useSnap and 2 or 1];

			local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
			if(not mana) then return end;

			if(mana.Value > amounts.min and mana.value < amounts.max) then
				lastCast = tick();
				if(useSnap) then
					LocalPlayer.Character.CharacterHandler.Remotes.RightClick:FireServer({math.random(1, 10), math.random()});
				else
					LocalPlayer.Character.CharacterHandler.Remotes.LeftClick:FireServer({math.random(1, 10), math.random()});
				end;
			end;
		end);
	end;

	function toggleSpellAdjust(toggle)
		if(not toggle) then return; end;

		repeat
			RunService.RenderStepped:Wait();

			local currentTool = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Tool');
			if(not currentTool) then continue; end;

			local amounts = spellValues[currentTool.Name];
			if(not amounts) then continue end;

			local useSnap = library.flags[toCamelCase(currentTool.Name .. ' Use Snap')];
			amounts = amounts[useSnap and 2 or 1];

			local amount = amounts.max - (amounts.max  - amounts.min) / 2;

			chargeManaUntil(amount);
		until not library.flags.spellAdjust;
	end;

	function goToGround()
		local params = RaycastParams.new();
		params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs, workspace.AreaMarkers};
		params.FilterType = Enum.RaycastFilterType.Blacklist;

		local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
		if (not rootPart) then return end;

		-- setclipboard(tostring(Character.HumanoidRootPart.Position));
		local floor = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), params);
		if(not floor) then return end;

		rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -(rootPart.Position.Y - floor.Position.Y) + 3, 0);
		-- rootPart.Velocity = Vector3.new(rootPart.Velocity.X, 0, rootPart.Velocity.Z);
	end;

	function pullToGround(t)
		if (not t) then
			maid.pullToGround = nil;
			return;
		end;

		local params = RaycastParams.new();
		params.FilterDescendantsInstances = {workspace.Live, workspace.NPCs, workspace.AreaMarkers};
		params.FilterType = Enum.RaycastFilterType.Blacklist;
		params.IgnoreWater = true;
		params.RespectCanCollide = true;

		maid.pullToGround = task.spawn(function()
			while true do
				task.wait(0.1);
				local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
				if (not rootPart) then continue end;

				local humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Humanoid');
				if (not humanoid) then continue end;

				if(humanoid.FloorMaterial ~= Enum.Material.Air) then continue; end;
				if (library.flags.fly or UserInputService:IsKeyDown(Enum.KeyCode.Space)) then continue; end;

				local floor = workspace:Raycast(rootPart.Position, Vector3.new(0, -1000, 0), params);
				if (not floor) then continue end;

				rootPart.CFrame = rootPart.CFrame * CFrame.new(0, -(rootPart.Position.Y - floor.Position.Y) + 3, 0);
				rootPart.Velocity = Vector3.zero;
			end;
		end);
	end;

	function setLocation()
		if (not library:ShowConfirm(string.format('Are you sure you want to tp to %s', library.flags.location))) then return end;

		local npc = spawnLocations[library.flags.location];
		local char = game.Players.LocalPlayer.Character;

		local con;
		con = RunService.Heartbeat:Connect(function()
			sethiddenproperty(LocalPlayer, 'MaxSimulationRadius', math.huge);
			sethiddenproperty(LocalPlayer, 'SimulationRadius', math.huge);
		end)

		dialog:FireServer({choice = 'Sure.'})
		for i = 1,10 do
			char:BreakJoints();
			task.wait();
			char:PivotTo(npc:GetPivot());
			char.HumanoidRootPart.CFrame = npc:GetPivot();

			task.wait(0.1);
			fireclickdetector(npc.ClickDetector);
			task.wait(0.2)
		end;

		con:Disconnect();
	end;

	function serverHop()
		if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Danger')) then
			repeat
				task.wait()
			until not LocalPlayer.Character:FindFirstChild('Danger');
		end;

		LocalPlayer:Kick('Server Hopping...');
		findServer();
	end;

	function satan(toggle)
		if (not toggle) then
			maid.satan = nil;

			if(LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')) then
				LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true);
			end;

			return;
		end;

		maid.satan = RunService.Heartbeat:Connect(function()
			if(not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChildWhichIsA('Humanoid')) then return end;

			LocalPlayer.Character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, false);
		end);
	end;

	function noStun(toggle)
		if (not toggle) then
			maid.noStun = nil;
			return;
		end;

		maid.noStun = RunService.Heartbeat:Connect(function()
			local character = LocalPlayer.Character;
			if (not character) then return end;

			if (character:FindFirstChild('Action')) then character.Action:Destroy() end;
			if (character:FindFirstChild('NoJump')) then character.NoJump:Destroy() end;
		end);
	end;

	function infMana(toggle)
		if (not toggle) then
			maid.infMana = nil;
			return;
		end;

		maid.infMana = RunService.Heartbeat:Connect(function()
			local mana = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('Mana');
			if (not mana) then return end;

			mana.Value = 100;
		end);
	end;

	function flyOwnership(toggle)
		if (not toggle) then
			maid.flyOwnership = nil;
			return;
		end;

		maid.flyOwnership = RunService.Heartbeat:Connect(function()
			local rootPart = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart');
			if (not rootPart) then return end;

			local bone = rootPart and rootPart:findFirstChild('Bone');

			if (bone and bone:FindFirstChild('Weld')) then
				bone.Weld:Destroy();
			end;
		end);
	end;

	function knockYourself()
		if (library:ShowConfirm('Are you sure you want to knock yourself ?')) then
			fallDamage:FireServer({math.random(), 1});
		end;
	end;

	local stringFormat = string.format;
	local bags = {};

	function autoPickupBag(toggle)
		if (not toggle) then
			maid.autoBagPickup = nil;
			return
		end;

		maid.autoBagPickup = RunService.Heartbeat:Connect(function()
			local rootPart = Utility:getRootPart();
			if (not rootPart) then return end;

			for _, bag in next, bags do
				local dist = (rootPart.Position - bag.Position).Magnitude;
				local range = bag.Name == 'ToolBag' and library.flags.bagPickupRange or library.flags.bagPickupRange * 2;
				if (dist > range) then continue end;

				task.spawn(function()
					firetouchinterest(bag, rootPart, 0);
					task.wait();
					firetouchinterest(bag, rootPart, 1);
				end);
			end;
		end);
	end;

	function EntityESP:Plugin()
		local holdingItem = self._player.Character and self._player.Character:FindFirstChildWhichIsA('Tool');
		local firstName = getPlayerStats(self._player);
		local manaAbilities = self._player.Character and self._player.Character:FindFirstChild('ManaAbilities');

		return {
			text = stringFormat(
				'\n[%s] [%s] [%s] [%s] %s',
				firstName,
				getPlayerClass(self._player),
				getPlayerRace(self._player),
				holdingItem and holdingItem.Name or 'None',
				manaAbilities and not manaAbilities:FindFirstChild('ManaSprint') and '[Day 0]' or ''
			);
		}
	end;

	local function initEspStuff()
		local damageIndicator = {};

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

				loadSound('IllusionistJoin.mp3');
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
						if (library.flags.artifactNotifier and (table.find(artifactsList, obj.Name) or obj:FindFirstChild('Artifact')) and not table.find(seen, obj.Name) and obj.Parent == backpack) then
							table.insert(seen, obj.Name);
							ToastNotif.new({
								text = string.format('%s has %s', player.Name, obj.Name)
							});
						end;

						if(obj.Name ~= 'Observe') then return end;
						addIllusionist(player);

						if(not library.flags.illusionistNotifier) then return end;
						print(player.Name, obj.Parent == character and 'in character' or 'in backpack');

						if(obj.Parent ~= backpack and not spectating) then
							spectating = true;
							loadSound('IllusionistSpectateStart.mp3');
							makeNotification('Spectate Alert', string.format('[%s] Started spectating', player.Name), true);

							if(library.flags.autoPanic and library.flags.autoPanicValues['Spectate']) then
								panic();
							end;
						end;
					end;

					local function onChildRemovedPlayer(obj)
						if(obj.Name ~= 'Observe' or not spectating) then return end;

						spectating = false;
						loadSound('IllusionistSpectateEnd.mp3');
						makeNotification('Spectate Alert', string.format('[%s] Stopped spectating', player.Name), true);
					end;

					Utility.listenToChildAdded(backpack, onChildAddedPlayer);
					Utility.listenToChildAdded(character, onChildAddedPlayer);
					character.ChildRemoved:Connect(onChildRemovedPlayer);

					local humanoid = character:WaitForChild('Humanoid');
					local head = character:WaitForChild('Head');

					local currentHealth = humanoid.Health;

					humanoid.HealthChanged:Connect(function(newHealth)
						if(newHealth < currentHealth and library.flags.damageIndicator and damageIndicator.new) then
							damageIndicator.new(head, currentHealth - newHealth);
						end;

						currentHealth = humanoid.Health;
					end);
				end;

				if(player.Character) then
					task.spawn(onCharacterAdded, player.Character);
				end;

				player.CharacterAdded:Connect(onCharacterAdded);

				if(string.find(moderatorIds, tostring(player.UserId)) or isInGroup(player, 4556484)) then
					moderatorInGame = true;
					allMods[player] = true;

					makeNotification('Mod Alert', string.format('[%s] Has joined your game.', player.Name), true);

					if(library.flags.autoPanic and library.flags.autoPanicValues['Mod Join']) then
						task.spawn(panic);
					end;

					loadSound('ModeratorJoin.mp3');
				end;

				if(table.find(blacklistedHouses, player:GetAttribute('LastName') or 'Unknown')) then
					makeNotification('Mudock Alert', string.format('[%s] Has joined your game', player.Name), true);
					mudockList[player] = true;

					if(library.flags.autoPanic and library.flags.autoPanicValues['Mudock Join']) then
						panic();
					end;
				end;
			end;

			local function onPlayerRemoving(player)
				if(allMods[player]) then
					moderatorInGame = false;
					allMods[player] = nil;
					loadSound('ModeratorLeft.mp3');
					makeNotification('Mod Alert', string.format('%s left the game', tostring(player)), true);
				end;

				if(illusionists[player]) then
					makeNotification('Illusionist', string.format('[%s] Has left your game', player.Name), true);
					loadSound('IllusionistLeft.mp3');
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

		if (library.flags.collectorAutoFarm) then
			warn('[Player ESP] Not turning off cause player has collector bot on');
			return;
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

		function getTrinketType(v) -- // This code is from the old source too lazy to remake it as this one works properly
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
			local specialInfo = getspecialinfo and getspecialinfo(v) or getproperties(v);
			local assetId = specialInfo and specialInfo.AssetId and specialInfo.AssetId:match('%d+') or 'NIL';

			if(ingredientsIds[assetId]) then
				return ingredientsIds[assetId];
			else
				id = id + 1;
				return string.format('Unknown %s', id);
			end;
		end;

		local objectsRaycastFilter = RaycastParams.new();
		objectsRaycastFilter.FilterType = Enum.RaycastFilterType.Whitelist;
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

		local function onMobAdded(object)
			task.wait(1);
			if (not object:FindFirstChild('MonsterInfo') or not object.MonsterInfo:FindFirstChild('MonsterType')) then
				return;
			end;

			local head = object:FindFirstChild('Head') or object.PrimaryPart;
			if (not head) then return end;

			local self = mobEspBase.new(head, object.MonsterInfo.MonsterType.Value);
			self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (object.Parent) then return end;
				self:Destroy();
			end));
		end;

		local function onNpcAdded(object)
			local head = object:FindFirstChild('Head') or object.PrimaryPart;
			if (not head) then return end;

			local self = npcEspBase.new(head, object.Name);
			self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
				if (object.Parent) then return end;
				self:Destroy();
			end));
		end;

		local function onBagAdded(object)
			if (object.Name ~= 'ToolBag' and object.Name ~= 'MoneyBag') then return end;

			table.insert(bags, object);

			local name = object:WaitForChild('BillboardGui', 1);
			name = name and name:WaitForChild('Tool', 1);
			name = name and name.Text;

			if(not name) then return end;

			local self = bagEspBase.new(object, name);
			self._maid:GiveTask(object:GetPropertyChangedSignal('Parent'):Connect(function()
				if(object.Parent) then return end;
				self:Destroy();
				table.remove(bags, table.find(bags, object));
			end));
		end;

		do -- // Damage Indicator
			damageIndicator.ClassName = 'DamageIndicator';
			damageIndicator.__index = damageIndicator;

			local function generateOffSet()
				local n = Random.new():NextNumber() * 2;
				if (Random.new():NextInteger(1, 2) == 1) then
					n = -n;
				end;

				return n;
			end;

			function damageIndicator.new(part, damage)
				local self = setmetatable({}, damageIndicator);
				self._maid = Maid.new();
				self._part = part;
				self._offset = Vector3.new(generateOffSet(), generateOffSet(), 0);

				self._gui = library:Create('ScreenGui', {
					Parent = game:GetService('CoreGui')
				});

				self._text = library:Create('TextLabel', {
					Parent = self._gui,
					Rotation = generateOffSet() * 5,
					Visible = true,
					TextColor3 = Color3.fromRGB(231, 76, 60),
					Text = '-' .. tostring(math.ceil(damage)),
					BackgroundTransparency = 1,
					TextStrokeTransparency = 0,
					TextSize = 10
				});

				self._maid:GiveTask(self._gui);

				self._maid:GiveTask(RunService.Heartbeat:Connect(function()
					self:Update();
				end));

				task.delay(2, function()
					self:Destroy();
				end);
			end;

			function damageIndicator:Update()
				local partPosition, visible = workspace.CurrentCamera:WorldToViewportPoint(self._part.Position + self._offset);
				partPosition = Vector2.new(partPosition.X, partPosition.Y);

				self._text.Visible = visible;
				self._text.Position = UDim2.new(0, partPosition.X, 0, partPosition.Y);
			end;

			function damageIndicator:Destroy()
				assert(self._maid);

				self._maid:Destroy();
				self._maid = nil;
			end;
		end;

		if(ingredientsFolder) then
			Utility.listenToChildAdded(ingredientsFolder, onChildAddedIngredient);
		end;

		Utility.listenToChildAdded(workspace, onChildAdded);
		Utility.listenToChildAdded(workspace.Live, onMobAdded);
		Utility.listenToChildAdded(workspace:FindFirstChild('NPCs') or Instance.new('Folder'), onNpcAdded);
		Utility.listenToChildAdded(workspace.Thrown, onBagAdded);
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

			if(boosts and library.flags.climbSpeed ~= 1) then
				climbBoost.Value = library.flags.climbSpeed;
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

	library.OnLoad:Connect(initEspStuff);
end;

function Utility:renderOverload(data)
	local misc = data.column1:AddSection('Misc');
	local trinketEsp = data.column2:AddSection('Trinkets');
	local ingredientEsp = data.column2:AddSection('Ingredients');

	local trinketsToggles = {};
	local ingrdientsToggles = {};

	data.espSettings:AddBox({
		text = 'ESP Search',
		skipflag = true,
		noload = true
	});

	local function createEspList(t, func)
		return function(toggle, ...)
			for i, v in next, t do
				v.visualize.Parent.Visible = toggle;
			end;

			func(toggle, ...);
		end;
	end;

	trinketEsp:AddToggle({
		text = 'Enable',
		flag = 'Trinket Esp',
		callback = createEspList(trinketsToggles, toggleTrinketEsp)
	}):AddSlider({text = 'Max Distance', flag = 'Trinket Esp Max Distance', value = 500, min = 10, max = 5000});
	trinketEsp:AddToggle({text = 'Show Distance', flag = 'Trinket Esp Show Distance'})

	ingredientEsp:AddToggle({
		text = 'Enable',
		flag = 'Ingredient Esp',
		callback = createEspList(ingrdientsToggles, toggleIngredientsEsp);
	}):AddSlider({text = 'Max Distance', flag = 'Ingredient Esp Max Distance', value = 500, min = 10, max = 5000});
	ingredientEsp:AddToggle({text = 'Show Distance', flag = 'Ingredient Esp Show Distance'});

	misc:AddDivider('Mobs');
	misc:AddToggle({
		text = 'Enable',
		flag = 'Mob Esp',
		callback = toggleMobEsp
	}):AddSlider({text = 'Max Distance', flag = 'Mob Esp Max Distance', value = 500, min = 10, max = 10000});
	misc:AddToggle({text = 'Show Distance', flag = 'Mob Esp Show Distance'});

	misc:AddDivider('NPC')
	misc:AddToggle({
		text = 'Enable',
		flag = 'Npc Esp',
		callback = toggleNpcEsp
	}):AddSlider({text = 'Max Distance', flag = 'Npc Esp Max Distance', value = 500, min = 10, max = 10000});
	misc:AddToggle({text = 'Show Distance', flag = 'Npc Esp Show Distance'});

	misc:AddDivider('Bags');
	misc:AddToggle({
		text = 'Enable',
		flag = 'Bag Esp',
		callback = toggleBagEsp
	}):AddSlider({text = 'Max Distance', flag = 'Bag Esp Max Distance', value = 500, min = 10, max = 10000});
	misc:AddToggle({text = 'Show Distance', flag = 'Bag Esp Show Distance'});

	-- local Colors = library:CreateWindow('Esp - Colors');
	-- local Toggles = library:CreateWindow('Esp - Toggles');
	-- local Sliders = data.Sliders;

	for i,v in next, Trinkets do
		table.insert(trinketsToggles, trinketEsp:AddToggle({text = v.Name, flag = string.format('Show %s', v.Name), state = true}):AddColor({flag = string.format('%s Color', v.Name)}));
	end;

	for i, v in next, Ingredients do
		table.insert(ingrdientsToggles, ingredientEsp:AddToggle({text = v, flag = string.format('Show %s', v), state = true}):AddColor({flag = string.format('%s Color', v)}));
	end;

	library.OnLoad:Connect(function()
		for i, v in next, trinketsToggles do
			v.visualize.Parent.Visible = false;
		end;

		for i, v in next, ingrdientsToggles do
			v.visualize.Parent.Visible = false;
		end;
	end);
end;

local window = library.window;
local column3 = window:AddColumn();

local Main = column1:AddSection('Main');
local AutoPanic = column1:AddSection('Auto Panic');
local Removals = column2:AddSection('Removals');
local Automation = column2:AddSection('Automation');
local Misc = column1:AddSection('Misc');
local NoClip = column3:AddSection('NoClip');
local Visuals = column3:AddSection('Visuals');
local Spell = column2:AddSection('Spells');
Bots = column3:AddSection('Bots');
local ManaViewer = column3:AddSection('Mana Viewer');

Main:AddToggle({text = 'Artifact Notifier', state = true});
Main:AddToggle({text = 'Illusionist Notifier', state = true});
Main:AddToggle({text = 'Silent Aim'});
Main:AddToggle({text = 'Spell Stack', callback = spellStack});
spellCounter = Main:AddLabel(string.format('Spell Counter: %d', tonumber(#queue)));
Main:AddBind({text = 'Spell Stack Keybind'});

NoClip:AddToggle({text = 'Xray', flag = 'No Clip Xray', callback = noClipXray});
NoClip:AddToggle({text = 'Enable', flag = 'No Clip', callback =  noClip}):AddList({
	text = 'Disable Event Types',
	flag = 'No Clip Disable Values',
	values = {'Disable On Water', 'Disable When Knocked'},
	multiselect = true
});

ManaViewer:AddToggle({text = 'Enable', flag = 'Mana Viewer', callback = manaViewer});
ManaViewer:AddToggle({text = 'Show Mana Helper', callback = manaHelper});
ManaViewer:AddToggle({text = 'Show Cast Zone', callback = showCastZone});
ManaViewer:AddToggle({text = 'Show Overlay', callback = showManaOverlay});
ManaViewer:AddBox({text = 'Overlay Url', callback = setOverlayUrl});

ManaViewer:AddSlider({text = 'Overlay Scale X', textpos = 2, min = 1, max = 1920});
ManaViewer:AddSlider({text = 'Overlay Scale Y', textpos = 2, min = 1, max = 1080});

ManaViewer:AddSlider({text = 'Overlay Offset X', textpos = 2, min = -1920, max = 1920});
ManaViewer:AddSlider({text = 'Overlay Offset Y', textpos = 2, min = -1080, max = 1080});

Main:AddToggle({text = 'AA Gun Counter', callback = aaGunCounter});
Main:AddToggle({text = 'Days Farm', callback = daysFarm}):AddSlider({
	text = 'Days Farm Auto Log Range',
	flag = 'Days Farm Range',
	min = 0,
	max = 3000,
	value = 500
});
Main:AddToggle({text = 'Satan', callback = satan});
Main:AddBind({text = 'Attach To Back', mode = 'hold', callback = attachToBack});
Main:AddButton({text = 'Respawn', callback = respawn});
Main:AddButton({text = 'Wipe', callback = wipe});
Main:AddList({text = 'Location', values = {}})
Main:AddButton({text = 'Set Location (RISKY)', callback = setLocation})

library.OnLoad:Connect(function()
	for _, npc in next, workspace.NPCs:GetChildren() do
		if (npc.Name == 'Inn Keeper') then
			local location = npc:FindFirstChild('Location');
			library.options.location:AddValue(location.Value);
			spawnLocations[location.Value] = npc;
		end;
	end;
end);

if (isGaia) then
	Main:AddButton({text = 'Knock Yourself', callback = knockYourself});
	Main:AddToggle({text = 'Knocked Ownership', callback = flyOwnership});
end;

Main:AddToggle({text = 'Temp Lock(Hide Trinkets)', flag = 'Temperature Lock', callback = temperatureLock});
Main:AddButton({text = 'Allow Food', callback = allowFood});
Main:AddButton({text = 'Server Hop', callback = serverHop});

Main:AddToggle({text = 'Mana Adjust', callback = manaAdjust}):AddSlider({flag = 'Mana Adjust Amount', min = 10, max = 100}):AddBind({
	callback = function() library.options.manaAdjust:SetState(not library.flags.manaAdjust) end,
	flag = 'manaAdjustBind'
})

Main:AddToggle({text = 'Speed Hack', flag = 'Toggle Speed Hack', callback = speedHack}):AddSlider({flag = 'SpeedHack Speed', min = 16, max = 250}):AddBind({
	callback = function() library.options.toggleSpeedHack:SetState(not library.flags.toggleSpeedHack) end,
	flag = 'toggleSpeedHackBind'
});

Main:AddToggle({text = 'Fly', callback = fly}):AddSlider({flag = 'Fly Speed', min = 16, max = 250}):AddBind({
	callback = function() library.options.fly:SetState(not library.flags.fly) end,
	flag = 'toggleFlyBind'
});

Main:AddToggle({text = 'Infinite Jump', callback = infiniteJump}):AddSlider({flag = 'Infinite Jump Height', min = 50, max = 250}):AddBind({
	callback = function() library.options.infiniteJump:SetState(not library.flags.infiniteJump) end,
	flag = 'infiniteJumpBind'
});


Main:AddToggle({text = 'Chat Logger', callback = chatLoggerSetEnabled});
Main:AddToggle({text = 'Chat Logger Auto Scroll'})
Main:AddToggle({text = 'Spell Stacking', callback = spellStacking});

Removals:AddToggle({text = 'Remove Kill Bricks', callback = removeKillBricks});
Removals:AddToggle({text = 'Anti Hystericus', callback = antiHystericus});
Removals:AddToggle({text = 'Anti Fire', callback = antiFire});
Main:AddToggle({text = 'No Stun', callback = noStun});
Removals:AddToggle({text = 'No Mental Injuries'});
Removals:AddToggle({text = 'No Fall Damage'});
Removals:AddToggle({text = 'No Injuries', callback = noInjuries});

Automation:AddToggle({text = 'Bag Auto Pickup', callback = autoPickupBag}):AddSlider({text = 'Bag Pickup Range', min = 10, max = 90, value = 90});
Automation:AddToggle({text = 'Auto Pickup', callback = autoPickup});
Automation:AddToggle({text = 'Auto Pickup Ingredients', callback = autoPickupIngredients});
Automation:AddToggle({text = 'Auto Bard'});

buildAutoPotion(Automation);
buildAutoCraft(Automation);

Automation:AddToggle({text = 'Auto Click', callback = spamClick});
Automation:AddToggle({text = 'Auto Smelt', callback = autoSmelt});
Automation:AddToggle({text = 'Auto Sell', callback = autoSell}):AddList({
	values = {'Scrolls', 'Gems', 'Swords'},
	flag = 'Auto Sell Values',
	multiselect = true
})

AutoPanic:AddToggle({text = 'Enable', flag = 'Auto Panic'}):AddList({
	text = 'Event Types',
	values = {'Spectate', 'Mod Join', 'Mudock Join'},
	flag = 'Auto Panic Values',
	multiselect = true
});

Visuals:AddToggle({text = 'No Fog', callback = noFog});
Visuals:AddToggle({text = 'Fullbright', callback = fullBright});
Visuals:AddToggle({text = 'Disable Ambient Color', callback = disableAmbientColors});
Visuals:AddToggle({text = 'Damage Indicator'});

if (isGaia) then
	local triggers = workspace.MonsterSpawns.Triggers;
	local triggeredLocations = {
		['Crypt'] = triggers.CryptTrigger.LastSpawned,
		['Castle Rock'] = triggers.CastleRockSnake.LastSpawned,
		['Snake Pit'] = triggers.MazeSnakes.LastSpawned,
		['Sunken Passage'] = triggers.evileye1.LastSpawned,
	};

	local function formatTime(seconds)
		local minutes = math.floor(seconds / 60);
		local hours = math.floor(minutes / 60);
		local days = math.floor(hours / 24);
		local formattedTime = '';

		if days > 0 then
			formattedTime = formattedTime .. days .. 'd ';
			hours = hours % 24;
		end;

		if hours > 0 then
			formattedTime = formattedTime .. hours .. 'h ';
			minutes = minutes % 60;
		end;

		if minutes > 0 then
			formattedTime = formattedTime .. minutes .. 'm';
			seconds = seconds % 60;
		end;

		return formattedTime;
	end;

	local function convertTime(dateTime)
		return os.time({year=dateTime.Year,month=dateTime.Month,day=dateTime.Day,hour=dateTime.Hour,min=dateTime.Minute,sec=dateTime.Second})
	end;

	for name, lastSpawned in next, triggeredLocations do
		local label = Misc:AddLabel('');

		local function onLastSpawnedChanged()
			if (lastSpawned.Value == 0) then
				label.Text = string.format('%s - Never taken', name);
				return;
			end;

			local lastSpawnedLocal = DateTime.fromUnixTimestamp(lastSpawned.Value):ToLocalTime()
			local currentTime = DateTime.now():ToLocalTime()

			local diff = os.difftime(convertTime(currentTime),convertTime(lastSpawnedLocal))
			label.Text = string.format('%s - %s ago', name, formatTime(diff));
		end;

		library.OnLoad:Connect(function()
			lastSpawned:GetPropertyChangedSignal('Value'):Connect(onLastSpawnedChanged);

			task.spawn(function()
				while true do
					onLastSpawnedChanged();
					task.wait(60);
				end;
			end);
		end);
	end;
end;

Misc:AddSlider({text = 'Climb Speed', min = 1, max = 10, textpos = 2});

Misc:AddBox({text = 'Spectate Player', callback = spectatePlayer});

Misc:AddToggle({text = 'Inf Mana (Client Side)', callback = infMana});
Misc:AddToggle({text = 'Use Alt Manager To Block'});
Misc:AddToggle({text = 'Max Zoom', callback = maxZoom});
Misc:AddToggle({text = 'Streamer Mode', callback = streamerMode});

Misc:AddBind({text = 'Click Destroy', callback = clickDestroy});
Misc:AddBind({text = 'Instant Log', nomouse = true, key = Enum.KeyCode.Plus, callback = instantLog});
Misc:AddBind({text = 'Go To Ground', callback = goToGround, mode = 'hold'})
Misc:AddToggle({text = 'Pull To Ground', callback = pullToGround, tip = 'Will pull you to the ground if you fly'})

Spell:AddToggle({text = 'Anti Backfire'});
Spell:AddToggle({text = 'Spell Adjust', callback = toggleSpellAdjust})
Spell:AddToggle({text = 'Auto Cast', callback = toggleSpellAutoCast})

for i, v in next, spellValues do
	if(v[2]) then
		Spell:AddToggle({
			text = i .. ' - Use Snap',
			flag = i .. ' Use Snap',
			state = true
		});
	end;
end;

if(isGaia) then
	Bots:AddToggle({text = 'Scroom Bot', callback = scroomBot});
	Bots:AddToggle({text = 'Scroom Bot Grip Mode'});
	Bots:AddList({flag = 'Scroom Bot Target Player', playerOnly = true});

	Bots:AddToggle({text = 'Gacha Bot', callback = gachaBot});
	Bots:AddToggle({text = 'Blacksmith Bot', callback = blackSmithBot});
	Bots:AddToggle({text = 'Auto Sell', flag = 'Blacksmith Bot Auto Sell'});
else
	Bots:AddToggle({text = 'Show Pickup Order UI', callback = showCollectorPickupUI});
	Bots:AddToggle({text = 'Roll Out Of FF'});
	Bots:AddToggle({text = 'Collector Auto Farm', callback = collectorAutoFarm});
	Bots:AddSlider({text = 'Collector Bot Wait Time', value = 12, min = 8, max = 60});

	Bots:AddBox({text = 'Webhook Url'});
end;

Bots:AddToggle({text = 'Automatically Rejoin', state = true});
Bots:AddToggle({text = 'Skip Illusionist Server'});
Bots:AddDivider('Custom Bots');

Bots:AddToggle({text = 'Dont Pickup Phoenix Down'});
Bots:AddToggle({text = 'Dont Pickup Scrolls'});

Bots:AddSlider({value = 200, min = 100, max = 1000, textpos = 2, text = 'Player Range Check'});

Bots:AddButton({text = 'Add Point', callback = addPoint});
Bots:AddButton({text = 'Clear Points', callback = clearPointsPrompt});
Bots:AddButton({text = 'Remove Last Point', callback = removeLastPoint});
Bots:AddButton({text = 'Preview Bot', callback = previewBot})
Bots:AddButton({text = 'Cancel Preview', callback = cancelPreview})
Bots:AddButton({text = 'Save Bot', callback = saveBot});
Bots:AddButton({text = 'Load Bot', callback = loadBot});
Bots:AddButton({text = 'Start Bot', callback = startBotPrompt});

Bots:AddBox({text = 'File Name'});
Bots:AddDivider('Custom Bots Settings');
