package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_37 extends BuffLogicParam {

	/** 修改哪项buff属性，对应BuffPropertyEnum */
	private int buffPro;

	private String formula;

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

	public int getBuffPro() {
		return buffPro;
	}

	public void setBuffPro(int buffPro) {
		this.buffPro = buffPro;
	}

}
