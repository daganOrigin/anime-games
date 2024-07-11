local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local signal = require(script.Parent.Parent.Parent.Utility.sleitnick.signal)
local flags = require(script.Parent.Flags)
--local trove = require(script.Parent.Parent.Parent.Utility.sleitnick.trove)
local validation = require(script.Parent.Validation)
local safePlayerAdded = require(script.Parent.Parent.Parent.Utility.safePlayerAdded)
local types = require(script.Parent.Types)

local StateProfiles = {}

local machine = {}
machine.__index = machine

function machine.new(player)
	local self = setmetatable({
		flag = {
			old = flags.idle,
			latest = flags.idle,
			timestamp = tick(),
		},
		changed = signal.new(),
		_playerRef = player,
	}, machine)

	return self
end

function machine:_canChangeState(state: string)
	local flag: types.Flag = self.flag
	local validFlag = flags[state]

	if not validFlag then
		warn(`"{state}" isn't defined in the flag list`)
		return false
	end

	if state == flag.latest then
		--warn(`attempt to change the current state to the same state`)
		return false
	end
	
	-- this will check if the current state has transitions
	local validationTbl = validation[flag.latest]
	if not validationTbl then
		warn(`it seems you forgot to define "{flag.latest}" in the validation tbl.`)
		return false
	end
	
	-- this will check if the state we want to change to
	-- is available as a transition for the current state "flag.latest"
	
	if not validationTbl[state] then
		--warn(`cannot change state because {flag.latest} doesn't accept a transition to "{state}" while active`);
		--warn(`consider adding "{state}" in {flag.latest} validation table.`)
		return false
	end

	return true
end

function machine:getState(): string
	return self.flag.latest
end

function machine:changeState(flag: string, duration: number?): boolean
	if not self:_canChangeState(flag) then
		--warn(`unable to change {player.Name} state`)
		return false
	end

	--self:_handleExitLogic(self.flag)

	local newFlag = {
		old = self.flag.latest,
		latest = flag,
		timestamp = duration and tick() + duration or 0,
	}

	self.flag = newFlag
	self.changed:Fire(newFlag.old, newFlag.latest) -- might be replaced by unreliable remote event

	--self:_handleEntryLogic(newFlag)

	return true
end

function machine:destroy()
	self.changed:Destroy()
	StateProfiles[self._playerRef] = nil
	table.clear(self)
end

safePlayerAdded(function(player)
	StateProfiles[player] = machine.new(player)
end)

Players.PlayerRemoving:Connect(function(player)
	local player_fsm = StateProfiles[player]
	--player_fsm:changeState()
	player_fsm:destroy()
end)

RunService.Heartbeat:Connect(function()
	for player, tbl: types.PlayerMachine in StateProfiles do
		local flag = tbl.flag
		
		if flag.latest == flags.idle or flag.timestamp <= 0 then
			continue
		end

		local now: number = tick()

		if now >= flag.timestamp then
			-- this will revert the state
			tbl:changeState(flag.old)
		end
	end
end)

return StateProfiles :: types.StateProfiles
