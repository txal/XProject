package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_7;

/**
 * buff抗性
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_7 extends BattleBuffLogicAdapter {
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_7();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> properties = SplitUtils.split2StringMap(params, ",", ":");
		BuffLogicParam_7 param = (BuffLogicParam_7) buff.getBuffParam();
		param.setBuffIds(SplitUtils.split2IntSet(properties.get("buffIds"), "\\|"));
		param.setBuffTypes(SplitUtils.split2IntSet(properties.get("buffTypes"), "\\|"));
	}

	@Override
	public void antiBuff(CommandContext commandContext, BuffLogicParam logicParam) {
		BuffLogicParam_7 param = (BuffLogicParam_7) logicParam;
		for (int buffId : commandContext.skill().targetBattleBuffIds()) {
			BattleBuff buff = BattleBuff.get(buffId);
			if (buff == null)
				continue;
			if (param.getBuffIds().contains(buffId) || param.getBuffTypes().contains(buff.getBuffType())) {
				commandContext.setAntiBuff(true);
				return;
			}
		}
		commandContext.setAntiBuff(false);
	}
}
