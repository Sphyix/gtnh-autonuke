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

function newReactor:new (proxyID, rsSide)

	local self = {comp = component.proxy(proxyID), redstoneSide = rsSide}
	tempReading = 0 --number, Blue input
	batteryStatus = 0 --number, Light grey input
	coolantExtracted = 0 --boolean, Green input
	depletedExtracted = 0 --boolean, Purple input
	--reactorStatus --boolean, White output
	--coolantExport	--boolean, Red output
	--depletedExport --boolean, Black output
	--coolantInsert --boolean, Yellow output
	--rodInsert --boolean, Grey output
	tempResetCount = 0 --number
	offOnThermalSafe = false

	cycleResetForTemp = 19
	cycleCounter = 0
	maxResetForTemp = 3

	initialize = function (self)
		self.updateValues()
		self.checkForTemperature()
		self.checkForCoolant()
		self.checkForDepleted()
		self.checkForBatteryStatus()
		self.turnOnReactor()
	end

	updateValues = function(self)
		self.tempReading = self.comp.getBundledInput(self.redstoneSide, colors.blue)
		self.batteryStatus = self.comp.getBundledInput(self.redstoneSide, colors.lightgrey)
		self.coolantExtracted = self.comp.getBundledInput(self.redstoneSide, colors.green)
		self.depletedExtracted = self.comp.getBundledInput(self.redstoneSide, colors.purple)
	end

	turnOffReactor = function(self)
		self.comp.setBundledOutput(self.redstoneSide, colors.white, 0)
	end

	turnOnReactor = function(self)
		if(self.offOnThermalSafe) then
			print("Reactor off on thermal safe")
		else
			self.comp.setBundledOutput(self.redstoneSide, colors.white, 15)
		end
	end

	checkForTemperature = function(self)
		if(self.tempResetCount>self.maxResetForTemp) then
			turnOffReactor()
			print("Reactor off on thermal safe")
			self.offOnThermalSafe = true
		else
			local isReset = true
			if(self.tempReading>0) then
				self.tempResetCount = self.tempResetCount + 1
				print("Reactor turned off on thermals n" .. tempResetCount)
				isReset = false
			else
				self.cycleCounter = self.cycleCounter + 1
				if(self.cycleCounter>=19) then
					self.tempResetCount = 0
					self.cycleCounter = 0
				end
			end
			while(isReset == false) do
				self.updateValues()
				os.sleep(1)
				if(self.tempReading == 0) then
					isReset = true
				end
			end
		end
	end

	checkForCoolant = function(self)
		self.comp.setBundledOutput(self.redstoneSide, colors.red, 15)
		os.sleep(1)
		self.updateValues()
		if(self.coolantExtracted>0) then
			print("Started changing coolant")
			self.turnOffReactor()
		
			local count = 1
			while(self.coolantExtracted>0) do
				print("Changing n " .. count)
				self.comp.setBundledOutput(self.redstoneSide, colors.yellow, 15)
				os.sleep(1)
				self.comp.setBundledOutput(self.redstoneSide, colors.yellow, 0)
				os.sleep(1)
				self.updateValues()
				count = count + 1
			end
			print("Finished changing coolant")
			self.turnOnReactor()
		end
		self.comp.setBundledOutput(self.redstoneSide, colors.red, 0)
	end

	checkForDepleted = function(self)
		self.comp.setBundledOutput(self.redstoneSide, colors.black, 15)
		os.sleep(1)
		self.updateValues()
		if(self.depletedExtracted>0) then
			print("Started changing rods")
			self.turnOffReactor()
		
			local count = 1
			while(self.depletedExtracted>0) do
				print("Changing n " .. count)
				self.comp.setBundledOutput(self.redstoneSide, colors.grey, 15)
				os.sleep(1)
				self.comp.setBundledOutput(self.redstoneSide, colors.grey, 0)
				os.sleep(1)
				self.updateValues()
				count = count + 1
			end
			print("Finished changing rods")
			self.turnOnReactor()
		end
		self.comp.setBundledOutput(self.redstoneSide, colors.black, 0)
	end

	checkForBatteryStatus = function(self)
		local latch = false
		repeat
			self.updateValues()
			if(self.batteryStatus>14 & latch == false) then
				print("Battery full, stopping reactor" .. self.batteryStatus)
				self.turnOffReactor()
				latch = true
			end

			if(self.batteryStatus<2 & latch == true) then
				print("Battery depleted, restarting reactor" .. self.batteryStatus)
				self.turnOnReactor()
				latch = false
			end

			if(latch == true) then
				os.sleep(10)
			end
		until not latch
	end
end





	


