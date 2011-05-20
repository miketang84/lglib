local table, pairs, next, type, require, ipairs = table, pairs, next, type, require, ipairs
local tostring, debug, assert, error, setmetatable = tostring, debug, assert, error, setmetatable
local string = string
local math = math


------------------------------------------------------------------------
__typename = 'Table'

-- 将序列部分和字典部分分离开来
-- 注：返回的是两个对象，每一个为序列，第二个为字典
function takeAparts(self)
	local list_len = #self
	local list_part, dict_part = {}, {}
	for i=1, list_len do
		table.insert(list_part, self[i])
	end
	
	for k, v in pairs(self) do
		if type(k) ~= 'number' or (type(k) == 'number' and k > list_len) then
			dict_part[k] = v
		end
	end
	
	local List, Dict = require 'lglib.list', require 'lglib.dict'
	return List(list_part), Dict(dict_part)
end


function copy(self)
	local res = {}
	for k, v in pairs(self) do
		res[k] = v
	end
	return res
end

function deepcopy(self, seen)
	local res = {}
	seen = seen or {}
	seen[self] = res
	for k, v in pairs(self) do
		if "table" == type(v) then
			if seen[v] then
				res[k] = seen[v]
			else
				res[k] = table.deepCopy(v, seen)
			end
		else
			res[k] = v
		end
	end
	seen[self] = nil
	return res
end

function pt(tt, indent, done)
    local done = done or {}
    local indent = indent or 0
    local space = (" "):rep(indent)

    if type(tt) == "table" then
        local sb = {}
        table.insert(sb, '{ ') 
        
        for key, value in pairs(tt) do
            table.insert(sb, space) -- indent it

            if type (value) == "table" and not done [value] then
                done[value] = true
                table.insert(sb, ('%s='):format(key));
                table.insert(sb, pt(value, indent, done))
                table.insert(sb, space) -- indent it
            elseif "number" == type(key) then
                table.insert(sb, ("%s, "):format(tostring(value)))
            elseif "number" == type(value) then
                table.insert(sb, ("['%s']=%s, "):format(tostring(key), tostring(value)))
			else
				table.insert(sb, ("['%s']='%s', "):format(tostring(key), tostring(value)))
            end
        end
        table.insert(sb, '}, ') 
        
		return table.concat(sb)
    else
        return ("%s"):format(tt)
    end
end

------------------------------------------------------------------------
-- 将source表中的keys值更新到self中去
-- @param self      被处理字符串
-- @param source    源表
-- @param keys      要更新哪些键值
-- @return self     自身
------------------------------------------------------------------------
function update(self, source, keys)
    if keys then 
        for _, key in ipairs(keys) do
            self[key] = source[key]
        end
    else
        for k,v in pairs(source) do
            self[k] = v
        end
    end

    return self
end

-- 要求传入的t1, t2必须为表格
-- dup为true表示并运算，为false表示差运算
function merge (t1, t2, dup)
    local res = {}
    for k,v in pairs(t1) do
        if dup or t2[k] then res[k] = v end
    end
    for k,v in pairs(t2) do
        if dup or t1[k] then res[k] = v end
    end
    return res
end

-- 要求传入的t1, t2必须为表格
-- symm为true表示求共有部分，symm为false表示异或运算
function difference (s1, s2, symm)
    local res = {}
    for k,v in pairs(s1) do
        if not s2[k] then res[k] = v end
    end
    if symm then
        for k,v in pairs(s2) do
            if not s1[k] then res[k] = v end
        end
    end
    return res
end

function isEmpty()
    return nil == next(self)
end
