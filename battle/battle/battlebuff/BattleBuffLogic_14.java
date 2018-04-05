/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 嘲讽，攻击buff释放者
 * 
 * @author xitao.huang
 *
 */
@Service
public class BattleBuffLogic_14 extends BattleBuffLogicAdapter {

	@Override
	public void onActionStart(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BattleSoldier target = buffEntity.getTriggerSoldier();
		if (target != null && !commandContext.getTargetIds().contains(target.getId()))
			commandContext.populateTarget(target);
	}

}
