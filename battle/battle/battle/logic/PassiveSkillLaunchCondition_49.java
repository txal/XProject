package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 回合内指定被动技能效果触发次数(超/未超)上限
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_49 extends AbstractPassiveSkillLaunchCondition {
	/** 被动技能配置ID */
	private int effectId;
	/** 1=未超上限;2=超上限*/
	private int flag;
	/** 技能触发次数上限*/
	private int limit;

	public int getEffectId() {
		return effectId;
	}

	public void setEffectId(int effectId) {
		this.effectId = effectId;
	}

	public int getFlag() {
		return flag;
	}

	public void setFlag(int flag) {
		this.flag = flag;
	}

	public int getLimit() {
		return limit;
	}

	public void setLimit(int limit) {
		this.limit = limit;
	}

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		int t = soldier.roundPassiveEffectTimeOf(effectId);
		if (flag == 1 && t < limit)
			return true;
		if (flag == 2 && t >= limit)
			return true;
		return false;
	}

}
