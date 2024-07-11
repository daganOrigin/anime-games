-- these are allowed transitions
-- if you want to change from idle to attack, this ensures that 'attack' is transition-able  for the 'idle' state.

local flags = require(script.Parent.Flags)

local validation = {
	[flags.idle] = {
		[flags.idle] = true,
		[flags.attack] = true,
		[flags.block] = true,
		[flags.walk] = true,
		[flags.jump] = true,
		[flags.run] = true,
	},
	
	[flags.walk] = {
		[flags.idle] = true,
		[flags.run] = true,
		[flags.block] = true,
		[flags.jump] = true,
		[flags.attack] = true,
	},
	
	[flags.run] = {
		[flags.idle] = true,	
		[flags.walk] = true,
		[flags.block] = true,
		[flags.attack] = true,
	},
	
	[flags.jump] = {
		[flags.idle] = true,	
	},
	
	[flags.attack] = {
		[flags.idle] = true,
		[flags.walk] = true,
		[flags.run] = true,
	},
	
	[flags.block] = {
		[flags.idle] = true,	
	},
}

return validation
