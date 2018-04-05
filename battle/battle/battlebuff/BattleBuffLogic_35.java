/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_35;
import com.nucleus.player.service.ScriptService;

/**
 * 影响反击伤害变动率
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_35 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_35();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> properties = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_35 param = (BuffLogicParam_35) buff.getBuffParam();
		param.setDamageVaryRate(properties.get("damageVaryRate"));
		if (properties.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(properties.get("skillId")));
		}
	}

	@Override
	public void onStrikeBack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam p = buffEntity.battleBuff().getBuffParam();
		if (!(p instanceof BuffLogicParam_35))
			return;
		BuffLogicParam_35 param = (BuffLogicParam_35) p;

		BattleSoldier trigger = buffEntity.getTriggerSoldier();
		int skillLevel = trigger.skillLevel(param.getSkillId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		Float damageVaryRate = ScriptService.getInstance().calcuFloat("", param.getDamageVaryRate(), params, false);
		commandContext.setCurDamageVaryRate(damageVaryRate);
	}

}
