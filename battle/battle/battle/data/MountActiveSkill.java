package com.nucleus.logic.core.modules.battle.data;

/**
 * 坐骑主动技能主要用于替换原玩家的技能
 *
 * @author zhanhua.xu
 */
public class MountActiveSkill extends MountSkill {
	/** 门派编号 */
	private int factionId;

	public int getFactionId() {
		return factionId;
	}

	public void setFactionId(int factionId) {
		this.factionId = factionId;
	}

}
