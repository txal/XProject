package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 本回合触发过的被动技能效果
 * 
 * @author yifan.chen
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_65 extends AbstractPassiveSkillLaunchCondition {
	/** 存在技能效果不触发 **/
	private Set<Integer> skipConfigIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		for (int configId : skipConfigIds) {
			if (soldier.roundPassiveEffects().containsKey(configId))
				return false;
		}
		return true;
	}

	public Set<Integer> getSkipConfigIds() {
		return skipConfigIds;
	}

	public void setSkipConfigIds(Set<Integer> skipConfigIds) {
		this.skipConfigIds = skipConfigIds;
	}

}
