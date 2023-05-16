--[[

	A service to work with the "breathing" mechanic in other scripts
	
	 ::: this service provides a basic state handling to prevent other scripted-events from overlapping (will get removed at some point)
	
]]

type subjectType = {
	OxygenLevel: NumberValue,
	State: IntValue,
}

local BREATH_IN_RATE = 1
local BREATH_OUT_RATE = 3


local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataManager = require(game.ServerScriptService.Shared.DataManager)

local Remotes = ReplicatedStorage.Remotes
local BreathRemote = Remotes.Breath

-- this service already has a state machine, but it's bound to change once we make a universal one to handle all the states
local States = {
	idle = 0,
	isBreathing = 1,
}

local Breath = {
	subjects = {},
}

function Breath:AddOxygenLevel(player: Player, amount: number)
	if not player or not player:IsA("Player") then
		warn("Invalid player object")
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

function Breath:GetPreciseOxygenLevel(player: Player): number
	if not player or not player:IsA("Player") then
		warn("Invalid player object")
		return 0
	end
	local subject: subjectType = self.subjects[player]
	if subject ~= nil then
		return subject.OxygenLevel.Value
	end
	return 0
end

function Breath:GetOxygenLevel(player: Player): number
	return math.round(self:GetPreciseOxygenLevel(player))
end

--[[
	if there is some sort of breathing mastery that makes breathing faster, this is where we add changes
	instead of using the constant variables, we have to retrieve the player's data and use whatever in there
]]
function Breath:HeartbeatUpdate(dt)
	for player, subject: subjectType in self.subjects do
		local oxygenLevel = subject.OxygenLevel
		local state = subject.State
		if state.Value == States.idle then
			-- remove remaining oxygen
			self:AddOxygenLevel(player, -BREATH_OUT_RATE)
		elseif state.Value == States.isBreathing then
			-- add oxygen
			self:AddOxygenLevel(player, BREATH_IN_RATE)
		end
	end
end

function Breath:Init()
	local function CreateSubjectProfile(Player)
		if not self.subjects[Player] then
			self.subjects[Player] = {
				OxygenLevel = Instance.new("NumberValue"),
				State = Instance.new("IntValue"),
			}
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
	
	--[[
		when InputBegan trigger == true
		when InputEnded trigger == false
	]]
	BreathRemote.OnServerEvent:Connect(function(player, trigger)
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
end

return Breath
