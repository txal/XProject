package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 宠物被动技能
 * 
 * @author wgy
 *
 */
public class PetPassiveSkill extends PetSkill implements IPassiveSkill {
	/**
	 * 技能配置
	 */
	private int[] configId;
	/** 推荐描述 */
	private String guideDesc;
	/**
	 * 技能是否飘字
	 */
	private boolean skillText;

	public static PetPassiveSkill get(int id) {
		return StaticDataManager.getInstance().get(PetPassiveSkill.class, id);
	}

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

	public boolean isSkillText() {
		return skillText;
	}

	public void setSkillText(boolean skillText) {
		this.skillText = skillText;
	}

}
