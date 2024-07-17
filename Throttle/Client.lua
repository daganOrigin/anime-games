
local function createRate(timeFunction: () -> number, rates: {[any]: number}, ignoreFirstRate: boolean?)
	local throttle = {}
	local earlierTimes = {} :: {
		[any]: number
	}

	local initialTime = timeFunction()

	for index, rate in rates do
		earlierTimes[index] = ignoreFirstRate and initialTime or initialTime + rate
	end

	function throttle:isOver(index: any)
		if not rates[index] then
			warn(`unable to find {index} in rates`)
			return false
		end

		local timeNow = timeFunction()

		if timeNow < earlierTimes[index] then
			return false
		end

		earlierTimes[index] = timeNow + rates[index]

		return true
	end

	-- should be used for localscripts in 'StarterCharacterScripts'
	function throttle:clear()
		table.clear(earlierTimes)
		table.clear(rates) 
		table.clear(self)
	end

	return throttle
end

return {
	new = createRate
}
