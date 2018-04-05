package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext;

/**
 * 存在不处于105（金刚护法）状态的非鬼魂单位
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_6 extends DefaultSkillAICondition {

	private final int buffId;

	public SkillAICondition_6(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		final RoundContext roundContext = soldier.roundContext();
		final int skillId = skill.getId();
		boolean onRoundStart = roundContext != null && roundContext.getState() == RoundContext.RoundState.RoundStart;
		for (BattleSoldier bs : soldiers) {
			if (onRoundStart && roundContext.isTargetBySkill(bs.getId(), skillId)) {
				continue;
			}
			if (!bs.isGhost() && !bs.buffHolder().hasBuff(buffId)) {
				return true;
			}
		}
		return false;
	}

}
