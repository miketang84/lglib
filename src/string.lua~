local require, getmetatable = require, getmetatable
local string, table, unpack, select, debug, error, loadstring, assert = string, table, unpack, select, debug, error, loadstring, assert
local type, tostring, pairs, io, error, print = type, tostring, pairs, io, error, print
local pcall, debug = pcall, debug

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

function length(self)
    return utf8len(self)
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
function startsWith(self, begin)
    if self:sub(1, #begin) ~= begin then
        return false
    end
    return true
end

------------------------------------------------------------------------
-- check whether string ends with substring or not
-- @param self  checked string
-- @param tail   substring
-- @return true|false   
------------------------------------------------------------------------
function endsWith(self, tail)
	if self:sub(-#tail) ~= tail then
		return false
	end
	return true
end

------------------------------------------------------------------------
-- spliting a given string by a delimiter
-- @param self 		splited sting
-- @param delim		delimiter
-- @param count	 	how many times that the delimiter could be replaced
-- @param no_patterns   true|false|nil    whether turn off regular expression in delimiter or not 
-- @return rlist 	list of splited pieces
------------------------------------------------------------------------
function split(self, delim, count, no_patterns)

    if delim == '' then error('invalid delimiter', 2) end
    local count = count or 0

    local next_delim = 1
    local i = 1
    local rlist = List()

    repeat
        local start, finish = self:find(delim, next_delim, no_patterns)
        if start and finish then
            rlist:append(self:sub(next_delim, start - 1))
            next_delim = finish + 1
        else
            break
        end
        i = i + 1
    until i == count + 1

    rlist:append(self:sub(next_delim))
    return rlist
end
------------------------------------------------------------------------
-- spliting a given string by a delimiter
-- @param self  	splited string 
-- @param delim 	delimiter
-- @param count 	times that a delimiter could be replaced
-- @param no_patterns   true|false|nil 	turn off regular expression in delimiter or not 
-- @return unpack a list of splited pieces
------------------------------------------------------------------------
function splitOut(self, delim, count, no_patterns)
    return unpack(split(self, delim, count, no_patterns))
end

------------------------------------------------------------------------
-- spliting a given string by several delimiters
-- @param self  splited string
-- @param ...   several delimiters
-- @return 		unpack a list of splited pieces
------------------------------------------------------------------------
function splitBy(self, ...)
	local res = List()
	local tail, values = self, {select(1, ...)}
	for i = 1, select("#", ...) do
		if not tail then break end
		local begPos, endPos = tail:find(values[i], 1, true)
		if begPos then
			table.insert(res, tail:sub(1, begPos-1))
			tail = tail:sub(endPos+1)
		end
	end
	table.insert(res, tail)
	return unpack(res)
end


------------------------------------------------------------------------
-- find location of the last substring in a given string
-- @param self  checked string
-- @param substr    substring
-- @return lastBegPos   the starting position of last substring
--         lastEndPos   the end position of last substring
-- @note   SHOULD be optimized by pattern matching in the reversed direction
------------------------------------------------------------------------
function rfind(self, substr)
	local i, lastBegPos, lastEndPos = 1
	local begPos, endPos = self:find(substr, i, true)
	while begPos do
		lastBegPos = begPos
		lastEndPos = endPos
		i = begPos+1
		begPos, endPos = self:find(substr, i, true)
	end
	return lastBegPos, lastEndPos
end

-- character set of blank spaces
local TRIM_CHARS = Set {(" "):byte();("\t"):byte();("\v"):byte();("\r"):byte();("\n"):byte();0}
------------------------------------------------------------------------
-- trim out the blank space at the head of string
-- @param self  trimed string
-- @return	 	clean string without blank space at the head
------------------------------------------------------------------------
function ltrim(self)
	local index = 1
	for i = 1, #self do
		if not TRIM_CHARS:has(self:byte(i)) then
			index = i
			break
		end
	end
	return self:sub(index)
end

------------------------------------------------------------------------
-- trim out blank space at the tail of string
-- @param self  trimed string
-- @return 		clean stirng without blank space at the tail
------------------------------------------------------------------------
function rtrim(self)
	local index = 1
	for i = #self, 1, -1 do
		if not TRIM_CHARS:has(self:byte(i)) then
			index = i
			break
		end
	end
	return self:sub(1, index)
end

------------------------------------------------------------------------
-- trim out blank space at both sides string
-- @param self  trimed string
-- @return 		clean string without blank space on both sides
------------------------------------------------------------------------
function trim(self)
	return self:ltrim():rtrim()
end

------------------------------------------------------------------------
-- replace substring with new substring
-- @param self  long string to be handled
-- @param ori   substring to be replaced
-- @param new   new substring
-- @param n     times of replacements
-- @return 		string after replacement
-- not necessary I think
------------------------------------------------------------------------
function replace(self, ori, new, n)
    return self:gsub(ori, new, n)
end

------------------------------------------------------------------------
-- multiple replacements by mapping from old substring to new one
-- @param self 		long string to be handled
-- @param mapping	mapping table between old substring to new ones, like {['ori'] = 'new', ['foo'] = 'bar'}
-- @param n   		times of replacements
-- @return 			utf8 string or nil
------------------------------------------------------------------------
function mapreplace (self, mapping, n)
    for k, v in pairs(mapping) do
        self:gsub(k, v, n)
    end
    
    return self
end

function index(self, i)
    return self:sub(i, i)
end

function slice(self, i, j)
	return utf8slice(self, i, j)
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


function findpart(str, start, endwhich)
	if endwhich < start then return '' end
	if endwhich <= 0 or start <= 0 then return '' end
	
	local str = str:trim()
	local count = 0
	local p = 0

	local i = 0
	while i do
		i = str:find(' ', i+1)
		if i then
			count = count + 1
			if count == start - 1 then
				p = i + 1
				break
			end
		end
	end
	
	if p == 0 then return '' end
	
	i = 0
	count = 0		
	str = str:sub(p)
	p = 0
	while i do
		i = str:find(' ', i+1)
		if i then
			count = count + 1
			if count == endwhich - start + 1 then
				p = i - 1
				break
			end
		end
	end
	
	if p == 0 then 
		return str 
	else
		return str:sub(1, p)
	end
end



function trailingPath(path)
	local path = path:gsub('//+', '/')
	if path:sub(-1) ~= '/' then
		path = ('%s/'):format(path)
	end
	
	return path
end
