local table, io = table, io
local assert = assert


-- 辅助函数，将一个文件加载到内存
-- @param from_dir
-- @param name
-- @return content 字符串
function loadFile(from_dir, name)
    local fd = assert(io.open(('%s/%s'):format(from_dir, name), 'r'))
    local content = fd:read('*a')
    fd:close()

    return content
end

-- Loads a source file, but converts it with line numbering only showing
-- from firstline to lastline.
function loadLines(source, firstline, lastline)
    local f = io.open(source)
    local lines = {}
    local i = 0

    -- TODO: this seems kind of dumb, probably a better way to do this
    for line in f:lines() do
        i = i + 1

        if i >= firstline and i <= lastline then
            lines[#lines+1] = ("%0.4d: %s"):format(i, line)
        end
    end

    return table.concat(lines,'\n')
end
