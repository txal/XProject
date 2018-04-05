package com.nucleus.logic.core.modules.battle.logic;

import java.util.Collection;
import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 己方有指定任一buff类型或者任一指定buff就能触发
 *
 * @author zhanhua.xu
 */
@GenIgnored
public class PassiveSkillLaunchCondition_43 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> buffTypes;
	private Set<Integer> buffIds;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Collection<BattleBuffEntity> allBuffs = soldier.buffHolder().allBuffs().values();
		for (int buffType : buffTypes) {
			for (BattleBuffEntity buffEntity : allBuffs) {
				if (buffEntity.battleBuffType() == buffType)
					return true;
			}
		}
		for (int buffId : buffIds) {
			for (BattleBuffEntity buffEntity : allBuffs) {
				if (buffEntity.battleBuffId() == buffId)
					return true;
			}
		}
		return false;
	}

	public Set<Integer> getBuffTypes() {
		return buffTypes;
	}

	public void setBuffTypes(Set<Integer> buffTypes) {
		this.buffTypes = buffTypes;
	}

	public Set<Integer> getBuffIds() {
		return buffIds;
	}

	public void setBuffIds(Set<Integer> buffIds) {
		this.buffIds = buffIds;
	}

}
