package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_7 extends BuffLogicParam {
	/**
	 * 免疫buffid集合
	 */
	private Set<Integer> buffIds;
	/**
	 * 免疫buff类型集合
	 */
	private Set<Integer> buffTypes;

	public Set<Integer> getBuffIds() {
		return buffIds;
	}

	public void setBuffIds(Set<Integer> buffIds) {
		this.buffIds = buffIds;
	}

	public Set<Integer> getBuffTypes() {
		return buffTypes;
	}

	public void setBuffTypes(Set<Integer> buffTypes) {
		this.buffTypes = buffTypes;
	}
}
