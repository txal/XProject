package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 灵魂连接:代理其他技能效果
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_42 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length == 0)
			return;
		int skillId = Integer.parseInt(config.getExtraParams()[0]);// 要代理的被动技能id
		Skill skill = Skill.get(skillId);
		if (skill == null || !(skill instanceof IPassiveSkill))
			return;
		IPassiveSkill ps = (IPassiveSkill) skill;
		for (int configId : ps.getConfigId()) {
			PassiveSkillConfig pc = PassiveSkillConfig.get(configId);
			if (pc == null)
				continue;
			IPassiveSkillLogic logic = pc.logic();
			if (logic == null)
				continue;
			((AbstractPassiveSkillLogic) logic).doApply(soldier, target, context, pc, timing, ps);
		}
	}
}
