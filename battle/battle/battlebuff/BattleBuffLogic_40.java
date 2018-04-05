package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_40;
import com.nucleus.player.service.ScriptService;

/**
 * 反弹伤害并扣除使用次数
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_40 extends BattleBuffLogicAdapter {
	@Autowired(required = false)
	private BattleBuffLogic_28 reduceLogic;

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_40();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> paramMap = SplitUtils.split2StringMap(params, ";", ":");
		BuffLogicParam_40 param = (BuffLogicParam_40) buff.getBuffParam();
		if (paramMap.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(paramMap.get("skillId")));
		}
		param.setReboundDamage((paramMap.get("reboundDamage")));
	}

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam_40 param = (BuffLogicParam_40) buffEntity.battleBuff().getBuffParam();
		if (param == null)
			return;
		int skillLevel = buffEntity.getEffectSoldier().skillLevel(param.getSkillId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("damage", commandContext.getDamageOutput());
		int damage = ScriptService.getInstance().calcuInt("BattleBuffLogic_40.underAttack", param.getReboundDamage(), params, false);
		BattleSoldier trigger = commandContext.trigger();
		trigger.decreaseHp(damage, commandContext.target());
		commandContext.skillAction().addTargetState(new VideoActionTargetState(trigger, damage, 0, false));
		if (reduceLogic != null)
			reduceLogic.underAttack(commandContext, buffEntity);
	}
}
