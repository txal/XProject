package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.annotation.GenIgnored;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 目标单位死亡(技能召唤、援助单位、鬼魂宠物除外)
 * 
 * @author wgy
 *
 */
@GenIgnored
public class PassiveSkillLaunchCondition_54 extends AbstractPassiveSkillLaunchCondition {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, IPassiveSkill passiveSkill) {
		return target.isDead() && !target.isGhost() && !target.team().getCalledMonsters().containsKey(target.getId()) && !target.team().reinforcementSet().contains(target.getId());
	}

}
