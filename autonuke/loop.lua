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
	Green: input if coolant is extracted
	Purple: input if depleted is extracted
--]]
local function newReactor(proxyID, rsSide)

	local reac = {
	comp = component.proxy(proxyID);
	redstoneSide = rsSide;
	tempReading = 0; --number, Blue input
	batteryStatus = 0; --number, Light grey input
	coolantExtracted = 0; --number, Green input
	depletedExtracted = 0; --number, Purple input
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

local updateValues = function(reactor)
	reactor.tempReading = reactor.comp.getBundledInput(reactor.redstoneSide, colors.blue);
	reactor.batteryStatus = reactor.comp.getBundledInput(reactor.redstoneSide, colors.lightblue);
	reactor.coolantExtracted = reactor.comp.getBundledInput(reactor.redstoneSide, colors.green);
	reactor.depletedExtracted = reactor.comp.getBundledInput(reactor.redstoneSide, colors.purple);
end;

local turnOffReactor = function(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.white, 0);
end;

local turnOnReactor = function(reactor)
	if(reactor.offOnThermalSafe) then
		print("Reactor off on thermal safe");
	else
		reactor.comp.setBundledOutput(reactor.redstoneSide, colors.white, 15);
	end;
end;

local checkForTemperature = function(reactor)
	if(reactor.tempResetCount>reactor.maxResetForTemp) then
		turnOffReactor(reactor);
		print("Reactor off on thermal safe");
		reactor.offOnThermalSafe = true;
	else
		local isReset = true;
		if(reactor.tempReading>0) then
			reactor.tempResetCount = sreactorelf.tempResetCount + 1;
			print("Reactor turned off on thermals n" .. tempResetCount);
			isReset = false;
		else
			reactor.cycleCounter = reactor.cycleCounter + 1;
			if(reactor.cycleCounter>=19) then
				reactor.tempResetCount = 0;
				reactor.cycleCounter = 0;
			end;
		end;
		while(isReset == false) do
			updateValues(reactor);
			os.sleep(1);
			if(reactor.tempReading == 0) then
				isReset = true;
			end;
		end;
	end;
end;

local checkForCoolant = function(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 15);
	os.sleep(1);
	updateValues(reactor);
	if(reactor.coolantExtracted>0) then
		print("Started changing coolant");
		turnOffReactor(reactor);
	
		local count = 1;
		while(reactor.coolantExtracted>0) do
			print("Changing n " .. count);
			reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 15);
			os.sleep(1);
			reactor.comp.setBundledOutput(reactor.redstoneSide, colors.yellow, 0);
			os.sleep(1);
			updateValues(reactor);
			count = count + 1;
		end;
		print("Finished changing coolant");
		turnOnReactor(reactor);
	end;
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.red, 0);
end;

local checkForDepleted = function(reactor)
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 15);
	os.sleep(1);
	updateValues(reactor);
	if(reactor.depletedExtracted>0) then
		print("Started changing rods");
		turnOffReactor(reactor);
	
		local count = 1;
		while(reactor.depletedExtracted>0) do
			print("Changing n " .. count);
			reactor.comp.setBundledOutput(reactor.redstoneSide, colors.gray, 15);
			os.sleep(1);
			reactor.comp.setBundledOutput(reactor.redstoneSide, colors.gray, 0);
			os.sleep(1);
			updateValues(reactor);
			count = count + 1;
		end;
		print("Finished changing rods");
		turnOnReactor(reactor);
	end;
	reactor.comp.setBundledOutput(reactor.redstoneSide, colors.black, 0);
end;

local checkForBatteryStatus = function(reactor)
	local latch = false;
	repeat
		updateValues(reactor);
		if(reactor.batteryStatus>14 and not latch) then
			print("Battery full, stopping reactor" .. reactor.batteryStatus);
			turnOffReactor(reactor);
			latch = true;
		end

		if(reactor.batteryStatus<2 and latch ) then
			print("Battery depleted, restarting reactor" .. reactor.batteryStatus);
			turnOnReactor(reactor);
			latch = false;
		end;
		if(latch == true) then
			os.sleep(10);
		end;
	until not latch
end;

local initialize = function (reactor)
	updateValues(reactor);
	checkForTemperature(reactor);
	checkForCoolant(reactor);
	checkForDepleted(reactor);
	checkForBatteryStatus(reactor);
	turnOnReactor(reactor);
end;

local rs1Code = "2009c856-ba4d-4449-afb4-37ceae46619d"

local reactor = newReactor(rs1Code, sides.south)

initialize(reactor)

while(true) do
	updateValues(reactor)
	checkForTemperature(reactor)
	checkForCoolant(reactor)
	checkForDepleted(reactor)
	checkForBatteryStatus(reactor)

	os.sleep(1)
end







	


