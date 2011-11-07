local table, pairs, next, type, require, ipairs = table, pairs, next, type, require, ipairs
local tostring, debug, assert, error, setmetatable = tostring, debug, assert, error, setmetatable
local string = string
local math = math


------------------------------------------------------------------------
__typename = 'Table'

-- To use the lua-table more efficiently, we could divide lua-table into list-part and dictionary-part when necessary.
-- From the implementation perspective of view, lua-table is a combination of C-array and Hash-table coded in C language.
-- list-part---->array
-- dict-part---->hash table


-- two objects returned, List and Dict. 
-- takeAparts function only handle one layer, how about a multi-layer case?
function takeAparts(self)
	local list_len = #self
	local list_part, dict_part = {}, {}
	
	-- old implementation
	for i=1, list_len do
		table.insert(list_part, self[i])
	end
	
	for k, v in pairs(self) do
		if type(k) ~= 'number' or (type(k) == 'number' and k > list_len) then
			dict_part[k] = v
		end
	end
	
	-- new implementation
	--[[
	for k, v in pairs(self) do
	    if type(k)== 'number' and k%1 == 0 and k <= list_len and k > 0 then
	        table.insert(list_part, self[k])
	    else
	        dict_part[k] = v
	    end
	end
	--]]
	
	local List, Dict = require 'lglib.list', require 'lglib.dict'
	return List(list_part), Dict(dict_part)
end


function equal(self, another)
    -- old implementation
	for k, v in pairs(self) do
		if another[k] ~= v then return false end
	end

	for k, v in pairs(another) do
		if self[k] ~= v then return false end
	end 
    
    -- new implementation
    --[[
    if self.size ~= another.size then
        return false
    else
        for k, v in pairs(self) do
            if another[k] ~= v then return false end
        end
    end
    --]]
	return true
end


function copy(self)
	local res = {}
	for k, v in pairs(self) do
		res[k] = v
	end
	return res
end


function deepCopy(self, seen)
	local res = {}
	seen = seen or {}
	seen[self] = res
	for k, v in pairs(self) do
		if "table" == type(v) then
			if seen[v] then
				res[k] = seen[v]
			else
				res[k] = table.deepCopy(v, seen)
			end
		else
			res[k] = v
		end
	end
	seen[self] = nil
	return res
end


--[[
   Author: Julio Manuel Fernandez-Diaz
   Date:   January 12, 2007
   (For Lua 5.1)
   
   Modified slightly by RiciLake to avoid the unnecessary table traversal in tablecount()

   Formats tables with cycles recursively to any depth.
   The output is returned as a string.
   References to other tables are shown as values.
   Self references are indicated.

   The string returned is "Lua code", which can be procesed
   (in the case in which indent is composed by spaces or "--").
   Userdata and function keys and values are shown as strings,
   which logically are exactly not equivalent to the original code.

   This routine can serve for pretty formating tables with
   proper indentations, apart from printing them:

      print(table.show(t, "t"))   -- a typical use
   
   Heavily based on "Saving tables with cycles", PIL2, p. 113.

   Arguments:
      t is the table.
      name is the name of the table (optional)
      indent is a first indentation (optional).
--]]
function tree(t, name, indent)
   local cart     -- a container
   local autoref  -- for self references

   --[[ counts the number of elements in a table
   local function tablecount(t)
      local n = 0
      for _, _ in pairs(t) do n = n+1 end
      return n
   end
   ]]
   -- (RiciLake) returns true if the table is empty
   local function isemptytable(t) return next(t) == nil end

   local function basicSerialize (o)
      local so = tostring(o)
      if type(o) == "function" then
         local info = debug.getinfo(o, "S")
         -- info.name is nil because o is not a calling level
         if info.what == "C" then
            return string.format("%q", so .. ", C function")
         else 
            -- the information is defined through lines
            return string.format("%q", so .. ", defined in (" ..
                info.linedefined .. "-" .. info.lastlinedefined ..
                ")" .. info.source)
         end
      elseif type(o) == "number" or type(o) == "boolean" then
         return so
      else
         return string.format("%q", so)
      end
   end

   local function addtocart (value, name, indent, saved, field)
      indent = indent or ""
      saved = saved or {}
      field = field or name

      cart = cart .. indent .. field

      if type(value) ~= "table" then
         cart = cart .. " = " .. basicSerialize(value) .. ";\n"
      else
         if saved[value] then
            cart = cart .. " = {}; -- " .. saved[value] 
                        .. " (self reference)\n"
            autoref = autoref ..  name .. " = " .. saved[value] .. ";\n"
         else
            saved[value] = name
            --if tablecount(value) == 0 then
	    if isemptytable(value) then
            --if table.isEmpty(value) then
               cart = cart .. " = {};\n"
            else
               cart = cart .. " = {\n"
               for k, v in pairs(value) do
                  k = basicSerialize(k)
                  local fname = string.format("%s[%s]", name, k)
                  field = string.format("[%s]", k)
                  -- three spaces between levels
                  addtocart(v, fname, indent .. "     ", saved, field)
               end
               cart = cart .. indent .. "};\n"
            end
         end
      end
   end

   name = name or "TABLE_WANTED"
   if type(t) ~= "table" then
      return name .. " = " .. basicSerialize(t)
   end
   cart, autoref = "", ""
   addtocart(t, name, indent)

   return cart .. autoref
end


------------------------------------------------------------------------
-- update the specific key-values of self BY the source table
-- @param self      the table to be updated
-- @param source    source table
-- @param keys      specific keys to be updated; if keys is nil, update will be reduced to the copy function.
-- @return self     the updated table 
------------------------------------------------------------------------
function update(self, source, keys)
    if keys then 
        for _, key in ipairs(keys) do
            self[key] = source[key]
        end
    else
        for k,v in pairs(source) do
            self[k] = v
        end
    end

    return self
end

-- 要求传入的t1, t2必须为表格
-- dup为true表示并运算，为false表示差运算
-- dup=true for union operation, values of common keys from first table t1 will be repalced/covered by the later one t2.
-- it also means, some info will disappear anyway.
-- dup=false for intersection, values of res are those of the later one t2. Be careful when using it!
function merge (t1, t2, dup)
    local res = {}
    for k,v in pairs(t1) do
        if dup or t2[k] then res[k] = v end
    end
    for k,v in pairs(t2) do
        if dup or t1[k] then res[k] = v end
    end
    return res
end

-- 要求传入的t1, t2必须为表格
-- symm为true表示求共有部分，symm为false表示异或运算
-- both A and B are lua-table
-- symm=true for symmetric difference AUB-AnB = (A-B)U(B-A), while symm=false for complement(anti-symmetric difference) A-B
function difference (s1, s2, symm)
    local res = {}
    for k,v in pairs(s1) do
        if not s2[k] then res[k] = v end
    end
    if symm then
        for k,v in pairs(s2) do
            if not s1[k] then res[k] = v end
        end
    end
    return res
end

function isEmpty(self)
    return nil == next(self)
end


