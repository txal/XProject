package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;

/**
 * 装备特效：4009产生buff,该buff对鬼魂生物无效
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_8 extends BattleBuffLogicAdapter {
	@Override
	public boolean propertyEffectable(CommandContext commandContext, BattleBasePropertyType propertyType) {
		BattleSoldier target = commandContext.target();
		if (target == null || target.isGhost())
			return false;
		return true;
	}
}
