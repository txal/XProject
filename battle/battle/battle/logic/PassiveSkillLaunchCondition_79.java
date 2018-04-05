package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 魔法系攻击次数取模
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_79 extends AbstractPassiveSkillLaunchCondition {

	private int value;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		int magicAttack = soldier.getMagicAttackTimes();
		if (context.skill().ifMagicAttack()) {
			return (magicAttack + 1) % value == 0;
		} else {
			if (magicAttack != 0) {
				return magicAttack % value == 0;
			}
		}
		return false;
	}

	public int getValue() {
		return value;
	}

	public void setValue(int value) {
		this.value = value;
	}

}
