-- dagan master

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local DialogueClass = require(ReplicatedStorage.Scripts.Class.Dialogue)

local player = Players.LocalPlayer
local playerGui = player:FindFirstChildOfClass("PlayerGui")

--task.wait(1)

---- disable other ui to debug dialogue only
--for _, v in playerGui:GetChildren() do
--	if v:IsA("ScreenGui") then
--		v.Enabled = false
--	end
--end

local DialogueV2 = script.DialogueV2
DialogueV2.Parent = playerGui

-- to easily accommodate new guis, the one right now is a placeholder
local gui = {
	screenGui = DialogueV2,
	speechBox = DialogueV2.Background.Speech,
	choicesBox = DialogueV2.Choices,
	choiceTemplate = DialogueV2.Choices.Template,
}

-- because other devs were changing the properties
gui.screenGui.ResetOnSpawn = false
gui.screenGui.Enabled = false
gui.speechBox.RichText = true
gui.choiceTemplate.RichText = true
gui.choiceTemplate.Visible = false

local allDialogues = {}

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

	allDialogues[prompt] = dialogue
	
	--print(allDialogues)

	prompt.Triggered:Connect(function(player: Player)
		if dialogue:isActive() then
			return
		end
		dialogue:start(cutsceneCallback)
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

-- doesn't work properly because each dialogue is using the same gui:
-- what would happen if all dialogue npcs call 'hide()' every 0.3 seconds if you're far from just one of them?
-- the gui just disappears whenever you press play, the gui disappears if you trigger a proximity prompt

--while true do
--	task.wait(0.3)
	
--	print("running")
	
	
--	if not player.Character then
--		continue
--	end
	
--	local basePart = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart

--	if not basePart then
--		continue
--	end
	
--	local basePartPoint: Vector3 = basePart.Position

--	for _, class in allDialogues do
--		local dialoguePoint = (class._prompt.Parent :: BasePart).Position
--		local distance: number = (basePartPoint - dialoguePoint).Magnitude
--		if distance > 10 then
--			class:hide()
--		end
--	end
--end
