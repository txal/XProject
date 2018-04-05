package com.nucleus.logic.core.modules.battlebuff.model;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 抗药性buff逻辑参数
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_12 extends BuffLogicParam {
	/**抗药性值低于此数值会移除buff*/
	private int value;

	public int getValue() {
		return value;
	}

	public void setValue(int value) {
		this.value = value;
	}
}
