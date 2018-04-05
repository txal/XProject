/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_29;
import com.nucleus.logic.core.modules.spell.SpellEffectCalculator;
import com.nucleus.player.service.ScriptService;

/**
 * 受击后减少buff触发次数
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_29 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_29();
	}

	@Override
	public void attackDead(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BattleSoldier target = buffEntity.getEffectSoldier();
		if (target.isDead()) {
			BattleSoldier trigger = buffEntity.getTriggerSoldier();
			BuffLogicParam_29 param = (BuffLogicParam_29) buffEntity.battleBuff().getBuffParam();

			int hp = calcFormula(trigger, buffEntity, param.getDeadFormula());
			target.increaseHp(hp);
			target.setLeave(false);
			VideoActionTargetState state = new VideoActionTargetState(target, hp, 0, false);
			commandContext.skillAction().addTargetState(state);

			String key = "buffCount";
			Map<String, Object> meta = buffEntity.getBattleMeta();
			int buffCount = (Integer) meta.getOrDefault(key, buffEntity.battleBuff().getBuffsEffectTimes());
			buffCount -= 1;
			meta.put(key, buffCount);
			if (buffCount <= 0) {
				meta.remove(key);
				int buffId = buffEntity.battleBuffId();
				target.buffHolder().removeBuffById(buffId);
				commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(target, buffId));
			}
		}
	}

	@Override
	public void onRemove(BattleBuffEntity buffEntity) {
		String key = "buffCount";
		Map<String, Object> meta = buffEntity.getBattleMeta();
		if (!meta.containsKey(key)) {
			BuffLogicParam_29 param = (BuffLogicParam_29) buffEntity.battleBuff().getBuffParam();
			BattleSoldier target = buffEntity.getEffectSoldier();
			BattleSoldier trigger = buffEntity.getTriggerSoldier();
			int hp = calcFormula(trigger, buffEntity, param.getRmFormula());
			target.increaseHp(hp);
			VideoActionTargetState state = new VideoActionTargetState(target, hp, 0, false);
			target.currentVideoRound().endAction().addTargetState(state);
		}
	}

	private int calcFormula(BattleSoldier soldier, BattleBuffEntity buffEntity, String formula) {
		if (StringUtils.isBlank(formula))
			return 0;

		int skillId = buffEntity.skillId();
		int skillLevel = buffEntity.getTriggerSoldier().skillLevel(skillId);
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		v = spellHealEffect(soldier, v);
		return v;
	}

	/**
	 * 修炼技能 治疗加成
	 * 
	 * @param skill
	 * @param trigger
	 * @param target
	 * @param hpVaryAmount
	 * @return
	 */
	private int spellHealEffect(BattleSoldier soldier, int hpVaryAmount) {
		if (hpVaryAmount < 0) {
			return hpVaryAmount;
		}
		float finalValue = SpellEffectCalculator.getInstance().healEffect(soldier, hpVaryAmount);
		return (int) finalValue;
	}
}
