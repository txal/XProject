package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 *
 * @author hwy
 *
 */
@GenIgnored
public class BuffLogicParam_25 extends BuffLogicParam {
	/** 公式 */
	private String formule;
	/** 反震伤害百分比 */
	private float rate;

	public String getFormule() {
		return formule;
	}

	public void setFormule(String formule) {
		this.formule = formule;
	}

	public float getRate() {
		return rate;
	}

	public void setRate(float rate) {
		this.rate = rate;
	}
}
