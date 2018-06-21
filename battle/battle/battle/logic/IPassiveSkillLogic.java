package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.logic.Logic;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;

/**
 * 被动技能生效逻辑
 * 
 * @author wgy
 *
 */
public interface IPassiveSkillLogic extends Logic {
	public void apply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill);

	public float propertyEffect(BattleSoldier soldier, BattleBasePropertyType property, PassiveSkillConfig config, IPassiveSkill passiveSkill);

	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill);
}
