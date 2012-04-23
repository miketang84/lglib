require 'lglib'
require 'posix'
local socket = require "socket"

local timer = require 'lglib.timer'
timer.timer (3,  function () print('in timer', os.time()) end)

while true do
    a = 1 + 1
    posix.sleep(1)
end

    --posix.sleep(20)
		
