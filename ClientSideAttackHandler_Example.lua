local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local getPlayerVariables = require(script.Parent.Parent.Parent.Parent.Utility.getPlayerVariables)
local ccHandler = require(script.Parent.Parent.Parent.ccHandler)
local animHandler = require(script.Parent.Parent.Parent.AnimHandler)
local HitboxHandler = require(script.Parent.Parent.Parent.HitboxHandler)

local remotes = ReplicatedStorage.Scripts.Remotes
local combatRemote = remotes.Combat
local combatReplicationRemote = remotes.CombatReplication

-- combat variables
local totalAttacks, attackSequence = 5, 0
local attackDuration, attackTimestamp = 0.5, 0
local exhaustionDuration, exaustionTimestamp = 1, 0

local MouseButton1 = {}

-- these below should move to a different module called 'combat' and be triggered by a simple method 'combat:process()'
function MouseButton1:hasCooldownActive(now)
	if now - attackTimestamp < attackDuration then
		return true
	end
	return false
end

function MouseButton1:hasExhaustedCombo(now)
	-- exaustionTimestamp is only set when player reaches the final hit
	-- so "if now - exaustionTimestamp" can actually be less than 3
	-- then the player really did exhaust the combo by reaching the final hit
	if now - exaustionTimestamp < exhaustionDuration then
		attackSequence = 0
		return true
	end
	return false
end

function MouseButton1:recoverFromExhaustion(now)
	-- reset combo after some time inactive
	if now - attackTimestamp > attackDuration + 0.5 then
		attackSequence = 0
	end
	attackTimestamp = now
	exaustionTimestamp = 0
end

function MouseButton1:playAttackSequence()
	if attackSequence >= totalAttacks then
		exaustionTimestamp = os.clock()
		return false -- Return false to indicate the sequence is exhausted and yield main scope
	end
	
	attackSequence = math.clamp(attackSequence + 1, 0, totalAttacks)
	
	getPlayerVariables().character:SetAttribute("activeAttackSequence", attackSequence)
	
	animHandler():play("swing" .. attackSequence, 0.2)
	
	print(attackSequence)
	
	return true
end

function MouseButton1:_tryReportEnemy()
	local now = workspace:GetServerTimeNow()
	
	local playerVariables: getPlayerVariables.PlayerVariables = getPlayerVariables()
	local rootPart = playerVariables.rootPart
	
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {playerVariables.character}
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.IgnoreWater = true
	
	local origin = rootPart.CFrame
	local direction = rootPart.CFrame.LookVector * 2
	
	-- to sync with attack animation (consider using GetMarkerReachedSignal over task.delay in the future)
	task.delay(0.3, function()
		HitboxHandler():HitStart(0.5)
	end)
end

function MouseButton1:canAttack()
	local now = os.clock()
	
	-- this also works to detect if the player is alive
	if not getPlayerVariables() then
		return false
	end
	
	if self:hasCooldownActive(now) then
		return false
	end
	
	if self:hasExhaustedCombo(now) then
		return false
	end
	
	if
		ccHandler():has("attacking")
		or ccHandler():has("stun")
		or ccHandler():has("silence")
		or ccHandler():has("blocking")
	then
		return false
	end
	
	self:recoverFromExhaustion(now)
	
	return true
end

function MouseButton1:tryAttack()
	if not self:canAttack() then
		return
	end
	
	ccHandler():give("slow", attackDuration)
	ccHandler():give("attacking", 1)
	
	if not self:playAttackSequence() then
		return
	end
	
	self:_tryReportEnemy() -- looks for an enemy within range of 'blockcast' and fires a remote to the server
end

function MouseButton1:init()
	
	combatReplicationRemote.OnClientEvent:Connect(function(targetRoot: BasePart)
		local playerVariables: getPlayerVariables.PlayerVariables = getPlayerVariables()

		if playerVariables and targetRoot == playerVariables.rootPart then
			animHandler():stopActiveAnimationTracks()
			ccHandler():give("stun", 2)
		end
		
		local hitParticles = targetRoot:FindFirstChild("Hit")
		if not hitParticles then return end
		for _, emitter in hitParticles:GetChildren() do
			emitter:Emit(emitter:GetAttribute("EmitCount"))
		end
	end)
	
end

function MouseButton1:onInputBegan(inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		self:tryAttack()
	end
end

MouseButton1:init()

return MouseButton1
