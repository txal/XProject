package com.nucleus.logic.core.modules.battle.ai.rules;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

import java.util.Iterator;
import java.util.List;

/**
 * 优先选择无105（金刚护法）[状态]的目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_10 extends SkillAITarget_2 {

	private final int buffId;

	public SkillAITarget_10(String ruleStr) {
		super(ruleStr);
		buffId = NumberUtils.toInt(ruleStr.trim());
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			BattleSoldier bs = it.next();
			if (bs.buffHolder().hasBuff(buffId) || bs.isLowGhost()) {
				it.remove();
				continue;
			}
		}
	}
}
