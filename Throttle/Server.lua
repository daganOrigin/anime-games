local Players = game:GetService("Players")

local function createRate(timeFunction: () -> number, rates: {[any]: number}, ignoreFirstRate: boolean?)	
	local throttle = {}

	local earlierTimes = {} :: {
		[Player]: {
			[any]: number,
		}
	}
	
	-- private methods
	local function register(player: Player)
		if earlierTimes[player] then return end
		earlierTimes[player] = {}

		local initialTime = timeFunction()

		for index, rate in rates do
			earlierTimes[player][index] = ignoreFirstRate and initialTime or initialTime + rate
		end
	end
	
	local function start()
		for _, player in Players:GetPlayers() do
			register(player)
		end

		Players.PlayerAdded:Connect(function(player)
			register(player)
		end)

		Players.PlayerRemoving:Connect(function(player)
			earlierTimes[player] = nil
		end)
	end

	--function throttle:resetAll(ignoreList: {Player})
	--	for _, player in Players:GetPlayers() do
	--		if ignoreList and table.find(ignoreList, player) then continue end
	--		task.spawn(function() self:reset(player) end)
	--	end
	--	table.clear(ignoreList)
	--end
	
	-- public methods
	function throttle:reset(player: Player)
		local initialTime = timeFunction()
		local tbl = earlierTimes[player]
		for i in tbl do
			tbl[i] = ignoreFirstRate and initialTime or initialTime + rates[i]
		end
	end

	function throttle:isOver(index: any, player: Player)
		if not rates[index] then
			warn(`unable to find {index} in rates`)
			return false
		end

		local timeNow = timeFunction()
		
		if timeNow < earlierTimes[player][index] then
			return false
		end

		earlierTimes[player][index] = timeNow + rates[index]

		return true
	end

	function throttle:clear()
		table.clear(earlierTimes)
		table.clear(rates) 
		table.clear(self)
	end
	
	start()

	return throttle
end

return {
	new = createRate
}
