package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 物理/法术攻击
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_16 extends BuffLogicParam {
	private int attackType;
	private float rate;
	public int getAttackType() {
		return attackType;
	}

	public void setAttackType(int attackType) {
		this.attackType = attackType;
	}

	public float getRate() {
		return rate;
	}

	public void setRate(float rate) {
		this.rate = rate;
	}

}
