package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.scene.model.NpcScenePloughMonsterBattleInfo;

/**
 * 只选择当前(地煞)对应的天罡
 * 
 * @author wgy
 *
 */
public class SkillAITarget_14 extends DefaultSkillAITarget {
	public SkillAITarget_14(String ruleStr) {
	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		BattleInfo battleInfo = trigger.battle().battleInfo();
		if (battleInfo != null && battleInfo instanceof NpcScenePloughMonsterBattleInfo) {
			NpcScenePloughMonsterBattleInfo info = (NpcScenePloughMonsterBattleInfo) battleInfo;
			BattleSoldier target = trigger.battleTeam().soldier(info.findBySub(trigger.getId()));
			if (target != null && target.isDead())
				return target;
		}
		return super.select(trigger, skill, ctx);
	}
}
