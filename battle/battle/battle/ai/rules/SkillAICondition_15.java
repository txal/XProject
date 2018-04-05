package com.nucleus.logic.core.modules.battle.ai.rules;

import java.util.List;

import org.apache.commons.lang3.math.NumberUtils;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;

/**
 * 所有玩家或者伙伴都已处于封印状态下自身不处于防御加强效果之下
 * <p>
 * Created by Tony on 15/6/19.
 */
public class SkillAICondition_15 extends DefaultSkillAICondition {

	private final int buffId;

	public SkillAICondition_15(String ruleStr) {
		final String[] ruleInfo = SplitUtils.split2StringArray(ruleStr, ":");
		buffId = NumberUtils.toInt(ruleInfo[0]);
	}

	@Override
	public boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx) {
		final boolean hasBuff = soldier.buffHolder().hasBuff(buffId);
		if (hasBuff) {
			return false;
		}
		final List<BattleSoldier> soldiers = getAvailableTargets(soldier, skill);
		for (BattleSoldier battleSoldier : soldiers) {
			if (battleSoldier.isMainCharactor() || battleSoldier.charactorType() == GeneralCharactor.CharactorType.Crew.ordinal()) {
				if (!hasBanState(battleSoldier)) {
					return false;
				}
			}
		}
		return true;
	}

}
