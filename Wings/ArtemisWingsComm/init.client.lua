local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

local Modules = ReplicatedStorage:WaitForChild("Modules")

local Zone = require(Modules.Utility.Zone)
local Wing = require(Modules.Class.Wing)
local Trove = require(Modules.Utility.Trove)
local bindToInstanceDestroyed = require(Modules.Utility.bindToInstanceDestroyed)

local gate = script:WaitForChild("Gate", 10)
gate = gate ~= nil and gate.Value

if not gate then
	warn("gate was not found")
	return
end

--local animate = script.Parent:FindFirstChild("Animate") :: LocalScript

local localPalyer = Players.LocalPlayer

local zone = Zone.new(gate)

local char = script.Parent
local humanoid = char:WaitForChild("Humanoid") :: Humanoid
local rootPart = char:WaitForChild("HumanoidRootPart") :: BasePart
local animator = humanoid:WaitForChild("Animator") :: Animator

local wing = Wing.new(char, humanoid, rootPart, animator, gate)

zone.playerEntered:Connect(function(player)
	if player == localPalyer and wing ~= nil then
		wing:equip()
		--if animate then
		--animate.Enabled = false
		--end
	end
end)

wing:start()

local forceStopConn= UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Space then
		wing:unequip()
		--if animate then
			--animate.Enabled = true
		--end
	end
end)

bindToInstanceDestroyed(char, function()
	forceStopConn:Disconnect()
	forceStopConn = nil
	--animate.Enabled = true
	zone:destroy()
	wing:destroy()
end)
