package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 
 * @author hwy
 *
 */
@GenIgnored
public class BuffLogicParam_32 extends BuffLogicParam {

	private Set<Integer> buffIds;

	public Set<Integer> getBuffIds() {
		return buffIds;
	}

	public void setBuffIds(Set<Integer> buffIds) {
		this.buffIds = buffIds;
	}
}
