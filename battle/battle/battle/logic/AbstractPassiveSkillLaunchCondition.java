package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.logic.data.LogicParamAdapter;

/**
 * 被动技能触发条件
 * 
 * @author wgy
 *
 */
@GenIgnored
public abstract class AbstractPassiveSkillLaunchCondition extends LogicParamAdapter {
	private int id;

	/**
	 * 是否可触发
	 * 
	 * @param context
	 * @return
	 */
	public abstract boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill);

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}
}
