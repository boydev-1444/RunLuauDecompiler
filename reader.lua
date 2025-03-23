local function NewReader(bytecode , FloatPrecision)
    local self = {}
	local private = {}
	private.buff = buffer.fromstring(bytecode)
	private.cur = 0
	private.buff_len = buffer.len(private.buff)
	private.float_p = FloatPrecision or 24
	function self:readByte()
		local byte = buffer.readu8(private.buff , private.cur)
		private.cur += 1
		return byte
	end
	function self:skipByte(custom_skip_amount : number | nil)
		private.cur += (custom_skip_amount and custom_skip_amount or 1)
	end
	function self:nextVarInt()
		local result = 0
		for i = 0, 4 do
			local b = self:readByte()
			result = bit32.bor(result, bit32.lshift(bit32.band(b, 0x7F), i * 7))
			if not bit32.btest(b, 0x80) then
				break
			end
		end
		return result
	end
	function self:readString()
		local blocksize = self:nextVarInt()
		if blocksize == 0 then
			return ""
		else
			local str = buffer.readstring(private.buff , private.cur , blocksize)
			private.cur += blocksize
			return str
		end
	end
	function self:nextDouble()
		local result = buffer.readf64(private.buff, private.cur)
		private.cur += 8
		return result
	end
	function self:nextUInt32()
		local result = buffer.readu32(private.buff , private.cur)
		private.cur += 4
		return result
	end
	function self:nextFloat()
		local result = buffer.readf32(private.buff , private.cur)
		private.cur += 4
		return tonumber(string.format(`%0.{private.float_p}f`, result))
	end
	function self:readWord()
		local word = buffer.readu32(private.buff, private.cur)
		private.cur += 4
		return word
	end
	function self:nextSignedByte()
		local signed_byte = buffer.readi8(private.buff, private.cur)
		private.cur += 1
		return signed_byte
	end
	function self:nextInt32()
		local int32 = buffer.readi32(private.buff, private.cur)
		private.cur += 4
		return int32
	end
	function self:__getc()
		return private.cur
	end
	return setmetatable(self, {
		["__namecall"] = function(_self, name, ...)
			if private.buff_len < private.cur then
				error(`Attempt to call reader function with mistmatching position of length.`)
				return nil
			end
			return _self[name](...)
		end
	})
end
return NewReader