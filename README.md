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
- You can check the following load examples:
- [Exploit Environment File](/setup_examples/Exploit.lua)
- [Visual Studio File](/setup_examples/VisualStudio.lua)
- [Roblox Studio File](/setup_examples/RobloxStudio.lua)

## Extra
- **WARNING** I made this decompiler in 1 night and it can have bad structured code, and it can have bugs, so be careful with it (I'm working on the decompiler 24/7)

- RunLuau decompiler only can read [Lua 5.1](https://www.lua.org/manual/5.1/) bytecode
  - If you set a lower or higher version of the specified version, the decompiler is gonna return a error of unhandled version.

- If you are gonna decompile a file, it must be to be a compiled file of the page before mentioned, if it isn't the decompiler isn't gonna can read it, and send a error
![CompileExample](/imgs/compilexample.png)

## Upcoming
- We are working in handle higher versions of Lua (5.1 -> Higher version)
- We are active checking all glitches in the Issues section!