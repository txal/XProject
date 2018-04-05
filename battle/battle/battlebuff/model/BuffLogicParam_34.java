package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 * 执行某动作就扣除一次buff作用次数
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class BuffLogicParam_34 extends BuffLogicParam {

	/** 动作集合 */
	private Set<Integer> battleCommandTypes;

	public Set<Integer> getBattleCommandTypes() {
		return battleCommandTypes;
	}

	public void setBattleCommandTypes(Set<Integer> battleCommandTypes) {
		this.battleCommandTypes = battleCommandTypes;
	}
}
