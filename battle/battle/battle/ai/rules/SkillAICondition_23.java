package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Collection;
import java.util.HashSet;
import java.util.Set;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 是否存在处于【或不处于】某种状态下的敌方目标
 * <p>
 * Created by hwy on 17/6/7.
 */
public class SkillAICondition_23 extends DefaultSkillAICondition {

	public static final int TYPE_NOT_IN = 0;

	public static final int TYPE_IN = 1;

	private final int type;

	private final Set<Integer> buffIds = new HashSet<>(3);

	public SkillAICondition_23(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		type = NumberUtils.toInt(ruleInfo[0]);
		for (int i = 1; i < ruleInfo.length; i++) {
			buffIds.add(NumberUtils.toInt(ruleInfo[i]));
		}
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final Collection<BattleSoldier> soldiers = soldier.team().getEnemyTeam().soldiersMap().values();
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
