-- RunLuauBinary (RunLuauBin) made for runluau
--!runluau-bin 
--!by-runluau

local len = string.len
local sub = string.sub
local byte = string.byte
local split = string.split
local gsub = string.gsub
local RunLuauBin = {}

-- Converts a text into runluau encoding format
function RunLuauBin.encode(input)
	local total_characters = len(input)
	local encoded = {}
	for i = 1 , total_characters do
		local char = sub(input, i)
		if char then
			local byte_string = ((((byte(char) * 1000) / 500) * 2550) * 360) * (total_characters / 100)
			table.insert(encoded , byte_string)
		end
	end
	return table.concat(encoded , ":")..`!BSIZE:{total_characters}!`
end

-- Converts the runluau encoded input to readable text
function RunLuauBin.decode(input)
	local total_characters = nil
	local decoded = {}
	input = gsub(input , "!BSIZE:(-?%d+)!" , function(size)
		if not total_characters then
			total_characters = tonumber(size)
			return ""
		end
	end)
	if not total_characters then
		return error(`RunLuauBin.decode Attempt #1 to decode input, missing key size`)
	end
	local chunks = split(input,":")
	for i = 1 , #chunks do
		local byte_number = chunks[i]
		byte_number = tonumber(byte_number)
		if byte_number then
			local char_string = (((((byte_number * (100 / total_characters)) / 360) / 2550) * 500) / 1000)
			local char = string.char(char_string)
			table.insert(decoded , char)
		end
	end
	return table.concat(decoded)
end