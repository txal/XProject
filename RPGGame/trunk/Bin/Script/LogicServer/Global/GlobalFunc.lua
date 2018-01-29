GF = {}

--名字库随机名字
function GF.GenNameByPool()
	local nIndex = math.random(1, #ctPlayerNamePoolConf)
	local tPoolConf = ctPlayerNamePoolConf[nIndex]
	local nRndXing = math.random(1, #tPoolConf.tXing)
	local nRndMing = math.random(1, #tPoolConf.tMing)
	local sXing = tPoolConf.tXing[nRndXing][1]
	local sMing = tPoolConf.tMing[nRndMing][1]
	return (sXing..sMing)
end

--检测长度
function GF.CheckNameLen(sName, nMaxLen)
	assert(string.len(sName) <= nMaxLen, "长度超出范围:"..nMaxLen)
end

--检测非法字不区分大小写
function GF.HasBadWord(sCont)
	local sLowerCont = string.lower(sCont)
    if GlobalExport.HasWord(sLowerCont) then
    	return true
    end
end

--过滤非法字不区分大小写
function GF.FilterBadWord(sCont)
	local sLowerCont = string.lower(sCont)
    if GlobalExport.HasWord(sLowerCont) then
    	return GlobalExport.ReplaceWord(sLowerCont, "*")
    else
    	return sCont
    end
end