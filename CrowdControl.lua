--[[

    Effects that are intended to deflect an enemy
    from the objective which limits active fighting in an encounter

    popular effects are: knockback, stun, freeze

	by dagan
]]

-- old code

type cc_target = {
	root: BasePart,
	hum: Humanoid,
}

type cc_tbl = {
	value: boolean,
	timestamp: number,
	duration: number,
}

local Trove = require(script.Parent.Parent.Parent.Packages.trove)

local ccTypes = {
	stun = "stun", -- prevents the player from performing any action
	knockback = "knockback", -- throws the player far away within a specified range
	slow = "slow", -- makes the player slow
	silence = "silence", -- prevents player from using certain abilities 
}

local CrowdControl = {}
CrowdControl.__index = CrowdControl

function CrowdControl.new(target: cc_target)
	local self = setmetatable({
		target = target,
		activeCC = {},
		_trove = Trove.new(),
	}, CrowdControl)

	self._trove:Add(game:GetService("RunService").Heartbeat:Connect(function(dt)
		self:_update(dt)
	end))

	return self
end

function CrowdControl:has(cc_type: string)
	local cc_tbl = self.activeCC[cc_type]
	return cc_tbl and cc_tbl.value or false
end

function CrowdControl:apply(cc_type: string, duration: number)
	if not ccTypes[cc_type] then
		warn(`CC type '{cc_type}' does not exist within the original CC-types table`)
		return
	end

	if not self:has(cc_type) then
		self.activeCC[cc_type] = {
			value = true,
			timestamp = os.clock(),
			duration = duration or 1,
		}
	end
end

function CrowdControl:remove(cc_type: string)
	if self:has(cc_type) then
		self.activeCC[cc_type] = {
			value = false,
			timestamp = 0,
			duration = 0,
		}
		self:_resetEffect(cc_type)
	end
end

function CrowdControl:_update(dt)
	local now: number = os.clock()
	for cc_type: string, ccTbl: cc_tbl in self.activeCC do
		if ccTbl.value == false then continue end

		local hasEnded = now - ccTbl.timestamp >= ccTbl.duration
		if hasEnded then
			self:remove(cc_type)
			continue
		end

		self:_applyEffect(cc_type)
	end
end

function CrowdControl:_applyEffect(cc_type: string)
	local target: cc_target = self.target
	if cc_type == ccTypes.stun then
		target.hum.WalkSpeed = 0
		target.hum.JumpPower = 0
		target.hum.JumpHeight = 0
		target.hum.AutoRotate = false
	elseif cc_type == ccTypes.knockback then
		target.root.AssemblyLinearVelocity = -target.root.CFrame.LookVector * 50
	elseif cc_type == ccTypes.slow then
		target.hum.WalkSpeed = 8
	elseif cc_type == ccTypes.silence then
		-- empty for now
		-- target:DisableAbilities()
	end
end

function CrowdControl:_resetEffect(cc_type: string)
	local target: cc_target = self.target
	if cc_type == ccTypes.stun then
		target.hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
		target.hum.JumpPower = game.StarterPlayer.CharacterJumpPower
		target.hum.JumpHeight = game.StarterPlayer.CharacterJumpHeight
		target.hum.AutoRotate = true
	elseif cc_type == ccTypes.knockback then
		target.root.AssemblyLinearVelocity = Vector3.zero
	elseif cc_type == ccTypes.slow then
		target.hum.WalkSpeed = game.StarterPlayer.CharacterWalkSpeed
	elseif cc_type == ccTypes.silence then
		-- target:EnableAbilities()
	end
end

function CrowdControl:destroy()
	self._trove:Destroy()
	table.clear(self.target)
	table.clear(self.activeCC)
	print("cc_interface destroyed")
end

return CrowdControl
