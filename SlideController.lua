-- old code

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(Knit.Util.Trove)

local slideForce: number = 60
local maxSlopeAngle: number = 45
local slideTime: number = 0
local isHolding: boolean = false

local SlideController = Knit.CreateController {
	Name = "SlideController",
	_trove = Trove.new(),
	isSliding = Instance.new("BoolValue"),
}

-- from unity
local function onSlope(root: BasePart, params: RaycastParams)
	local from, to = root.CFrame.Position, -Vector3.yAxis * 8
	local raycast = workspace:Raycast(from, to, params)
	if raycast then
		local angle: number = math.round(math.deg(raycast.Instance.Position:Angle(Vector3.yAxis, raycast.Normal)))
		return angle < maxSlopeAngle and angle ~= 0, raycast.Normal
	end
	return false
end

function SlideController:Slide()
	local char = Knit.Player.Character :: Model
	if not char then return end

	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {char}
	
	isHolding = true
	local slopeDetected
	while root.AssemblyLinearVelocity.Magnitude > 0 and not slopeDetected and isHolding do
		slopeDetected = onSlope(root, params)
		print("detecting slope")
		task.wait(1/30)
	end

	if slopeDetected then
		slideTime = 1
		self.isSliding.Value = true
	end
end

function SlideController:Stop()
	self.isSliding.Value = false
	isHolding = false
end

function SlideController:KnitStart()
	local player = Knit.Player
	
	local function instantitateSound(soundName: string, parent: Instance)
		local sound = ReplicatedStorage.Sounds:FindFirstChild(soundName, true)
		if not sound then print("unable to find sound", soundName) return end
		local clone = sound:Clone()
		clone.Parent = parent
		return clone
	end
	
	local function onRespawn(char: Model)
		self._trove:Clean()
		
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		local animator = hum:WaitForChild("Animator") :: Animator
		local root = char:WaitForChild("HumanoidRootPart") :: BasePart
		
		local slide_down_hill_sfx = instantitateSound("slide_down_hill", root)
		
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = {char}
		
		self._trove:Add(RunService.Heartbeat:Connect(function(dt)
			if not self.isSliding.Value then return end
			slideTime += dt
			
			local isPlayerOnSlope: boolean, slopeDirection: Vector3 = onSlope(root, params)
			if isPlayerOnSlope then
				slopeDirection = slopeDirection.Unit
				
				hum.CameraOffset = hum.CameraOffset:Lerp(Vector3.one * math.random(-1, 1), 0.05)
				hum.JumpPower = 0
				
				root.CFrame = CFrame.lookAlong(root.CFrame.Position, slopeDirection - Vector3.yAxis, Vector3.yAxis)
				root.AssemblyLinearVelocity = root.AssemblyLinearVelocity:Lerp(slideTime * slopeDirection * slideForce , 0.1)
				
				root:ApplyImpulse(slideTime * -Vector3.yAxis * 30)
			end
		end))
		
		self._trove:Add(self.isSliding.Changed:Connect(function(value)
			if slide_down_hill_sfx ~= nil then
				slide_down_hill_sfx.Playing = value
			end
			hum.AutoRotate = not value
		end))
	end
	
	player.CharacterAdded:Connect(function(char: Model) task.defer(onRespawn, char)  end)
	
	if player.Character then
		task.defer(onRespawn, player.Character)
	end
	
	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe or self.isSliding.Value then return end
		if input.KeyCode == Enum.KeyCode.C then
			self:Slide()
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == Enum.KeyCode.C then
			self:Stop()
		end
	end)
	
end

return SlideController
