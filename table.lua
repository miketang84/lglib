local table, pairs, next, type, require, ipairs = table, pairs, next, type, require, ipairs
local tostring, debug, assert, error, setmetatable = tostring, debug, assert, error, setmetatable
local string = string
local math = math


------------------------------------------------------------------------
-- List or Array Specific
------------------------------------------------------------------------
function append(self, val)
    table.insert(self, val)
    return self
end

function prepend(self, val)
    table.insert(self, 1, val)
    return self
end

function ins(self, i, val)
    table.insert(self, i, val)
    return self
end

function joint(self, another)
	for _, v in ipairs(another) do
		table.insert(self, v)
	end
	return self
end

-- 支持start, stop为空，为负值
function slice(self, start, stop, is_rev)
		
	local nt = {}
	local start = start or 1
	local stop = stop or #self
	
	if (stop > 0 and start > 0) or (stop < 0 and start < 0) then assert( stop >= start) end
	if start > #self then return {} end
	
	-- 处理索引为负数的情况
	-- 最后一个元素为-1，倒数第二个为-2
	if start == 0 then 
		start = 1 
	elseif start < 0 then
		if math.abs(start) >= #self then
			start = 1
		else
			start = #self + start + 1
		end
	end
	if stop == 0 then 
		stop = 1 
	elseif stop < 0 then 
		stop = #self + stop + 1 
		if stop < 1 then return {} end
	end
	
	if not is_rev then
		for i = start, (#self > stop and stop or #self) do
			table.insert(nt, self[i])
		end
	else
		for i = (#self > stop and stop or #self), start, -1 do
			table.insert(nt, self[i])
		end
	end
	
	return nt
end


function takeApart(self)
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
	
	return list_part, dict_part
end
------------------------------------------------------------------------
-- Dict or Hash Table Specific
------------------------------------------------------------------------
function keys(self)
	local res = {}
	for key, _ in pairs(self) do
		table.insert(res, key)
	end
	return res
end

function size(self)
	local count = 0
	for _ in pairs(self) do
		count = count + 1
	end
	return count
end

function hasKey(self, key)
    for k, _ in pairs(self) do
		if k == key then
            return true
        end
	end
	return false
end

function isEmpty(self)
    return nil == next(self)
end

function isIn(self, val)
	for k, v in pairs(self) do
		if val == v then
			return true
		end
	end
    
    return false
end

function ifind(self, val)
	for k, v in ipairs(self) do
		if val == v then
			return k
		end
	end
end

function find(self, val)
	for k, v in pairs(self) do
		if val == v then
			return k
		end
	end
    return nil
end

function imap(self, func)
	local res = {}
	for _, val in ipairs(self) do
		local newVal
		if "string" == type(func) then
			newVal = val[func](val)
		else
			newVal = func(val)
		end
		if newVal then
			table.insert(res, func(val))
		end
	end
	return res
end

function map(self, func)
	local res = {}
	for key, val in pairs(self) do
		if "string" == type(func) then
			res[key] = val[func](val)
		else
			res[key] = func(val)
		end
	end
	return res
end

function iremVal(self, val)
	local key = table.ifind(self, val)
	if key then
		return table.remove(self, key)
	end
end

function remVal(self, val)
	local key = table.find(self, val)
	if key then
		return table.remove(self, key)
	end
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


function ijoin(self, sep)
	local res
	sep = sep or ""
	for _, v in ipairs(self) do
		res = ('%s%s'):format((res and ('%s%s'):format(res, sep) or ""), tostring(v))
	end
	return res or ""
end

function join(self, sep)
	local res
	sep = sep or ""
	for _, v in pairs(self) do
		res = ('%s%s'):format((res and ('%s%s'):format(res, sep) or ""), tostring(v))
	end
	return res or ""
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

