--local path = game:GetService("Players").wingensh.Backpack.Suke.FruitModel -- Fruitmodel...

local Kages = {'Shadows Grasp', 'Shadow Trap', "Sillhouette's Assault"}
local Kage = tostring(game:GetService('Players').LocalPlayer.Name).."'s Sillhouette"
local Kage_char = nil
local blocking = tick()
local Cooldowns = {
	Hand = tick(),
	Trap = tick(),
	Kage = tick()
}
local function Fireskill(skill:number,cfrem)
	if Kages[skill] then
		local args = {
			[1] = Kages[skill],
			[2] = cfrem, -- cframe
		}
		game:GetService("ReplicatedStorage").Events.Skill:InvokeServer(unpack(args))
	end
end
local function Block()
	local args = {
		[1] = true,
		[2] = "Melee",
		[3] = true
	}
	game:GetService("ReplicatedStorage").Events.Block:InvokeServer(unpack(args))
end
local function UnBlock()
	local args = {
		[1] = false,
		[2] = "Melee"
	}
	game:GetService("ReplicatedStorage").Events.Block:InvokeServer(unpack(args))
end

--//

local Player = game:GetService'Players'.LocalPlayer;

local JumpHeight,XOffset,Pos,YNew = 100, 0, Player.Character.HumanoidRootPart.Position, 100

function Action(Object, Function) if Object ~= nil then Function(Object); end end

local char = Player.Character
local rp = char.HumanoidRootPart

local floatmode, anchorrp, isboss = true,true, false
task.spawn(function()
	while true do
		if floatmode == true then
			if rp.Position.Y < Pos.Y + YNew then
				rp.Anchored = false
				Action(Player.Character.Humanoid, function(self)
					Action(self.Parent.HumanoidRootPart, function(self)
						self.Velocity = Vector3.new(XOffset, JumpHeight, 0);
					end)
				end)
			else
				if anchorrp == true then
					rp.Anchored = true
				end
			end
		else
			rp.Anchored = false
		end
		wait(0.5)
	end
end)

local sus = game:GetService("Workspace").Islands:FindFirstChild('Sky Islands')

local IsFree = true

local function WalkHumanoid(humanoid:Humanoid, startGoal:Vector3, endGoal:Vector3, target)
	IsFree = false	
	anchorrp = false
	floatmode = false
	task.spawn(function()
		repeat
			wait(2)
			Action(Player.Character.Humanoid, function(self)
				Action(self.Parent.HumanoidRootPart, function(self)
					self.Velocity = Vector3.new(0, JumpHeight*1.1, 0);
				end)
			end)
			if math.fmod(tonumber(game:GetService("ReplicatedStorage").Matchinfo.wave.Value),5) == 0 then
				if XOffset == 0 then
					XOffset = 50
				else
					XOffset = -XOffset
				end
			else
				XOffset = 0
			end
		until IsFree == true
	end)
	repeat 
		wait(1)
		if target:FindFirstChild('HumanoidRootPart') then
			humanoid:MoveTo(endGoal)
			print('walking to')
			local cPos = rp.Position
			local vPos = target:FindFirstChild('HumanoidRootPart').Position
			if (vPos - cPos).Magnitude <= 150 then
				for o,c in pairs(Cooldowns) do
					if o ~= 'Kage' then
						if (tick() - c) >= 5 then
							Cooldowns[o] = tick()
							if o == 'Hand' then
								UnBlock()
								Fireskill(1,CFrame.new(vPos))
								wait(1)
								Block()
							else
								UnBlock()
								Fireskill(2,CFrame.new(vPos))
								wait(1)
								Block()
							end
						end
					end
				end
			end
		end
	until not target or not (target and target:FindFirstChild('HumanoidRootPart')) or (target and target:FindFirstChild('Humanoid') and target:FindFirstChild('Humanoid').Health <= 0)
	anchorrp = true
	IsFree = true
	-- setting up path properties
	print('end')
end

