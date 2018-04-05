package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import com.google.common.collect.Lists;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.RoundContext;

/**
 * 存在未中封印状态且未被其他友方单位作为目标的敌方单位
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_8 extends DefaultSkillAICondition {

	public SkillAICondition_8(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final RoundContext roundContext = soldier.roundContext();
		final int skillId = skill.getId();
		List<BattleSoldier> soldiers = null;
		if (ctx != null && roundContext.getState() == RoundContext.RoundState.RoundStart) {
			soldiers = Lists.newArrayList(ctx.target());
		} else {
			soldiers = getAvailableTargets(soldier, skill);
		}
		boolean onRoundStart = roundContext != null && roundContext.getState() == RoundContext.RoundState.RoundStart;
		for (BattleSoldier bs : soldiers) {
			if (bs.isGhost() || bs.isDead())
				continue;
			if (onRoundStart && roundContext.isTargetBySkill(bs.getId(), soldier.getId(), skillId)) {
				continue;
			}
			if (onRoundStart && roundContext.isTargetBySkill(bs.getId(), skillId)) {
				continue;
			}
			if (!hasBanState(bs)) {
				return true;
			}
		}
		return false;
	}

}
