package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 仙羽被动技能
 * 
 * @author zhuyuanbiao
 *
 * @since 2016年11月15日 下午5:54:40
 */
public class WingPassiveSkill extends Skill implements IPassiveSkill {

	private int type;

	private int[] configId;

	public WingPassiveSkill() {
	}

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setType(int type) {
		this.type = type;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

	@Override
	public int getType() {
		return type;
	}

}
