package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.List;

/**
 * 1、不处于buffId；2、且HP小于hpRate；3、不带鬼魂
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_21 extends DefaultSkillAICondition {

	private final int buffId;

	private final float hpRate;

	private final boolean ignoreGhost;

	public SkillAICondition_21(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
		hpRate = NumberUtils.toFloat(ruleInfo[1]);
		ignoreGhost = NumberUtils.toInt(ruleInfo[2]) > 0;
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		if (ctx != null && ctx.target() != null) {
			BattleSoldier target = ctx.target();
			boolean valid = validTarget(target);
			return valid;
		}
		for (BattleSoldier bs : soldiers) {
			if (validTarget(bs))
				return true;
		}
		return false;
	}

	private boolean validTarget(BattleSoldier target) {
		if (target.isDead())
			return false;
		if (target.hpRate() >= hpRate)
			return false;
		if (ignoreGhost && target.isGhost())
			return false;
		if (target.buffHolder().hasBuff(buffId))
			return false;
		return true;
	}

}
