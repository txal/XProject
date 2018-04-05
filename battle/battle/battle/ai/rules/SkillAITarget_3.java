package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Comparator;
import java.util.Iterator;
import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;

/**
 * 优先选择玩家或伙伴目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAITarget_3 extends SkillAITarget_2 {

	private final boolean filterBanned;

	public SkillAITarget_3(String ruleStr) {
		super(ruleStr);
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		filterBanned = ruleInfo.length <= 0 ? false : (NumberUtils.toInt(ruleInfo[0]) > 0);
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		if (!filterBanned) {
			return;
		}
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			final BattleSoldier soldier = it.next();
			if (soldier.buffHolder().isAttackBanned()) {
				it.remove();
			}
		}
	}

	@Override
	protected Comparator<BattleSoldier> getComparator() {
		return new Comparator<BattleSoldier>() {
			private final int charactorTypeCount = GeneralCharactor.CharactorType.values().length;

			@Override
			public int compare(BattleSoldier o1, BattleSoldier o2) {
				// 按角色类型，再按位置
				int weight1 = (charactorTypeCount - o1.charactorType()) * 1000 + o1.getPosition();
				int weight2 = (charactorTypeCount - o2.charactorType()) * 1000 + o2.getPosition();
				return weight1 - weight2;
			}
		};
	}
}
