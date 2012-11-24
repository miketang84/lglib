module(..., package.seeall)

function normalize(path)
	local path = path:gsub('//+', '/')
	if path:sub(-1) ~= '/' and not path:find('.', 1, true) then
		path = ('%s/'):format(path)
	end
	
	return path
end
