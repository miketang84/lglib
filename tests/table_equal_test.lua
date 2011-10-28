require 'lglib'

context('lglib', function ()
					 context('table', function ()
										  test('equal', function ()
															local a = {2, 3, 5, x = 12, y = '12', z = "xvvv"}
															local b = {2, 3, 5, x = 12, y = '12', z = "xvvv"}
															local c =  {2, 4, 5, x = 12, y = '12', z = "vvvv"}

															assert_true(table.equal(a, b))
															assert_false(table.equal(b, c))
															assert_false(table.equal(a, c))
															
														end) 
									  end) 

			 end)
