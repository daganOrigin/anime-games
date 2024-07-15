local Players = game:GetService("Players")

local function createRate(timeFunction: () -> number, rates: {[any]: number}, ignoreFirstRate: boolean?)
	local RateLimiter = {}

	local earlierTimes = {} :: {
		[Player]: {
			[string]: number,
		}
	}

	function RateLimiter:start()
		if self.started then
			error("RateLimiter already started", 2) return
		end
		self.started = true

		for _, player in Players:GetPlayers() do
			self:register(player)
		end

		Players.PlayerAdded:Connect(function(player)
			self:register(player)
		end)

		Players.PlayerRemoving:Connect(function(player)
			earlierTimes[player] = nil
		end)
	end

	function RateLimiter:register(player: Player)
		if earlierTimes[player] then return end
		earlierTimes[player] = {}

		local initialTime = ignoreFirstRate and 0 or timeFunction()

		for index, rate in rates do
			earlierTimes[player][index] = initialTime
		end
	end

	function RateLimiter:resetAll(ignoreList: {Player})
		local initialTime = timeFunction()
		for _, player in Players:GetPlayers() do
			if ignoreList and table.find(ignoreList, player) then continue end
			local tbl = earlierTimes[player]
			task.spawn(function()
				for i in tbl do
					tbl[i] = ignoreFirstRate and 0 or initialTime + rates[i]
				end
			end)
		end
		--table.clear(ignoreList)
	end

	function RateLimiter:reset(player: Player)
		local initialTime = timeFunction()
		local tbl = earlierTimes[player]
		for i in tbl do
			tbl[i] = ignoreFirstRate and 0 or initialTime + rates[i]
		end
	end

	function RateLimiter:isOver(index: any, player: Player)
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

	function RateLimiter:clear()
		table.clear(earlierTimes)
		table.clear(rates) 
		table.clear(self)
	end

	return RateLimiter
end

return {
	new = createRate
}
