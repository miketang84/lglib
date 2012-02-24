-- after loading lglib.strict, all global variables should be declared before use
require 'lglib.strict'

module(..., package.seeall)

--======================================================================
--==                  some global helper functions     	              ==
--======================================================================

--[[ local orig_assert = assert
_G['assert'] = function (bool, error_prompt)
	if not bool then
		if error_prompt then print(error_prompt) end
		print(debug.traceback())
		orig_assert(bool)
	end
	return bool
end --]]

-- is equal for all type
_G['equal'] = function (a, b)
	local type_a = type(a)
	local type_b = type(b)
	
	-- check type equality
	if type_a ~= type_b then return false end
	
	if type_a == 'table' then
		local ret = true
		local tp_av
		local tp_bv
		for k, v in pairs(a) do
			tp_av = type(v)
			tp_bv = type(b[k])
			if tp_av ~= tp_bv then return false end
			
			if tp_av == 'table' then
				ret = equal(v, b[k])
				if not ret then return false end
			end
			
		end
	elseif a ~= b then
		-- check native value equality
		return false
	else
		-- check metatable equality
		local meta_a = getmetatable(a)
		local meta_b = getmetatable(b)
		if meta_a ~= meta_b then return false end
	end
	
	return true
end

-- register extended methods into lua standard library, like string, table, io, etc 
function import(wrap_table, sub_modname)
	local info = debug.getinfo(1, 'S')
	local filedir = info.source:sub(2, -10)

	setfenv(assert(loadfile( ('%s/%s.lua'):format(filedir, sub_modname))), setmetatable(wrap_table, {__index=_G}))(filedir)
	setmetatable(wrap_table, nil)
end

-- explicitly setting global variables
_G['import'] = import

-- Define some global callable functions and use them directly later without "require"
-- the only root or parent of all class objects
_G['Object'] = require 'lglib.oop'
_G['List'] = require 'lglib.list'
_G['Dict'] = require 'lglib.dict'
_G['Set'] = require 'lglib.set'

-- accessing the field of "typename"，the object passed into should be one of List, Dict, Table, Set, etc.
-- then we also define "checkType" for List, Dict, Set, Table???---->just isList(), isDict(), isSet()
local typename = function (t)
	local typet = type(t)

	local tmeta = getmetatable(t)
	if tmeta and rawget(tmeta, '__typename') then
		return tmeta.__typename
	else
		return typet
	end
end
_G['typename'] = typename

-- checking the type of instance
local isType = function (t, name)
	local ret = typename(t) 
	if ret and ret == name then
		return true
	else
		return false
	end
end

_G['isType'] = isType

_G['isList'] = function (t)
	return isType(t, 'list')
end

_G['isDict'] = function (t)
	return isType(t, 'dict')
end

_G['isSet'] = function (t)
	return isType(t, 'set')
end

--------------------------------------------------------------------------------
-- print one layer of table information
_G['ptable'] = function (t)
	if type(t) ~= 'table' then print(t); return print(("[Warning] parameter '%s' passed in is not a table "):format(tostring(t))) end
    print('-----------------------------------------------')
    for k, v in pairs(t) do
		print(k, v)
    end
    print('^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^')
end

-- print all layers of table information 
_G['fptable'] = function (t)
	if type(t) ~= 'table' then print(t);  return print(("[Warning] parameter '%s' passed in is not a table "):format(tostring(t))) end
    print(table.tree(t))
end

---
-- checkType(a, b, c, 'string', 'table', 'number')
-- add several more types, like set, dict, list, queue, etc  ????
_G['checkType'] = function (...)
	local args_len = select('#', ...)
	local args = {...}
	assert(args_len % 2 == 0, 'Argument types and objs are not matched.')
	
	local half = args_len / 2;
	local typev, targettype
	for i=1, half do
		typev = typename(args[i])
		targettype = args[i+half]
		assert('string' == type(targettype), '[Error] The lower half part of the argumet list should be string!')
		assert(targettype == typev , ("[Error] This %snd argument: %s doesn't match given type: %s"):format(i, tostring(args[i]), targettype))
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

-- use for what?
-- nil, false, 0, "", {}, etc
_G['isFalse'] = function (onearg)
	if not onearg or onearg == '' or onearg == 0 then
		return true
	end

	if type(onearg) == 'table' and table.isEmpty(onearg) then
		return true
	end
	
	return false
end

-- check if is string or number
_G['isStrOrNum'] = function (arg)
	local ctype = type(arg)
	return ctype == 'string' or ctype == 'number'
end

-- config a prototype for a given object/instance
_G['setProto'] = function (obj, proto)
	checkType(proto, 'table')
	
	local mt = getmetatable(obj) or {}
	local old_t = mt.__index
	
	-- methods binding when old_meta is nil or table
	if old_t == nil then
		mt.__index = proto
	elseif type(old_t) == 'table' then
		mt.__index = function (t, k)  	-- here, 't' is the table self
			return old_t and old_t[k] or proto[k] 
		end
	elseif type(old_t) == 'function' then
		mt.__index = function (t, k)
			return old_t(t, k) or proto[k]
		end
	end
	
	return setmetatable(obj, mt)
end

-- printf as an alias of string.format()
_G['printf'] = function (...) 
	print(string.format(...)) 
end


------------------------------------------------------------------------
-- serialize lua instances/objects into a lua-table format
-- @param self  object to be serialized
-- @param seen  holding tables that have been serialized 
-- @return string|nil  if works. string returned. otherwise for nil
------------------------------------------------------------------------
_G['serialize'] = function (self, seen)
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
					res = ('%s%s'):format(res, serialize(v, seen))
					index = index + 1
				else
					if "number" == type(k) then
						res = ('%s[%s]='):format(res, k)
					else
						res = ("%s[%s]="):format(res, ("%q"):format(k))
					end
					res = ('%s%s'):format(res, serialize(v, seen))
				end
			end
		end
		List.remove(seen, self)
		return ('%s}'):format(res)
	end
	return nil
end

------------------------------------------------------------------------
-- deserialization is just loading serialized string into memory
-- the point is that format of serialzation are just lua code of assignment of lua-tables
-- @param self  serialized string 
-- @return lua tables/instance
------------------------------------------------------------------------
_G['deserialize'] = function (self)
	if not self then
		return nil
	end
	
	-- just loading them into memory
	local func = loadstring(("return %s"):format(self))
	if not func then
		error(("[Error] deserialize fails %s %s"):format(debug.traceback(), self))
	end
	
	-- running the string as lua-code
	return func()
end


------------------------------------------------------------------------
-- Injection of several methods into standard library 
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


-- DO NOT UNDERSTAND 
-- for debug issue
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
