package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;
import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 不存在buffId&&对应配置的门派的优先
 * 
 * @author hwy
 *
 */
public class SkillAITarget_20 extends SkillAITarget_2 {

	private final int buffId;
	private final Map<Integer, Integer> factionOrders;

	public SkillAITarget_20(String ruleStr) {
		super(ruleStr);
		final int[] ruleInfo = SplitUtils.split2IntArray(ruleStr, ":");
		buffId = ruleInfo[0];
		factionOrders = new HashMap<>(ruleInfo.length);
		for (int i = 1; i < ruleInfo.length; i++) {
			factionOrders.put(ruleInfo[i], i);
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = getFactionOrder(o1);
				int weight2 = getFactionOrder(o2);
				return weight1 - weight2;
			}
		};
	}

	private int getFactionOrder(BattleSoldier solider) {
		if (!solider.buffHolder().hasBuff(buffId) && factionOrders.containsKey(solider.factionId()))
			return factionOrders.get(solider.factionId());
		else
			return 100;
	}
}
