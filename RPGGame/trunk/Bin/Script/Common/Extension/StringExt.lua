--Add slashes
function string.AddSlashes(sVal)
	local sRet = string.gsub(sVal, "['\"\\]", "\\%1")
	sRet = string.gsub(sRet, "\0", "\\0")
	return sRet 
end

--Strip slashes
function string.StripSlashes(sVal)
	local sRet = string.gsub(sVal, "\\0", "\0")
	sRet = string.gsub(sRet, "\\\\", "\\")
	sRet = string.gsub(sRet, "\\\'", "\'")
	sRet = string.gsub(sRet, "\\\"", "\"")
	return sRet 
end

--Format sql cmd
function string.SqlFormat(...)
	arg = table.pack(...)
	local tar = arg[1] or ""
	local f, j, atype = 0, 2, ""
	while true do
		_, f = string.find(tar, "%%", f+1)
		if not f then break end
		local c = string.sub(tar, f+1, f+1)
		if c == "s" then
			atype = type(arg[j])
			if atype ~= "string" then
				return error("param '#" .. j  .. "' string excepted, got " .. atype, 2)
			end
			arg[j] = string.AddSlashes(arg[j])
		elseif c == "d" then
			atype = type(arg[j])
			if atype ~= "number" then
				return error("param '#" .. j  .. "' number excepted, got " .. atype, 2)
			end
		else 
			return error("not support '%" .. c .. "*' format", 2)
		end
		j = j + 1
		f = f + 1
	end
	return string.format(table.unpack(arg))
end

--String split
function string.Split(szFullString, szSeparator)
	local nFindStartIndex = 1 
	local nSplitIndex = 1 
	local nSplitArray = {}
	while true do
		local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)
		if not nFindLastIndex then
			nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))
			break
		end 
		nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)
		nFindStartIndex = nFindLastIndex + string.len(szSeparator)
		nSplitIndex = nSplitIndex + 1 
	end 
	return nSplitArray
end

--Get string len(include chinese)
function string.UTF8Len(sVal)
	local nLen1, nLen2 = 0, 0
	local i, nSize = 1, #sVal
	while (i <= nSize) do
		local c = string.byte(sVal, i)
		if c >= 0x01 and c <= 0x7f then
			i = i + 1
			nLen1 = nLen1 + 1
		elseif c >= 0xc2 and c <= 0xdf then
			i = i + 2
			nLen2 = nLen2 + 1
		elseif c == 0xe0 then
			i = i + 3
			nLen2 = nLen2 + 1
		elseif c>=0xe1 and c<=0xef then
			i = i + 3
			nLen2 = nLen2 + 1
		elseif c == 0xF0 then
			i = i + 4
			nLen2 = nLen2 + 1
		elseif c >= 0xf1 and c <= 0xf7 then
			i = i + 4
			nLen2 = nLen2 + 1
		else
			return -1
		end
	end
	return nLen1 + nLen2
end

--Get word set(include chinese) 
function string.UTF8Words(sVal)
	local tList = {}
	local i, nSize = 1, #sVal
	while (i <= nSize) do
		local c = string.byte(sVal, i)
		if c >= 0x01 and c <= 0x7f then
			table.insert(tList, string.sub(sVal, i, i)) 
				i = i + 1 
		elseif c >= 0xc2 and c <= 0xdf then
			table.insert(tList, string.sub(sVal, i, i+1)) 
			i = i + 2 
		elseif c == 0xe0 then
			table.insert(tList, string.sub(sVal, i, i+2)) 
			i = i + 3 
		elseif c >= 0xe1 and c <= 0xef then
			table.insert(tList, string.sub(sVal, i, i+2)) 
			i = i + 3 
		elseif c == 0xF0 then
			table.insert(tList, string.sub(sVal, i, i+3)) 
			i = i + 4 
		elseif c >= 0xf1 and c <= 0xf7 then
			table.insert(tList, string.sub(sVal, i, i+3)) 
			i = i + 4 
		else
			return
		end 
	end 
	return tList
end

function string.Trim(sVal)
  r = "%s+"
  return (sVal:gsub ("^" .. r, ""):gsub (r .. "$", ""))
end
