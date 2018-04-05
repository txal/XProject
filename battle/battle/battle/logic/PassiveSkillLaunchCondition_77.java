package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 是否宠物
 * 
 * @author hwy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_77 extends AbstractPassiveSkillLaunchCondition {

	/** 不是宠物 */
	private static final int NOT_PET = 0;
	/** 是宠物 */
	private static final int IS_PET = 1;

	private int charatorType;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		boolean rlt = false;
		if (context == null)
			return rlt;
		switch (charatorType) {
			case NOT_PET:
				rlt = !target.ifPet();
				break;
			case IS_PET:
				rlt = target.ifPet();
				break;
			default:
				break;
		}
		return rlt;
	}

	public int getCharatorType() {
		return charatorType;
	}

	public void setCharatorType(int charatorType) {
		this.charatorType = charatorType;
	}

}
