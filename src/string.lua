local require, getmetatable = require, getmetatable
local string, table, unpack, select, debug, error, loadstring, assert = string, table, unpack, select, debug, error, loadstring, assert
local type, tostring, pairs, io, error, print = type, tostring, pairs, io, error, print
local pcall, debug = pcall, debug

require 'lgstring'

local List = require 'lglib.list'
local Set = require 'lglib.set'

-- unpack() only acting on list-part of table ??
-- formatting one string or list of string  
-- therefore, we can do 1). extend the function of unpack  2). checkType(list) to make sure b is a LIST
getmetatable("").__mul = function(a, b)
	if not b then
		return a
	elseif type(b) == "table" then
		return string.format(a, unpack(b))
	else
		return string.format(a, b)
	end
end

-- modify the regular expression for robustness, like "${ name} is ${  value}"  ?????
-- print( "${name} is ${value}" % {name = "foo", value = "bar"} )
-- Outputs "foo is bar"
getmetatable("").__mod = function (s, tab)
  return (s:gsub('($%b{})', function(w) return tab[w:sub(3, -2)] or w end))
end

-- 
-- print( "%(key)s is %(val)7.2f%" / {key = "concentration", val = 56.2795} )
-- outputs "concentration is   56.28%" 
getmetatable("").__div = function (s, tab)
  return (s:gsub('%%%((%a%w*)%)([-0-9%.]*[cdeEfgGiouxXsq])',
            function(k, fmt) return tab[k] and ("%"..fmt):format(tab[k]) or
                '%('..k..')'..fmt end))
end


getmetatable("").__add = function (self, astr)
	local ok, ret = pcall(function (self, astr) return self .. astr end, self, astr)
	if not ok then print(debug.traceback()); error('[ERROR] concating string is nil!', 2) end

	return (ok and ret or self)
end


------------------------------------------------------------------------
-- capitalizing first letter of word  
-- @param self one string word
-- @usage 'example':cap()
-- @return first letter of word to be capitalized
------------------------------------------------------------------------
function cap(self)
    if #self == 0 then return self end
    return ('%s%s'):format(self:sub(1, 1):upper(), self:sub(2))
end

------------------------------------------------------------------------
-- check whether string "self" contains "substr" or not 
-- @param self  checked string 
-- @param substr   sub-string
-- @return true|false  true for containing, otherwise false
------------------------------------------------------------------------
function contains(self, substr)
    if self:find(substr, 1, true) then
        return true
    end
    return false
end

------------------------------------------------------------------------
-- check whether string starts with substring or not
-- @param self  checked string 
-- @param beg   substring
-- @return true|false   
------------------------------------------------------------------------
startsWith = lgstring.startsWith

------------------------------------------------------------------------
-- check whether string ends with substring or not
-- @param self  checked string
-- @param tail   substring
-- @return true|false   
------------------------------------------------------------------------
endsWith = lgstring.endsWith

------------------------------------------------------------------------
-- spliting a given string by a delimiter
-- @param self 		splited sting
-- @param delim		delimiter
-- @param count	 	how many times that the delimiter could be replaced
-- @return rlist 	list of splited pieces
------------------------------------------------------------------------
split = lgstring.split

------------------------------------------------------------------------
-- spliting a given string by a delimiter
-- @param self  	splited string 
-- @param delim 	delimiter
-- @param count 	times that a delimiter could be replaced
-- @return unpack a list of splited pieces
------------------------------------------------------------------------
function splitout(self, delim, count)
    return unpack(split(self, delim, count))
end


------------------------------------------------------------------------
-- spliting a given string by some delimiters
-- @param self  	splited string 
-- @param delim 	delimiter
-- @param count 	times that a delimiter could be replaced
-- @return unpack a list of splited pieces
------------------------------------------------------------------------
splitset = lgstring.splitset

