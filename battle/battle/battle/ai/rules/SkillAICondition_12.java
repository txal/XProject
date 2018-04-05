package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 120（变身）状态下存在未被封印的玩家或者伙伴目标
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_12 extends DefaultSkillAICondition {

	private final int buffId;

	public SkillAICondition_12(String ruleStr) {
		if (StringUtils.isNotBlank(ruleStr)) {
			final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
			buffId = NumberUtils.toInt(ruleInfo[0]);
		} else
			buffId = 0;
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		// 兼容无需变身状态
		if (this.buffId > 0) {
			boolean hasBuff = soldier.buffHolder().hasBuff(this.buffId);
			if (!hasBuff)
				return false;
		}
		for (BattleSoldier battleSoldier : soldiers) {
			if (battleSoldier.getId() == soldier.getId()) {
				continue;
			}
			if (!battleSoldier.buffHolder().isAttackBanned()) {
				return true;
			}
		}
		return false;
	}

}
