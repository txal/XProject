package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 指定的buff在剩余第几回合的时候触发
 * 
 * @author yifan.chen
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_62 extends AbstractPassiveSkillLaunchCondition {
	/** 指定的buffid **/
	private Set<Integer> buffIds;
	/** 剩余回合 **/
	private int leftRound;
	/** 触发时是否清除指定的buff表现 **/
	private boolean clearBuff;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		for (int buffId : buffIds) {
			BattleBuffEntity buff = soldier.buffHolder().getBuff(buffId);
			if (buff == null)
				continue;
			if (buff.getBuffPersistRound() == leftRound) {
				if (clearBuff) {
					context.skillAction().addTargetState(new VideoBuffRemoveTargetState(soldier, buffId));
				}
				return true;
			}
		}
		return false;
	}

	public Set<Integer> getBuffIds() {
		return buffIds;
	}

	public void setBuffIds(Set<Integer> buffIds) {
		this.buffIds = buffIds;
	}

	public int getLeftRound() {
		return leftRound;
	}

	public void setLeftRound(int leftRound) {
		this.leftRound = leftRound;
	}

	public boolean isClearBuff() {
		return clearBuff;
	}

	public void setClearBuff(boolean clearBuff) {
		this.clearBuff = clearBuff;
	}

}
