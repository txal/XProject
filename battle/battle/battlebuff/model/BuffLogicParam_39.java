package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 使用某技能就扣除一次buff作用次数
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class BuffLogicParam_39 extends BuffLogicParam {

	/** 技能集合 */
	private Set<Integer> skillIds;

	public Set<Integer> getSkillIds() {
		return skillIds;
	}

	public void setSkillIds(Set<Integer> skillIds) {
		this.skillIds = skillIds;
	}

}
