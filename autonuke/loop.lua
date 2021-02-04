local component = require("component")
local sides = require("sides")
local colors = require("colors")

--[[ 
How to
Colors:
	Blue: input for overTemperature
	Light gray: battery charge
	White: output to turn on/off reactor
	Red: output to start extracting coolant
	Black: output to start extracting depleted
	Yellow: output to start inserting coolant
	Gray: output to start inserting rods
	Green: input for average EU
--]]
local function newReactor(proxyID, rsSide)

	local reac = {
	comp = component.proxy(proxyID);
	redstoneSide = rsSide;
	tempReading = 0; --number, Blue input
	batteryStatus = 0; --number, Light gray input
	avgEU = 0;--number, Green input
	--reactorStatus --boolean, White output
	--coolantExport	--boolean, Red output
	--depletedExport --boolean, Black output
	--coolantInsert --boolean, Yellow output
	--rodInsert --boolean, Gray output
	tempResetCount = 0;
	offOnThermalSafe = false;

	cycleResetForTemp = 19;
	cycleCounter = 0;
	maxResetForTemp = 3;
	batteryLatch = false;
	}
	return reac;
end

local function updateAllValues(reactorTable)
	for k,reactor in pairs(reactorTable) do
		reactor.tempReading = reactor.comp.getBundledInput(reactor.redstoneSide, colors.blue)
		reactor.batteryStatus = reactor.comp.getBundledInput(reactor.redstoneSide, colors.lightblue)
		reactor.avgEU = reactor.comp.getBundledInput(reactor.redstoneSide, colors.green)
	end
end

local function updateValues(reactor)
	reactor.tempReading = reactor.comp.getBundledInput(reactor.redstoneSide, colors.blue)
	reactor.batteryStatus = reactor.comp.getBundledInput(reactor.redstoneSide, colors.lightblue)
	reactor.avgEU = reactor.comp.getBundledInput(reactor.redstoneSide, colors.green)
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

local function resetAll(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.gray, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.white, 0)
end

--[[ TODO WIP
local function checkForTemperature(reactorTable)
	for k,reactor in pairs(reactorTable) do
		if(reactor.tempResetCount>reactor.maxResetForTemp) then
			turnOffReactor(reactor)
			print("Reactor n " .. k .. " off on thermal safe")
			reactor.offOnThermalSafe = true
		else
			if(reactor.tempReading>0) then
				reactor.tempResetCount = reactor.tempResetCount + 1
				print("Reactor " .. k .. " turned off on thermals n " .. reactor.tempResetCount .. " times")
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
end
--]]

local function startChangeCoolant(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 255)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 255)
end

local function stopChangeCoolant(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 0)
	os.sleep(1)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 0)
end

local function changeDepleted(reactor)
	print("Changing Rods")
	turnOffReactor(reactor)
	stopChangeCoolant(reactor)
	os.sleep(1)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 255)
	os.sleep(5) 
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 0)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.gray, 255)
	os.sleep(5)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.gray, 0)
	turnOnReactor(reactor)
	print("Rods Changed")
	os.sleep(1)
	startChangeCoolant(reactor)
end

local function checkForDepleted(reactorTable)
	for k,reactor in pairs(reactorTable) do
		updateValues(reactor)
	if(reactor.batteryStatus<40 and reactor.comp.getBundledOutput(reactor.redstoneSide, colors.white) > 0 and reactor.avgEU == 0) then
		print("Rods depleted on reactor n " .. k ..", getting ready to change them")
		print("avgEU: " .. reactor.avgEU .. " battery status: " .. reactor.batteryStatus)
		changeDepleted(reactor)
		os.sleep(5)
	end
end

local function checkForBatteryStatus(reactorTable)
	for k,reactor in pairs(reactorTable) do
		updateValues(reactor)
		if(reactor.batteryStatus>215 and not reactor.batteryLatch) then --max 255(?)
			print("Battery full, stopping reactor n " .. k .. ": " .. reactor.batteryStatus)
			turnOffReactor(reactor)
			reactor.batteryLatch = true
		end
		if(reactor.batteryStatus<50 and reactor.batteryLatch ) then
			print("Battery depleted, restarting reactor" .. k .. ": " .. reactor.batteryStatus)
			turnOnReactor(reactor)
			reactor.batteryLatch = false
		end
	end
end

local function initialize(reactorTable)
	for _,reactor in pairs(reactorTable) do
		resetAll(reactor)
		updateValues(reactor)
		checkForTemperature(reactor)
		checkForBatteryStatus(reactor)
		startChangeCoolant(reactor)
		turnOnReactor(reactor)
		os.sleep(2)
		checkForDepleted(reactor)
	end
end

local rs1Code = "29d0a39d-794a-41c6-8f3e-800db8dbd01d"

local reactors = {}
reactors[1] = newReactor(rs1Code, sides.east)
reactors[2] = newReactor(rs1Code, sides.west)

initialize(reactors)

while(true) do
	updateAllValues(reactors)
	--checkForTemperature(reactor)
	checkForBatteryStatus(reactors)
	os.sleep(2)
	checkForDepleted(reactors)
end







	


