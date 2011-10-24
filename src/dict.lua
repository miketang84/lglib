local string, table = string, table
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat,table.sort
local normalize_slice = table.normalize_slice
local List = require('lglib.list')

module(..., package.seeall)

-- 让所有List的实例都继承自这个List原型
local Dict = {}
	-- 它自身就是元表，本体与元表合二为一
Dict.__index = Dict
Dict.__typename = "Dict"


local function is_key(self, key)
	local list_len = #self
	if type(key) ~= 'number' or (type(key) == 'number' and key > list_len) then
		return true
	else
		return false
	end
end

-- 创建实例
local function new (tbl)
	-- 如果没传入表作参数，则生成一个空表
	local t = {}
	-- 只抽取
	if tbl then
		checkType(tbl, 'table')
		for k, v in pairs(tbl) do
			if is_key(k) then
				t[k] = v
			end
		end
	end

	return setmetatable(t, Dict)
end

-- 使可使用Dict()语法
setmetatable(Dict, {
    __call = function (self, tbl)
        return new(tbl)
    end,
	__index = table
})



-- 创建一个list，将Dict的key搜集进去
function Dict:keys()
	local res = List()
	for key, _ in pairs(self) do
		-- 只找符合字典定义的键
		if is_key(self, key) then
			tinsert(res, key)
		end
	end
	return res
end

function Dict:hasKey(key)
    for k, _ in pairs(self) do
		if is_key(self, k) and k == key then
            return true
        end
	end
	return false
end

function Dict:size()
	local count = 0
	for key in pairs(self) do
		if is_key(self, key) then
			count = count + 1
		end
	end
	return count
end

function Dict:values()
	local res = List()
	for key, v in pairs(self) do
		-- 只找符合字典定义的键
		if is_key(self, key) then
			tinsert(res, v)
		end
	end
	return res
end

return Dict
