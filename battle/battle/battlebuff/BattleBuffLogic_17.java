/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_5;

/**
 * 有机率攻击buff施放者
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_17 extends BattleBuffLogicAdapter {
	@Autowired
	private BattleBuffLogic_14 proxy;
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_5();
	}
	
	@Override
	public void onActionStart(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (!commandContext.skill().ifHpLossFunction())
			return;
		BuffLogicParam_5 param = (BuffLogicParam_5) buffEntity.battleBuff().getBuffParam();
		boolean success = RandomUtils.baseRandomHit(param.getRate());
		if (success)
			proxy.onActionStart(commandContext, buffEntity);
	}

}
