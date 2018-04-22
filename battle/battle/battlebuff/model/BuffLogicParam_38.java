package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_38 extends BuffLogicParam {

	/** 影响哪项属性 */
	private int property;
	/** 影响公式 */
	private String formula;
	/** 如果需要用到技能等级参数，就指定是哪个技能 */
	private int skillId;

	public String getFormula() {
		return formula;
	}

	public void setFormula(String formula) {
		this.formula = formula;
	}

	public int getSkillId() {
		return skillId;
	}

	public void setSkillId(int skillId) {
		this.skillId = skillId;
	}

	public int getProperty() {
		return property;
	}

	public void setProperty(int property) {
		this.property = property;
	}

}
