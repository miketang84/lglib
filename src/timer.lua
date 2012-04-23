module(..., package.seeall)

require "alarm"

-- t	timeout seconds
-- f	callback of timeout
-- ... 	callback args
function timeout (t, f, ...)
    alarm (t, function () error("timeout!") end )
    pcall (f, ...)
    alarm ()
end

-- t	interval seconds
-- f	callback of timer
-- ... 	callback args
function timer (t, f, ...)
    alarm (t, function (...) alarm(t); pcall(f, ...); end)
end

