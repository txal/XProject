package com.nucleus.logic.core.modules.battlebuff.model;

import java.util.Set;

import com.nucleus.commons.annotation.GenIgnored;

/**
 *
 * @author wgy
 *
 */
@GenIgnored
public class BuffLogicParam_21 extends BuffLogicParam {
	private Set<Integer> battleCommandTypes;

	public Set<Integer> getBattleCommandTypes() {
		return battleCommandTypes;
	}

	public void setBattleCommandTypes(Set<Integer> battleCommandTypes) {
		this.battleCommandTypes = battleCommandTypes;
	}
}
