package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 怒气值变化
 * 
 * @author wgy
 * 
 */
public class VideoRageTargetState extends VideoTargetState {
	/** 怒气值变化值,有正负 */
	private int rage;
	/** 是否非普通技能触发 */
	private boolean skill;

	public VideoRageTargetState() {
	}

	public VideoRageTargetState(BattleSoldier target, int rage, boolean skill) {
		super(target);
		this.rage = rage;
		this.skill = skill;
	}

	public int getRage() {
		return rage;
	}

	public void setRage(int rage) {
		this.rage = rage;
	}

	public boolean isSkill() {
		return skill;
	}

	public void setSkill(boolean skill) {
		this.skill = skill;
	}
}
