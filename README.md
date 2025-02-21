![Main](/imgs/runluau_dec.png "RunLuau Introduction")
# Introduction

- RunLuau is a powerful decompiler than compiles a bytecode, and coverts it into readable and working code.

- RunLuau decompiler works with [Luac](https://luac.nl) compiler, we are working in handle it with binary bytecode!

## How it works?

- RunLuau decompiler with a imput of the bytecode "disassembles" all the bytecode information, for next, convert it to readable lua code.
- You can check the [Example.lua](/example.lua) file or the following code example:
```lua
local bytecode = BYTECODE_INPUT
print(Decompile(BYTECODE_INPUT , CUSTOM_OPTIONS))
```

## Extra

- RunLuau decompiler only can read [Lua 5.1](https://www.lua.org/manual/5.1/) bytecode
  - If you set a lower or higher version of the specified version, the decompiler is gonna return a error of unhandled version.

- If you are gonna decompile a file, it must be to be a compiled file of the page before mentioned, if it isn't the decompiler isn't gonna can read it, and send a error
![CompileExample](/imgs/compilexample.png)

## Upcoming
- We are working in handle higher versions of Lua (5.1 -> Higher version)
- We are active checking all glitches in the Issues section!