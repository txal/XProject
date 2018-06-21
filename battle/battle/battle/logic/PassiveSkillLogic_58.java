package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.ai.NpcBattleAI;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 前置技能：按技能ai筛选目标
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_58 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getExtraParams() == null || config.getExtraParams().length <= 0)
			return;
		int skillId = Integer.parseInt(config.getExtraParams()[0]);
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		try {
			NpcBattleAI ai = null;
			if (soldier.skillHolder().getBattleAI() instanceof NpcBattleAI) {
				ai = (NpcBattleAI) soldier.skillHolder().getBattleAI();
			}
			if (ai != null)
				target = ai.selectTarget(skill);
			if (target != null && target.isDead() == skill.ifReliveFunction()) {
				soldier.autoBattle(skill, target);
				soldier.actionStart();
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
