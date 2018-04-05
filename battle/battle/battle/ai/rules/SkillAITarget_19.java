package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 不存在buffId，按配置的门派排序优先
 * 
 * @author hwy
 *
 */
public class SkillAITarget_19 extends SkillAITarget_2 {

	private final int buffId;
	private final Map<Integer, Integer> factionOrders;

	public SkillAITarget_19(String ruleStr) {
		super(ruleStr);
		final int[] ruleInfo = SplitUtils.split2IntArray(ruleStr, ":");
		buffId = ruleInfo[0];
		factionOrders = new HashMap<>(ruleInfo.length);
		for (int i = 1; i < ruleInfo.length; i++) {
			factionOrders.put(ruleInfo[i], i);
		}
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

		// Fixed #8753 要求在发现所有目标没有门派，从所有目标中随机一个，而不是按站位顺序来选择
		final boolean hasFaction = targets.stream().anyMatch(soldier -> factionOrders.containsKey(soldier.factionId()));
		if (hasFaction) {
			sort(targets);
			return getTarget(targets);
		}
		if (targets.size() > 0) {
			return RandomUtils.next(targets);
		} else {
			return null;
		}
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			final BattleSoldier soldier = it.next();
			if (soldier.buffHolder().hasBuff(buffId))
				it.remove();
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				// 按指定门派顺序排序
				int weight1 = getFactionOrder(o1.factionId());
				int weight2 = getFactionOrder(o2.factionId());
				return weight1 - weight2;
			}
		};
	}

	private int getFactionOrder(int factionId) {
		if (factionOrders.containsKey(factionId)) {
			return factionOrders.get(factionId);
		}
		return 100;
	}
}
