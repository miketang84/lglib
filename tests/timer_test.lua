require 'lglib'
require 'posix'
local socket = require "socket"

context("Test lglib", function ()

    context("Test Timer -- timer.lua", function ()
	local timer = require 'lglib.timer'
	test("timeout", function ()
	    local ret, err = pcall(timer.timeout, 2,  function (n) posix.sleep(n) end, 1)
	    assert_equal(ret, true)
	    local ret, err = pcall(timer.timeout, 2,  function (n) posix.sleep(n) end, 10)
	    assert_equal(ret, true)
		
	end)
	test("timer", function ()
	    local ret, err = timer.timer (2,  function () print('in timer') end)
	    posix.sleep(10)
	    --assert_equal(ret, true)
		
	end)
	
    end)
    
end)
