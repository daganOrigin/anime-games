local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DialogueClass = require(ReplicatedStorage.Scripts.Class.Dialogue)

local player = Players.LocalPlayer
local playerGui = player:FindFirstChildOfClass("PlayerGui")

--task.wait(1)

---- debug
--for _, v in playerGui:GetChildren() do
--	if v:IsA("ScreenGui") then
--		v.Enabled = false
--	end
--end

local DialogueV2 = script.DialogueV2
DialogueV2.Parent = playerGui

local gui = {
	screenGui = DialogueV2,
	speechBox = DialogueV2.Background.Speech,
	choicesBox = DialogueV2.Choices,
	choiceTemplate = DialogueV2.Choices.Template,
}

gui.screenGui.ResetOnSpawn = false
gui.screenGui.Enabled = false
gui.speechBox.RichText = true
gui.choiceTemplate.RichText = true
gui.choiceTemplate.Visible = false

local allDialogues = {}
local freeRunnerDialogue = nil

local function setupDialogue(prompt: ProximityPrompt)
	if allDialogues[prompt] then
		return
	end
	
	--print(tostring(prompt), "started")
	
	prompt.RequiresLineOfSight = false
	
	local dialogueData = prompt:FindFirstChild("Data")
	
	if not dialogueData or not dialogueData:IsA("ModuleScript") then
		warn(prompt, "does not have dialogue")
		return
	end
	
	local cutsceneCallback: (any)?
	local cutsceneData = prompt:FindFirstChild("Cutscene")
	if cutsceneData then
		cutsceneCallback = require(cutsceneData)
	end

	local dialogueTree = require(dialogueData)
	local dialogue = DialogueClass.new(prompt, gui, dialogueTree)
	dialogue.worldPoint = (prompt.Parent :: BasePart).Position

	allDialogues[prompt] = dialogue
	
	--print(allDialogues)
	
	dialogue.onFinished:Connect(function()
		player.Character.Humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower
		player.Character.Humanoid.JumpHeight = game.StarterPlayer.CharacterJumpHeight
		player.Character:SetAttribute("dialogue", false)
		freeRunnerDialogue = nil
	end)

	prompt.Triggered:Connect(function(player: Player)
		if dialogue:isActive() then
			return
		end
		player.Character:SetAttribute("dialogue", true) -- erg
		player.Character.Humanoid.JumpPower = 0
		player.Character.Humanoid.JumpHeight = 0
		dialogue:start(cutsceneCallback)
		freeRunnerDialogue = dialogue
	end)
end

-- simple observer for proximity prompts (streaming enabled support)
CollectionService:GetInstanceAddedSignal("DialoguePrompts"):Connect(function(prompt: ProximityPrompt)
	setupDialogue(prompt)
end)

CollectionService:GetInstanceRemovedSignal("DialoguePrompts"):Connect(function(prompt: ProximityPrompt)
	local dialogue = allDialogues[prompt]
	if dialogue ~= nil then
		dialogue:destroy()
		allDialogues[prompt] = nil
	end
end)

-- setup dialogue for prompts within the render at start of the session
for _, prompt: ProximityPrompt in CollectionService:GetTagged("DialoguePrompts") do
	setupDialogue(prompt)
end

while task.wait(0.5) do
	local character =  player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	
	if not humanoid or not humanoid.RootPart then
		continue
	end
	
	if freeRunnerDialogue and freeRunnerDialogue:isActive() then
		local myPoint = humanoid.RootPart.Position
		local dist = (myPoint - freeRunnerDialogue.worldPoint).Magnitude
		if dist > 10 or humanoid.Health <= 0 then
			freeRunnerDialogue:hide()
		end
	end
end
