package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 攻击带隐身【状态】的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_13 extends SkillAITarget_2 {

	public SkillAITarget_13(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			BattleSoldier bs = it.next();
			if (!bs.buffHolder().isHidden()) {
				it.remove();
			}
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = o2.buffHolder().isHidden() ? 1 : 0;
				int weight2 = o2.buffHolder().isHidden() ? 1 : 0;
				return weight1 - weight2;
			}
		};
	}
}
