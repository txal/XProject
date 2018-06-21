package com.nucleus.logic.core.modules.battle.logic;

import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 禁锢敌方速度最快目标
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_72 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getTargetBuff() < 1)
			return;
		BattleBuff buff = BattleBuff.get(config.getTargetBuff());
		if (buff == null)
			return;
		Optional<BattleSoldier> opt = soldier.team().getEnemyTeam().aliveSoldiers().stream().filter(s -> !s.buffHolder().hasBanBuff()).sorted(TargetSelectLogic_3.speedComparator).findFirst();
		if (!opt.isPresent())
			return;
		target = opt.get();
		final int round = Integer.parseInt(config.getExtraParams()[0]);
		BattleBuffEntity buffEntity = new BattleBuffEntity(buff, soldier, target, passiveSkill.getId(), round);
		if (buffEntity != null) {
			target.buffHolder().addBuff(buffEntity);
			VideoBuffAddTargetState state = new VideoBuffAddTargetState(buffEntity);
			if (context != null)
				context.skillAction().addTargetState(state);
		}
	}
}
