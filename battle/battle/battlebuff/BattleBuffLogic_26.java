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
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_5;

/**
 * 伤害分担
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_26 extends BattleBuffLogicAdapter {
	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_5();
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
		int damage = commandContext.getDamageOutput();
		if (damage < 0) {
			BuffLogicParam_5 param = (BuffLogicParam_5) buffEntity.battleBuff().getBuffParam();
			int absDamage = Math.abs(damage);
			int bearDamage = (int) Math.floor(absDamage * param.getRate());
			int shareDamage = absDamage - bearDamage;

			BattleSoldier trigger = buffEntity.getTriggerSoldier();
			if (!trigger.isDead()) {
				trigger.decreaseHp(-shareDamage);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, -shareDamage, 0, false));
				commandContext.setDamageOutput(-bearDamage);
			}
		}
	}
}
