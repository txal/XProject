package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;
import java.util.Set;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 所有除鬼魂外的目标都处于封印状态或已经成为己方封系的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_7 extends DefaultSkillAICondition {
	private Set<Integer> ignoreCharactorTypes;

	public SkillAICondition_7(String ruleStr) {
		// final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		ignoreCharactorTypes = SplitUtils.split2IntSet(ruleStr, ":");
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (this.ignoreCharactorTypes.contains(soldier.charactorType()))
			return true;
		List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		if (soldiers.isEmpty()) {
			return false;
		}
		for (BattleSoldier bs : soldiers) {
			if (bs.isGhost())
				continue;
			if (!bs.buffHolder().isAttackBanned()) {
				return false;
			}
		}
		return true;
	}

}
