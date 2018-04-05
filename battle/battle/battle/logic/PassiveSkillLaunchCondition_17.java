package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 符合指定类型的buff
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_17 extends AbstractPassiveSkillLaunchCondition {
	private Set<Integer> buffTypes;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (buffTypes != null && !buffTypes.isEmpty()) {
			if (context != null && context.getTargetBuff() != null) {
				BattleBuffEntity buff = context.getTargetBuff();
				boolean ok = false;
				for (int buffType : this.buffTypes) {
					if (buff.battleBuffType() == buffType) {
						ok = true;
						break;
					}
				}
				return ok;
			}
		}
		return true;
	}

	public Set<Integer> getBuffTypes() {
		return buffTypes;
	}

	public void setBuffTypes(Set<Integer> buffTypes) {
		this.buffTypes = buffTypes;
	}

}
