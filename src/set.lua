require('lglib')
local string = string
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat,table.sort
local List = require('lglib.list')
local Dict = require('lglib.dict')


module(..., package.seeall)

-- this is a set prototype, and all of Set instances will inherit it
local Set = {}

--itself as its metatable
Set.__index = Set
Set.__typename = "Set"

-- constructor of Set objects
local function new (tbl)
	-- if tbl is nil, empty table returned
	local t = {}
	if #tbl > 0 then
		checkType(tbl, 'table')
		-- passed in params is a list
		for _, v in ipairs(tbl) do
			t[v] = true  
		end
	elseif not table.isEmpty(tbl) then
		t = tbl
	end

	return setmetatable(t, Set)
end

-- binding constructor new(tbl) with Set() sytanx
-- Dict can be accessed via __index from its/Set metatable ?????
setmetatable(Set, {
    __call = function (self, tbl)
        return new(tbl)
    end,
	-- Set is a special Dict, whose values are true or nil. 
	-- Be careful that the value can not be false!!!
	__index = Dict,
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

Set.members = Dict.keys

-- if set value can be false, it will be wrong somehow because of values overwritten..?????????
function Set:union (set)
    return Set(table.merge(self, set, true))  -- the type of data that merge() returned is not LIST...?????????
end
Set.__add = Set.union


function Set:intersection (set)
    return Set(table.merge(self,set,false))
end
Set.__mul = Set.intersection


function Set:difference (set)
    return Set(table.difference(self,set,false))
end
Set.__sub = Set.difference


function Set:symmetricDifference (set)
    return Set(table.difference(self,set,true))
end
Set.__pow = Set.symmetricDifference


-- two cases of returned values, each one has two values
-- the first one indicates true and empty string, while the second is false and element that is the first element is not contained in set. 
function Set:isSub (set)
    for k in pairs(self) do
        if not set[k] then return false, k end
    end
    return true, ''
end
Set.__lt = Set.isSub


-- override the tostring() function
-- join is a method of LIST
function Set:__tostring ()
    return '['..self:members():join(',')..']'
end


return Set
