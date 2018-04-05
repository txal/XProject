package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * @author hwy
 *
 */
@GenIgnored
public class BuffLogicParam_29 extends BuffLogicParam {

	/** 死亡删除处理公式 */
	private String deadFormula;
	/** 正常删除处理公式 */
	private String rmFormula;

	public String getDeadFormula() {
		return deadFormula;
	}

	public void setDeadFormula(String deadFormula) {
		this.deadFormula = deadFormula;
	}

	public String getRmFormula() {
		return rmFormula;
	}

	public void setRmFormula(String rmFormula) {
		this.rmFormula = rmFormula;
	}
}
