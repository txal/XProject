package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 攻击配置血量的目标
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_85 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null || !context.skill().ifHpLossFunction() || config.getExtraParams().length <= 0)
			return;
		int order = 0;
		try {
			order = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			e.printStackTrace();
		}
		BattleTeam enemyTeam = soldier.team().getEnemyTeam();
		BattleSoldier maxHpSoldier = null;
		BattleSoldier minHpSoldier = null;
		for (BattleSoldier s : enemyTeam.aliveSoldiers()) {
			if (s.isDead())
				continue;
			// hp最大士兵
			if (maxHpSoldier == null) {
				maxHpSoldier = s;
			} else {
				if (s.hp() > maxHpSoldier.hp())
					maxHpSoldier = s;
			}
			// hp最小士兵
			if (minHpSoldier == null) {
				minHpSoldier = s;
			} else {
				if (s.hp() < minHpSoldier.hp())
					minHpSoldier = s;
			}
		}
		if (order == 0 && minHpSoldier != null)
			context.populateTarget(minHpSoldier);
		else if (order == 1 && maxHpSoldier != null)
			context.populateTarget(maxHpSoldier);
	}
}
