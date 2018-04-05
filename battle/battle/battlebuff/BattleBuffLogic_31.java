/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_31;
import com.nucleus.player.service.ScriptService;

/**
 * 相同buff连锁伤害
 * 
 * @author hwy
 *
 */
@Service
public class BattleBuffLogic_31 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_31();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> params = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_31 param = (BuffLogicParam_31) buff.getBuffParam();
		param.setSkillIds(SplitUtils.split2IntSet(params.get("skillIds"), "\\|"));
		param.setRateFormula(params.get("rate"));
	}

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		chainDamage(commandContext, buffEntity);
	}

	/**
	 * 连锁伤害
	 * 
	 * @param commandContext
	 * @param buffEntity
	 */
	private void chainDamage(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (commandContext == null)
			return;
		BuffLogicParam_31 param = (BuffLogicParam_31) buffEntity.battleBuff().getBuffParam();
		// 会触发连锁伤害的技能
		Set<Integer> skillIds = param.getSkillIds();
		if (!skillIds.contains(commandContext.skill().getId()))
			return;
		float rate = culRate(buffEntity, param.getRateFormula());
		int damage = commandContext.getDamageOutput();
		int buffId = buffEntity.battleBuffId();
		int damageValue = (int) Math.floor(damage * rate);
		BattleSoldier target = buffEntity.getEffectSoldier();
		List<BattleSoldier> soldiers = target.team().aliveSoldiers();
		for (BattleSoldier soldier : soldiers) {
			if (soldier.getId() == target.getId() || soldier.buffHolder().hasBuff(buffId))
				continue;
			soldier.decreaseHp(damageValue);
			commandContext.skillAction().addTargetState(new VideoActionTargetState(soldier, damageValue, 0, false));
		}
	}

	private float culRate(BattleBuffEntity buffEntity, String formula) {
		if (StringUtils.isBlank(formula))
			return 0;

		int skillId = buffEntity.skillId();
		int skillLevel = buffEntity.getTriggerSoldier().skillLevel(skillId);
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		int v = ScriptService.getInstance().calcuInt("", formula, params, false);
		return v;
	}
}
