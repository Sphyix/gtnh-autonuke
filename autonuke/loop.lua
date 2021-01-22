local component = require("component")
local sides = require("sides")
local colors = require("colors")

--[[ 
How to
Colors:
	Blue: input for overTemperature
	Light grey: battery charge
	White: output to turn on/off reactor
	Red: output to start extracting coolant
	Black: output to start extracting depleted
	Yellow: output to start inserting coolant
	Grey: output to start inserting rods
	Green: input for average EU
--]]
local function newReactor(proxyID, rsSide)

	local reac = {
	comp = component.proxy(proxyID);
	redstoneSide = rsSide;
	tempReading = 0; --number, Blue input
	batteryStatus = 0; --number, Light grey input
	avgEU = 0;--number, Green input
	--reactorStatus --boolean, White output
	--coolantExport	--boolean, Red output
	--depletedExport --boolean, Black output
	--coolantInsert --boolean, Yellow output
	--rodInsert --boolean, Grey output
	tempResetCount = 0; --number
	offOnThermalSafe = false;

	cycleResetForTemp = 19;
	cycleCounter = 0;
	maxResetForTemp = 3;
	}
	return reac;
end

local function updateValues(reactor)
	reactor.tempReading = reactor.comp.getBundledInput(reactor.redstoneSide, colors.blue)
	reactor.batteryStatus = reactor.comp.getBundledInput(reactor.redstoneSide, colors.lightblue)
	reactor.coolantExtracted = reactor.comp.getBundledInput(reactor.redstoneSide, colors.green)
	reactor.depletedExtracted = reactor.comp.getBundledInput(reactor.redstoneSide, colors.purple)
end

local function turnOffReactor(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.white, 0)
end

local function turnOnReactor(reactor)
	if(reactor.offOnThermalSafe) then
		print("Reactor off on thermal safe")
	else
		reactor.comp.setBundledOutput(reactor.redstoneSide, colors.white, 255)
	end
end

local function checkForTemperature(reactor)
	if(reactor.tempResetCount>reactor.maxResetForTemp) then
		turnOffReactor(reactor)
		print("Reactor off on thermal safe")
		reactor.offOnThermalSafe = true
	else
		local isReset = true
		if(reactor.tempReading>0) then
			reactor.tempResetCount = reactor.tempResetCount + 1
			print("Reactor turned off on thermals n " .. reactor.tempResetCount)
			isReset = false
		else
			reactor.cycleCounter = reactor.cycleCounter + 1
			if(reactor.cycleCounter>=19) then
				reactor.tempResetCount = 0
				reactor.cycleCounter = 0
			end
		end
		while(isReset == false) do
			updateValues(reactor)
			os.sleep(1)
			if(reactor.tempReading == 0) then
				isReset = true
			end
		end
	end
end

local function startChangeCoolant(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 255)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 255)
end

local function stopChangeCoolant(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 255)
	os.sleep(1)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 255)
end

local function changeDepleted(reactor)
	print("Changing Rods")
	turnOffReactor(reactor)
	stopChangeCoolant(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 0)
	os.sleep(1)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 255)
	os.sleep(5) 
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.grey, 255)
	os.sleep(5)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.grey, 0)
	turnOnReactor(reactor)
	print("Rods Changed")
	os.sleep(1)
	startChangeCoolant(reactor)
end

local function checkForDepleted(reactor)
	updateValues(reactor)
	if(reactor.batteryStatus<20 and reactor.comp.getBundledOutput(reactor.redstoneSide, colors.white) > 0 and reactor.avgEU == 0) then
		print("Rods depleted, getting ready to change them")
	end
end

local function checkForBatteryStatus(reactor)
	local latch = false
	repeat
		updateValues(reactor)
		if(reactor.batteryStatus>215 and not latch) then --max 221
			print("Battery full, stopping reactor" .. reactor.batteryStatus)
			turnOffReactor(reactor)
			latch = true
		end

		if(reactor.batteryStatus<20 and latch ) then
			print("Battery depleted, restarting reactor" .. reactor.batteryStatus)
			turnOnReactor(reactor)
			latch = false
		end
		if(latch == true) then
			os.sleep(10)
		end
	until not latch
end

local function initialize(reactor)
	updateValues(reactor)
	checkForTemperature(reactor)
	checkForBatteryStatus(reactor)
	startChangeCoolant(reactor)
	turnOnReactor(reactor)
	os.sleep(2)
	checkForDepleted(reactor)
end

local rs1Code = "2009c856-ba4d-4449-afb4-37ceae46619d"

local reactor = newReactor(rs1Code, sides.south)

initialize(reactor)

while(true) do
	updateValues(reactor)
	checkForTemperature(reactor)
	checkForBatteryStatus(reactor)
	os.sleep(2)
	checkForDepleted(reactor)
end







	


