	--startup

	local component = require("component")
	local sides = require("sides")

	rsOutput = component.proxy("2009c856-ba4d-4449-afb4-37ceae46619d")
	rsRefill = component.proxy("81161fbe-f767-4ae0-acc2-ca869b393692")


	rsOutput.setOutput(sides.east, 0)
	rsRefill.setOutput(sides.east, 0) 		--stop coolant refill
	rsRefill.setOutput(sides.west, 0) 		--stop quad refill
	startCoolant = rsOutput.getInput(sides.west)
	startCell = rsOutput.getInput(sides.south)
	if (startCoolant > 0 and startCell > 0) then			-- *Both coolant and cell, something went wrong*
		print("Something went wrong")
		rsOutput.setOutput(sides.east, 14) 		--stop output
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor TODO turn on some lights?
	else
		rsOutput.setOutput(sides.bottom, 14)	--start reactor
	end


while true do
	os.sleep(0.1)

	local coolant = rsOutput.getInput(sides.west)
	local cell = rsOutput.getInput(sides.south)
	local energyQty = rsRefill.getInput(sides.north)
	--rsOutput
		--east: export from reactor
		--bottom: turn on and off reactor
		--south: rs input for export depleted
		--west: rs input for export coolant

	--rsRefill
		--bottom: rs input for quantity of coolant
		--east: insert coolant
		--south: insert quad

	if (energyQty == 14) then
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor, batteries full
		print("Reactor stopped, batteries are full: " + energyQty)
		print("Checking again in 20 seconds")
		os.sleep(20)
	elseif (coolant > 0 and cell > 0) then		-- *Both coolant and cell, something went wrong*
		print("Something went wrong")
		rsOutput.setOutput(sides.east, 14) 		--stop output
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor TODO turn on some lights?
	elseif (coolant > 0 and cell == 0) then		-- *Coolant, stop reactor, process and refill, start reactor*
		print("Changing coolant")
		rsOutput.setOutput(sides.east, 14) 		--stop output, process coolant
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor
		rsRefill.setOutput(sides.east, 14) 		--refill coolant
		os.sleep(1)
		rsRefill.setOutput(sides.east, 0) 		--stop refill
		rsOutput.setOutput(sides.east, 0)		--start output
		os.sleep(1)
		coolantAgain = rsOutput.getInput(sides.west)
		while(coolantAgain > 0) do
			print("Changing coolant again")
			rsOutput.setOutput(sides.east, 14) 		--stop output, process coolant
			rsRefill.setOutput(sides.east, 14) 		--refill coolant
			os.sleep(1)
			rsRefill.setOutput(sides.east, 0) 		--stop refill
			rsOutput.setOutput(sides.east, 0)		--start output
			os.sleep(1)
			coolantAgain = rsOutput.getInput(sides.west)
		end
		rsOutput.setOutput(sides.bottom, 14) 	--start reactor
		rsOutput.setOutput(sides.east, 0)		--start output
		print("Coolant changed")
	elseif(coolant == 0 and cell > 0) then		-- *Quad, stop reactor,  refill, start reactor*
		print("Changing quad")
		rsOutput.setOutput(sides.east, 14) 		--stop output, process coolant
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor
		rsRefill.setOutput(sides.west, 14) 		--refill quad
		os.sleep(1)
		rsRefill.setOutput(sides.west, 0) 		--stop refill
		rsOutput.setOutput(sides.bottom, 14) 	--start reactor
		rsOutput.setOutput(sides.east, 0)		--start output
		print("Qaud changed")
	end
end







