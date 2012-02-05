local string = string
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat, table.sort
local List = require('lglib.list')
local Dict = require('lglib.dict')


module(..., package.seeall)

-- this is a set prototype, and all of Set instances will inherit it
local Set = {}
local Set_meta = {}
Set_meta.__index = Set
Set_meta.__typename = "set"
--Set_meta.__newindex = function (self, k, v)
--end

-- constructor of Set objects
-- now, the key of the set is not suit for table/object
local function new (tbl)
	assert(type(tbl) == 'table', "[Error] paramerter passed in Set constructor should be table.")

	-- retreive list item, left the key-value part
	for _, v in ipairs(tbl) do
		t[v] = true
	end

	return setmetatable(t, Set)
end

-- binding constructor new(tbl) with Set() sytanx
-- Dict can be accessed via __index from its/Set metatable ?????
setmetatable(Set, {
    __call = function (self, tbl)
        return new(tbl)
    end,
})


function Set:add (key)
    self[key] = true
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

function Set:members(self)
	local r = List()
	for k, _ in pairs(self) do
		tinsert(r, k)
	end
	return r
end

-- if set value can be false, it will be wrong somehow because of values overwritten..?????????
function union (self, set)
    assert(isSet(set), '[Error] the #2 passed in union is not set.')
    for k, v in pairs(set) do
        if not self[k] then self[k] = v end
    end
    return self
end
Set_meta.__add = union


function intersection (self, set)
    for k, v in pairs(self) do
        if not set[k] then self[k] = nil end
    end
	return self
end
Set_meta.__mul = intersection


function difference (self, set)
    for k, v in pairs(set) do
        if self[k] then self[k] = nil end
    end
    return self
end
Set_meta.__sub = difference


function symmetricDifference (self, set)
    for k, v in pairs(set) do
        if self[k] then 
			self[k] = nil 
		else	
			self[k] = v
		end
    end

    return self
end
Set_meta.__pow = symmetricDifference


-- two cases of returned values, each one has two values
-- the first one indicates true and empty string, while the second is false and element that is the first element is not contained in set. 
function isSub (self, set)
    for k in pairs(self) do
        if not set[k] then return false, k end
    end
    return true, ''
end
Set_meta.__lt = isSub


-- override the tostring() function
-- join is a method of LIST
function Set_meta:__tostring ()
    return '{' .. self:members():join(',') .. '}'
end


return Set
