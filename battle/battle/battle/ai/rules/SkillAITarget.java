package com.nucleus.logic.core.modules.battle.ai.rules;

import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 技能AI目标选择规则
 *
 * Created by Tony on 15/6/19.
 */
public interface SkillAITarget {

	void setSkillId(int skillId);

	BattleSoldier select(BattleSoldier trigger, Skill skill, CommandContext ctx);

}
