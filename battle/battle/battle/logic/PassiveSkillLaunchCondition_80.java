package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.NpcActiveSkill;
import com.nucleus.logic.core.modules.battle.data.NpcPassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自己已召唤的单位不超过某个值
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_80 extends AbstractPassiveSkillLaunchCondition {

	private int value;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		// 天蓬召唤被动技能会触发另一个召唤技能，要求已召唤数量不超过限定，并且自己血量足够触发召唤技能
		int calledCount = soldier.battleTeam().getCalledMonsters().size();
		NpcPassiveSkillConfig config = (NpcPassiveSkillConfig) PassiveSkillConfig.get(passiveSkill.getConfigId()[0]);
		if (config != null) {
			NpcActiveSkill callSkill = (NpcActiveSkill) Skill.get(Integer.parseInt(config.getExtraParams()[0]));
			if (callSkill != null) {
				int hpSpent = -(int) BattleUtils.valueWithSoldierSkill(soldier, callSkill.getSpendHpFormula(), callSkill);
				if (calledCount < value && hpSpent < soldier.hp()) {
					return true;
				}
			}
		}
		return false;
	}

	public int getValue() {
		return value;
	}

	public void setValue(int value) {
		this.value = value;
	}

}
