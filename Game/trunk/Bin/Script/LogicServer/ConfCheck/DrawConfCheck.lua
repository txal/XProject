local function _DrawConfCheck()
	local nCount = 0
	for nPos, tConf in pairs(ctDiamondDraw) do
		assert(#tConf.tItem == 1, "diamonddraw.xml只能配一个物品")
		local tItem = tConf.tItem[1]
		if tItem[1] == gtObjType.eArm then
			assert(ctArmConf[tItem[2]], "diamonddraw.xml位置:"..nPos.."装备:"..tItem[2].."找不到")
		elseif tItem[1] == gtObjType.eProp then
			assert(ctPropConf[tItem[2]], "diamonddraw.xml位置:"..nPos.."道具:"..tItem[2].."找不到")
		elseif tItem[1] == gtObjType.eWSProp then
			assert(ctWSPropConf[tItem[2]], "diamonddraw.xml位置:"..nPos.."工坊道具:"..tItem[2].."找不到")
		else
			assert(false, "diamonddraw.xml位置:"..nPos.."物品类型错误")
		end
		nCount = nCount + 1
	end
	assert(nCount == #ctDiamondDraw, "diamonddraw.xml位置不连续")
end
_DrawConfCheck()
