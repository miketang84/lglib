local string = string

module(..., package.seeall)

------------------------------------------------------------------------
-- 简单的HTML转义
-- @param 
-- @return
------------------------------------------------------------------------
function escapeHTML(s)
    checkType(s, 'string')
    local esced, i = s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;')
    return esced
end

------------------------------------------------------------------------
-- 简单的URL解码，能处理带+号的情况（替换为空白符）
-- @param 
-- @return
------------------------------------------------------------------------
-- Simplistic URL decoding that can handle + space encoding too.
function decodeURL(url)
	checkType(url, 'string')
    return url:gsub("%+", ' '):gsub('%%(%x%x)', function (s)
        return string.char(tonumber(s, 16))
    end)
end

------------------------------------------------------------------------
-- 简单的URL编码
-- @param 
-- @return
------------------------------------------------------------------------
function encodeURL(url)
	checkType(url, 'string')
    return url:gsub("\n","\r\n"):gsub("([^%w%-%.])", 
        function (c) return ("%%%02X"):format(string.byte(c)) 
    end)
end

------------------------------------------------------------------------
-- 解析URL带的参数
-- @param 
-- @return
------------------------------------------------------------------------
function parseURL(url, sep)
	if not url then return {} end
    local result = {}
    sep = sep or '&'
    url = ('%s%s'):format(url, sep)

    for piece in url:gmatch(("(.-)%s"):format(sep)) do
        local k,v = piece:match("%s*(.-)%s*=(.*)")

        if k then
			k = decodeURL(k)
			if k:endsWith('[]') then
				k = k:sub(1, -3)
				if not result[k] then result[k] = {} end
				-- table.insert(result[k], decodeURL(v))
				result[k][#result[k] + 1] = decodeURL(v)
				ptable(result[k])
			else
				result[k] = decodeURL(v)
			end
        else
            result[#result + 1] = decodeURL(piece)
        end
    end

    return result
end

