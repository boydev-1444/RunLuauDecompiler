--!nonstrict

local DEFAULT_OPTIONS = {
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

local RunService = game:GetService("RunService")
local Http = game:GetService("HttpService")
local format = string.format
local random = math.random
local abs = math.abs
local VariableDefault = "v%s"
local GlobalENV = (getfenv or getrenv or getgenv)()
local ForceHttp = true

function Resquest(url)
	local Loaded , Result = nil , nil
	if ForceHttp then
	    Loaded , Result = pcall(Http.GetAsync , Http , url , true)
	else
	    Loaded , Result = pcall(game.GetHttp , game , url , true)
	end
	return Loaded , Result
end

function CallLoadstring(chunk)
	local Loadstringed , Result = nil , nil
	Loadstringed , Result = pcall(loadstring , chunk)
	return Result
end

function LoadFromUrl(file)
	local USER_BRANCH = "boydev-1444"
	local BRANCH_NAME = "main"
	local URL = "https://raw.githubusercontent.com/%s/RunLuauDecompiler/%s/%s.lua"
	local FormattedURL = format(URL , USER_BRANCH , BRANCH_NAME , file)
	local Loaded , Result = Resquest(FormattedURL)
	if not Loaded then
		warn(`{random()} FAILED TO LOAD MODULE "{file}" : {tostring(Result)}`)
		return
	end
	local Callback = CallLoadstring(Result)
	local CallbackType = typeof(Callback)
	if CallbackType ~= "function" then
		warn(`{random()} FAILED TO LOADSTRING CHUNK "{CallbackType}" (function expected)`)
		return
	end
	return Callback()
end

local Luau = LoadFromUrl("Luau")
function Decompile(bytecode , options , IS_FUNCTION_BODY)
	options = options or DEFAULT_OPTIONS
	local elapsed_t = tick() -- @field Elapsed time
	local function IsFlagEnabled(flagName)
		if options then
			if options.Flags then
				if options.Flags[flagName] then
					return options.Flags[flagName] == true
				end
			end
		end
		return false
	end
	-- @field Custom/Default Options
	local TIMEOUT_ENABLED , TIMEOUT_LIMIT = (options.DecompilerTimeOut ~= 0 and options.DecompilerTimeOut ~= nil) and true or false , options.DecompilerTimeOut or nil
	local GLOBALS_ENABLED = options.ShowUsedGlobals or false
	local RETURNS_ELAPSED_TIME = options.ElapsedTime or false
	local SEMICOLONS = options.SemiColons or false
	local HELP_COMMENTS_ENABLED = options.HelpComments or false
	-- @field Custom/Default Flags
	local Disassemble = IsFlagEnabled("Disassemble")
	local Logs = IsFlagEnabled("Logs")
	local Verbose = IsFlagEnabled("Verbose")
	local DecoDate = IsFlagEnabled("DecompilationDateOnTop")
	local Upvalues = IsFlagEnabled("ListUpvalues")
	local Constants = IsFlagEnabled("ShowConstants")
	local AllVariables = IsFlagEnabled("ShowAllVariables")
	local LocalVariables = IsFlagEnabled("ShowLocalVariables")

	local RestrictGlobals = false
	if AllVariables == true then
		LocalVariables = false
		RestrictGlobals = true
	end
	if GLOBALS_ENABLED == true and LocalVariables == true then
		RestrictGlobals = true
		LocalVariables = false
		AllVariables = true
	end
	local function GetEnabledFlags()
		local Flags = {}
		if options and options.Flags then
			for FlagName , FlagValue in pairs(options.Flags) do
				if IsFlagEnabled(FlagName) then
					table.insert(Flags , FlagName)
				end
			end
		end
		return Flags
	end
	local EnabledFlags = GetEnabledFlags()
	local ref_variables = {}
	local startLinePos = "NOT_FOUNDED_BY_RUNLUAU"
	local finished1 , finished2 = false , false
	local constants = {}
	local ignoringLines = {}
	local ready_functions = {}
	local globalArgs = 0
	local typeof_quotes = {`"`,"`","'"}
	local function Decomp()
		local output = {}
		local globals = {}
		local function insert_constant(x)
			if GlobalENV[x] then
				table.insert(globals, x)
			end
			if not table.find(constants , x) then
				table.insert(constants , x)
			end
		end
		local function cleanQuotes(str)
			for _ , quote in typeof_quotes do
				str = string.gsub(str , quote , "")
			end
			return str
		end
		local function GetEscape(x , helpArg , returnFormatted)
			local escape = `.%s`
			x = cleanQuotes(x)
			if x == "-" then
				escape = "[%s]"
				x = VariableDefault:format(helpArg)
			else
				local firstChar = x:sub(1,1)
				local blacklistedFirstChars = {
					"0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
					"!", "@", "#", "$", "%", "^", "&", "*", "(", ")", 
					"-", "=", "+", "{", "}", "|", "\\", ":", ";", "<",
					">", ",", ".", "?", "/", "~"
				}
				if tonumber(firstChar) or table.find(blacklistedFirstChars , firstChar) then
					escape = '["%s"]'
				end
			end
			return returnFormatted and escape:format(x) or escape
		end
		local function SetComment(x,blockinitial_space)
			if x and HELP_COMMENTS_ENABLED then
				return (blockinitial_space and "" or " ").."-- "..tostring(x)
			end
			return ""
		end
		-- STEP 1 : Collect all bytecode information
		local function disassemble()
			local line_pattern = "^(%d+)%s+(%w+)%s*(%d*)%s*(-?%d*)%s*(-?%d*)%s*;?%s*(.*)$"
			local r = {}
			local globalChunk = 1
			local chunks = string.split(bytecode , "\n")
			local total_chunks = #chunks
			local rebuilders = {}
			for i = globalChunk , total_chunks do
				local line = chunks[globalChunk]
				local _ , startLine = line:match("%s*function%s+([%w_]+)%s*%b()%s*--line%s*(%d+)%s*through%s*(%d+)")
				local skipTheLine = false
				if startLine and not finished1 then
					finished1 = true
					startLinePos = startLine
					skipTheLine = true
				end
				if line and not skipTheLine then
					local partIndex , constructor , register , argument , constant , value = string.match(line, line_pattern)
					partIndex = tonumber(partIndex)
					constructor = tostring(constructor)
					register = tonumber(register)
					argument = tonumber(argument)
					constant = tonumber(constant)
					value = tostring(value)
					if partIndex and Luau.ValidOpcode(constructor) then
						local rawFile = {
							partIndex = partIndex,
							constructor = constructor,
							register = register,
							argument = argument,
							constant = constant,
							globalId = globalChunk,
							value = nil,
						}
						local currentValue = value
						if currentValue == "" or currentValue == " " then
							currentValue = nil
						end
						if currentValue then
							local skip = false
							local jump = currentValue:match("to%s*pc%s*(-?%d+)")
							if jump then
								skip = true
								currentValue = tonumber(jump)
							end
							if not skip then
								if constructor:find("CLOSURE") then
									local functionPattern = "%s*function%s*(.*)%s*%(([^)]*)%)%s*@%s*([%w_]+)"
									local name , args , id = currentValue:match(functionPattern)
									if name and id then
										local splittedArguments = string.split(args , ",")
										local function v_prefix(pref)
											local lib = string.split(name, pref)
											if #lib < 2 then return nil end
											local splitted = lib[2]
											local pattern = "%s*function%s*" .. lib[1] .. pref .. splitted .. "%s*%(([^)]*)%)%s*@%s*([%w_]+)"
											if currentValue:match(pattern) then
												return lib[1] , pattern
											end
											return nil , nil
										end
										local isTableFunction , p1 = v_prefix(".")
										local isSelfFunction , p2 = v_prefix(":")
										local alreadyMatched = false
										local pattern = p1 or p2 or ("%s*function%s+" .. name .. "%s*%(([^)]*)%)%s*--line%s*(%d+)%s*through%s*(%d+)")
										local functionRaw = {
											type = "default",
											arguments = {},
											library = nil,
											functionName = VariableDefault:format(register),
											originallyUnammed = true,
											notCalledInScript = false,
											line = "NULL",
											body = {}
										}
										if isSelfFunction and not alreadyMatched then
											table.remove(splittedArguments, 1)
											alreadyMatched = true
											functionRaw.type = "self"
											functionRaw.library = isSelfFunction -- returns library
										end
										if isTableFunction and not alreadyMatched then
											alreadyMatched = true
											functionRaw.type = "table"
											functionRaw.library = isTableFunction -- returns library
										end
										if not isSelfFunction and not isTableFunction then
											functionRaw.functionName = name
											functionRaw.originallyUnammed = false
										end
										functionRaw.arguments = splittedArguments
										currentValue = functionRaw
										insert_constant(name)
										local startChunk = 1
										for i = 1 , total_chunks do
											local line = chunks[i]
											if line then
												if line:match(pattern) then
													local _ , startLine = line:match(pattern)
													functionRaw.line = tonumber(startLine) or "NULL"
													startChunk = i
													break
												end
											end
										end
										startChunk = startChunk
										local currentLine = startChunk + 1
										while currentLine <= #chunks and (chunks[currentLine] and chunks[currentLine] ~= "end") do
											table.insert(functionRaw.body, chunks[currentLine])
											table.insert(ignoringLines , currentLine)
											currentLine = currentLine + 1
											task.wait()
										end
										skip = true
									end
								end
							end
							--// FIX STRINGS
							if type(currentValue) == "string" then
								local ASCII_BROKEN_PATTERN = "\\(%d+)"
								local strlength = #currentValue 
								local fchar , lchar = currentValue:sub(1,1) , currentValue:sub(strlength,strlength)
								if table.find(typeof_quotes , fchar) and table.find(typeof_quotes , lchar) then
									if currentValue:match(ASCII_BROKEN_PATTERN) then
										local positions = {}
										currentValue = string.gsub(currentValue , ASCII_BROKEN_PATTERN , function(ascii)
											table.insert(positions, tostring(ascii))
											return utf8.char(ascii)
										end)
										currentValue = currentValue .. SetComment(`fixed with utf8 lib ({table.concat(positions , " , ")})`)
									end
								end
								local _str2 = tonumber(currentValue)
								if _str2 then
									if _str2 ~= math.floor(_str2) then
										currentValue = string.format(("%."..tostring(math.floor(_str2))).."f", _str2)
									end
								end
							end
							
						end
						rawFile.value = currentValue
						table.insert(r, rawFile)
					end
				end
				globalChunk = i
			end
			return r
		end

		-- STEP 2 : Decompilation
		local disassembled = disassemble()
		local global_chunk = 1
		local total_chunks = #disassembled
		local function FormatRaw(raw)
			local var = VariableDefault:format(raw.register)
			if table.find(ref_variables , raw.register) then
				return `{var} = `
			end
			table.insert(ref_variables , raw.register)
			return `local {var} = `
		end
		local ignoreMoveObjects = {}
		local storaged_global_objs = {}
		local function build_closure(raw)
			local rawclone = raw
			raw = raw.value
			local function decompile_Arguments()
				local args = raw.arguments
				local original , decompiled = {} , {}
				for i = 1 , #args do
					local arg = args[i]
					globalArgs = globalArgs + 1
					local replace = VariableDefault:format(globalArgs - 1)
					original[replace] = arg
					local function isListArg(x)
						if x == "..." or x == " ..." or x == "... " then
							return true
						end
						return false
					end
					if isListArg(arg) then
						table.insert(decompiled, "...")
						break
					end
					table.insert(decompiled , replace)
				end
				return decompiled , original
			end
			local decompiled_Args , originalArguments = decompile_Arguments()
			local decompiled_body , _ , disassembled_func_body = Decompile(table.concat(raw.body,"\n") , options , true)
			local upv = {}
			for _ , ch in pairs(disassembled_func_body) do
				if ch then
					if ch.constructor and table.find({"MOVE","GETUPVAL"}, ch.constructor) then
						local var = VariableDefault:format(ch.register)
						if not table.find(upv , var) then
							table.insert(upv, var)
						end
					end
				end
			end
			local function load_upvalues()
				local upvals = #upv
				if upvals > 0 then
					local upvals_2 = {}
					for _ , str in pairs(upv) do
						table.insert(upvals_2, tostring(str))
					end
					return table.concat({
						`--[[ Upvalues[{tostring(upvals)}]`,
						table.concat(upvals_2 , "\n"),
						"]]"
					},"\n")
				else
					return ""
				end
			end
			local funcName = raw.functionName
			table.insert(ready_functions , funcName)
			local var = VariableDefault:format(rawclone.register)
			return `local {var} = nil\n{var} = function({table.concat(decompiled_Args," , ")}) --{(funcName == "" or funcName == " ") and "" or ` Named: { raw.functionName} ,`} Line: {raw.line}\n{load_upvalues()}\n{decompiled_body}\nend`
		end
		local jumps = {}
		local else_points = {}
		local ready_selfs = {}
		local function GetIndexAndValue(str)
			str = str or "- -"
			local index , val = "-" , "-"
			local raw_val = str
			local i , v = raw_val:match("(.*)%s+(.*)$")
			if i then
				index = i
			end
			if v  then
				val = v
			end
			return index , val
		end
		local constructors = {
			["NEWTABLE"] = function(raw)
				return FormatRaw(raw).."{}"
			end, 
			["LOADK"] = function(raw)
				insert_constant(raw.value)
				return FormatRaw(raw)..raw.value
			end,
			["GETGLOBAL"] = function(raw)
				if table.find(ready_functions, VariableDefault:format(raw.argument)) then
					return nil , true
				end
				storaged_global_objs[raw.value] = raw.register
				insert_constant(raw.value)
				return FormatRaw(raw)..raw.value
			end,
			["SETTABLE"] = function(raw)
				local custom = nil
				local index , value = GetIndexAndValue(raw.value)
				if (value == "-") then
					value = VariableDefault:format(abs(raw.constant))
				end 
				if (index == "-") then
					index = VariableDefault:format(abs(raw.argument))
					custom = `[%s]`
				end
				for _ , quote in pairs(typeof_quotes) do
					index = string.gsub(index , quote , "")
				end
				local function get_method()
					local firstDigit = index:sub(1,1)
					if custom then
						return custom
					end
					if tonumber(firstDigit) or index:match("%s+") then
						return `["%s"]`
					end
					return ".%s"
				end
				return `{VariableDefault:format(raw.register)}{get_method():format(index)} = {value}`
			end,
			["RETURN"] = function(raw)
				if (raw.argument -1 ) > 0 then
					local arguments = {}
					for i = 0 , raw.argument - raw.register do
						local arg = VariableDefault:format(i)
						table.insert(arguments , arg)
					end
					local arraysize = #arguments
					arguments = table.concat(arguments , " , ")
					return `return {arguments} {SetComment(`Returned {arraysize} items in the array`)}`
				end
				return nil , true
			end,
			["MOVE"] = function(raw)
				local moved = VariableDefault:format(abs(raw.argument))
				return FormatRaw(raw)..moved..SetComment("moved value")
			end,
			["CALL"] = function(raw)
				local arguments = (raw.argument - 1)
				local returns = raw.constant > 1
				local initialFunction = VariableDefault:format(raw.register)
				local argList = {}
				local nextChunk = disassembled[math.clamp(raw.globalId + 2 , 1 , total_chunks)]
				if raw.argument > 0 then
					for i = 1 , (raw.argument - 1) do
						local val = VariableDefault:format(raw.register + i)
						table.insert(argList , val)
					end
				end
				if nextChunk and nextChunk.constructor == "FORPREP" then
					return nil , true
				end
				local str = `{initialFunction}({table.concat(argList , " , ")})`
				local self_raw = ready_selfs[raw.register]
				if self_raw then
					table.remove(argList , 1)
					str = `{VariableDefault:format(self_raw.argument)}:{cleanQuotes(self_raw.value)}({table.concat(argList, " , ")})`
				end
				if returns then
					local returningArgs = {}
					for i = 1 , (raw.constant - 1) do
						table.insert(returningArgs, VariableDefault:format(i))
					end
					str = `{#returningArgs > 1 and "local " or ""}{table.concat(returningArgs , " , ")} = {str}`
				end
				return str
			end,
			["GETTABLE"] = function(raw)
				local currentValue = raw.value
				local currentEscape = "[%s]"
				if not currentValue then
					currentValue = VariableDefault:format(raw.constant)
				else
					currentValue = cleanQuotes(currentValue)
					currentEscape = GetEscape(currentValue , raw.constant)
				end
				return `{FormatRaw(raw)}{VariableDefault:format(raw.argument)}{currentEscape:format(currentValue)}`
			end,
			["JMP"] = function(raw)
				local JUMP_TO = raw.value
				for i = raw.globalId , 1 , -1 do
					local chunk = disassembled[i]
					if chunk then
						if chunk.partIndex == JUMP_TO then
							global_chunk = chunk.globalId - 1
							break
						end
					end
				end
				for i = raw.globalId , total_chunks do
					local chunk = disassembled[i]
					if chunk then
						if chunk.partIndex == JUMP_TO then
							global_chunk = chunk.globalId - 1
							break
						end
					end
				end
				table.insert(jumps , (global_chunk - 1))
				table.insert(else_points , {
					["from"] = (global_chunk - 1),
					["from_raw"] = raw,
					["jump_to"] = JUMP_TO, 
				})
				return nil , true
			end,
			["LOADNIL"] = function(raw)
				local nilAmount = raw.argument
				local nil_amt = {}
				local vars = {}
				for i = 1 , nilAmount do
					table.insert(vars , VariableDefault:format(nilAmount + i))
				end
				local str = {}
				for _ , var in pairs(vars) do
					table.insert(str , `local {var} = nil`)
				end
				return table.concat(str , "\n")
			end,
			["CLOSURE"] = build_closure,
			["DIPCLOSURE"] = build_closure,
			["SETGLOBAL"] = function(raw)
				if ready_functions[raw.value] then
					return nil , true
				end
				return `{raw.value} = {VariableDefault:format(raw.register)}`
			end,
			["TEST"] = function(raw)
				local isNot = raw.constant > 0
				local str = `if {isNot and "not " or ""}{VariableDefault:format(raw.register)} then`
				return str
			end,
			["LEN"] = function(raw)
				return FormatRaw(raw)..`#{VariableDefault:format(raw.argument)}`
			end,
			["SELF"] = function(raw)
				ready_selfs[raw.register] = raw
				return nil , true
			end,
			["LOADBOOL"] = function(raw)
				local bool = "false"
				if raw.argument == 1 then
					bool = "true"
				end
				return FormatRaw(raw)..bool
			end,
			["SUB"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} - {rhs}`
			end,
			["ADD"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} + {rhs}`
			end,
			["DIV"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} / {rhs}`
			end,
			["MUL"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} * {rhs}`
			end,
			["MOD"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} % {rhs}`
			end,
			["POW"] = function(raw)
				local lhs , rhs = GetIndexAndValue(raw.value)
				if lhs == "-" then
					lhs = VariableDefault:format(raw.argument)
				end
				if rhs == "-" then
					rhs = VariableDefault:format(raw.constant)
				end
				return `{FormatRaw(raw)}{lhs} ^ {rhs}`
			end,
			["NOT"] = function(raw)
				return `{FormatRaw(raw)}not {VariableDefault:format(raw.argument)}`
			end,
			["CONCAT"] = function(raw)
				local vars = {}
				for i = raw.argument, raw.constant do
					table.insert(vars, VariableDefault:format(i))
				end
				return `{FormatRaw(raw)}{table.concat(vars, " .. ")}`
			end,
			["TFORLOOP"] = function(raw)
				local main = raw.register
				local index , value = main + 2  , main + 3
				local generator = VariableDefault:format(main)
				local index_str = VariableDefault:format(index)
				local value_str = VariableDefault:format(value)
				local index_str2 , value_str2 = index + 1 , value + 1
				index_str2 = VariableDefault:format(index_str2)
				value_str2 = VariableDefault:format(value_str2)
				return `while true do\nlocal {index_str2} , {value_str2} = {generator}({table.concat({index_str,value_str}, " , ")})`
			end,
			["TAILCALL"] = function(raw)
				local args = {}
				local func = VariableDefault:format(raw.register)
				local arguments = raw.argument - 1
				if arguments > 0 then
					for i = 1 , arguments do
						local arg = raw.register + i
						arg = VariableDefault:format(arg)
						table.insert(args , arg)
					end
				end
				local arg_c = #args
				args = table.concat(args , " , ")
				return `return {func}({args}){SetComment(`block ends calling {func} with {arg_c} argument(s)`)}`
			end,
			["VARARG"] = function(raw)
				return (`{FormatRaw(raw)}%s{SetComment(`{raw.argument} argument(s)`)}`):format("{ ... }")
			end,
			["SETLIST"] = function(raw)
				local args = {}
				local list_args = raw.argument
				if list_args > 0 then
					for i = 1, list_args do
						local isLast = (i == list_args)
						local value = (i + raw.register) + (isLast and (raw.constant - 1) or 0)
						table.insert(args, VariableDefault:format(value))
					end
				end
				local table = VariableDefault:format(raw.register)
				local str = `{SetComment(`inserts {#args} index(es) in {table} array`,true)}`
				for i = 1 , #args do
					local arg = args[i]
					local current = "ARGUMENT_NOT_FOUNDED_BY_RUNLUAU"
					if arg then
						current = arg
					end
					str = str..`\ntable.insert({table}, {arg})`
				end
				return str
			end,
			["GETUPVAL"] = function(raw)
				return `{FormatRaw(raw)}{VariableDefault:format(raw.argument)} -- upvalue ({raw.value or "UPVALUE_NOT_FOUNDED_BY_UNLUAU"})`
			end,
			["EQ"] = function(raw)
				local symbol = "=="
				local a , b = "NOT_FOUNDED_BY_RUNLUAU" , "NOT_FOUNDED_BY_RUNLUAU"
				if raw.register > 0 then
					symbol = "~="
				end
				if raw.value == nil then
					a = VariableDefault:format(raw.argument)
					b = VariableDefault:format(raw.constant)
				else
					local function fix(x,h)
						if x == "-" then
							return VariableDefault:format(h)
						end
						return x
					end
					local index , value = GetIndexAndValue(raw.value)
					a = fix(index , raw.argument)
					b = fix(value , raw.constant)
				end
				return `if {a} {symbol} {b} then`
			end,
		}
		local repeated = 0
		for i = global_chunk , total_chunks do
			if i < global_chunk then
				continue
			end
			local JUMP_POINT = table.find(jumps , i)
			if JUMP_POINT then
				local function search_conditional()
					local raw = nil
					for _ , data in else_points do
						if data.from == i then
							raw = data
							break
						end
					end
					return raw
				end
				local conditional = search_conditional()
				local else_adding = nil
				if conditional then
					local x = conditional.from_raw.globalId - 2
					local before_conditional = disassembled[math.clamp(x , 1 , total_chunks)]
					local conditional_constructor = before_conditional.constructor
					local isConditional = Luau.IsConditionalConstructor(conditional_constructor)
					if isConditional and conditional.from_raw.constructor == "JMP" then
						else_adding = true						
					end
				end
				if else_adding then
					table.insert(output , "else")
				end
			end 
			if table.find(ignoringLines , i) then
				continue
			end
			local disassembled_chunk = disassembled[i]
			if disassembled_chunk then
				local constructor = disassembled_chunk.constructor
				local constructor_callback = constructors[constructor]
				local current = `-- RUNLUAUWARNING: Unvalid constructor "{constructor}" at #{disassembled_chunk.partIndex}`
				if constructor_callback then
					local ok , r , returnedNilForSpace = pcall(constructor_callback, disassembled_chunk)
					if returnedNilForSpace then
						current = nil
					else
						if ok and r then
							current = tostring(r)
						elseif ok and not r and not returnedNilForSpace then
							current = `-- RUNLUAUWARNING: {constructor} at #{disassembled_chunk.partIndex} unvalid result`
						end
					end
					if not ok then
						print(constructor)
						warn(r)
						current = `-- RUNLUAUERROR: {constructor} at #{disassembled_chunk.partIndex} failed to analyze`
					end
				end
				if current then
					table.insert(output, current)
				end
			end
			repeated = 1
			global_chunk = i
		end
		return table.concat(output , "\n") , globals , disassembled
	end
	local ok , result , globals , disassembled = pcall(Decomp)
	local DecompiledOutput = {}
	local SourceEnabled = true
	if not IS_FUNCTION_BODY then
		table.insert(DecompiledOutput,`-- Decompiled with RunLuau Decompiler V1 made in Luau by boydev1444`)
		elapsed_t = tick() - elapsed_t -- Elapsed time is done
		if RETURNS_ELAPSED_TIME then
			table.insert(DecompiledOutput , `-- Time taken: {string.format("%.6f", elapsed_t)} seconds`)
		end
		if DecoDate then
			table.insert(DecompiledOutput , `-- Decompiled on: {os.date("%Y-%m-%d (%H-%M-%S)")}`)
		end
		if #EnabledFlags > 0 then
			local FlagRenames = {
				["Disassemble"] = "disassm",
				["Logs"] = "logs",
				["Verbose"] = "verbose",
				["DecompilationDateOnTop"] = "date",
				["ListUpvalues"] = "upvalues",
				["ShowConstants"] = "constants",
				["ShowAllVariables"] = "get-all",
			}
			local PrefixedFlags = {}
			for _ , Flag in EnabledFlags do
				if Flag then
					if FlagRenames[Flag] then
						table.insert(PrefixedFlags , "!"..tostring(FlagRenames[Flag]))
					end
				end
			end
			table.insert(DecompiledOutput, `-- Used Flags ({#EnabledFlags}):  [{table.concat(PrefixedFlags , " , ")}]`)
		end
		if GLOBALS_ENABLED and not RestrictGlobals then
			globals = globals or {}
			if not table.find(globals , "...") then
				table.insert(globals  , "...")
			end
			local changedGlobals = {}
			for i = 1 , #globals do
				local global = globals[i] or "NOT_FOUNDED_GLOBAL_BY_RUNLUAU"
				table.insert(changedGlobals, `    #{i} {tostring(global)}`)
			end
			table.insert(DecompiledOutput , `--[[ Used Global Variables [{#globals}]\n{table.concat(changedGlobals,"\n")}\n]]`)
		end
		table.insert(DecompiledOutput, `-- Start Line: {startLinePos}`)
		table.insert(DecompiledOutput, "")
		local AlreadyErrored = false
		if not AlreadyErrored then
			if (ENV or _ENV) ~= nil then
				AlreadyErrored = true
				table.insert(DecompiledOutput, `--[[ Decompilation Error!\n  Luau Version isn't supported (Lua 5.1 expected, got higher Lua 5.1 version)\n]]`)
				SourceEnabled = false
			end
		end
		if elapsed_t > TIMEOUT_LIMIT and not AlreadyErrored then
			AlreadyErrored = true
			local formatted = string.format("%.6f", elapsed_t)
			table.insert(DecompiledOutput, `--[[ Decompilation Timeout! ({formatted}) seconds\n  (You can execute this code in command bar to verify)\n  print("Script Timeouted:",{formatted} > {TIMEOUT_LIMIT}) \n]]`)
			SourceEnabled = false
		end
		if not ok and not AlreadyErrored then
			AlreadyErrored = true
			table.insert(DecompiledOutput, `--[[ Decompiler Error!\n  {tostring(result:match(":%d+%s*:(.*)"))}\n]]`)
			SourceEnabled = false
		end
	end
	if SourceEnabled then
		table.insert(DecompiledOutput, result)
	end
	return table.concat(DecompiledOutput,"\n") , RETURNS_ELAPSED_TIME and elapsed_t or nil , IS_FUNCTION_BODY and disassembled or nil
end

GlobalENV.decompile = function(script , options)
	local result , elapsed_t = `-- Unknown Error` , nil
	assert(getscriptbytecode , `exploit not supported!`)
	local function isValidScript()
		local class = script.ClassName
		if class == "Script" then
			return script.RunContext == Enum.RunContext.Client
		else
			return class == "LocalScript" or class == "ModuleScript"
		end
	end
	if not isValidScript() then
		warn(`Attempt to "decompile" Argument #1 (Local/Module->Script expected, got ServerSidedScript)`)
		return result , elapsed_t
	end
	local sourc , elapsed_tim = Decompile(getscriptbytecode(script) , options)
	result = sourc
	elapsed_t = elapsed_tim
	return sourc , elapsed_t
end

return Decompile
