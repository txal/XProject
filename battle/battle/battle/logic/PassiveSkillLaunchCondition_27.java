package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 没有指定技能的其他怪全部死亡
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_27 extends AbstractPassiveSkillLaunchCondition {
	private int skillId;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		for (BattleSoldier s : soldier.team().aliveSoldiers()) {
			if (s.getId() != soldier.getId() && s.skillHolder().skill(skillId) == null)
				return false;
		}
		return true;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

}
