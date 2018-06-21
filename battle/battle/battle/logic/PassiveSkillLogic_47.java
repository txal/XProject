package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 自身死亡,对应的怪物回合末逃跑
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_47 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!soldier.isDead())
			return;
		if (config.getExtraParams() == null)
			return;
		for (String strMonsterId : config.getExtraParams()) {
			int monsterId = Integer.parseInt(strMonsterId);
			if (monsterId <= 0)
				continue;
			for (BattleSoldier s : soldier.team().aliveSoldiers()) {
				if (s.monsterId() == monsterId) {
					s.forceLeaveBattle(true);
					s.initForceSkill(Skill.retreatSkillId());
				}
			}
		}
	}
}