------------------------------------------------------------------------
-- find location of the last substring in a given string
-- @param self  checked string
-- @param substr    substring
-- @return lastBegPos   the starting position of last substring
--         lastEndPos   the end position of last substring
-- @note   SHOULD be optimized by pattern matching in the reversed direction
------------------------------------------------------------------------
rfind = lgstring.rfind

-- character set of blank spaces
local TRIM_CHARS = Set {(" "):byte();("\t"):byte();("\v"):byte();("\r"):byte();("\n"):byte();0}
------------------------------------------------------------------------
-- trim out the blank space at the head of string
-- @param self  trimed string
-- @return	 	clean string without blank space at the head
------------------------------------------------------------------------
ltrim = lgstring.ltrim

------------------------------------------------------------------------
-- trim out blank space at the tail of string
-- @param self  trimed string
-- @return 		clean stirng without blank space at the tail
------------------------------------------------------------------------
rtrim = lgstring.rtrim

------------------------------------------------------------------------
-- trim out blank space at both sides string
-- @param self  trimed string
-- @return 		clean string without blank space on both sides
------------------------------------------------------------------------
trim = lgstring.trim


splittrim = function (str, delimiters)
	local r = str:split(delimiters)
	for i, v in ipairs(r) do
		r[i] = trim(v)
	end
	return r
end

------------------------------------------------------------------------
-- ABNF from RFC 3629
--
-- UTF8-octets = *( UTF8-char )
-- UTF8-char   = UTF8-1 / UTF8-2 / UTF8-3 / UTF8-4
-- UTF8-1      = %x00-7F
-- UTF8-2      = %xC2-DF UTF8-tail
-- UTF8-3      = %xE0 %xA0-BF UTF8-tail / %xE1-EC 2( UTF8-tail ) /
--               %xED %x80-9F UTF8-tail / %xEE-EF 2( UTF8-tail )
-- UTF8-4      = %xF0 %x90-BF 2( UTF8-tail ) / %xF1-F3 3( UTF8-tail ) /
--               %xF4 %x80-8F 2( UTF8-tail )
-- UTF8-tail   = %x80-BF
------------------------------------------------------------------------

------------------------------------------------------------------------
-- counting length of the UTF8 char located at i-position of UTF8 string, or check whether it is a UTF8 char
-- @param self 	   checked UTF8 string
-- @param i        indexing a UTF8 char
-- @return 1|2|3|4|nil   1～4 for number of bytes, nil for invalid UTF8 char
------------------------------------------------------------------------
local function utf8charbytes(self, i)
	-- argument defaults
	i = i or 1

	-- argument checking
	if type(self) ~= "string" then
		error("bad argument #1 to 'utf8charbytes' (string expected, got ".. type(self).. ")")
	end
	if type(i) ~= "number" then
		error("bad argument #2 to 'utf8charbytes' (number expected, got ".. type(i).. ")")
	end

	local c = self:byte(i)

	-- determine bytes needed for character, based on RFC 3629
	-- validate byte 1
	if c > 0 and c <= 127 then
		-- UTF8-1
		return 1

	elseif c >= 194 and c <= 223 then
		-- UTF8-2
		local c2 = self:byte(i + 1)

		if not c2 then
			error("UTF-8 string terminated early")
		end

		-- validate byte 2
		if c2 < 128 or c2 > 191 then
			error("Invalid UTF-8 character")
		end

		return 2

	elseif c >= 224 and c <= 239 then
		-- UTF8-3
		local c2 = self:byte(i + 1)
		local c3 = self:byte(i + 2)

		if not c2 or not c3 then
			error("UTF-8 string terminated early")
		end

		-- validate byte 2
		if c == 224 and (c2 < 160 or c2 > 191) then
			error("Invalid UTF-8 character")
		elseif c == 237 and (c2 < 128 or c2 > 159) then
			error("Invalid UTF-8 character")
		elseif c2 < 128 or c2 > 191 then
			error("Invalid UTF-8 character")
		end

		-- validate byte 3
		if c3 < 128 or c3 > 191 then
			error("Invalid UTF-8 character")
		end

		return 3

	elseif c >= 240 and c <= 244 then
		-- UTF8-4
		local c2 = self:byte(i + 1)
		local c3 = self:byte(i + 2)
		local c4 = self:byte(i + 3)

		if not c2 or not c3 or not c4 then
			error("UTF-8 string terminated early")
		end

		-- validate byte 2
		if c == 240 and (c2 < 144 or c2 > 191) then
			error("Invalid UTF-8 character")
		elseif c == 244 and (c2 < 128 or c2 > 143) then
			error("Invalid UTF-8 character")
		elseif c2 < 128 or c2 > 191 then
			error("Invalid UTF-8 character")
		end

		-- validate byte 3
		if c3 < 128 or c3 > 191 then
			error("Invalid UTF-8 character")
		end

		-- validate byte 4
		if c4 < 128 or c4 > 191 then
			error("Invalid UTF-8 character")
		end

		return 4

	else
		error("Invalid UTF-8 character")
	end
