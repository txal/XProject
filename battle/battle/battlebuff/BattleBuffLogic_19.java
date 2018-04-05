/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 有此buff的目标可以攻击到敌方隐身单位
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class BattleBuffLogic_19 extends BattleBuffLogicAdapter {
	@Override
	public void beforeAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (commandContext != null)
			commandContext.setHiddenFail(true);
	}
}
