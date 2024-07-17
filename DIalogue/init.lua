--!strict

-- scripted by dagan
-- (this is overcomplicated from start because dialogue will be expanded with more features either way, and this can also be useful for my games)
-- 7/11/2024

local Types = require(script.Types)
local Settings = require(script.Settings)
local disconnectAndClear = require(script.Parent.Parent.Utility.disconnectAndClear)
local Signal = require(script.Parent.Parent.Packages.Signal)

local cam = workspace.CurrentCamera

local function playsound()
	local sfx = script.click:Clone()
	sfx.Playing = true
	sfx.Parent = cam
	sfx.Ended:Once(function()
		sfx:Destroy()
	end)
end

local function removeTags(str: string)
	str = str:gsub("<br%s*/>", "\n")
	return (str:gsub("<[^<>]->", ""))
end

local function createDialogue(prompt: ProximityPrompt, coreGui: Types.UIElements, tree: Types.DialogueFormat)
	local dialogue = {
		speechIndex = 1,
		totalSpeeches = #tree,
		talking = false,
		skipped = false,
		worldPoint = Vector3.zero, -- not set here
		onFinished = Signal.new(),
		_connections = {},
		_prompt = prompt,
		isDialogueEnabled = false,
	} :: Types.Dialogue

	function dialogue.isActive(self)
		return coreGui.screenGui.Enabled == true and self.isDialogueEnabled == true -- and self.talking == true or self.isDialogueEnabled == true
	end

	function dialogue.start(self, cutsceneCallback: (unknown) -> ())
		if self:isActive() then
			return
		end
		self.isDialogueEnabled = true

		self.clearAllChoices()

		if cutsceneCallback ~= nil then
			cutsceneCallback() -- should yield
		end

		self.speechIndex = 1

		coreGui.screenGui.Enabled = true
		self._prompt.Enabled = false

		self:talk()

		table.insert (
			self._connections,
			coreGui.speechBox.InputBegan:Connect(function(input: InputObject)
				if not self.talking then return end

				local mouseClick = input.UserInputType == Enum.UserInputType.MouseButton1
				local touchTap = input.UserInputType == Enum.UserInputType.Touch

				if mouseClick or touchTap then
					self:skip()
				end
			end)
		)

	end

	function dialogue.hide(self)
		if not self:isActive() then
			return
		end
		self:skip()
		self.clearAllChoices()
		disconnectAndClear(self._connections)
		self._prompt.Enabled = true
		self.isDialogueEnabled = false
		coreGui.screenGui.Enabled = false
		self.onFinished:Fire()
	end

	function dialogue.displayChoices(self, choices: {Types.Choice})
		local choiceConnections: {RBXScriptConnection} = {}

		for i = 1, #choices do
			local choiceBranch = choices[i]

			local choice = coreGui.choiceTemplate:Clone()
			choice.Visible = true
			choice.Text = choiceBranch.text or "template"
			choice.LayoutOrder = choiceBranch.layoutOrder
			choice.Parent = coreGui.choicesBox

			choice:SetAttribute("choice", true)

			local UIStroke = choice:FindFirstChildOfClass("UIStroke")

			table.insert (
				choiceConnections,
				choice.MouseEnter:Connect(function()
					if UIStroke then
						UIStroke.Enabled = true
					end
				end)
			)

			table.insert (
				choiceConnections,
				choice.MouseLeave:Connect(function()
					if UIStroke then
						UIStroke.Enabled = false
					end
				end)
			)

			table.insert(choiceConnections, choice.Activated:Once(function(input: InputObject, clickCount: number)
				local mouseClick = input.UserInputType == Enum.UserInputType.MouseButton1
				local touchTap = input.UserInputType == Enum.UserInputType.Touch
				print(input.UserInputType)
				if mouseClick or touchTap then
					choiceBranch.callback()
					self.clearAllChoices()

					self.speechIndex = math.clamp(self.speechIndex + 1, 1, self.totalSpeeches)

					self:talk()

					disconnectAndClear(choiceConnections)
				end
			end))
		end

	end

	function dialogue.clearAllChoices()
		for _, choice in coreGui.choicesBox:GetChildren() do
			local isChoice = choice:GetAttribute("choice")
			if isChoice ~= nil and isChoice then
				choice:Destroy()
			end
		end
	end

	-- animates the speech box
	function dialogue.talk(self)
		local branch = tree[self.speechIndex]
		local speech = removeTags(branch.speech)

		self.talking = true

		coreGui.speechBox.Text = branch.speech
		coreGui.speechBox.MaxVisibleGraphemes = 0

		for i = 1, #speech do
			-- play sound every 2 letters to reduce the impact of instantiation
			if i % 2 == 0 then
				playsound()
			end

			if self.skipped then
				self.skipped = false
				self.talking = false
				break
			end

			coreGui.speechBox.MaxVisibleGraphemes = i + 1

			task.wait(Settings.DELAY_PER_CHARACTER)
		end

		self.talking = false
		coreGui.speechBox.MaxVisibleGraphemes = -1

		if self.speechIndex < self.totalSpeeches then
			self:displayChoices(branch.choices)
		end
		
		if self.speechIndex == self.totalSpeeches then
			task.delay(2.5, function()
				if self:isActive() and not self.talking then
					self:hide()
				end
			end)
		end
	end

	function dialogue.skip(self)
		local isTalking = self.talking
		if isTalking ~= nil and isTalking == true then
			self.skipped = true
		end
	end

	-- this will be called for proxmity prompts out of render because of streaming enabled
	-- but once the prompt is within render again, the whole dialogue tree is recreated
	function dialogue.destroy(self)
		self.onFinished:DisconnectAll()
		self:hide()
		table.clear(self)
	end

	return dialogue
end

return {
	new = createDialogue,
}
