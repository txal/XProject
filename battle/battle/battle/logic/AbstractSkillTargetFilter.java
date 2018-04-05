package com.nucleus.logic.core.modules.battle.logic;

import java.util.Map;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.logic.data.LogicParamAdapter;

/**
 * 目标过滤
 * 
 * @author wgy
 *
 */
@GenIgnored
public abstract class AbstractSkillTargetFilter extends LogicParamAdapter {
	private int id;

	/**
	 * 目标过滤
	 * 
	 * @param targets
	 * @return
	 */
	public abstract Map<Long, BattleSoldier> filter(Map<Long, BattleSoldier> targets);

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}
}
