package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 是否有宠物
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_78 extends AbstractPassiveSkillLaunchCondition {

	/** 没有宠物 */
	private static final int NOT_HAD_PET = 0;
	/** 有宠物 */
	private static final int HAD_PET = 1;

	private int hadType;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		BattleTeam team = soldier.battleTeam();
		BattlePlayerSoldierInfo soldierInfo = team.soldiersByPlayer(soldier.getId());
		long petId = soldierInfo.petSoldierId();
		BattleSoldier petSoldier = team.battleSoldier(petId);
		boolean rlt = false;
		switch (hadType) {
			case NOT_HAD_PET:
				rlt = petSoldier == null || petSoldier.isDead() || petSoldier.isLeave();
				break;
			case HAD_PET:
				rlt = petSoldier != null && !petSoldier.isDead() && !petSoldier.isLeave();
				break;
			default:
				break;
		}
		return rlt;
	}

	public int getHadType() {
		return hadType;
	}

	public void setHadType(int hadType) {
		this.hadType = hadType;
	}

}
