package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_11;
import com.nucleus.logic.core.modules.player.data.Props;

/**
 * 禁药,逻辑id属于指定范围且不在排除列表的道具禁用
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_11 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_11();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> properties = SplitUtils.split2StringMap(params, ",", ":");
		BuffLogicParam_11 param = (BuffLogicParam_11) buff.getBuffParam();
		param.setAntiLogicIds((SplitUtils.split2IntSet(properties.get("antiLogicIds"), "\\|")));
		param.setExcludeItemIds((SplitUtils.split2IntSet(properties.get("excludeItemIds"), "\\|")));
	}

	@Override
	public boolean antiItem(BuffLogicParam logicParam, int itemId) {
		if (logicParam == null || !(logicParam instanceof BuffLogicParam_11) || itemId <= 0)
			return false;
		BuffLogicParam_11 param = (BuffLogicParam_11) logicParam;
		Props prop = Props.get(itemId);
		return param.getAntiLogicIds().contains(prop.getLogicId()) && !param.getExcludeItemIds().contains(itemId);
	}
}
