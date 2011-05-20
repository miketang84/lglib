require 'lglib'

Dict = require 'lglib.dict'

a = Dict {
	x = 'xxxxxx',
	y = '34343434',
	z = 'zcvcvc',
	g = '4444444',
	h = '34343aaa',

}

ptable(a:keys())
ptable(a:values())
print(a:hasKey('x'))
print(a:hasKey('xx'))
print(a:isEmpty())