local a = 'Dungeon Gun User'
task.spawn(function()
	local isfinding = false
	local npcs = game:GetService("Workspace").NPCs
	
	local newround = false
	local newroundtick = tick()
	local cacd = tick()
	local waittime = 60
	npcs.ChildAdded:Connect(function(c)
		if (tick() - cacd) >= 10 then
			if c.Name ~= Kage then
				cacd = tick()
				wait(1)
				newround = true
				newroundtick = tick()
			end
		end
	end)
	
	while true do
		game:GetService('RunService').Heartbeat:Wait()
		if newround == true then
			IsFree = true
			floatmode = false
			newround = false
			newroundtick = tick()
			waittime = 45
			anchorrp = true
			task.spawn(function()
				wait(2)
				floatmode = true
			end)
		else
			if isfinding == true then
				for i,v in pairs(npcs:GetChildren()) do
					if v.Name ~= Kage then
						local tarrp = v:FindFirstChild('HumanoidRootPart')
						if v:FindFirstChild('Humanoid') and tarrp and v:FindFirstChild('Humanoid').Health > 0 then
							local vPos = tarrp.Position
							local cPos = rp.Position
							if (vPos - cPos).Magnitude <= 150 then
								print('Killin')
								for o,c in pairs(Cooldowns) do
									if o ~= 'Kage' then
										if (tick() - c) >= 5 then
											Cooldowns[o] = tick()
											if o == 'Hand' then
												UnBlock()
												Fireskill(1,CFrame.new(vPos))
												wait(1)
												Block()
											else
												UnBlock()
												Fireskill(2,CFrame.new(vPos))
												wait(1)
												Block()
											end
										end
									end
								end
							else
								floatmode = false
								UnBlock()
								print('walking to')
								local newpos = Vector3.new(vPos.X,cPos.Y,vPos.Z)
								task.spawn(WalkHumanoid,char.Humanoid, cPos, newpos, v)
								if v and v:FindFirstChild('Humanoid') then
									repeat
										if (vPos - cPos).Magnitude <= 150 then
											for o,c in pairs(Cooldowns) do
												if o ~= 'Kage' then
													if (tick() - c) >= 5 then
														Cooldowns[o] = tick()
														if o == 'Hand' then
															UnBlock()
															Fireskill(1,CFrame.new(vPos))
															wait(1)
															Block()
														else
															UnBlock()
															Fireskill(2,CFrame.new(vPos))
															wait(1)
															Block()
														end
													end
												end
											end
										end
										wait(1)
									until not v or (v and v:FindFirstChild('Humanoid') and v:FindFirstChild('Humanoid').Health == 0) or (v and not v:FindFirstChild('Humanoid'))
									floatmode = false
								end
							end
						end
					end
				end
				isfinding = false
			else
				for i,v in pairs(npcs:GetChildren()) do
					if v.Name ~= Kage then
						local tarrp = v:FindFirstChild('HumanoidRootPart')
						if v:FindFirstChild('Humanoid') and tarrp then
							local vPos = tarrp.Position
							local cPos = rp.Position
							floatmode = true
							if math.abs(vPos.X - cPos.X) <= 10 and math.abs(vPos.Z - cPos.Z) <= 10 then
								waittime = 45
								wait(1)
								print('Casting Spell')
								for o,c in pairs(Cooldowns) do
									if o ~= 'Kage' then
										if (tick() - c) >= 5 then
											Cooldowns[o] = tick()
											if o == 'Hand' then
												UnBlock()
												Fireskill(1,CFrame.new(vPos))
												wait(1)
												Block()
												break
											else
												UnBlock()
												Fireskill(2,CFrame.new(vPos))
												wait(1)
												Block()
												break
											end
										end
									end
								end
								print('Done Casting Spell')
							else
								print('Checking If New round or not')
								if (tick() - newroundtick) >= waittime then
									print('out of time')
									local hasattacker,hasmob = false, false
									for o,c in pairs(npcs:GetChildren()) do
										if c.Name ~= Kage then
											if c.Name ~= 'Dungeon Gun User' then
												hasattacker = true
												hasmob = true
												break
											else
												hasmob = true
											end
										end
									end
									if hasattacker == true then
										print('retry')
										newroundtick = tick()
										waittime = 5
									else
										if hasmob == true then
											print('find')
											isfinding = true
										else
											print('newround')
											newround = tick()
										end
										break
									end
								end
							end
						end

					end
				end
			end
			if not npcs:FindFirstChild(Kage) and (tick() - Cooldowns.Kage) >= 10 then
				Cooldowns.Kage = tick()
				UnBlock()
				Fireskill(3,CFrame.new(Pos))
				wait(1)
				if npcs:FindFirstChild(Kage) then
					Kage_char = npcs:FindFirstChild(Kage)
				else
					Kage_char = nil
				end
				Block()
			end
		end
	end
end)
