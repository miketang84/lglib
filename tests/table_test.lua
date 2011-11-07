require 'lglib'

ptable(table)

List = require 'lglib.list'
Dict = require 'lglib.dict'

t = T {
	'a', 'b', 'c', 'd', 'e', 'f',
		x = 'xxxxxx',
	y = '34343434',
	z = 'zcvcvc',
	g = '4444444',
	h = '34343aaa',
	
}
ptable(getmetatable(t))

a, b = table.takeAparts(t)

ptable(t)
ptable(a)
ptable(b)
print(typename(a))
print(typename(b))
print(isList(a))
print(isDict(b))

c, d = t:takeAparts()
ptable(c)
ptable(d)

--testing the deep copy
atable = {1, 2, 3, one = 1, two = 2, {three = 3, four = 4, {five = 5, six = 6}}}
fptable(atable)
anothertable = table.deepcopy(atable)

fptable(anothertable)

t1 = {one = 1, two = 2, three = 3, four = 4, five = 5}
t2 = {zero = 0, three = 43, five = 55, seven = 7, eight = 8}
ptable(t1)
ptable(t2)

-- testing the union, intersection, difference/complement, symmetric difference operations
union = table.merge(t1, t2, true)
ptable(union)

inter = table.merge(t1, t2, false)
ptable(inter)

symmdiff = table.difference(t1, t2, true)
ptable(symmdiff)

antisymmdiff = table.difference(t1, t2, false)
ptable(antisymmdiff)

-- testing the takeAparts again
tt = {1, 2, 3, 4, one = 1, two = 2}
tt[0]=0
tt[-3] = -3
tt[1.23] = 1.23
fptable(tt)
list, dict = table.takeAparts(tt)
fptable(list)
fptable(dict)
