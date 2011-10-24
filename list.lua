local string, table = string, table
local tinsert, tremove, concat, tsort = table.insert, table.remove, table.concat, table.sort

module(..., package.seeall)

-- 让所有List的实例都继承自这个List原型
local List = {}
-- 它自身就是元表，本体与元表合二为一
List.__index = List
List.__typename = "List"

-- 创建实例
local function new (tbl)
	-- 如果没传入表作参数，则生成一个空表
	local t = {}
	
	if tbl then
		checkType(tbl, 'table')
		for _, v in ipairs(tbl) do
			tinsert(t, v)
		end
	end
	-- 设置为继承自List
	return setmetatable(t, List)
end

-- 使可使用List()语法
setmetatable(List, {
    __call = function (self, tbl)
        return new(tbl)
    end,
	__index = table
})


-- 正规化索引序号
function normalize_slice( self, start, stop )
	local start = start or 1
	local stop = stop or #self
	
	if (stop > 0 and start > 0) or (stop < 0 and start < 0) then assert( stop >= start) end
	if start > #self then return nil, nil end
	
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
		if stop < 1 then return nil, nil end
	end
	
	return start, stop
end


------------------------------------------------------------------------
-- 给List对象本身用的

-- 产生一个有序序列
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


-- 将函数用到多个List上
-- 每个list的元素个数都必须相同
function List.mapn(fn,...)
    --fun = function_arg(1,fun)
    local res = {}
    local lists = {...}
    
	for i = 1, #lists do
        local args = {}
        for j = 1, #lists do
            args[#args+1] = lists[j][i]
        end
        res[#res+1] = fun(unpack(args))
    end
    return res
end


-- @usage zip({10,20,30},{100,200,300}) is {{10,100},{20,200},{30,300}}
function List.zip(...)
    return List.mapn(function(...) return {...} end, ...)
end

------------------------------------------------------------------------
-- 给实例用的


-- 追加元素
function List:append(val)
    tinsert(self, val)
    return self
end

-- 前加元素
function List:prepend(val)
    tinsert(self, 1, val)
    return self
end

-- 用一个新list来扩展本list
function List:extend( another )
	checkType(another, 'table')
	for i = 1, #another do tinsert(self, another[i]) end
	return self
end

-- 按索引删除
function List:iremove (i)
    checkType(i, 'number')
    tremove(self, i)
    return self
end

-- 按值删除（删除所有同值的）
function List:remove(x)
    for i=1, #self do
        if self[i] == x then tremove(self,i) end
    end
    return self
end

-- 压入个新元素到最后
List.push = List.append
-- 弹出最后的元素
function List:pop()
    return tremove(self)
end

function List:find(val, idx)
    checkType(self, 'table')
    local idx = idx or 1
    if idx < 0 then idx = #self + idx + 1 end
    for i = idx, #self do
        if self[i] == val then return i end
    end
    return nil
end

-- 是否包含
function List:contains(x)
    return self:find(x, 1) and true or false
end

-- 检查同值元素次数
function List:count(x)
	local cnt=0
	for i=1, #self do
		if self[i] == x then cnt = cnt+1 end
	end
	return cnt
end

-- 将表生成字符串
function List:join(sep)
	return concat(self, sep)
end

-- 排序
function List:sort(cmp)
	tsort(self, cmp)
	return self
end

-- 反转
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

-- 切片
-- 支持start, stop为空，为负值
function List:slice(start, stop, is_rev)
	-- NOTICE: here, should not use checkType!
	-- because start, stop, is_rev are all probably nil.
	local nt = {}
	local start, stop = normalize_slice(self, start, stop)
	if not start or not stop then return List() end
	
	if is_rev ~= 'rev' then
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

-- 清空
function List:clear()
	for i=1, #self do tremove(self, i) end
	return self
end

-- 测量长度
function List:len()
	return #self
end

-- 删除一个区间
function List:chop(i1,i2)
	local i1, i2 = normalize_slice(i1, i2)
    for i = i1, i2 do
        tremove(t, i)
    end
	return self
end

-- 将一个表插入到本表中来
function List:splice(idx, list)
    checkType(idx, list, 'number', 'table')
    local i = idx
    for _, v in ipairs(list) do
        tinsert(self, i, v)
        i = i + 1
    end
    return self
end

-- slice赋值
function List:sliceAssign(i1, i2, seq)
    checkType(i1, i2, 'number', 'number')
    local i1, i2 = normalize_slice(self, i1, i2)
	local delta = i2 - i1 + 1
	
	if i2 >= i1 then self:chop(i1, i2) end
    self:splice(i1, seq)
    return self
end

-- 定义了这个后可以在两个List之间用 + 连接
-- 生成一个新的List返回
function List:__add(another)
    checkType(another, 'table')
    
	local ls = List(self)
    ls:extend(another)
    return ls
end

-- 定义这个，可以对两个List之间进行相等比较
function List:__eq(L)
    if #self ~= #L then return false end
    for i = 1, #self do
        if self[i] ~= L[i] then return false end
    end
    return true
end

function List:__tostring()
    -- return '{'..self:join(',',tostring_q)..'}'
end

-- 对所有元素执行函数操作，生成一个新的List返回
-- 貌似跟foreach基本一样
function List:map(fn, ...)

	
end

-- 对所有元素执行函数操作，在自身上改变
function List:transform (fn, ...)
    
	return self
end




return List


