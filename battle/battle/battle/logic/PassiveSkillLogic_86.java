package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashSet;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Skill.SkillActionTypeEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 攻击配置门派的目标
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_86 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (context == null || config.getExtraParams().length <= 0)
			return;
		Set<Integer> factionIds = new HashSet<>();
		try {
			factionIds.addAll(SplitUtils.split2IntSet(config.getExtraParams()[0], ","));
		} catch (Exception e) {
			e.printStackTrace();
		}
		if (factionIds.isEmpty())
			return;
		BattleTeam enemyTeam = soldier.team().getEnemyTeam();

		Skill skill = context.skill();
		Set<Integer> targetBattleBuffIds = new HashSet<>();
		if (skill.getSkillActionType() == SkillActionTypeEnum.Seal.ordinal() || skill.getSkillActionType() == SkillActionTypeEnum.Support.ordinal())
			targetBattleBuffIds = skill.targetBattleBuffIds();
		outer: for (BattleSoldier s : enemyTeam.aliveSoldiers()) {
			if (s.isDead())
				continue;
			if (!targetBattleBuffIds.isEmpty()) {
				for (Integer targetBattleBuffId : targetBattleBuffIds) {
					if (s.buffHolder().hasBuff(targetBattleBuffId))
						continue outer;
				}
			}
			if (factionIds.contains(s.factionId())) {
				context.populateTarget(s);
				break;
			}
		}
	}
}
