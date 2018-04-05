package com.nucleus.logic.core.modules.battle.logic;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.player.service.ScriptService;

/**
 * 60 恢复主人的hp/mp/sp/法宝法力
 *
 * @author zhanhua.xu
 */
@Service
public class PassiveSkillLogic_60 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		BattleSoldier mainCharactorSoldier = soldier.team().battleSoldier(soldier.playerId());
		if (mainCharactorSoldier == null || mainCharactorSoldier.isDead())
			return;
		VideoActionTargetState state = new VideoActionTargetState(mainCharactorSoldier, 0, 0, false);
		for (int i = 0; i < config.getPropertys().length; i++) {
			int property = config.getPropertys()[i];
			int skillLevel = soldier.skillLevel(passiveSkill.getId());
			int value = (int) calcLevelValue(soldier, config.getPropertyEffectFormulas()[i], mainCharactorSoldier,skillLevel);
			if (property == BattleBasePropertyType.Hp.ordinal()) {
				mainCharactorSoldier.increaseHp(value);
				state.setHp(value);
			} else if (property == BattleBasePropertyType.Mp.ordinal()) {
				mainCharactorSoldier.increaseMp(value);
				state.setMp(value);
			} else if (property == BattleBasePropertyType.Sp.ordinal()) {
				mainCharactorSoldier.increaseSp(value);
				state.setSp(value);
			} else if (property == BattleBasePropertyType.MagicMana.ordinal()) {
				value = mainCharactorSoldier.increateMagicEquipmentMana();
				if (value > 0) 
					state.setMagicMana(value);
			}
		}
		if (timing == PassiveSkillLaunchTimingEnum.RoundStart)
			mainCharactorSoldier.currentVideoRound().readyAction().addTargetState(state);
		else if (context != null)
			context.skillAction().addTargetState(state);
	}

	private float calcLevelValue(BattleSoldier soldier, String formula, BattleSoldier target,int skillLevel) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("level", soldier.grade());
		params.put("skillLevel", skillLevel);
		params.put("target", target);
		return ScriptService.getInstance().calcuFloat("", formula, params, false);
	}
}
