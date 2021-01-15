while true do
	os.sleep(0.1)
	local component = require("component")
	local sides = require("sides")

	rsOutput = component.proxy("2009c856-ba4d-4449-afb4-37ceae46619d")
	rsRefill = component.proxy("81161fbe-f767-4ae0-acc2-ca869b393692")

	local coolant = rsOutput.getInput(sides.west)
	local cell = rsOutput.getInput(sides.south)

	--rsOutput
		--east: export from reactor
		--bottom: turn on and off reactor
		--south: rs input for export depleted
		--west: rs input for export coolant

	--rsRefill
		--bottom: rs input for quantity of coolant
		--east: insert coolant
		--south: insert quad

	if (coolant > 0 & cell > 0) then			-- *Both coolant and cell, something went wrong*
		print("Something went wrong")
		rsOutput.setOutput(sides.east, 14) 		--stop output
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor TODO turn on some lights?
	elseif (coolant > 0 & cell == 0) then		-- *Coolant, stop reactor, process and refill, start reactor*
		print("Changing coolant")
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor
		rsOutput.setOutput(sides.east, 14) 		--stop output, process coolant
		rsRefill.setOutput(sides.north, 14) 	--refill coolant
		os.sleep(1)
		rsRefill.setOutput(sides.north, 0) 		--stop refill
		rsOutput.setOutput(sides.bottom, 14) 	--start reactor
	elseif(coolant == 0 & cell > 0) then		-- *Quad, stop reactor,  refill, start reactor*
		print("Changing quad")
		rsOutput.setOutput(sides.bottom, 0)		--stop reactor
		rsRefill.setOutput(sides.west, 14) 		--refill quad
		os.sleep(1)
		rsRefill.setOutput(sides.west, 0) 		--stop refill
		rsOutput.setOutput(sides.bottom, 14) 	--start reactor
	end
end







