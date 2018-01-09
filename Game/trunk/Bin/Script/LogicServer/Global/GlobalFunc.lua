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

--检测名字长度
function GF.CheckNameLen(sName, nMaxLen)
	assert(string.len(sName) <= nMaxLen, "名字过长:"..sName)
end