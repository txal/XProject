/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_18;

/**
 * 物理/法术攻击情况下,反弹百分比伤害
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_18 extends BattleBuffLogicAdapter {
	
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_18();
	}
	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam_18 param = (BuffLogicParam_18) buffEntity.battleBuff().getBuffParam();
		if (param == null || commandContext.skill().getSkillAttackType() != param.getAttackType())
			return;
		BattleSoldier trigger = commandContext.trigger();
		int hp = commandContext.getDamageOutput();
		hp *= param.getPercent();
		trigger.decreaseHp(hp, commandContext.target());
		commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, hp, 0, false));
	}

}
