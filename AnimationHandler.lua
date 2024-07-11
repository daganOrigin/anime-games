-- old code

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Trove = require(script.Parent.Parent.Parent.Packages.trove)
local getPlayerVariables = require(script.Parent.Parent.Utility.getPlayerVariables)

local animations = ReplicatedStorage.Assets.Animations:GetDescendants()

local Animation = {}
Animation.__index = Animation

function Animation.new(char: Model)
	local self = setmetatable({
		char = char,
		animTracks = {},
		playerVariables = getPlayerVariables(),
		_trove = Trove.new(),
	}, Animation)

	self:init()
	
	return self
end

-- preloads all the animations and stores them within the tbl
function Animation:init()
	self:enable()
	
	if not self.playerVariables then
		print(`unable to load animation tracks because player variables are missing: {self.playerVariables}`)
		return
	end
	
	self._trove:Add(RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end))
	
	for _, anim: Animation in animations do
		if not anim:IsA("Animation") then
			continue
		end
		local hasId = anim.AnimationId ~= ""
		if not hasId then continue end
		self.animTracks[anim.Name:lower()] = self.playerVariables.animator:LoadAnimation(anim)
	end
end

function Animation:play(animName: string, fadeIn: number?, animPriority: Enum.AnimationPriority)
	if not self.enabled then
		warn("animation handler is disabled")
		return
	end
	local track: AnimationTrack = self.animTracks[animName]
	if track ~= nil and not track.IsPlaying then
		track:Play(fadeIn)
		if animPriority ~= nil then
			track.Priority = animPriority
		end
	end
end

function Animation:stop(animName: string, fadeOut: number?)
	if not self.enabled then
		return
	end
	local track = self.animTracks[animName]
	if track ~= nil and track.IsPlaying then
		track:Stop(fadeOut)
	end
end

--function Animation:adjustSpeed(animName: string, factor: number?)
--	local track: AnimationTrack = self.animTracks[animName]
--	if track ~= nil and track.IsPlaying then
--		track:AdjustSpeed(factor)
--	end
--end

function Animation:stopActiveAnimationTracks()
	for index, animTrack in self.animTracks do
		animTrack:Stop()
	end
end

function Animation:enable()
	if self.enabled then
		return
	end
	self.enabled = true
end

function Animation:disable()
	if not self.enabled then
		return
	end
	self.enabled = false
	
	self:stopActiveAnimationTracks()
end

function Animation:_handleMovementAnims()
	local hum = self.playerVariables.humanoid :: Humanoid

	local isMoving = hum.MoveDirection ~= Vector3.zero
	local isRunning = hum.WalkSpeed > game.StarterPlayer.CharacterWalkSpeed

	if isMoving then
		if isRunning then
			self:play("run", 0.1, Enum.AnimationPriority.Action)
			self:stop("walk")	
		else
			self:play("walk", 0.1, Enum.AnimationPriority.Movement)
			self:stop("run")
		end
	else
		self:stop("run")
		self:stop("walk")
		self:play("idle", 0.1, Enum.AnimationPriority.Idle)
	end
end

local refreshRate = 0.1
local timestamp = time() + refreshRate

function Animation:_update(dt)
	if not self.enabled then return end
	local timeNow = time()
	if timeNow < timestamp then return end
	timestamp = timeNow + refreshRate
	
	self:_handleMovementAnims()
end

function Animation:destroy()
	self:disable()
	self._trove:Destroy()
	self.char = nil
	table.clear(self.playerVariables)
	table.clear(self.animTracks)
end

return Animation
