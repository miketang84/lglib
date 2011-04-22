local table = table
local loadstring, assert = loadstring, assert
local tostring, getmetatable, setmetatable, error, io, debug, type, pairs, rawget, rawset = tostring, getmetatable, setmetatable, error, io, debug, type, pairs, rawget, rawset
local ipairs, debug, require, select = ipairs, debug, require, select

module('lglib.oop')

local abstractMethod = function () error(("Method must be implemented first.\n%s"):format(debug.traceback())) end


local Object
Object = {
	__tag = "Object";
	_parent = Object;
	-- 每个类的定义的时候，都必须定义这个init方法。它有两个功能：
	-- 1. 在这个方法里面，进行类的属性的定义；
	-- 2. 在这个方法里面，对类的属性进行初始化；
	-- 在使用的时候，要求此函数一般要返回self（对象实例本身）。
	init = abstractMethod;
	-- 类扩展/继承，这里这个self指的是父类本身
	extend = function (self, tbl)
		-- 在子类中记录父类信息，私有属性
		tbl._parent = self
		-- 在子类中，会自动引用实例创建函数new以及__index, __call
		setmetatable(tbl, {new=self.new; __index=self; __call=function (self, ...) return self:new(...) end})
		return tbl
	end;
	-- 这里，这个self参数，表示原型本身
	-- 一般在其它的子类中不用再实现new函数，而只需实现init函数即可
	new = function (self, ...)
		local obj = {new=self.maskedMethod; extend=self.maskedMethod; _parent=self}
		
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
		if not self.init then
			error('Class must implement init() function while defined.')
		end
		
		-- 存储继承链关系
		local proto_chain = {}
		local p = self
		repeat
			table.append(proto_chain, p)
			-- 往上回溯，找到所有类的继承链
			p = p._parent
		-- 当回溯到Object这个原始原型的时候，就停止
		until p == Object
		
		-- 由于继承类型是从下向上回溯的，子类放在链表前端，父类放在后端，
		-- 在执行初始化的时候，是从上向下依次执行init，所以要反向执行
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
	-- 这个函数，可以判断一个对象是不是某一个类的实例，或某一个类单例是不是某个类单例
	isInstance = function (self, class)
		if class then
			local parent = self._parent
			return self == class or (parent and parent:isInstance(class))
		else
			-- 如果获取到了，就是类
			if rawget(self, '__tag') then
				return false
			else
				return true
			end
		end
	end;
	isClass = function (self)
		local tag = rawget(self, '__tag')
		if tag then
			return true
		else
			return false
		end
	end;
	-- 返回父类引用
	parent = function (self) return self._parent end;
	abstractMethod = abstractMethod;
	maskedMethod = function () error(("Masked method "):format(debug.traceback())) end;
	-- 用于构建类单例，类即对象，对象即类，只有一个
	singleton = function (self) return self end;
}

return Object
