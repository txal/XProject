package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.Comparator;

/**
 * 处于115（普度众生）状态且HP＜50%的己方单位
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_11 extends SkillAITarget_2 {

	private final int buffId;

	public SkillAITarget_11(String ruleStr) {
		super(ruleStr);
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0].trim());
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = o1.buffHolder().hasBuff(buffId) ? 1 : 0;
				int weight2 = o2.buffHolder().hasBuff(buffId) ? 1 : 0;
				if (weight1 == weight2) {
					return (int) (o1.hpRate() * 100 - o2.hpRate() * 100);
				}
				return weight1 - weight2;
			}
		};
	}
}
