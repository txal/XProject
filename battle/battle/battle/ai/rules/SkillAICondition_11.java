package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 存在处于115（普度众生）状态且HP＜50%的己方单位
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_11 extends DefaultSkillAICondition {

	private final int buffId;

	private final float rate;

	public SkillAICondition_11(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
		rate = NumberUtils.toInt(ruleInfo[1]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		for (BattleSoldier battleSoldier : soldiers) {
			if (battleSoldier.buffHolder().hasBuff(buffId) && battleSoldier.hpRate() < rate) {
				return true;
			}
		}
		return false;
	}

}
