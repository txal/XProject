package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 技能目标对应策略
 * 
 * @author wgy
 *
 */
public class SkillTargetPolicy {
	/**
	 * 技能目标
	 */
	private BattleSoldier target;
	/**
	 * 施放策略
	 */
	private SkillTargetInfo policy;

	public SkillTargetPolicy() {
	}

	public SkillTargetPolicy(BattleSoldier target, SkillTargetInfo policy) {
		this.target = target;
		this.policy = policy;
	}

	public BattleSoldier getTarget() {
		return target;
	}

	public void setTarget(BattleSoldier target) {
		this.target = target;
	}

	public SkillTargetInfo getPolicy() {
		return policy;
	}

	public void setPolicy(SkillTargetInfo policy) {
		this.policy = policy;
	}
}
