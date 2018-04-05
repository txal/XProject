package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 攻击倒地目标
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_87 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null || !context.skill().ifHpLossFunction())
			return;
		BattleTeam enemyTeam = soldier.team().getEnemyTeam();
		for (BattleSoldier s : enemyTeam.roundQueue()) {
			if (s.isDead()) {
				context.populateTarget(s);
				break;
			}
		}
	}
}
