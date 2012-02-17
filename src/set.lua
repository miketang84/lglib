local string = string
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat, table.sort
local assert = assert
local List = require('lglib.list')
local Dict = require('lglib.dict')


module(..., package.seeall)

-- this is a set prototype, and all of Set instances will inherit it
local Set = {}
local Set_meta = {}
Set_meta.__index = Set
Set_meta.__typename = "set"
Set_meta.__newindex = function (self, k, v)
	assert(isStrOrNum(k), '[Error] the key passed in to Set should only be string or number.')
	rawset(self, k, v)
end

-- constructor of Set objects
-- now, the key of the set is not suit for table/object, only for number and string, 
-- and the stored type is always string
local function new (tbl)
	tbl = tbl or {}
	assert(type(tbl) == 'table', "[Error] paramerter passed in Set constructor should be table.")

	-- retreive list item, left the key-value part
	for i, v in ipairs(tbl) do
		rawset(tbl, tostring(v), true)
		rawset(tbl, i, nil)
	end

	return setmetatable(tbl, Set_meta)
end

-- binding constructor new(tbl) with Set() sytanx
-- Dict can be accessed via __index from its/Set metatable ?????
setmetatable(Set, {
    __call = function (self, tbl)
        return new(tbl)
    end,
})


function Set:add (key, value)
    self[key] = value or true
end

function Set:delete (key)
    self[key] = nil
end

function Set:has (key)
    if self[key] then
		return true
	else
		return false
	end
end

function Set:members()
	local r = List()
	for k, _ in pairs(self) do
		tinsert(r, k)
	end
	return r
end

-- if set value can be false, it will be wrong somehow because of values overwritten..?????????
function Set:union (set)
    assert(isSet(set), '[Error] the #2 passed in union is not set.')
    for k, v in pairs(set) do
        if not self[k] then self[k] = v end
    end
    return self
end
Set_meta.__add = Set.union


function Set:intersection (set)
    for k, v in pairs(self) do
        if not set[k] then self[k] = nil end
    end
	return self
end
Set_meta.__mul = Set.intersection


function Set:difference (set)
    for k, v in pairs(set) do
        if self[k] then self[k] = nil end
    end
    return self
end
Set_meta.__sub = Set.difference


function Set:symmetricDifference (set)
    for k, v in pairs(set) do
        if self[k] then 
			self[k] = nil 
		else	
			self[k] = v
		end
    end

    return self
end
Set_meta.__pow = Set.symmetricDifference


-- two cases of returned values, each one has two values
-- the first one indicates true and empty string, while the second is false and element that is the first element is not contained in set. 
function Set:isSub (set)
    for k in pairs(self) do
        if not set[k] then return false, k end
    end
    return true, ''
end
Set_meta.__lt = Set.isSub


-- override the tostring() function
-- join is a method of LIST
function Set_meta:__tostring ()
    return '{' .. self:members():join(', ') .. '}'
end

function Set:size()
	local count = 0
	while next(self) do
		count = count + 1
	end
	return count
end
Set_meta.__len = Set.size


return Set
