local RunService = game:GetService("RunService")

local flags = require(script.Parent.Flags)
local signal = require(script.Parent.Parent.Parent.Utility.sleitnick.signal)
local trove = require(script.Parent.Parent.Parent.Utility.sleitnick.trove)
local validation = require(script.Parent.Validation)
local types = require(script.Parent.Types)

local player = game:GetService("Players").LocalPlayer

local machine = {}
machine.__index = machine

function machine.new()
	local cleaner = trove.new()
	
	local self = {
		flag = {
			old = flags.idle,
			latest = flags.idle,
			timestamp = time(),
		},
		--states = table.freeze(flags),
		changed = cleaner:Add(signal.new(), "Destroy"),
		_trove = cleaner,
	}

	setmetatable(self, machine)
	
	cleaner:Add(RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end))
	
	return self
end

function machine:_canChangeState(state: string)
	local flag: types.Flag = self.flag
	local validFlag = flags[state]
	
	if not validFlag then
		warn(`sorry but "{state}" isn't defined in the flag list`)
		return false
	end
	
	if state == flag.latest then
		--warn(`attempt to change the current state to the same state`)
		return false
	end
	
	local validationTbl = validation[flag.latest]
	if not validationTbl then
		warn(`it seems you forgot to define "{flag.latest}" in the validation tbl.`)
		return false
	end
	
	if not validationTbl[state] then
		--warn(`cannot change state because {flag.latest} doesn't accept a transition to "{state}" while active`);
		--warn(`consider adding "{state}" in {flag.latest} validation table.`)
		return false
	end
	
	return true
end

function machine:getState()
	return self.flag.latest
end

function machine:changeState(flag: string, duration: number?)
	if not self:_canChangeState(flag) then
		--warn(`unable to change state`)
		return false
	end
	
	self:_handleExitLogic(self.flag)

	local newFlag = {
		old = self.flag.latest,
		latest = flag,
		timestamp = duration and os.clock() + duration or 0,
	}

	self.flag = newFlag
	self.changed:Fire(newFlag.old, newFlag.latest)

	self:_handleEntryLogic(newFlag)
	
	return true
end

-- this is fired whenever the state is changed but uses the 'new' state
-- it's meant to setup the animations, visuals and sounds
function machine:_handleEntryLogic(newFlag: types.Flag)
	--print(`entering {newFlag.latest}`)
end

-- this is fired whenever the state is changed but uses the 'old' state
-- it's meant to clean up the previous animations, visuals and sounds
function machine:_handleExitLogic(oldFlag: types.Flag)
	--print(`exiting {oldFlag.latest}`)
	--[[
		example:
		
		local transition = transitions.exit[oldFlag.latest]
		if transition then
			transition()
		end
	
	]]
end

function machine:_update(_)
	local flag: types.Flag = self.flag

	if flag.latest == flags.idle or flag.timestamp <= 0 then
		return
	end

	local now: number = os.clock()

	if now >= flag.timestamp then
		-- this will revert the state
		self:changeState(flag.old)
	end
end

function machine:destroy()
	self._trove:Destroy()
	table.clear(self)
end

return machine
