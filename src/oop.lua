local table = table
local loadstring, assert = loadstring, assert
local tostring, getmetatable, setmetatable, error, io, type, pairs, rawget, rawset = tostring, getmetatable, setmetatable, error, io, type, pairs, rawget, rawset
local ipairs, debug, require, select = ipairs, debug, require, select
local type, print = type, print

local List = require 'lglib.list'

module('lglib.oop')


local Object
Object = {
	__tag = "Object";
	_parent = Object;

	-- init function must be overridden by each of its child class.
	-- inside init() function, doing declaration and assginment for each field
	init = nil;

	-- inheritation function, here 'self' is the parent class
	extend = function (self, tbl)
		local this = rawget(self, 'extend')
		assert(this and type(this) == 'function', "[ERROR] Only class can use extend method.")

		tbl._parent = self
		tbl.new = self.new
		tbl.extend = self.extend
		-- define the local a = Model(...) syntax 
		setmetatable(tbl, {__index=self; __call=function (self, ...) return self:new(...) end})

		return tbl
	end;

	--- instance creatation function, here 'self' is a class
	new = function (self, ...)
		local this = rawget(self, 'new')
		assert(this and type(this) == 'function', "[ERROR] Only class can use new method.")
		local obj = {}
		
		local magic_methods = {"__add";"__sub";"__mul";"__div";"__mod";"__pow";"__unm";"__concat";"__len";"__eq";"__lt";"__le";"__tostring"}
		
		-- make a copy of metatable of prototype (self)
		-- pls remember that this is just one-layer copy, mostly references
		local mt = table.copy(getmetatable(self) or {})
		-- for magic methods, a reference/index cache could accelarate callback processes
		-- once callback functions modified, the change can not propagate into the reference cache?? lost a little of flexibility 
		for _, v in ipairs(magic_methods) do
			local method = self[v]
			if method then
				rawset(mt, v, method)   
			end
		end
		-- pointing back to the prototype itself "self"
		mt.__index = self
		-- setting table and meta-table relationship
		setmetatable(obj, mt)
		-- check if the init() function exists. if not, reporting the error.
		assert(self.init, '[ERROR] Class must implement init() function while defined.')
		
		-- store the inherited chain
		local proto_chain = List()
		local p = self
		repeat
			proto_chain:append(p)
			-- go backward 
			p = p._parent
		-- stop unless back to primitive prototype, like Object or other root parent class
		-- it also means this oop structure is not single rooted??
		until p == Object or not p
		
		-- the inheritance relation is from bottom to top, child at head of list and parent at the tail
		-- for init process, it should run in the backward direction
		-- This feature makes every initial function in child class do its own new
		-- fields' initialization only.
		for i = #proto_chain, 1, -1 do
			-- adding fields one group by another
			-- non-last one should return self itself
			obj = proto_chain[i].init(obj, ...)
		end
		
		return obj
		
		-- simplified version. 
		-- return self.init(obj, ...)
	end
	clone = function (self)
		local new = table.copy(self)  --why not call table.deepCopy(self)??
		setmetatable(new, getmetatable(self))
		return new
	end;
	
	-- whether an instance or not
	isInstance = function (self)
		-- only 
		local this = rawget(self, 'new')
		if this and type(this) == 'function' then
			return false
		else
			return true
		end
	end;
	
	-- whether a class or not 
	isClass = function (self)
		local this = rawget(self, 'new')
		if this and type(this) == 'function' then
			return true
		else
			return false
		end
	end;
	
	-- only the class object exist
	singleton = function (self) return self end;
}

return Object
