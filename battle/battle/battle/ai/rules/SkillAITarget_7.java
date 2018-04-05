package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 优先选择带鬼魂和高级鬼魂的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_7 extends SkillAITarget_2 {

	public SkillAITarget_7(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				if (o1.isGhost() && o2.isGhost()) {
					return o1.hp() - o2.hp();
				} else if (o1.isGhost()) {
					return -1;
				} else if (o2.isGhost()) {
					return 1;
				} else {
					return 0;
				}
			}
		};
	}
}
