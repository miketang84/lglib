local require, getmetatable = require, getmetatable
local string, table, unpack, select, debug, error, loadstring, assert = string, table, unpack, select, debug, error, loadstring, assert
local type, tostring, pairs, io, error, print = type, tostring, pairs, io, error, print
local pcall, debug = pcall, debug

local List = require 'lglib.list'
local Set = require 'lglib.set'

--
getmetatable("").__mul = function(a, b)
	if not b then
		return a
	elseif type(b) == "table" then
		return string.format(a, unpack(b))
	else
		return string.format(a, b)
	end
end

--
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
-- 单词首字母大写
-- @param self 单词字符串
-- @usage 'example':cap()
-- @return 首字母大写的单词
------------------------------------------------------------------------
function cap(self)
    if #self == 0 then return self end
    return ('%s%s'):format(self:sub(1, 1):upper(), self:sub(2))
end

------------------------------------------------------------------------
-- 检查字串包含指定子串
-- @param self  被检查字串
-- @param substr   子串
-- @return true|false   如果self包含substr，返回true，否则返回false
------------------------------------------------------------------------
function contains(self, substr)
    if self:find(substr, 1, true) then
        return true
    end
    return false
end

------------------------------------------------------------------------
-- 检查字串以指定子串开始
-- @param self  被检查字串
-- @param beg   子串
-- @return true|false   如果self以beg开始，返回true，否则返回false
------------------------------------------------------------------------
function startsWith(self, beg)
    if 1 ~= self:find(beg, 1, true) then
        return false
    end
    return true
end

------------------------------------------------------------------------
-- 检查字串以指定子串结束
-- @param self  被检查字串
-- @param tail   子串
-- @return true|false   如果self以tail结束，返回true，否则返回false
------------------------------------------------------------------------
function endsWith(self, tail)
	if self:sub(-#tail) ~= tail then
		return false
	end
	return true
end

------------------------------------------------------------------------
-- 将一个字符串以给定分隔符分割
-- @param self  被处理字符串
-- @param delim 分隔符
-- @param count 限定分隔符被替换的次数
-- @param no_patterns   true|false|nil 是否关闭delim中的样式匹配
-- @return rlist 存储分割的结果列表
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
-- 将一个字符串以给定分隔符分割
-- @param self  被处理字符串
-- @param delim 分隔符
-- @param count 限定分隔符被替换的次数
-- @param no_patterns   true|false|nil 是否关闭delim中的样式匹配
-- @return 解开列表包裹的多值返回
------------------------------------------------------------------------
function splitOut(self, delim, count, no_patterns)
    return unpack(split(self, delim, count, no_patterns))
end

------------------------------------------------------------------------
-- 将一个字符串以给定分隔符分割
-- @param self  被处理字符串
-- @param ...   多个分隔符
-- @return 解开列表包裹的多值返回
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
-- 找到字符串中最后一个出现子串的始末位置
-- @param self  被处理字符串
-- @param substr    子串
-- @return lastBegPos   子串最后出现的起始位置
--         lastEndPos   子串最后出现的结束位置
-- @note 这函数函数的效率并不高，需要改进
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

-- 空白字符集
local TRIM_CHARS = Set {(" "):byte();("\t"):byte();("\v"):byte();("\r"):byte();("\n"):byte();0}
------------------------------------------------------------------------
-- 清除字符串首部的空白
-- @param self  被处理字符串
-- @return 去除首部空白的字符串
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
-- 清除字符串尾部的空白
-- @param self  被处理字符串
-- @return 去除尾部空白的字符串
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
-- 清除字符串两端的空白
-- @param self  被处理字符串
-- @return 去除两端空白的字符串
------------------------------------------------------------------------
function trim(self)
	return self:ltrim():rtrim()
end

------------------------------------------------------------------------
-- 替换字符串中的子串为新串
-- @param self  被处理字符串
-- @param ori   将要被替换的子串（可为正则表达式）
-- @param new   用于替换的新串
-- @param n     可选。指定替换几次
-- @return 替换后的新串
------------------------------------------------------------------------
function replace(self, ori, new, n)
    return self:gsub(ori, new, n)
end

------------------------------------------------------------------------
-- 映射替换。一次替换多个子串
-- @param self 被替换的字符串
-- @param mapping 子串映射表。形式为 {['ori'] = 'new', ['foo'] = 'bar'}
-- @param n     可选。指定替换几次
-- @return UTF8字符|nil 如果找到了，就返回UTF8字符，否则返回nil
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
-- 用于返回一个UTF8字符串中从某一个位置开始UTF8字符的长度，也可用于检测是否是UTF8字节
-- @param self 被搜索的字符串
-- @param i 字符串中的位置指针
-- @return 1|2|3|4|nil 数字1～4，如果i指向的字节不是一个有效的UTF8字节，则返回nil
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
-- 计算一个UTF8字符串的UTF8字符个数，也即字符长度，而不是字节长度
-- @param self 被计算的字符串
-- @return len 长度
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
-- 计算一个UTF8字符串的UTF8字符个数，也即字符长度，而不是字节长度
-- @param self 被计算的字符串
-- @param i 第i个字符，要求，0<i<len（后面，要对传入函数的参数做统一的检查）
-- @return UTF8字符|nil 如果找到了，就返回UTF8字符，否则返回nil
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
-- 取一个UTF8字符串的长度片断
-- @param self 被计算的字符串
-- @param i 第i个字符，要求，0<i<len（后面，要对传入函数的参数做统一的检查）
-- @param j 第j个字符，要求，0<j<len, j >= i
-- @return UTF8字符|nil 如果找到了，就返回UTF8字符，否则返回nil
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
