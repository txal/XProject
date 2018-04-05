package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 1、战斗开始第N回合 2、是否存在处于【或不处于】某种状态下的目标
 * <p>
 * Created by hwy on 17/6/7.
 */
public class SkillAICondition_24 extends DefaultSkillAICondition {

	public static final int TYPE_NOT_IN = 0;

	public static final int TYPE_IN = 1;

	private final int round;

	private final int type;

	private final Set<Integer> buffIds = new HashSet<>(3);

	public SkillAICondition_24(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		round = NumberUtils.toInt(ruleInfo[0]);
		type = NumberUtils.toInt(ruleInfo[1]);
		for (int i = 2; i < ruleInfo.length; i++) {
			buffIds.add(NumberUtils.toInt(ruleInfo[i]));
		}
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (soldier.battle().getCount() != round)
			return false;
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		for (BattleSoldier s : soldiers) {
			boolean hasBuffers = hasBuffers(s);
			if ((type == TYPE_NOT_IN && !hasBuffers) || (type == TYPE_IN && hasBuffers))
				return true;
		}
		return false;
	}

	private boolean hasBuffers(BattleSoldier soldier) {
		for (Integer buffId : buffIds) {
			if (soldier.buffHolder().hasBuff(buffId))
				return true;
		}
		return false;
	}
}