end

------------------------------------------------------------------------
-- counting the number of UTF8 chars for given UTF8 string, rather than number of bytes
-- @param self 	UTF8 strng
-- @return len 	length of UTF8 string
------------------------------------------------------------------------
function utf8len(self)
	local pos = 1
	local bytes = self:len()
	local len = 0

	while pos <= bytes do
		len = len + 1
		pos = pos + utf8charbytes(self, pos)
	end

	return len
end

------------------------------------------------------------------------
-- random accessing a UTF8 char from given string
-- @param self   UTF8 string 
-- @param i  indexing i-th UTF8 char, i should statisfy 0<i<=len
-- @return  UTF8 char or nil if not found
------------------------------------------------------------------------
function utf8index(self, i)
	local pos = 1
	local bytes = self:len()
	local len = 0
    local begPos, endPos

	while pos <= bytes do
        begPos = pos
   		pos = pos + utf8charbytes(self, pos)
        endPos = pos
		len = len + 1
        if len == i then
            return self:sub(begPos, endPos-1)
        end
	end
    
    return nil
end

------------------------------------------------------------------------
-- slicing a UTF8 string
-- @param self  UTF8 string 
-- @param i   	starting position at given UTF8 string, i should statisfy 0<i<=len
-- @param j   	ending position at given UTF8 string, j should statisfy 0<j<=len and j>=i
-- @return   	UTF8 char or nil if not found 
------------------------------------------------------------------------
function utf8slice(self, i, j)
	if i > j then
        return nil
    end
    
    local pos = 1
	local bytes = self:len()
	local len = 0
    local ibegPos, iendPos, jbegPos, jendPos

	while pos <= bytes do
        ibegPos = pos
   		pos = pos + utf8charbytes(self, pos)
        iendPos = pos
		len = len + 1
        if len == i then
            break
        end
	end
    
    -- if len < i, now len is the length of this utf8 string
    if len < i then
        return nil
    end
    
    if i == j then
        return self:sub(ibegPos, iendPos-1)
    end
    
    while pos <= bytes do
        jbegPos = pos
   		pos = pos + utf8charbytes(self, pos)
        jendPos = pos
		len = len + 1
        if len == j then
            break
        end
	end
    
    return self:sub(ibegPos, jendPos-1)
    
end

-- identical to string.reverse except that it supports UTF-8
function utf8reverse (self)
	local bytes = self:len()
	local pos = bytes
	local charbytes
	local newstr = ""

	while pos > 0 do
		c = self:byte(pos)
		while c >= 128 and c <= 191 do
			pos = pos - 1
			c = self:byte(pos)
		end

		charbytes = utf8charbytes(self, pos)

		newstr = newstr .. self:sub(pos, pos + charbytes - 1)

		pos = pos - 1
	end

	return newstr
end


