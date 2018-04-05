package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

/**
 * 120（变身）状态下，敌方存活人数≥3
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_13 extends DefaultSkillAICondition {

	private final int buffId;

	private final int aliveCount;

	public SkillAICondition_13(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
		aliveCount = NumberUtils.toInt(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (this.buffId > 0) {// 兼容无需变身的情况
			boolean hasBuff = soldier.buffHolder().hasBuff(this.buffId);
			if (!hasBuff)
				return false;
		}
		return soldier.team().getEnemyTeam().aliveSoldiers().size() >= aliveCount;
	}

}
