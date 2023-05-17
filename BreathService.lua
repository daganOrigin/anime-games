--[[
	A service to work with the "breathing" mechanic in other scripts
	
	by blisson
]]

type subjectType = {
	OxygenLevel: NumberValue,
	State: IntValue,
	Time: number,
	Locked: boolean,
}

local BREATH_IN_RATE = 0.5
local BREATH_OUT_RATE = 0.3
local LOCK_COOLDOWN = 0.3

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(game.ServerScriptService.Shared.DataManager)
local Net = require(ReplicatedStorage.RbxUtil.Net)

local States = {
	idle = 0,
	isBreathing = 1,
}

local Breath = {
	subjects = {},
}

--[[
	will stop breathing from changing.
	this is called after a skill is used.
	meant to prevent the player from quickly spamming skills by not letting go of the charge key.
	before the lock was implemented you could go from 50 oxygen to 60-70 too quickly.
	lock is unlocked automatically after the cooldown expires.
	you can make use of "forceChangeBool" if you want to bypass the lock.
]]
function Breath:lock(player, forceChangeBool: boolean?)
	local subject: subjectType = self.subjects[player]
	if subject ~= nil then
		subject.Locked = forceChangeBool or true
	end
end

function Breath:AddOxygenLevel(player: Player, amount: number)
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("Invalid Player Object")
		return 0
	end
	local subject: subjectType = self.subjects[player]
	if subject ~= nil then
		local data = DataManager:WaitAndGetData(player)
		
		if not data then
			warn("Failed to retrieve data in " .. script:GetFullName())
			return 0
		end
		
		local oxygenLevel = subject.OxygenLevel
		
		local breathCap = data.Gameplay.BreathCap
		oxygenLevel.Value = math.clamp(oxygenLevel.Value + amount, 0, breathCap)
	end
end

function Breath:GetOxygenLevel(player: Player): number
	if not player or typeof(player) ~= "Instance" or not player:IsA("Player") then
		warn("Invalid Player Object")
		return 0
	end
	local subject: subjectType = self.subjects[player]
	if subject ~= nil then
		return subject.OxygenLevel.Value
	end
	return 0
end

--[[
	if there is some sort of breathing mastery that makes breathing faster, this is where we add changes
	instead of using the constant variables, we have to retrieve the player's data and use whatever in there
]]

--[[
	this could be a better replacement for "lock"
	it's an attempt to know if the player used a skill based on timing and other variables
	
	local lastOxygenLevel = 100
	local currentOxygenLevel = 50
	
	-- player most likely used a skill
	if currentOxygenLevel/lastOxygenLevel < 0.5 and timeStamp < 0.1 then
		-- add skill_use delay here
	end
]]

function Breath:HeartbeatUpdate(dt)
	for player, subject: subjectType in self.subjects do
		local oxygenLevel = subject.OxygenLevel
		local state = subject.State
		
		if subject.Locked == true and tick() - subject.Time < LOCK_COOLDOWN then
			continue
		end
		
		subject.Locked = false
		subject.Time = tick()
		
		if state.Value == States.idle then
			-- remove remaining oxygen
			self:AddOxygenLevel(player, -BREATH_OUT_RATE)
		elseif state.Value == States.isBreathing then
			-- add oxygen
			self:AddOxygenLevel(player, BREATH_IN_RATE)
		end
		
		print(self:GetOxygenLevel(player))
	end
end

function Breath:Init()
	local function CreateSubjectProfile(Player)
		if not self.subjects[Player] then
			self.subjects[Player] = {
				OxygenLevel = Instance.new("NumberValue"),
				State = Instance.new("IntValue"),
				Locked = false,
				Time = tick(),
			}
			
			local subject = self.subjects[Player]
			
			local Oxygen = subject.OxygenLevel
			Oxygen.Name = "Oxygen"
			Oxygen.Parent = Player
		end
	end
	
	for _, Player in Players:GetPlayers() do
		CreateSubjectProfile(Player)
	end
	
	Players.PlayerAdded:Connect(CreateSubjectProfile)
	Players.PlayerRemoving:Connect(function(Player)
		self.subjects[Player] = nil
	end)
	
	game:GetService("RunService").Heartbeat:Connect(function(dt)
		self:HeartbeatUpdate(dt)
	end)
	
	Net:Connect("Breath", function(player, trigger)
		local subject: subjectType = self.subjects[player]
		if subject ~= nil then
			local state = subject.State
			if trigger then
				state.Value = States.isBreathing
			else
				state.Value = States.idle
			end
		end
	end)
	
	local SkillUsed = Net:RemoteEvent("SkillUsed")
	
	Net:Connect("TakeSomeBreath", function(player)
		self:AddOxygenLevel(player, -30)
		SkillUsed:FireClient(player)
		Breath:lock(player)
	end)
	
	Net:Connect("TakeMassiveBreath", function(player)
		self:AddOxygenLevel(player, -50)
		SkillUsed:FireClient(player)
		Breath:lock(player)
	end)
end

return Breath
