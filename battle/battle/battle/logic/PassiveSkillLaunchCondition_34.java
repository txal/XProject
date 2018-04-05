package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BuffClassTypeEnum;

/**
 * 使用封印技能
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_34 extends AbstractPassiveSkillLaunchCondition {

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		for (int buffId : context.skill().targetBattleBuffIds()) {
			BattleBuff buff = BattleBuff.get(buffId);
			if (buff == null)
				continue;
			if (buff.getBuffClassType() == BuffClassTypeEnum.Ban.ordinal())
				return true;
		}
		return false;
	}

}
