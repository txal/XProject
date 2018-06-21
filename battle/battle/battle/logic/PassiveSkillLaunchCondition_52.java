package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用门派默认攻击技能
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_52 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		Skill fs = soldier.factionDefaultSkill();
		if (fs == null)
			return false;
		return context.skill().getId() == fs.getId();
	}

}
