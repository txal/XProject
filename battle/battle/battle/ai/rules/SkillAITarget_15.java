package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

import org.apache.commons.lang3.math.NumberUtils;

import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

/**
 * 1、不处于buffId；2、且HP小于hpRate；3、不带鬼魂
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_15 extends SkillAITarget_2 {

	private final int buffId;

	private final float hpRate;

	private final boolean ignoreGhost;

	public SkillAITarget_15(String ruleStr) {
		super(ruleStr);
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
		hpRate = NumberUtils.toFloat(ruleInfo[1]);
		ignoreGhost = NumberUtils.toInt(ruleInfo[2]) > 0;
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			BattleSoldier bs = it.next();
			if (ignoreGhost && bs.isGhost()) {
				it.remove();
				continue;
			}
			if (bs.hpRate() >= hpRate) {
				it.remove();
				continue;
			}
			if (bs.buffHolder().hasBuff(buffId)) {
				it.remove();
			}
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				int weight1 = (int) (o1.hpRate() * 10000 + o1.getPosition());
				int weight2 = (int) (o2.hpRate() * 10000 + o2.getPosition());
				return weight1 - weight2;
			}
		};
	}

}
