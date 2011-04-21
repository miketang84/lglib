
-- 设置全局变量使用检查，加载执行了这个文件后。所有的全局变量使用前必须声明
require 'lglib.strict'

module(..., package.seeall)
local modname = ...

function import(wrap_table, sub_modname)
	local info = debug.getinfo(1, 'S')
	local filedir = info.source:sub(2, -10)
	
	setfenv(assert(loadfile( ('%s/%s.lua'):format(filedir, sub_modname))), setmetatable(wrap_table, {__index=_G}))(filedir)
	setmetatable(wrap_table, nil)
end
-- 这一句必须写在这里，后面几个函数要用
_G['import'] = import

function loadStringModule()
	import(string, 'string')
end

function loadTableModule()
	import(table, 'table')
end

function loadIoModule()
	import(io, 'io')
end

-------------------------------------------------
-- Initialize all sub module
-------------------------------------------------
local function lglib_init()
	loadTableModule()
	loadStringModule()
	loadIoModule()
end
-- call it
lglib_init()


--======================================================================
--==                     其它一些全局辅助函数                          ==
--======================================================================

-- 加载http库
require 'lglib.http'
local Object = require 'lglib.oop'

-------------------------------------------------
-- Define some global callable functions
-------------------------------------------------
-- 类树最基础的设施
_G['Object'] = Object

-- put _M here maybe not right, this _M is lglib's _M
_G['class'] = function (constructor)
	return function ()
		local _M = _M
		setmetatable(_M, {__index=_G, __call = function (...)
			return constructor(...)
		end})
	end
end

_G['I_AM_CLASS'] = function (self)
	assert(self:isClass(), 'This function is only allowed to be called by class singleton.')
end

_G['UTF8_FULLSUPPORT'] = true


_G['T'] = function (t)
	local mt = getmetatable(t) or {}
	local oi = mt.__index
	
	mt.__index = function(k)
		return (oi and oi(k)) or table[k] 
	end
	
	return setmetatable(t, mt)
	-- Simple case: If t doesn't have metatable
	-- return setmetatable(t or {}, {__index=table})
end

_G['toString'] = function (obj)
	if "nil" == type(obj) then
        return tostring(nil)
    elseif "table" == type(obj) then
		-- 去掉字符串末尾的', '字符，所以要来个sub(1, -3)
        return table.pt(obj):sub(1, -3)
    elseif  "string" == type(obj) then
        return obj
    else
        return tostring(obj)
    end
end


_G['po'] = function (obj)
	print(toString(obj))
end

_G['dump'] = function (obj, name)
	print(toString({name or "*", obj}))
end

_G['ptable'] = function (t)
	print('--------------------------------------------')
	for i,v in pairs(t) do print(i,v) end
	print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
end

---
-- checkType(a, b, c, 'string', 'table', 'number')
--
_G['checkType'] = function (...)
	local args_len = select('#', ...)
	local args = {...}
	assert(args_len % 2 == 0, 'Argument types and objs are not matched.')
	
	local half = args_len / 2;
	for i=1, half do
		assert('string' == type(args[i+half]), 
			'The front half part of the argumet list should be string!')
		assert( args[i+half] == type(args[i]), 
			("This %snd argument doesn't match given type: %s"):format(i, args[i+half]))
	end

	return true
end

---
-- checkType(a, 0, 10, b, 20, 30, c, 10, 100)
--
_G['checkRange'] = function (...)
	local args_len = select('#', ...)
	local args = {...}
	assert(args_len % 3 == 0, 'Argument types and objs are not matched.')
	
	local par = args_len / 3;
	for i=1, par do
		local t = (i-1)*3
		assert('number' == type(args[t+2]), ('This argument: [%s]=%s should be number!'):format(t+2, args[t+2]))
		assert('number' == type(args[t+3]), ('This argument: [%s]=%s should be number!'):format(t+3, args[t+3]))
		assert( args[t+1] >= args[t+2] and args[t+1] <= args[t+3], 
			("This argument: %s is not between %s and %s!"):format(t+1, t+2, t+3))
	end

	return true
end

_G['isFalse'] = function (onearg)
	if not onearg or onearg == '' or onearg == 0 then
		return true
	end
	if type(onearg) == 'table' and table.isEmpty(onearg) then
		return true
	end
	
	return false
end

-- 实例函数。判断实例对象是不是空的。即数据库中的没有符合要求的对象。
-- 下面是我们的规则
_G['isEmpty'] = function (obj)
	if isFalse(obj) then return false end
	checkType(obj, 'table')
	
	for k, v in pairs(obj) do
		if not k:startsWith('_') 		-- 去掉_parent
		and type(v) ~= 'function' 		-- 去掉new, extend两个函数
		and k ~= 'id'					-- 去掉id字段
		and k ~= 'name'					-- 去掉name字段
		then
			return false
		end
	end
	
	return true
end;

_G['setProto'] = function (obj, proto)
	checkType(obj, proto, 'table', 'table')
	
	return setmetatable(obj, {__index=proto})
end



------------------------------------------------------------------------
-- 序列化lua对象
-- @param self  被处理的对象
-- @param seen  .....
-- @return 字符串|nil  如果处理成功返回字符串，否则，返回nil
------------------------------------------------------------------------
_G['seri'] = function (self, seen)
	seen = seen or {}
	local selfType = type(self)
	if "string" == selfType then
		return ("%s"):format(self)
	elseif "number" == selfType or "boolean" == selfType or "nil" == selfType  then
		return tostring(self)
	elseif "table" == selfType then
		local res, first = "{", true
		table.insert(seen, self)
		local index = 1
		for k, v in pairs(self) do
			if not table.ifind(seen, v)
			and nil ~= v and "function" ~= type(v) then
				if first then
					first = false
				else
					res = ('%s;'):format(res)
				end
				if k == index then
					res = ('%s%s'):format(res, seri(v, seen))
					index = index + 1
				else
					if "number" == type(k) then
						res = ('%s[%s]='):format(res, k)
					else
						res = ('%s[%s]='):format(res, ("%q"):format(k))
					end
					res = ('%s%s'):format(res, seri(v, seen))
				end
			end
		end
		table.iremVal(seen, self)
		return ('%s}'):format(res)
	end
	return nil
end

------------------------------------------------------------------------
-- 将序列化的字符串加载到内存中，生成lua对象
-- @param self  被处理字符串
-- @return lua对象
------------------------------------------------------------------------
_G['unseri'] = function (self)
	if not self then
		return nil
	end
	local func = loadstring(("return %s"):format(self))
	if not func then
		error(("unserialize fails %s %s"):format(debug.traceback(), self))
	end
	return func()
end





