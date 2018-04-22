package com.nucleus.logic.core.modules.battle.logic;

import org.apache.commons.lang3.math.NumberUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 映射并强制使用某技能
 * 
 * @author zhanhua.xu
 *
 */
@Service
public class PassiveSkillLogic_61 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int forceSkillId = NumberUtils.toInt(config.getExtraParams()[0]);
		int mappingSkillId = NumberUtils.toInt(config.getExtraParams()[1]);
		soldier.initForceSkill(forceSkillId);
		context.setSkill(Skill.get(forceSkillId));
		int skillsLevel = soldier.skillLevel(mappingSkillId);
		soldier.skillHolder().battleSkillHolder().forceSkillLevel(forceSkillId, skillsLevel);
	}
}
