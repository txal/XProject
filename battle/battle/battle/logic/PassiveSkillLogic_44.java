package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 凝视:攻击敌方特定怪
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_44 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null)
			return;
		if (!context.skill().ifHpLossFunction())
			return;
		if (config.getExtraParams() == null)
			return;
		int monsterId = 0;
		try {
			monsterId = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			e.printStackTrace();
		}
		if (monsterId <= 0)
			return;
		BattleTeam enemyTeam = soldier.team().getEnemyTeam();
		for (BattleSoldier s : enemyTeam.aliveSoldiers()) {
			if (s.isDead())
				continue;
			if (s.monsterId() == monsterId) {
				context.populateTarget(s);
				break;
			}
		}
	}
}
