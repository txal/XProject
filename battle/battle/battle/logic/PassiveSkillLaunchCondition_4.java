package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 技能互斥:1目标存在指定技能则无法触发;2己方有特定技能则忽略规则1
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_4 extends AbstractPassiveSkillLaunchCondition {
	/**
	 * 目标存在这些技能则无法触发
	 */
	private Set<Integer> skillIds;
	/**
	 * 己方如果存在这些技能则突破目标技能限制
	 */
	private Set<Integer> ignoreSkillIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (target == null)
			return false;
		// 如果触发者有符合的技能,则忽略后面的规则,可以触发
		if (this.ignoreSkillIds != null && !this.ignoreSkillIds.isEmpty()) {
			for (int skillId : this.ignoreSkillIds) {
				if (soldier.skillHolder().passiveSkill(skillId) != null)
					return true;
			}
		}
		if (this.skillIds != null) {
			for (Integer skillId : skillIds) {
				Skill skill = target.skillHolder().passiveSkill(skillId);
				if (skill != null)
					return false;
			}
		}
		return true;
	}

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

	public Set<Integer> getIgnoreSkillIds() {
		return ignoreSkillIds;
	}

	public void setIgnoreSkillIds(Set<Integer> ignoreSkillIds) {
		this.ignoreSkillIds = ignoreSkillIds;
	}

}
