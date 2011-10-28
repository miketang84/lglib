require 'lglib'

Set = require 'lglib.set'

s1 = Set { 'a', 'b', 'c', 'd', 'e', 'f' }
s2 = Set { 'a', 'g', 'h', '0oo', 'e', 'f' }
s3 = Set { 'a', 'c', 'd'}

ptable(s1)

ptable(s1+s2)
ptable(s1-s2)
ptable(s1*s2)
ptable(s1^s2)
print(s3 < s1)
print(s2 < s1)

print(s1)
s2:add('123')
s2:add('456')
ptable(s2)
