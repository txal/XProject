package com.nucleus.logic.core.modules.battle.data;

/**
 * 天赋主动技能主要用于替换原玩家的技能
 *
 * @author hwy
 */
public class TalentActiveSkill extends TalentSkill {
	/** 门派编号 */
	private int factionId;

	public int getFactionId() {
		return factionId;
	}

	public void setFactionId(int factionId) {
		this.factionId = factionId;
	}

}
