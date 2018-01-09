local function _GVGMatchConfCheck()
	local nCount = 0
	for k, v in pairs(ctGVGMatchConf) do
		nCount = nCount + 1
	end
	assert(#ctGVGMatchConf == nCount, "gvgmatchconf.xml 编号必须连续")
end
_GVGMatchConfCheck()

local nLastMulti, bLastWin
local function _GenWeightInfo(nMulti, bWin)
	if nLastMulti == nMulti and bLastWin == bWin then
		return
	end
	nLastMulti, bLastWin = nMulti, bWin

	local sAddField = bWin and "nWinAdd" or "nLoseAdd"
	local nPreWeight, nTotalWeight = 0, 0
	for k, v in ipairs(ctGVGMatchConf) do
		local nWeight = v.nBaseWeight + v[sAddField] * nMulti

		v.nMinWeight = nPreWeight + 1
		v.nMaxWeight = v.nMinWeight + nWeight - 1
		nPreWeight = v.nMaxWeight	
		nTotalWeight = nTotalWeight + nWeight
	end
	ctGVGMatchConf.nTotalWeight = nTotalWeight
end

--连胜连败声望浮动值
function GetGVGMatchFameAdd(nWins, nLoses)
	assert(nWins and nLoses)
	if nWins >= 3 then
		_GenWeightInfo(nWins-2, true)

	elseif nLoses >= 3 then
		_GenWeightInfo(nLoses-2, false)

	else
		_GenWeightInfo(0, false)

	end
	local nRnd = math.random(1, ctGVGMatchConf.nTotalWeight)
	for k, v in ipairs(ctGVGMatchConf) do
		if nRnd >= v.nMinWeight and nRnd <= v.nMaxWeight then
			return v.nFameAdd
		end
	end
	return 0
end
