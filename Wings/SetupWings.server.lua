--[[

    this is a fly system i scripted for a comm that didn't work out because of the lack for mobile support.

--]]

local Players = game:GetService("Players")

local localscript = script.ArtemisWingsComm
local events = script.Events
local setupWingsEvent = events.SetupWings
local assets = script.Assets
local modules = localscript.Modules
local wings = assets.models.wings

local wingFlapsAnimation = assets.Anims.wingflaps

assets.Parent = game.ReplicatedStorage
events.Parent = game.ReplicatedStorage
modules.Parent = game.ReplicatedStorage

--local flyingPlayers = {} :: {
--	[Player]: {
--		value: boolean, -- are they flying?
--		timestamp: number, -- when did they start flying?
--	}
--}

local function canTriggerEvent(player: Player, timestamp: number, action: boolean)
	if typeof(timestamp) ~= "number" or timestamp <= 0 then
		return
	end
	
	if typeof(action) ~= "boolean" then
		return false
	end
	
	local now = workspace:GetServerTimeNow()
	local latency = now - timestamp
	
	-- prevent high latency players from using wing (AlignOrientation doesn't work properly with + 0.5-1 latency)
	if now < timestamp or latency > 0.4 then
		return false
	end
	
	if not player.Character then
		return false
	end
	
	local hum = player.Character:FindFirstChildOfClass("Humanoid")
	
	if not hum or hum.Health <= 0 or hum.RootPart == nil then
		return false
	end
	
	return true
end

local function assignTeamColorToWings(player, wing)
	if not wing then return end
	
	local team = player.Team
	local teamColor = team and team.TeamColor.Color or Color3.fromRGB(0, 0, 0)

	for _, v in wing:GetDescendants() do
		if v:IsA("BasePart") then
			v.Color = teamColor
		end
	end
end

setupWingsEvent.OnServerEvent:Connect(function(player: Player, timestamp: number, action: boolean)
	if canTriggerEvent(player, timestamp, action) then
		local char = player.Character
		local root = char.HumanoidRootPart
		--local animator = char.Humanoid:FindFirstChildOfClass("Animator")
		
		local wing = char:FindFirstChild("Wing")
		if action then
			if wing then
				wing:Destroy()
			end
			root.Anchored = true
			
			local newWing = wings:Clone() :: Model
			newWing:PivotTo(char:GetPivot() * CFrame.new(0, -1.5, 0.5))
			newWing.Name = "Wing"
			
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = root
			weld.Part1 = newWing.RootPart
			weld.Parent = weld.Part1
			
			assignTeamColorToWings(player, newWing)

			newWing.Parent = char
			root.Anchored = false
			
			task.wait()

			if not wingFlapsAnimation or wingFlapsAnimation.AnimationId == "" then
				return
			end

			local animController = Instance.new("AnimationController")
			animController.Parent = newWing

			local animator = Instance.new("Animator")
			animator.Parent = animController

			local animTrack = animator:LoadAnimation(wingFlapsAnimation)
			animTrack:Play()
		else
			if wing then
				wing:Destroy()
			end
		end
		
		--flyingPlayers[player] = {
		--	value = action,
		--	timestamp = timestamp,
		--}
	end
end)

--local function update()
--	local now = workspace:GetServerTimeNow()
--	for player, tbl in flyingPlayers do
--	end
--end

local function onCharacterAdded(char: Model)
	local clone = localscript:Clone()
	clone.Parent = char

	task.defer(function()
		clone.Enabled = true
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.Changed:Connect(function()
		local char = player.Character
		if char then
			assignTeamColorToWings(player, char:FindFirstChild("Wing"))
		end
	end)
	
	player.Chatted:Connect(function(message: string, recipient: Player)
		if recipient then return end
		local command = string.split(message, " ")
		local prefix = command[1]
		local desiredTeam = string.lower(command[2])
		if string.lower(prefix) == ".team" then
			for _, team: Team in game.Teams:GetChildren() do
				if string.lower(team.Name) == desiredTeam then
					player.Team = team; break
				end
			end
		end
	end)
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	
	player.CharacterAdded:Connect(onCharacterAdded)
end)
