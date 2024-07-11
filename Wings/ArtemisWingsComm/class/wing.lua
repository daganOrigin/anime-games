local FLY_SPEED = 120

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Trove = require(script.Parent.Parent.Utility.Trove)
--local Gui = require(script.Parent.Parent.Class.Gui)

local events = ReplicatedStorage:WaitForChild("Events")
local setupWingsEvent = events:WaitForChild("SetupWings")

local assets = ReplicatedStorage.Assets
local wingModel = assets:FindFirstChild("wings", true)
local wingFlapsAnimation = assets:FindFirstChild("wingflaps", true)
local flyLoopAnimation = script:FindFirstChild("FlyLoop")

local player = Players.LocalPlayer
local cam = workspace.CurrentCamera :: Camera
local controls = require(player.PlayerScripts:WaitForChild("PlayerModule")):GetControls()

if not wingModel then
	warn("wing model missing")
end

if not wingFlapsAnimation then
	warn("wing flap animation missing")
end

local Wing = {}
Wing.__index = Wing

function Wing.new(
	character: Model,
	humanoid: Humanoid,
	rootPart: BasePart,
	animator: Animator,
	gate: BasePart
)
	local self = setmetatable({
		char = character,
		rootPart = rootPart,
		animator = animator,
		humanoid = humanoid,
		_gate = gate,
		_trove = Trove.new(),
	}, Wing)

	self:start()

	return self
end

function Wing:start()
	if self.started then
		return
	end
	self.started = true
	
	self.dt = 0
	
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {self.char}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	
	self._params = params
	
	self._trove:Add(RunService.Heartbeat:Connect(function(dt)
		self:_update(dt)
	end))
end

function Wing:equip(idle)
	if self.equipped then
		return
	end
	setupWingsEvent:FireServer(workspace:GetServerTimeNow(), true)
	
	local wing = self.char:WaitForChild("Wing", 10)
	if not wing then return end
	
	self.equipped = true
	self.humanoid.AutoRotate = false
	
	if flyLoopAnimation then
		self.flyTrack = self.animator:LoadAnimation(flyLoopAnimation)
		self.flyTrack:Play()	
		self.flyTrack.Priority = Enum.AnimationPriority.Idle
	end

	local attachment = self.rootPart:FindFirstChildOfClass("Attachment")

	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.zero
	velocity.Attachment0 = attachment
	velocity.Parent = self.rootPart

	local alignOrientation = script.AlignOrientation:Clone()
	alignOrientation.Attachment0 = attachment
	alignOrientation.MaxTorque = math.huge
	alignOrientation.CFrame = CFrame.lookAt(self.rootPart.Position - self._gate.CFrame.LookVector, self.rootPart.Position)
	alignOrientation.Parent = self.rootPart

	self.orientation = alignOrientation
	self.velocity = velocity
end

function Wing:unequip()
	if not self.equipped then
		return
	end
	self.equipped = false
	self.humanoid.AutoRotate = true
	
	self.velocity:Destroy()
	self.velocity = nil
	
	self.orientation:Destroy()
	self.orientation = nil
	
	self.flyTrack:Stop()
	self.flyTrack:Destroy()
	self.flyTrack = nil
	
	self.rootPart.AssemblyLinearVelocity = Vector3.zero
	
	setupWingsEvent:FireServer(workspace:GetServerTimeNow(), false)
	
	cam.CameraType = Enum.CameraType.Custom
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	
	self.dt = 0

	-- fire server to remove wings
end

local totalDuration = 60*5--20--60*5
--local accel = 0.1

function Wing:_update(dt)
	if not self:isEquipped() then
		return
	end
	
	self.dt += dt
	
	if self.dt >= totalDuration then
		self:unequip()	
	end
	
	if self.equipped then
		if self.dt < 1.2 then
			local goal = 30*self._gate.CFrame.LookVector+30*self._gate.CFrame.UpVector*self.dt
			self.velocity.VectorVelocity = self.velocity.VectorVelocity:Lerp(goal, 0.3)
		else
			
      -- move direction doesn't support Y axis
      -- ngl this could also be a swim system

			local wDown = UIS:IsKeyDown(Enum.KeyCode.W)
			local aDown = UIS:IsKeyDown(Enum.KeyCode.A)
			local dDown = UIS:IsKeyDown(Enum.KeyCode.D)
			local sDown = UIS:IsKeyDown(Enum.KeyCode.S)
			
			local dir = Vector3.zero

			if wDown then
				dir += cam.CFrame.LookVector
			end
			if sDown then
				dir -= cam.CFrame.LookVector
			end
			if aDown then
				dir -= cam.CFrame.RightVector
			end
			if dDown then
				dir += cam.CFrame.RightVector
			end

			if dir.Magnitude > 0 then
				dir = dir.Unit
			end

			-- z angle -> front/back
			-- y angle -> right/left
			-- x angle -> up/down?
			
			local rootPos = self.rootPart.Position
			local zAngle = 0
			
			local xAngle = self.orientation.CFrame.RightVector:Dot(dir) > 0 and -45 or 45
			local yAngle = 0
			
			if wDown then
				zAngle = 90
			end

			if sDown then
				zAngle = -90
			end
			
			if aDown or dDown then
				yAngle = aDown and 90 or dDown and -90 or 0
				zAngle = 0
				xAngle = 0
			end
			
			if wDown then
				zAngle = 90
				yAngle = aDown and 45 or dDown and -45 or 0
			elseif sDown then
				zAngle = -90
				yAngle = aDown and 45 or dDown and -45 or 0
			end
		
			if dir == Vector3.zero then
				xAngle = 0
				yAngle = 0
				zAngle = 0
			end
			
			local goal = CFrame.new(rootPos - cam.CFrame.LookVector, rootPos) * CFrame.Angles(-math.rad(zAngle), math.rad(xAngle), math.rad(yAngle))
			
			self.velocity.VectorVelocity = self.velocity.VectorVelocity:Lerp(dir * FLY_SPEED, dt)
			self.orientation.CFrame = self.orientation.CFrame:Lerp(goal, 0.1)
		end
	end
end

function Wing:isEquipped()
	return self.equipped == true
end

function Wing:destroy()
	self._trove:Destroy()
end

return Wing
