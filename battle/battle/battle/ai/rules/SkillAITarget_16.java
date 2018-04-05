package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 优先选择无指定buff目标，并随机选择其一
 * 
 * @author wgy
 *
 */
public class SkillAITarget_16 extends SkillAITarget_10 {

	public SkillAITarget_16(String ruleStr) {
		super(ruleStr);
	}

	@Override
	protected void sort(List<BattleSoldier> targets) {
	}

	@Override
	protected BattleSoldier getTarget(List<BattleSoldier> targets) {
		int size = targets.size();
		if (size < 1)
			return null;
		int idx = RandomUtils.nextInt(size);
		return targets.get(idx);
	}
}
