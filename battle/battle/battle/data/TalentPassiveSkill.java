package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;

/**
 * 坐骑通用被动技能
 *
 * @author zhanhua.xu
 */
public class TalentPassiveSkill extends TalentSkill implements IPassiveSkill {

	public static TalentPassiveSkill get(int id) {
		return StaticDataManager.getInstance().get(TalentPassiveSkill.class, id);
	}

	private int type;
	/** 技能配置 */
	private int[] configId;
	/** 效果公式 */
	private String effectFormula;

	@Override
	public int getType() {
		return type;
	}

	public void setType(int type) {
		this.type = type;
	}

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

	public String getEffectFormula() {
		return effectFormula;
	}

	public void setEffectFormula(String effectFormula) {
		this.effectFormula = effectFormula;
	}
}
