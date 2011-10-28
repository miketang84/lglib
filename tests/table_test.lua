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
