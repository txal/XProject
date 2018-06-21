package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 技能召唤小怪
 * 
 * @author wgy
 *
 */
public class VideoCallSoldierState extends VideoTargetState {
	/**
	 * 新召唤出来的soldier
	 */
	private VideoSoldier soldier;

	/** 技能ID */
	private int skillId;

	public VideoCallSoldierState() {
	}

	public VideoCallSoldierState(BattleSoldier soldier) {
		super(soldier);
		this.soldier = new VideoSoldier(soldier);
	}

	public VideoSoldier getSoldier() {
		return soldier;
	}

	public void setSoldier(VideoSoldier soldier) {
		this.soldier = soldier;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}
}
