local component = require("component")
local sides = require("sides")
local colors = require("colors")

--[[ 
How to
Colors:
	Blue: input for overTemperature (doesn't control reactor directly, but checks if it resets too often)
	Light grey: battery charge
	White: output to turn on/off reactor
	Red: output to start extracting coolant
	Black: output to start extracting depleted
	Yellow: output to start inserting coolant
	Grey: output to start inserting rods
	Green: input if coolant is extracted
	Purple: input if depleted is extracted
--]]

local rs1Code = "2009c856-ba4d-4449-afb4-37ceae46619d"

local reactor = newReactor(rs1Code, sides.south)

reactor:initialize()
while(true) do
	reactor:checkForTemperature()
	reactor:checkForCoolant()
	reactor:checkForDepleted()
	reactor:checkForBatteryStatus()
	os.sleep(1)
end

function newReactor (proxyID, rsSide)

	local self = {comp = component.proxy(proxyID), redstoneSide = rsSide}
	local tempReading --number, Blue input
	local batteryStatus --number, Light grey input
	local coolantExtracted --boolean, Green input
	local depletedExtracted --boolean, Purple input
	--reactorStatus --boolean, White output
	--coolantExport	--boolean, Red output
	--depletedExport --boolean, Black output
	--coolantInsert --boolean, Yellow output
	--rodInsert --boolean, Grey output
	local tempResetCount = 0 --number
	local offOnThermalSafe = false

	local cycleResetForTemp = 19
	local cycleCounter = 0
	local maxResetForTemp = 3

	local initialize = function ()
		updateValues()
		checkForTemperature()
		checkForCoolant()
		checkForDepleted()
		checkForBatteryStatus()
		turnOnReactor()
	end

	local updateValues = function()
		tempReading = self.comp.getBundledInput(self.redstoneSide, colors.blue)
		batteryStatus = self.comp.getBundledInput(self.redstoneSide, colors.lightgrey)
		coolantExtracted = self.comp.getBundledInput(self.redstoneSide, colors.green)
		depletedExtracted = self.comp.getBundledInput(self.redstoneSide, colors.purple)
	end

	local turnOffReactor = function()
		self.comp.setBundledOutput(self.redstoneSide, colors.white, 0)
	end

	local turnOnReactor = function()
		if(offOnThermalSafe) then
			print("Reactor off on thermal safe")
		else
			self.comp.setBundledOutput(self.redstoneSide, colors.white, 15)
		end
	end

	local checkForTemperature = function()
		if(tempResetCount>maxResetForTemp) then
			turnOffReactor()
			print("Reactor off on thermal safe")
			offOnThermalSafe = true
		else
			local isReset = true
			if(tempReading>0) then
				tempResetCount = tempResetCount + 1
				print("Reactor turned off on thermals n" .. tempResetCount)
				isReset = false
			else
				cycleCounter = cycleCounter + 1
				if(cycleCounter>=19) then
					tempResetCount = 0
					cycleCounter = 0
				end
			end
			while(isReset == false) do
				updateValues()
				os.sleep(1)
				if(value == 0) then
					isReset = true
				end
			end
		end
	end

	local checkForCoolant = function()
		self.comp.setBundledOutput(self.redstoneSide, colors.red, 15)
		os.sleep(1)
		updateValues()
		if(coolantExtracted>0) then
			print("Started changing coolant")
			turnOffReactor()
		
			local count = 1
			while(coolantExtracted>0) do
				print("Changing n " .. count)
				self.comp.setBundledOutput(self.redstoneSide, colors.yellow, 15)
				os.sleep(1)
				self.comp.setBundledOutput(self.redstoneSide, colors.yellow, 0)
				os.sleep(1)
				updateValues()
				count = count + 1
			end
			print("Finished changing coolant")
			turnOnReactor()
		end
		self.comp.setBundledOutput(self.redstoneSide, colors.red, 0)
	end

	local checkForDepleted = function()
		self.comp.setBundledOutput(self.redstoneSide, colors.black, 15)
		os.sleep(1)
		updateValues()
		if(depletedExtracted>0) then
			print("Started changing rods")
			turnOffReactor()
		
			local count = 1
			while(depletedExtracted>0) do
				print("Changing n " .. count)
				self.comp.setBundledOutput(self.redstoneSide, colors.grey, 15)
				os.sleep(1)
				self.comp.setBundledOutput(self.redstoneSide, colors.grey, 0)
				os.sleep(1)
				updateValues()
				count = count + 1
			end
			print("Finished changing rods")
			turnOnReactor()
		end
		self.comp.setBundledOutput(self.redstoneSide, colors.black, 0)
	end

	local checkForBatteryStatus = function()
		local latch = false
		repeat
			updateValues()
			if(batteryStatus>14 && latch == false) then
				print("Battery full, stopping reactor" .. batteryStatus)
				turnOffReactor()
				latch = true
			end

			if(batteryStatus<2 && latch == true) then
				print("Battery depleted, restarting reactor" .. batteryStatus)
				turnOnReactor()
				latch = false
			end

			if(latch == true) then
				os.sleep(10)
			end
		until not latch
	end

end





	


