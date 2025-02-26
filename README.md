![Main](/imgs/runluau_dec.png "RunLuau Introduction")
# Introduction

- RunLuau is a powerful decompiler than reads the bytecode, and coverts it into readable and working code.
- RunLuau is a decompiler 100% programmed with Lua
- RunLuau decompiler works with [Luac](https://luac.nl) compiler, we are working in handle it with binary bytecode!
- You can check the [patches list](/RepPatches.md) for more information!

## How it works?

- RunLuau decompiler with a imput of the bytecode "disassembles" all the bytecode information, for next, convert it to readable lua code.
- You can check the following code example:
```lua
local bytecode = BYTECODE_INPUT
local ENV = (getfenv or getrenv or getgenv)()
local ldecompile = Decompile or decompile or ENV["decompile"]
print(ldecompile(BYTECODE_INPUT , CUSTOM_OPTIONS))
```

## How to load and set-up (All types)
- You can check the following load example:
```lua
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
		["DecompilationDateOnTop"] = true, -- Shows the decompilation date on top of the decompilation
		["ListUpvalues"] = true, -- Shows a list of upvalues on top of the decompilation
		["ShowAllVariables"] = false, -- Shows all variables (Global, local, upvalues, constants) on top of the decompilation
		["ShowLocalVariables"] = false, -- Shows a list of local variables on top of output
	},
}
local output = runluau_decompile(Input , CustomOptions) -- Main process
local writefile = writefile
writefile("Output.lua", output)
```

## Extra
- **WARNING** I made this decompiler in 1 night and it can have bad structured code, and it can have bugs, so be careful with it (I'm working on the decompiler 24/7)

- RunLuau decompiler only can read [Lua 5.1](https://www.lua.org/manual/5.1/) bytecode
  - If you set a lower or higher version of the specified version, the decompiler is gonna return a error of unhandled version.

- If you are gonna decompile a file, it must be to be a compiled file of the page before mentioned, if it isn't the decompiler isn't gonna can read it, and send a error
![CompileExample](/imgs/compilexample.png)

## Upcoming
- We are working in handle higher versions of Lua (5.1 -> Higher version)
- We are active checking all glitches in the Issues section!