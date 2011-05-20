local string = string
local tinsert, tremove, tconcat, tsort = table.insert, table.remove, table.concat,table.sort
local merge, difference = table.merge, table.difference 
local List = require('lglib.list')
local Dict = require('lglib.dict')

module(..., package.seeall)

-- 让所有List的实例都继承自这个List原型
local Set = {}
	-- 它自身就是元表，本体与元表合二为一
Set.__index = Set
Set.__typename = "Set"

-- 创建实例
local function new (tbl)
	-- 如果没传入表作参数，则生成一个空表
	local t = {}
	if tbl then
		checkType(tbl, 'table')
		-- 传入的列表要求是一个list，这里只找list部分
		for _, v in ipairs(tbl) do
			t[v] = true
		end
	end

	return setmetatable(t, Set)
end

-- 使可使用List()语法
setmetatable(Set, {
    __call = function (self, tbl)
        return new(tbl)
    end,
	-- Set是一种特殊的Dict，即values全为true或nil, false的dict
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



function Set:union (set)
    return merge(self, set, true)
end
Set.__add = Set.union


function Set:intersection (set)
    return merge(self,set,false)
end
Set.__mul = Set.intersection


function Set:difference (set)
    return difference(self,set,false)
end
Set.__sub = Set.difference


function Set:symmetric_difference (set)
    return difference(self,set,true)
end
Set.__pow = Set.symmetric_difference


function Set:is_subset (set)
    for k in pairs(self) do
        if not set[k] then return false end
    end
    return true
end
Set.__lt = Set.is_subset


-- 改变默认打印输出方式
function Set:__tostring ()
    return '['..self:members():join(',')..']'
end


return Set


