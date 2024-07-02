local MIN_DMG_RANGE = 8

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ServerScriptService = game:GetService("ServerScriptService")

--local playerData = require(ReplicatedStorage.Scripts.PlayerData.Server)
local getPlayerVariables = require(ReplicatedStorage.Scripts.Utility.getPlayerVariables)
local ragdoll = require(ServerScriptService.R6Ragdoll.ModuleScript)
local soundManager = require(ReplicatedStorage.Utility.soundManager)

local sounds = ReplicatedStorage.Assets.Sounds
local remotes = ReplicatedStorage.Scripts.Remotes
local combatRemote = remotes.Combat
local combatReplicationRemote= remotes.CombatReplication

local playerCooldowns = {}
local cooldown = 0.5

local combat = {}

-- sanity checks to prevent exploiters (there are still more sanity checks to add)
function combat:canHandleCombat(player: Player, playerTimestamp: number, enemy: Model?, activeAttackSequence: number)
	local now = workspace:GetServerTimeNow()
	
	local latency = now - playerTimestamp

	if now <= playerTimestamp or latency >= 1 then
		--warn("latency diff")
		return false
	end
	
	if playerCooldowns[player] and now - playerCooldowns[player] < cooldown then
		return false
	end
	
	local playerVariables: getPlayerVariables.PlayerVariables = getPlayerVariables(player)

	if not playerVariables then
		--warn("the player is dead")
		return false
	end
	
	if not enemy or typeof(enemy) ~= "Instance" or enemy:IsA("Model") == false then
		--warn("the enemy is missing")
		return false
	end
	
	local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not enemyHumanoid or enemyHumanoid.Health <= 0 then
		--warn("cannot dmg enemy because humanoid is missing or dead")
		return false
	end
	
	local enemyRootPart = enemy:FindFirstChild("HumanoidRootPart")
	if not enemyRootPart then
		--warn("cannot dmg because the enemy's root-part is missing")
		return false
	end
	
	if player:DistanceFromCharacter(enemyRootPart.CFrame.Position) > MIN_DMG_RANGE then
		--warn("cannot dmg enemy because the character is too far away")
		return false
	end
	
	playerCooldowns[player] = now
	
	return true
end
local function handleCombat(player: Player, enemy: Model, activeAttackSequence: number)
	local playerVariables: getPlayerVariables.PlayerVariables = getPlayerVariables(player)
	
	local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid") :: Humanoid -- humanoid could have a different name so we use FindFirstChildOfClass
	local enemyRootPart = enemy:FindFirstChild("HumanoidRootPart") :: BasePart
	
	--local characterTbl = playerData.getValue(player, "character")
	local strength: number = 10 --characterTbl.stats.strength or
	
	local enemyPlayer: Player? = Players:FindFirstChild(enemy.Name)
	
	local dmg: number = strength -- + unknown factors
	local knockbackDir: Vector3 = playerVariables.rootPart.CFrame.LookVector
	local knockbackForce: number = 8
	
	local playerPos = playerVariables.rootPart.Position
	
	local enemyPos = enemyRootPart.CFrame.Position
	local playerPlaneVector = Vector3.new(playerPos.X, 0, playerPos.Z)
	
	soundManager.playAt(sounds.Hit, enemyRootPart)
	
	if activeAttackSequence >= 5 then
		ragdoll:Ragdoll(enemy)
		task.delay(2, function()
			ragdoll:Unragdoll(enemy)
		end)
	end
	
	enemyHumanoid:TakeDamage(math.max(math.abs(dmg), 0))
	
	-- unreliable remote
	combatReplicationRemote:FireAllClients(enemyRootPart, knockbackDir, activeAttackSequence)
end

function combat:init()
	combatRemote.OnServerEvent:Connect(function(player: Player, playerTimestamp: number, enemy: Model, activeAttackSequence: number)
		if not self:canHandleCombat(player, playerTimestamp, enemy, activeAttackSequence) then
			return
		end
		handleCombat(player, enemy, activeAttackSequence)
	end)
end

return combat
