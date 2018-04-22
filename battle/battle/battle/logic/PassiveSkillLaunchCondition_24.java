package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 敌方指定目标死亡
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_24 extends AbstractPassiveSkillLaunchCondition {
	private int monsterId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (monsterId <= 0)
			return false;
		for (BattleSoldier s : soldier.team().getEnemyTeam().allSoldiersMap().values()) {
			if (s.monsterId() == monsterId && s.isDead())
				return true;
		}
		return false;
	}

	public int getMonsterId() {
		return monsterId;
	}

	public void setMonsterId(int monsterId) {
		this.monsterId = monsterId;
	}

}
