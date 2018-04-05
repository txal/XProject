package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 回合数尾数为指定值
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_85 extends AbstractPassiveSkillLaunchCondition {
	/** 回合数尾数 */
	private int roundTailNum;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		int tail = 0;
		if (context.currentVideoRound() != null) {
			int round = context.currentVideoRound().getCount();
			tail = round % 10;
		}
		return tail == roundTailNum;
	}

	public int getRoundTailNum() {
		return roundTailNum;
	}

	public void setRoundTailNum(int roundTailNum) {
		this.roundTailNum = roundTailNum;
	}

}
