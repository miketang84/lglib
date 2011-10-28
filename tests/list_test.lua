require 'lglib'

List = require 'lglib.list'

a = List { 1,2,3,4,5,6,7, x=123, y="343434"}
ptable(a)

ptable(List.range(10))
ptable(List.range(10, 20))

print('test a:insert(100) insert is function in table')
a:insert(140)
ptable(a)
