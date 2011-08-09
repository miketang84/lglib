
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

--======================================================================
--==                     其它一些全局辅助函数                          ==
--======================================================================
local Object = require 'lglib.oop'

-------------------------------------------------
-- Define some global callable functions
-------------------------------------------------
-- 类树最基础的节点
_G['Object'] = Object
-- 把它们自动加为全局对象，不用引入直接可以使用
_G['List'] = require 'lglib.list'
_G['Dict'] = require 'lglib.dict'
_G['Set'] = require 'lglib.set'

-- 获取typename属性，传入的对象必须为List, Dict, Table, Set中的一种
_G['typename'] = function (t)
	checkType(t, 'table')
	if t.__typename then
		return t.__typename
	else 
		return nil
	end
end

local istabletype = function (t, name)
	local ret = typename(t) 
	if ret and ret == name then
		return true
	else
		return false
	end
end

_G['isList'] = function (t)
	return istabletype(t, 'List')
end

_G['isDict'] = function (t)
	return istabletype(t, 'Dict')
end

_G['isSet'] = function (t)
	return istabletype(t, 'Set')
end

--------------------------------------------------------------------------------
_G['ptable'] = function (t)
	local ok, ret = pcall(function (t)
		print('--------------------------------------------')
	    for i,v in pairs(t) do print(i,v) end
	 	    print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
		end, t)
	if not ok then print(debug.traceback()); error('[ERROR] when do table print!', 2) end
end

_G['pptable'] = function (t)
	local ok, ret = pcall(function (t)
		print('-----------------PPTABLE--------------------')
		for i,v in pairs(t) do 
			print('>>', i, '<<  ', tostring(v))
			for ii, vv in pairs(v) do
				print(ii,vv) 
			end
		end
		print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
	end, t)
	if not ok then print(debug.traceback()); error('[ERROR] when do table table print!', 2) end
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
		if 'string' ~= type(args[i+half]) then
			print(debug.traceback())
			error('The front half part of the argumet list should be string!', 2)
		end
		
		if args[i+half] ~= type(args[i]) then
			print(debug.traceback())
			error(("This %snd argument: %s doesn't match given type: %s"):format(i, tostring(args[i]), args[i+half]), 2)
		end
	end

	return true
end


---
-- checkRange(a, 0, 10, b, 20, 30, c, 10, 100)
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
	if type(onearg) == 'table' and #onearg == 0 then
		return true
	end
	
	return false
end

_G['isEmpty'] = _G['isFalse']


_G['setProto'] = function (obj, proto)
	checkType(obj, proto, 'table', 'table')
	
	local mt = getmetatable(obj) or {}
	local old_meta = mt.__index
	
	-- 当old_meta为nil或表格时，才进行函数绑定
	if not old_meta or type(old_meta) == 'table' then
		mt.__index = function(t, k)
			return (old_meta and old_meta[k]) or proto[k] 
		end
	end
	
	return setmetatable(obj, mt)
end

_G['T'] = function (t)
	local t = t or {}
	return setProto(t, table)
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
		return ("%q"):format(self)
	elseif "number" == selfType or "boolean" == selfType or "nil" == selfType  then
		return tostring(self)
	elseif "table" == selfType then
		local res, first = "{", true
		table.insert(seen, self)
		local index = 1
		for k, v in pairs(self) do
			if not List.find(seen, v)
			and nil ~= v and "function" ~= type(v) then
				if first then
					first = false
				else
					res = ('%s,'):format(res)
				end
				if k == index then
					res = ('%s%s'):format(res, seri(v, seen))
					index = index + 1
				else
					if "number" == type(k) then
						res = ('%s[%s]='):format(res, k)
					else
						res = ("%s[%s]="):format(res, ("%q"):format(k))
					end
					res = ('%s%s'):format(res, seri(v, seen))
				end
			end
		end
		List.remove(seen, self)
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


------------------------------------------------------------------------
-- 几个注入操作
------------------------------------------------------------------------
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


local function getname(func_info)
	local n = func_info
	if n.what == "C" then return n.name end
	local lc = string.format("[%s]:%s", n.short_src, n.linedefined)
	if n.namewhat ~= '' then
		return string.format("%s (%s)", lc, n.name)
	else
		return lc
	end 
end 

local function trace_intof(event)
	local stable = debug.getinfo(2, 'Sn')
	local sfile = stable.short_src
	local sname = getname(stable)
	if sname and (sname:match('bamboo') or sname:match('lglib') or sname:match('tests') or sname:match('workspace')) then
		print('In file:', sfile, 'Enter function:', sname)
	end
end

local function trace_leavef(event)
	local stable = debug.getinfo(2, 'Sn')
	local sfile = stable.short_src
	local sname = getname(stable)
	if sname and (sname:match('bamboo') or sname:match('lglib') or sname:match('tests') or sname:match('workspace')) then
		print('In file:', sfile, 'Leave function:', sname)
	end
end

local isdebug = os.getenv('DEBUG') 
if isdebug then
	debug.sethook(trace_intof, 'c')
--	debug.sethook(trace_leavef, 'r')
end
