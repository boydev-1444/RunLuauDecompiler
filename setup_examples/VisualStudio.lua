local http = require("socket.http")
local ltn12 = require("ltn12")
local url = "https://raw.githubusercontent.com/boydev-1444/RunLuauDecompiler/main/runluau.lua"
local data = {}
local options = {
	["DecompilerTimeOut"] = 10, -- Maximum time to decompile (If it passes it returns "Decompiler Timeout") (VALUE 0 OR NIL NOTHING WILL HAPPEN IF DECOMPILATION TIME EXCEEDS TOO LONG)
	["ShowUsedGlobals"] = true, -- Show all items than are used in ENV on top of output
	["ElapsedTime"] = true, -- When you call "Decompile(...)" it returns and shows in output the elapsed time of the process
	["SemiColons"] = true, -- When line gets generated, it is gonna add a ";" in the end
	["HelpComments"] = true,
	["Flags"] = { -- Add/remove/change the values of the script
		["Disassemble"] = true, -- Disassembled view of the bytecode
		["DecompilationDateOnTop"] = true, -- Shows the decompilation date on top of the decompilation
		["ListUpvalues"] = true, -- Shows a list of upvalues on top of the decompilation
		["ShowAllVariables"] = false, -- Shows all variables (Global, local, upvalues, constants) on top of the decompilation
		["ShowLocalVariables"] = false, -- Shows a list of local variables on top of output
	},
}
local res, code, headers, status = http.request {
    url = url,
    sink = ltn12.sink.table(data),
    method = "GET",
}
if code == 200 then
    local src = load(code)
    if src then
        local file = io.open("InputBytecode.lua", "r")
        local luac_nl_input = file:read("*all")
        local runluau_decompile = src
        local result = runluau_decompile(luac_nl_input , options)
        local file = io.open("Runluau_output.lua", "w")
        file:write(result)
        file:close()
    end
else
    print("Failed to get Runluau source: "..tostring(res))
end