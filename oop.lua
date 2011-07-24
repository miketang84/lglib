local table = table
local loadstring, assert = loadstring, assert
local tostring, getmetatable, setmetatable, error, io, debug, type, pairs, rawget, rawset = tostring, getmetatable, setmetatable, error, io, debug, type, pairs, rawget, rawset
local ipairs, debug, require, select = ipairs, debug, require, select
local type, print = type, print

local List = require 'lglib.list'

module('lglib.oop')


local Object
Object = {
	__tag = "Object";
	_parent = Object;

	--- init function must be override by every child class.
	-- in init function, do really field creataton and assgined
	init = nil;

	--- inheritation function, here 'self' is the parent class
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
		-- 获得原型的元表，并复制一份
		local mt = table.copy(getmetatable(self) or {})
		-- 创建实例对象的时候，把原型的特殊方法定义复制过来（函数代码保持同一份，但多了一个引用）
		-- 这一段可以提高效率，但同时也丧失了部分动态灵活性
		for _, v in ipairs(magic_methods) do
			local method = self[v]
			if method then
				rawset(mt, v, method)
			end
		end
		-- 回溯路径指向原型本身
		mt.__index = self
		-- 设定原型关系
		setmetatable(obj, mt)
		-- 检查是否有初始化函数，没有就报错。
		assert(self.init, '[ERROR] Class must implement init() function while defined.')
		
		-- 存储继承链关系
		local proto_chain = List()
		local p = self
		repeat
			proto_chain:append(p)
			-- 往上回溯，找到所有类的继承链
			p = p._parent
		-- 当回溯到Object这个原始原型的时候，就停止
		until p == Object or not p
		
		-- 由于继承类型是从下向上回溯的，子类放在链表前端，父类放在后端，
		-- 在执行初始化的时候，是从上向下依次执行init，所以要反向执行
		-- This feature makes every initial function in child class do its own new
		-- fields' initialization only.
		for i = #proto_chain, 1, -1 do
			-- 不断对新生成的obj对象进行初始化操作，可依次添加属性
			-- 要求，非末端初始化函数返回值必须是self本身，不能是其它值
			obj = proto_chain[i].init(obj, ...)
		end
		
		return obj
		
		-- 这是上面的简化版：用最近一级原型的init方法以及传入的参数，来初始化这个实例对象
		-- 并返回新对象
		-- return self.init(obj, ...)
	end;
	
	clone = function (self)
		local new = table.copy(self)
		setmetatable(new, getmetatable(self))
		return new
	end;
	
	-- 这个函数，可以判断一个对象是不是实例
	isInstance = function (self)
		-- 如果获取到了，就是类
		local this = rawget(self, 'new')
		if this and type(this) == 'function' then
			return false
		else
			return true
		end
	end;

	isClass = function (self)
		local this = rawget(self, 'new')
		if this and type(this) == 'function' then
			return true
		else
			return false
		end
	end;

	singleton = function (self) return self end;
}

return Object
