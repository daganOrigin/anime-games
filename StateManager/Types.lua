local signal = require(script.Parent.Parent.Parent.Utility.sleitnick.signal)

export type Flag = {
	old: string,
	latest: string,
	timestamp: number,
}

export type PlayerMachine = {
	flag: Flag,
	_playerRef: Player,
	changed: signal.Signal<>,
	getState: (self: PlayerMachine, state: string) -> string,
	changeState: (self: PlayerMachine, state: string, duration: number?) -> boolean,
	destroy: (self: PlayerMachine) -> (),
}

export type StateProfiles = {[Player]: PlayerMachine}

return nil
