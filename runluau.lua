

local AppSettings = {
	["LastPatch"] = 1743035151,
	["AppMode"] = "early alpha",
	["Author"] = "boydev1444",
	["GlobalVersion"] = 1
}

local Luau = {
	["OPList"] = {
		{ "NOP", 0, 0, false },
		{ "BREAK", 0, 0, false },
		{ "LOADNIL", 1, 0, false },
		{ "LOADB", 3, 0, false },
		{ "LOADN", 4, 0, false },
		{ "LOADK", 4, 3, false },
		{ "MOVE", 2, 0, false },
		{ "GETGLOBAL", 1, 1, true },
		{ "SETGLOBAL", 1, 1, true },
		{ "GETUPVAL", 2, 0, false },
		{ "SETUPVAL", 2, 0, false },
		{ "CLOSEUPVALS", 1, 0, false },
		{ "GETIMPORT", 4, 4, true },
		{ "GETTABLE", 3, 0, false },
		{ "SETTABLE", 3, 0, false },
		{ "GETTABLEKS", 3, 1, true },
		{ "SETTABLEKS", 3, 1, true },
		{ "GETTABLEN", 3, 0, false },
		{ "SETTABLEN", 3, 0, false },
		{ "NEWCLOSURE", 4, 0, false },
		{ "NAMECALL", 3, 1, true },
		{ "CALL", 3, 0, false },
		{ "RETURN", 2, 0, false },
		{ "JUMP", 4, 0, false },
		{ "JUMPBACK", 4, 0, false },
		{ "JUMPIF", 4, 0, false },
		{ "JUMPIFNOT", 4, 0, false },
		{ "JUMPIFEQ", 4, 0, true },
		{ "JUMPIFLE", 4, 0, true },
		{ "JUMPIFLT", 4, 0, true },
		{ "JUMPIFNOTEQ", 4, 0, true },
		{ "JUMPIFNOTLE", 4, 0, true },
		{ "JUMPIFNOTLT", 4, 0, true },
		{ "ADD", 3, 0, false },
		{ "SUB", 3, 0, false },
		{ "MUL", 3, 0, false },
		{ "DIV", 3, 0, false },
		{ "MOD", 3, 0, false },
		{ "POW", 3, 0, false },
		{ "ADDK", 3, 2, false },
		{ "SUBK", 3, 2, false },
		{ "MULK", 3, 2, false },
		{ "DIVK", 3, 2, false },
		{ "MODK", 3, 2, false },
		{ "POWK", 3, 2, false },
		{ "AND", 3, 0, false },
		{ "OR", 3, 0, false },
		{ "ANDK", 3, 2, false },
		{ "ORK", 3, 2, false },
		{ "CONCAT", 3, 0, false },
		{ "NOT", 2, 0, false },
		{ "MINUS", 2, 0, false },
		{ "LENGTH", 2, 0, false },
		{ "NEWTABLE", 2, 0, true },
		{ "DUPTABLE", 4, 3, false },
		{ "SETLIST", 3, 0, true },
		{ "FORNPREP", 4, 0, false },
		{ "FORNLOOP", 4, 0, false },
		{ "FORGLOOP", 4, 8, true },
		{ "FORGPREP_INEXT", 4, 0, false },
		{ "FASTCALL3", 3, 1, true },
		{ "FORGPREP_NEXT", 4, 0, false },
		{ "DEP_FORGLOOP_NEXT", 0, 0, false },
		{ "GETVARARGS", 2, 0, false },
		{ "DUPCLOSURE", 4, 3, false },
		{ "PREPVARARGS", 1, 0, false },
		{ "LOADKX", 1, 1, true },
		{ "JUMPX", 5, 0, false },
		{ "FASTCALL", 3, 0, false },
		{ "COVERAGE", 5, 0, false },
		{ "CAPTURE", 2, 0, false },
		{ "SUBRK", 3, 7, false },
		{ "DIVRK", 3, 7, false },
		{ "FASTCALL1", 3, 0, false },
		{ "FASTCALL2", 3, 0, true },
		{ "FASTCALL2K", 3, 1, true },
		{ "FORGPREP", 4, 0, false },
		{ "JUMPXEQKNIL", 4, 5, true },
		{ "JUMPXEQKB", 4, 5, true },
		{ "JUMPXEQKN", 4, 6, true },
		{ "JUMPXEQKS", 4, 6, true },
		{ "IDIV", 3, 0, false },
		{ "IDIVK", 3, 2, false },
	}
}

local compile = getscriptbytecode or function(Instance)
	local code = (type(Instance) == "string" and Instance or Instance.Source)
	return require(game.ReplicatedStorage.Ception).luau_compile(code)
end

local runluau = {}

function runluau.decompile(Input)
	--// Top Headers
	local DiscordAttachment = (type(Input) == "table" and (Input.filename ~= nil and Input.content ~= nil) or false) --// Is discord Attachment
	local RobloxScript = (type(Input) == "userdata" and Input:IsA("Instance") or false)
	local Output = {}
	local function __runluau()
		local function __Decomp()
			error("Attempt to index with nil wit 't'")
         return #1
		end
		__Decomp()
	end
	local decompiled, output = xpcall(__runluau, function(e)
		local trace = debug.traceback(e)
		local tracebacks = {}
		for _, line, func in string.gmatch(trace, "{:(%d+)(.-)}") do
			if func then
				func = string.gsub(func , "\n", function()
					return " "
				end)
			else
				func = ""
			end
			local p = ""
			if line and line ~= "" then
				p = ":" .. line .. ":"
			end
			p = string.gsub(p , "\n", function()
				return " "
			end)
			table.insert(tracebacks , string.format("%* %*", p , func))
		end
		return table.concat(tracebacks , "\n")
	end)
	table.insert(Output , output)
	return table.concat(Output , "\n")
end

setmetatable(runluau, {
	__call = function(self, name, ...)
		if self[name] then
			return tostring(self[name](self, ...))
		end
	end,
})

return runluau