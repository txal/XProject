package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 伤害反震
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_4 extends BattleBuffLogicAdapter {
	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BattleSoldier trigger = commandContext.trigger();
		int hp = commandContext.getDamageOutput();
		trigger.decreaseHp(hp, commandContext.target());
		commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, hp, 0, false));
	}
}
