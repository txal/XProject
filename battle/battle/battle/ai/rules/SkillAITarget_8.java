package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Iterator;
import java.util.List;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 不处于封印状态的非鬼魂宠物
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_8 extends SkillAITarget_2 {

	public SkillAITarget_8(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			final BattleSoldier soldier = it.next();
			if (soldier.isGhost() || hasBanState(soldier)) {
				it.remove();
			}
		}
	}
}
