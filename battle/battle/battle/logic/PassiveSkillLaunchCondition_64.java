package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 指定关系触发
 * 
 * @author yifan.chen
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_64 extends AbstractPassiveSkillLaunchCondition {
	private int type;

	private enum RelationType {
		/** 未知 **/
		Unknow,
		/** 主宠 **/
		Pet,
		/** 结拜 **/
		Brother,
		/** 伴侣 **/
		Fere
	}

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (type == RelationType.Unknow.ordinal())
			return false;

		RelationType[] rtArray = RelationType.values();
		RelationType relationType = rtArray[type];
		switch (relationType) {
			case Pet:
				if (this.isMyPet(soldier, target) || this.isMyPet(target, soldier))
					return true;
				break;
			case Brother:
				if (soldier.isBro(target))
					return true;
				break;
			case Fere:
				if (soldier.ifFere(target.getId()))
					return true;
				break;
			default:
				return false;
		}
		return false;
	}

	private boolean isMyPet(BattleSoldier soldier, BattleSoldier target) {
		if (soldier.isMainCharactor() && soldier.myPet() != null) {
			if (target.getId() == soldier.myPet().getId())
				return true;
		}
		return false;
	}

	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

}
