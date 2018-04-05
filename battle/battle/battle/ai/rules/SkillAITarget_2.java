package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.*;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 血量排序，最大优先
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_2 extends DefaultSkillAITarget {

	public SkillAITarget_2(String ruleStr) {
	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		final CommandContext checkContext = new CommandContext(trigger, skill, null);
		final Map<Long, BattleSoldier> availableTargets = skill.skillAi().skillAiLogic().availableTargets(checkContext);
		if (availableTargets.size() <= 0) {
			return null;
		}
		final List<BattleSoldier> targets = new ArrayList<>(availableTargets.values());
		filter(targets);
		sort(targets);
		return getTarget(targets);
	}

	protected BattleSoldier getTarget(List<BattleSoldier> targets) {
		if (targets.size() > 0) {
			return targets.get(0);
		} else {
			return null;
		}
	}

	protected void filter(List<BattleSoldier> targets) {
	}

	protected void sort(List<BattleSoldier> targets) {
		Collections.sort(targets, getComparator());
	}

	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = (int) (o1.hpRate() * 10000 + o1.getPosition());
				int weight2 = (int) (o2.hpRate() * 10000 + o2.getPosition());
				return weight2 - weight1;
			}
		};
	}
}
