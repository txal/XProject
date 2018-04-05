package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * Created by Tony on 15/6/19.
 */
public class DefaultSkillAITarget implements SkillAITarget {

	protected int skillId;

	@Override
	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	@Override
	public BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx) {
		return null;
	}

	protected boolean hasBanState(BattleSoldier soldier) {
		for (BattleBuffEntity buffEntity : soldier.buffHolder().allBuffs().values()) {
			if (buffEntity.battleBuff().getBuffClassType() == BattleBuff.BuffClassTypeEnum.Ban.ordinal()) {
				return true;
			}
		}
		return false;
	}
}
