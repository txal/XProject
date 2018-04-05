package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 子女被动技能
 * 
 * @author wgy
 *
 */
public class ChildPassiveSkill extends ChildSkill implements IPassiveSkill {
	/**
	 * 技能配置
	 */
	private int[] configId;
	/** 推荐描述 */
	private String guideDesc;
	/**
	 * PetSkillTypeEnum
	 */
	private int type;

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

	public String getGuideDesc() {
		return guideDesc;
	}

	public void setGuideDesc(String guideDesc) {
		this.guideDesc = guideDesc;
	}

	@Override
	public int getType() {
		return this.type;
	}

	public void setType(int type) {
		this.type = type;
	}
}
