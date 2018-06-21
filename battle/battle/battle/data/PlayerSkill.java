package com.nucleus.logic.core.modules.battle.data;

/**
 * 人物技能
 * 
 * @author wgy
 *
 */
public class PlayerSkill extends Skill {
	/** 门派编号 */
	private int factionId;

	public int getFactionId() {
		return factionId;
	}

	public void setFactionId(int factionId) {
		this.factionId = factionId;
	}
}
