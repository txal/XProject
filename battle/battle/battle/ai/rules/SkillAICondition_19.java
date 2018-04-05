package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.scene.model.NpcScenePloughMonsterBattleInfo;

/**
 * 复活地煞对应的天罡
 * 
 * @author wgy
 *
 */
public class SkillAICondition_19 extends DefaultSkillAICondition {
	public SkillAICondition_19(String ruleStr) {
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		BattleInfo battleInfo = soldier.battle().battleInfo();
		if (battleInfo != null && battleInfo instanceof NpcScenePloughMonsterBattleInfo) {
			NpcScenePloughMonsterBattleInfo info = (NpcScenePloughMonsterBattleInfo) battleInfo;
			BattleSoldier target = soldier.battleTeam().soldier(info.findBySub(soldier.getId()));
			if (target != null && target.isDead())
				return true;
		}
		return false;
	}
}
