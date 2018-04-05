package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 影响魔法值消耗
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class BuffLogicParam_33 extends BuffLogicParam {

	private String mpSpendFormula;

	private int skillId;

	public String getMpSpendFormula() {
		return mpSpendFormula;
	}

	public void setMpSpendFormula(String mpSpendFormula) {
		this.mpSpendFormula = mpSpendFormula;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

}
