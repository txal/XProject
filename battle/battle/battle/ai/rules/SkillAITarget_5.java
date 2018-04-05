package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 70%几率【rate】选择气血最少的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_5 extends SkillAITarget_2 {

	private final double rate;

	public SkillAITarget_5(String ruleStr) {
		super(ruleStr);
		rate = NumberUtils.toDouble(ruleStr.trim());
	}

	@Override
	protected BattleSoldier getTarget(List<BattleSoldier> targets) {
		if (targets.size() <= 0)
			return null;

		final double rnd = Math.random();
		if (rnd < rate) {
			return targets.get(0);
		} else {
			final int index = (int) (Math.random() * targets.size());
			return targets.get(index);
		}
	}
}
