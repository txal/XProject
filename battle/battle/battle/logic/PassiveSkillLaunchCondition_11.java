package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Monster.MonsterType;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * boss和玩家无效
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_11 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (target == null)
			return false;
		if (target.ifMainCharactor())
			return false;
		if (target.getMonsterType() == MonsterType.Boss.ordinal())
			return false;
		return true;
	}

}
