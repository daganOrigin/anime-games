-- github said "fuck" typecheking highlights

export type Choice = {
	text: string,
	layoutOrder: number,
	callback: (any) -> (), -- called only when a choice is selected
}

export type DialogueTree = {
	speech: string,
	choices: {Choice},
	callback: (any) -> (), -- immediate callback (called whenever a new speech initializes)
}

export type DialogueFormat = { DialogueTree }

export type UIElements = {
	screenGui: ScreenGui,
	speechBox: TextLabel, -- the textlabel that should display the text
	choicesBox: Frame, -- the frame that should hold all the choices
	choiceTemplate: TextButton -- the template to use for each new choice
}

export type Dialogue = {
	speechIndex: number,
	totalSpeeches: number,
	talking: boolean,
	skipped: boolean,
	_connections: {RBXScriptConnection?},
	_prompt: ProximityPrompt,
	isDialogueEnabled: boolean,
	
	isActive: (self: Dialogue) -> (),
	talk: (self: Dialogue) -> (),
	skip: (self: Dialogue) -> (),
	start: (self: Dialogue, (unknown) -> ()) -> (),
	hide: (self: Dialogue) -> (),
	displayChoices: (self: Dialogue, {Choice}) -> (),
	clearAllChoices: () -> (),
	destroy: (self: Dialogue) -> (),
}

return {}
