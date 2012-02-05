module(..., package.seeall)

function trailingPath(path)
	local path = path:gsub('//+', '/')
	if path:sub(-1) ~= '/' then
		path = ('%s/'):format(path)
	end
	
	return path
end
