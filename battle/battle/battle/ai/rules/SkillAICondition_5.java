package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.List;

/**
 * 存在HP少于35%的玩家或者伙伴目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_5 extends DefaultSkillAICondition {

	private final int camp;

	private final float rate;

	public SkillAICondition_5(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		camp = NumberUtils.toInt(ruleInfo[0]);
		rate = NumberUtils.toFloat(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = null;
		if (camp <= 0) {
			soldiers = soldier.team().getEnemyTeam().aliveSoldiers();
		} else {
			soldiers = soldier.team().aliveSoldiers();
		}
		for (BattleSoldier bs : soldiers) {
			if (bs.hpRate() < rate) {
				return true;
			}
		}
		return false;
	}

}
