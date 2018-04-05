package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattlePlayerSoldierInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 恢复宠物的hp/mp/sp
 *
 * @author hwy
 */
@Service
public class PassiveSkillLogic_96 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleTeam team = soldier.battleTeam();
		BattlePlayerSoldierInfo soldierInfo = team.soldiersByPlayer(soldier.getId());
		long petId = soldierInfo.petSoldierId();
		BattleSoldier petSoldier = team.battleSoldier(petId);
		if (petSoldier == null || petSoldier.isDead() || petSoldier.isLeave())
			return;
		VideoActionTargetState state = new VideoActionTargetState(petSoldier, 0, 0, false);
		for (int i = 0; i < config.getPropertys().length; i++) {
			int property = config.getPropertys()[i];
			int skillLevel = soldier.skillLevel(passiveSkill.getId());
			int value = (int) calcLevelValue(soldier, config.getPropertyEffectFormulas()[i], petSoldier, skillLevel, context.getDamageOutput());
			if (property == BattleBasePropertyType.Hp.ordinal()) {
				petSoldier.increaseHp(value);
				state.setHp(value);
			} else if (property == BattleBasePropertyType.Mp.ordinal()) {
				petSoldier.increaseMp(value);
				state.setMp(value);
			} else if (property == BattleBasePropertyType.Sp.ordinal()) {
				petSoldier.increaseSp(value);
				state.setSp(value);
			}
		}
		if (timing == PassiveSkillLaunchTimingEnum.RoundStart)
			petSoldier.currentVideoRound().readyAction().addTargetState(state);
		else if (context != null)
			context.skillAction().addTargetState(state);
	}

	private float calcLevelValue(BattleSoldier soldier, String formula, BattleSoldier target, int skillLevel, int damage) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", soldier.grade());
		params.put("skillLevel", skillLevel);
		params.put("target", target);
		params.put("damage", damage);
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
