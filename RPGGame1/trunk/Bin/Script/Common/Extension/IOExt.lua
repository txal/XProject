--文件是否存在
function io.FileExist(filename)
    local file = io.open(filename, "r") 
    if file then
        file:close()
    end
    return (file and true or false)
end

--写文件
--@mode "w","a"
function io.FilePutContent(filename, content, mode)
	mode = mode or "w"
	local file, err = io.open(filename, mode)
	if not file then
		return print(err)
	end
	file:write(content)
	file:close()
end