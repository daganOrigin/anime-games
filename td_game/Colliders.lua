local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")

local Network = require(ReplicatedStorage.Scripts.Packages.Network)

local collided, teleportCollision = {}, {}
local colliderRequests = {}

local function getColliderRelativeLabel(labelName: string, collider: BasePart)
	return collider:FindFirstChild(labelName, true)
end

local function updateColliderRequestAmount(collider: BasePart)
	local textLabel = getColliderRelativeLabel("requests", collider)
	if textLabel then
		textLabel.Text = `{colliderRequests[collider]}/{collider:GetAttribute("TotalRequestsAllowed")}`
	end
end

local function safeTeleportPlayers(collider: BasePart, placeId: number, players: {Player})
	local teleportOptions = Instance.new("TeleportOptions")
	teleportOptions.ShouldReserveServer = true
	
	local success = pcall(function()
		TeleportService:TeleportAsync(placeId, players, teleportOptions)
	end)
	
	while success and #players > 0 do
		for i, player in players do
			if not player:IsDescendantOf(Players) then
				table.remove(players, i)
			end
		end
		task.wait()
	end
	
	table.clear(teleportCollision[collider])
	
	colliderRequests[collider] = 0
	
	updateColliderRequestAmount(collider)
end

local function teleportEvent(collider: BasePart, totalRequests: number)
	local totalRequestsAllowed = collider:GetAttribute("TotalRequestsAllowed") or 4
	if totalRequests >= totalRequestsAllowed then
		local textLabel = getColliderRelativeLabel("countdown", collider)
		
		updateColliderRequestAmount(collider)
		
		if textLabel then
			local start = workspace:GetServerTimeNow() + 10
			textLabel.Visible = true

			while workspace:GetServerTimeNow() < start do
				if #teleportCollision[collider] <  totalRequestsAllowed then
					break
				end
				textLabel.Text = `{math.round(start - workspace:GetServerTimeNow())}`
				task.wait()
			end
			
			textLabel.Visible = false
		end
		
		for _, player in teleportCollision[collider] do
			Network:FireClientUnreliable(player, "ToggleControls", false)
			Network:FireClientUnreliable(player, "ToggleExitButton", false)
		end
		
		updateColliderRequestAmount(collider)
		
		if #teleportCollision[collider] >= totalRequestsAllowed then
			safeTeleportPlayers (
				collider,
				collider:GetAttribute("GameModePlace"),
				teleportCollision[collider]
			)
		end
	end
end

for _, collider in CollectionService:GetTagged("Colliders") do
	if not collider:IsA("BasePart") then return end

	if not colliderRequests[collider] then
		local totalRequestsAllowed = collider:GetAttribute("TotalRequestsAllowed") or 4

		colliderRequests[collider] = 0
		teleportCollision[collider] = {}

		updateColliderRequestAmount(collider)
		
		collider.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or collided[player] then return end
			if table.find(teleportCollision[collider], player) then return end

			if colliderRequests[collider] >= totalRequestsAllowed then return end

			colliderRequests[collider] = math.clamp(colliderRequests[collider] + 1, 0, totalRequestsAllowed)
			collided[player] = collider:FindFirstChildOfClass("Attachment")

			table.insert(teleportCollision[collider], player)

			local link = collider:FindFirstChildOfClass("ObjectValue")

			if link then
				player.Character:PivotTo(link.Value.CFrame * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(180), 0))
				Network:FireClientUnreliable(player, "ToggleExitButton", true)
			end
			
			updateColliderRequestAmount(collider)
			
			--print(colliderRequests)

			teleportEvent(collider, colliderRequests[collider])
		end)
	end
end

Network:BindEvents({
	ExitPlatform = {
		function(player: Player)
			local exitPoint = collided[player]
			local collider = exitPoint and exitPoint.Parent

			if exitPoint ~= nil and player.Character then
				local totalRequestsAllowed = collider:GetAttribute("TotalRequestsAllowed")
				
				player.Character:PivotTo(exitPoint.WorldCFrame)
				
				collided[player] = nil
				colliderRequests[exitPoint.Parent] = math.clamp(colliderRequests[exitPoint.Parent] - 1, 0, totalRequestsAllowed)

				updateColliderRequestAmount(collider)
				
				local tbl = teleportCollision[collider]
				table.remove(tbl, table.find(tbl, player))
			end

			Network:FireClientUnreliable(player, "ToggleExitButton", false)
			Network:FireClientUnreliable(player, "ToggleControls", true)
		end
	}
})
