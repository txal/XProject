package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.Iterator;
import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 不存在【或存在】buffId，优先敌方玩家或者伙伴目标
 * 
 * @author hwy
 *
 */
public class SkillAITarget_18 extends SkillAITarget_3 {

	public static final int TYPE_NOT_IN = 0;

	public static final int TYPE_IN = 1;

	private final int type;

	private final int buffId;

	public SkillAITarget_18(String ruleStr) {
		super(ruleStr);
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		type = NumberUtils.toInt(ruleInfo[1]);
		buffId = NumberUtils.toInt(ruleInfo[2]);
	}

	@Override
	protected void filter(List<BattleSoldier> targets) {
		Iterator<BattleSoldier> it = targets.iterator();
		while (it.hasNext()) {
			final BattleSoldier soldier = it.next();
			if ((type == TYPE_NOT_IN && soldier.buffHolder().hasBuff(buffId)) || (type == TYPE_IN && !soldier.buffHolder().hasBuff(buffId)))
				it.remove();
		}
		super.filter(targets);
	}
}
