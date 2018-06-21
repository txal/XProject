package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 造成伤害值尾数为指定值
 * 
 * @author wangyu
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_84 extends AbstractPassiveSkillLaunchCondition {
	/** 伤害值尾数 */
	private int damageTailNum;

	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		if (context == null)
			return false;
		int damage = context.getDamageOutput();
		int tail = -damage % 10;
		return tail == damageTailNum;
	}

	public int getDamageTailNum() {
		return damageTailNum;
	}

	public void setDamageTailNum(int damageTailNum) {
		this.damageTailNum = damageTailNum;
	}

}
