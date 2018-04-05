package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 力量属性最高且未处于封印状态的宠物目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_12 extends SkillAITarget_2 {

	public SkillAITarget_12(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = (o1.buffHolder().isAttackBanned() ? 0 : 1) * 1000000 + o1.strength();
				int weight2 = (o2.buffHolder().isAttackBanned() ? 0 : 1) * 1000000 + o2.strength();
				return weight1 - weight2;
			}
		};
	}
}
