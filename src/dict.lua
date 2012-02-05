local string, table = string, table
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat,table.sort
local List = require('lglib.list')

module(..., package.seeall)

-- this is a Dict prototype, and all instances of Dict must inherit it
-- we limite: the key is only string
local Dict = {}
local Dict_meta = {}
--itself as its metatable
Dict_meta.__index = Dict
Dict_meta.__typename = "dict"
Dict_meta.__newindex = function (self, k, v)
	assert(type(k) == 'string', '[Error] parameter passed in Dict must be string.')
	rawset(self, k, v)
end



-- constructor for Dict objects
local function new (tbl)
	assert(type(tbl) == 'table', "[Error] paramerter passed in Dict constructor should be table.")
	for k, v in pairs(tbl) do
		if type(k) ~= 'string' then
			tbl[tostring(k)] = v
			tbl[k] = nil
		end
	end
	return setmetatable(tbl, Dict_meta)
end

-- binding constructor new(tbl) with Dict sytanx
-- table can be accessed via __index from its/Dict metatable 
setmetatable(Dict, {
    __call = function (self, tbl)
        return new(tbl)
    end,
})

-- collecting all keys of Dict and puting them into a List
function Dict:keys()
	local res = List()
	for key, _ in pairs(self) do
		tinsert(res, key)
	end
	return res
end

function Dict:hasKey(key)
    return self[key] and true or false
end

function Dict:size()
	local count = 0
	for key in pairs(self) do
		count = count + 1
	end
	return count
end

function Dict:values()
	local res = List()
	for key, v in pairs(self) do
		tinsert(res, v)
	end
	return res
end


return Dict
