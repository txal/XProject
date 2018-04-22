package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * npc被动技能
 * 
 * @author wgy
 *
 */
public class NpcPassiveSkill extends NpcSkill implements IPassiveSkill {
	/**
	 * 技能配置
	 */
	private int[] configId;

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

}
