package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 魔法值最高的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_4 extends SkillAITarget_2 {

	public SkillAITarget_4(String ruleStr) {
		super(ruleStr);
	}

	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				// 按角色类型，再按位置
				int weight1 = o1.mp();
				int weight2 = o2.mp();
				return weight2 - weight1;
			}
		};
	}
}
