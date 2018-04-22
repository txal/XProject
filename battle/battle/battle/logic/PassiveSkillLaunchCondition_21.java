package com.nucleus.logic.core.modules.battle.logic;

import java.util.Collection;
import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 目标存在指定buff则技能无法触发
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_21 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> buffIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Collection<BattleBuffEntity> allBuffs = target.buffHolder().allBuffs().values();
		for (BattleBuffEntity buff : allBuffs) {
			if (buffIds.contains(buff.battleBuffId()))
				return false;
		}
		return true;
	}

	public Set<Integer> getBuffIds() {
		return buffIds;
	}

	public void setBuffIds(Set<Integer> buffIds) {
		this.buffIds = buffIds;
	}

}
