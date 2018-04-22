package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 47使用群伤规则技能
 * 
 * @author zhanhua.xu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_47 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		final Skill skill;
		return context != null && (skill = context.skill()) != null && skill.isUseSkillMassRule();
	}
}
