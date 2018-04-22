package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Skill.ClientSkillType;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 单体攻击（普攻、物理单体、法术单体）
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_86 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Skill skill = context.skill();
		int skillTYpe = skill.getClientSkillType();
		if (skillTYpe == ClientSkillType.NormalAttack.ordinal() || skillTYpe == ClientSkillType.LongSingle.ordinal() || skillTYpe == ClientSkillType.ShortSingle.ordinal())
			return true;
		return false;
	}

}
