package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 技能使用条件规则
 *
 * Created by Tony on 15/6/19.
 */
public interface SkillAICondition {

	boolean isAvailable(BattleSoldier soldier, Skill skill, CommandContext ctx);

}
