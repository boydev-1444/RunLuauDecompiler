-- WARNING! USING ROLOX EXPLOIT ENVIRONENT
local URL = "https://raw.githubusercontent.com/boydev-1444/RunLuauDecompiler/main/runluau.lua"
local runluau_decompile = loadstring(game:HttpGet(URL))
local Input = nil -- [[Some luac.nl bytecode input]]
local CustomOptions = {
	["DecompilerTimeOut"] = 10, -- Maximum time to decompile (If it passes it returns "Decompiler Timeout") (VALUE 0 OR NIL NOTHING WILL HAPPEN IF DECOMPILATION TIME EXCEEDS TOO LONG)
	["ShowUsedGlobals"] = true, -- Show all items than are used in ENV on top of output
	["ElapsedTime"] = true, -- When you call "Decompile(...)" it returns and shows in output the elapsed time of the process
	["SemiColons"] = true, -- When line gets generated, it is gonna add a ";" in the end
	["HelpComments"] = true,
	["Flags"] = { -- Add/remove/change the values of the script
		["Disassemble"] = true, -- Disassembled view of the bytecode
		["Logs"] = true, -- Enables/Disables the logging system
		["DecompilationDateOnTop"] = true, -- Shows the decompilation date on top of the decompilation
		["ListUpvalues"] = true, -- Shows a list of upvalues on top of the decompilation
		["ShowAllVariables"] = false, -- Shows all variables (Global, local, upvalues, constants) on top of the decompilation
		["ShowLocalVariables"] = false, -- Shows a list of local variables on top of output
	},
}
-- SECOND WARNING! THIS DECOMPILER IS NEW, IM WORKING ON IT, CAN HAVE A LOT OF ERRORS
local output = runluau_decompile(Input , CustomOptions) -- Main process
local writefile = writefile
writefile("Output.lua", output)