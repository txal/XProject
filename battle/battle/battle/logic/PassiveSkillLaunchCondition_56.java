package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.MountActiveSkill;
import com.nucleus.logic.core.modules.battle.data.PlayerActiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.TalentActiveSkill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 使用加血治疗技能(不包括特技)
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_56 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		final Skill skill;
		return context != null && (skill = context.skill()) != null && skill.ifHpIncreaseFunction()
				&& (skill instanceof PlayerActiveSkill || skill instanceof MountActiveSkill || skill instanceof TalentActiveSkill);
	}
}
