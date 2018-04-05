package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 1、倒地；2、不带鬼魂和高级鬼魂技能；3、不带BUFF夺命蛛丝（126）
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_22 extends DefaultSkillAICondition {

	private final int buffId = 126;

	public SkillAICondition_22(String ruleStr) {
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		for (BattleSoldier bs : soldiers) {
			if (!bs.canRelive())
				continue;
			// if (!bs.isDead() || bs.isGhost()) continue;
			// if (bs.buffHolder().hasBuff(buffId)) continue;
			return true;
		}
		return false;
	}

}
