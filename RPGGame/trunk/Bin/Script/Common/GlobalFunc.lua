--全局函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
GF = GF or {}

--名字库随机名字
function GF.GenNameByPool()
	local nIndex = math.random(1, #ctRoleNamePoolConf)
	local tPoolConf = ctRoleNamePoolConf[nIndex]
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

--通过副本唯一ID取副本ID
--@nDupMixID: 副本唯一ID, 城镇:dupid 副本:autoid<<16|dupid
function GF.GetDupID(nDupMixID)
    assert(nDupMixID, "参数错误")
    return (nDupMixID & 0xFFFF)
end

--通过会话ID取网关服务ID
--@nSession: 会话ID
function GF.GetService(nSession)
    assert(nSession, "参数错误")
    return (nSession >> nSERVICE_SHIFT)
end

--随机坐标
--@nPosX, nPosY: 原点
--@nRad: 半径
function GF.RandPos(nPosX, nPosY, nRad)
    local nRndX = math.max(0, math.random(nPosX-nRad, nPosX+nRad))
    local nRndY = math.max(0, math.random(nPosY-nRad, nPosY+nRad))
    return nRndX, nRndY
end