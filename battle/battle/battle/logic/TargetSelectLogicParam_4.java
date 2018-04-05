package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 随机n个目标
 * 
 * @author wgy
 *
 */
@GenIgnored
public class TargetSelectLogicParam_4 extends TargetSelectLogicParam {
	private int min;
	private int max;

	public int getMin() {
		return min;
	}

	public void setMin(int min) {
		this.min = min;
	}

	public int getMax() {
		return max;
	}

	public void setMax(int max) {
		this.max = max;
	}
}
