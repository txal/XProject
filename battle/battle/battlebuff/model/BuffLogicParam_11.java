package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 逻辑id属于指定范围且不属于排除列表道具
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_11 extends BuffLogicParam {
	/**道具逻辑属于该指定逻辑集合的道具不能用*/
	private Set<Integer> antiLogicIds;
	private Set<Integer> excludeItemIds;
	public Set<Integer> getAntiLogicIds() {
		return antiLogicIds;
	}

	public void setAntiLogicIds(Set<Integer> antiLogicIds) {
		this.antiLogicIds = antiLogicIds;
	}

	public Set<Integer> getExcludeItemIds() {
		return excludeItemIds;
	}

	public void setExcludeItemIds(Set<Integer> excludeItemIds) {
		this.excludeItemIds = excludeItemIds;
	}

}
