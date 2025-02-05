local Luau = {}

local Opcodes = {
	"MOVE", "LOADK", "LOADBOOL", "LOADNIL", "GETUPVAL", "GETGLOBAL", "GETTABLE",
	"SETGLOBAL", "SETUPVAL", "SETTABLE", "NEWTABLE", "SELF", "ADD", "SUB", "MUL", "DIV", "MOD",
	"POW", "UNM", "NOT", "LEN", "CONCAT", "JMP", "EQ", "LT", "LE", "TEST", "TESTSET",
	"CALL", "TAILCALL", "RETURN", "FORLOOP", "FORPREP", "TFORLOOP", "SETLIST", "CLOSE", "CLOSURE", "VARARG"
}


function Luau:ISVALIDOP(opName)
    local valid = false
    for _ , opcodeName in pairs(Opcodes) do
       if opcodeName == opName then
          valid = true
          break
       end
    end
    return valid
end

return Luau