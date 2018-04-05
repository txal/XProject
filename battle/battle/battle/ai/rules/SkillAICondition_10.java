package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.HashSet;
import java.util.Set;

/**
 * 是否处于【或不处于】某种状态下
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_10 extends DefaultSkillAICondition {

	public static final int TYPE_NOT_IN = 0;

	public static final int TYPE_IN = 1;

	private final int type;

	private final Set<Integer> buffIds = new HashSet<>(3);

	public SkillAICondition_10(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		type = NumberUtils.toInt(ruleInfo[0]);
		for (int i = 1; i < ruleInfo.length; i++) {
			buffIds.add(NumberUtils.toInt(ruleInfo[i]));
		}
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (type == TYPE_NOT_IN) {
			return !hasBuffers(soldier);
		}
		if (type == TYPE_IN) {
			return hasBuffers(soldier);
		}
		return false;
	}

	private boolean hasBuffers(BattleSoldier soldier) {
		for (Integer buffId : buffIds) {
			if (soldier.buffHolder().hasBuff(buffId)) {
				return true;
			}
		}
		return false;
	}

}
