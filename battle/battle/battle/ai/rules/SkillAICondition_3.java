package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 己方所有单位HP=100%
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_3 extends DefaultSkillAICondition {
	private Set<Integer> ignoreCharactorTypes;

	public SkillAICondition_3(String ruleStr) {
		this.ignoreCharactorTypes = SplitUtils.split2IntSet(ruleStr, ":");
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		if (ignoreCharactorTypes.contains(soldier.charactorType()))
			return true;
		List<BattleSoldier> soldiers = new ArrayList<>(soldier.team().soldiersMap().values());
		for (BattleSoldier battleSoldier : soldiers) {
			if (battleSoldier.hpRate() < 1) {
				return false;
			}
		}
		return true;
	}

}
