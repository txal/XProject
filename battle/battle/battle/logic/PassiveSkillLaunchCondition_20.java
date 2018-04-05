package com.nucleus.logic.core.modules.battle.logic;

import java.util.function.Predicate;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 己方被封单位大于等于指定数量(自身除外)
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_20 extends AbstractPassiveSkillLaunchCondition {
	private int bannedCount;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		Predicate<BattleSoldier> predicate = s -> s.getId() != soldier.getId() && s.buffHolder().hasBanBuff();
		long count = soldier.battleTeam().soldiersMap().values().stream().filter(predicate).count();
		return count >= bannedCount;
	}

	public int getBannedCount() {
		return bannedCount;
	}

	public void setBannedCount(int bannedCount) {
		this.bannedCount = bannedCount;
	}

}
