package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 1、倒地；2、不带鬼魂和高级鬼魂技能；3、不带BUFF夺命蛛丝（126）
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_9 extends SkillAITarget_2 {

	private final int buffId = 126;

	public SkillAITarget_9(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			final BattleSoldier soldier = it.next();
			if (!soldier.canRelive())
				it.remove();
			// if(!soldier.isDead() || soldier.isGhost() || soldier.buffHolder().hasBuff(buffId)) {
			// it.remove();
			// }
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				/*
				 * 修改为随便排序 int weight1 = o1.maxHp(); int weight2 = o2.maxHp(); return weight1 - weight2;
				 */
				// 随便[-1, 0, 1]
				return RandomUtils.nextInt(3) - 1;
			}
		};
	}
}
