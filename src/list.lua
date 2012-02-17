local string, table = string, table
local tinsert, tremove, concat, tsort = table.insert, table.remove, table.concat, table.sort
local assert = assert
local equal = equal

module(..., package.seeall)

-- this is a LIST prototype, and all of list instances inherit it
local List = {}
local List_meta = {}
List_meta.__index = List
List_meta.__typename = "list"
List_meta.__newindex = function (self, k, v)
	assert(type(k) == 'number', "[Error] List can only accept number as index.")
	assert(k > 0 and k <= #self + 1 , "[Error] index overflow.")
	rawset(self, k, v)
end

-- constructor of List object
local function new (tbl)
	tbl = tbl or {}
	assert(type(tbl) == 'table', "[Error] paramerter passed in List constructor should be table.")
	-- here, we keep the thing simple to keep speed
	-- setting the inheritance relationship
	return setmetatable(tbl, List_meta)
end

-- binding constructor new(tbl) with List() sytanx
-- table can be accessed via __index from its/List metatable. It means List can reuse the table API??
setmetatable(List, {
    __call = function (self, tbl)
        return new(tbl)
    end,
})


-- the normalization of indice
function normalize_slice( self, start, stop )
	local start = start or 1
	local stop = stop or #self
	
	if stop > 0 and start > 0 or stop < 0 and start < 0 then assert(stop >= start) end
	if start > #self then return nil, nil end
	
	-- the negative index
	-- -1 is the last elment, -2 the penultimate, and so on
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
		if stop < 1 then return nil, nil end
	end
	
	return start, stop
end


------------------------------------------------------------------------
-- @class method
-- start para is optional, and the default value is 1
-- generate a sequence of integers 
function List.range(start, finish)
	if not finish then
		finish = start
		start = 1
	end
	checkType(start, finish, 'number', 'number')
	
	local  t = new()
	for i = start, finish do tinsert(t, i) end
	return t
end


------------------------------------------------------------------------
-- @object methods

-- appending extra element at the tail of list
function List:append(val)
    tinsert(self, val)
    return self
end

-- super slow, time complexity is O(N). IF implemented by lua-table, it will be much better
function List:prepend(val)
    tinsert(self, 1, val)
    return self
end

--list expansion by another one
function List:extend( another )
	checkType(another, 'list')
	for i = 1, #another do tinsert(self, another[i]) end
	return self
end

-- delete by index
function List:pop (i)
	tremove(self, i)
    return self
end

-- delete by value, and all of them
-- maybe a better API is List:remove(x, numOfDeletion)
-- if numOfDeletion is negative integer,then counting from the last one in reversing order.
function List:remove(x)
    for i = #self, 1, -1 do
        if self[i] == x then tremove(self, i) end
    end
    return self
end

-- push a new element into list at right-hand side
List.push = List.append


-- starting from idx index and trying to find the first element with value=val, 
function List:find(val, idx)
    local idx = idx or 1
    if idx < 0 then idx = #self + idx + 1 end
    for i = idx, #self do
        if self[i] == val then return i end
    end
    return nil
end

-- contain element x or not
function List:contains(x)
    return self:find(x, 1) and true or false
end

-- counting the times that element x appears in a list
function List:count(x)
	local cnt=0
	for i=1, #self do
		if self[i] == x then cnt = cnt+1 end
	end
	return cnt
end

-- simple wrapper of table.concat() method
function List:join(sep)
	local _t = {}
	for _, v in ipairs(self) do
		tinsert(_t, tostring(v))
	end
	return concat(_t, sep)
end

-- sorting, a simple wrapper of table.sort()
function List:sort(cmp)
	tsort(self, cmp)
	return self
end

-- reverse the order of list elements
function List:reverse()
    local t = self
    local n = #t
    local n2 = n/2
    for i = 1, n2 do
        local k = n - i + 1
        t[i], t[k] = t[k], t[i]
    end
    return self
end

-- slicing
-- start, stop maybe nil, negative integer, or other values
function List:slice(start, stop, is_rev)
	-- NOTICE: here, should not use checkType!
	-- because start, stop, is_rev are all probably nil.
	local nt = List()
	local start, stop = normalize_slice(self, start, stop)
	if not start or not stop then return List() end
	
	if is_rev ~= 'rev' then
		for i = start, (#self > stop and stop or #self) do
			tinsert(nt, self[i])
		end
	else
		for i = (#self > stop and stop or #self), start, -1 do
			tinsert(nt, self[i])
		end
	end
	
	return nt
end

-- delete all of list elements
function List:clear()
	for i=1, #self do tremove(self, i) end
	return self
end

-- length/size of list
function List:len()
	return #self
end

-- deleted by indexing interval 
function List:chop(i1,i2)
	local i1, i2 = normalize_slice(i1, i2)
    for i = i1, i2 do
        tremove(t, i)
    end
	return self
end

-- insert another *list* at the location *idx*
function List:splice(idx, list)
    checkType(idx, list, 'number', 'list')
    local i = idx
    for _, v in ipairs(list) do
        tinsert(self, i, v)
        i = i + 1
    end
    return self
end

-- assignment in the style of slicing
function List:sliceAssign(i1, i2, seq)
    checkType(i1, i2, 'number', 'number')
    local i1, i2 = normalize_slice(self, i1, i2)
	local delta = i2 - i1 + 1
	
	-- old implementation
	if i2 >= i1 then self:chop(i1, i2) end
    self:splice(i1, seq)
    
    -- new implementation
    for i = 1, delta do
    	self[i1 + i - 1] = seq[i]
    end
    
    return self
end

function List_meta:__add(another)
    checkType(another, 'list')
    
    ls:extend(another)
    return ls
end

List.__eq = equal

function List_meta:__tostring()
	return '[' .. self:join(', ') .. ']'
end


function List:each(func)
	local ret = List()
	if self then
		for _, v in ipairs(self) do
			ret:append(func(v))
		end
	end
	return ret	
end

function List:dump(count)
	for i=1, #self do
		if type(self[i]) == 'string' then
			print(i, self[i])
		else
			if self[i].dump then
				self[i]:dump(count)
			end
		end
	end
end


-- 
function List:isEmpty ()
	if type(self) ~= 'table' then
		error('You use isEmpty(), but the parameter is not a list.', 2)
	end
	
    if #self == 0 then
		return true
	else
		return false
	end
end


return List
