/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BuffPropertyEnum;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_37;
import com.nucleus.player.service.ScriptService;

/**
 * 获得buff 之后改变buff某些属性
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_37 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_37();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> paramMap = SplitUtils.split2StringMap(params, ";", ":");
		BuffLogicParam_37 param = (BuffLogicParam_37) buff.getBuffParam();
		if (paramMap.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(paramMap.get("skillId")));
		}
		if (paramMap.get("buffPro") != null) {
			param.setBuffPro(Integer.parseInt(paramMap.get("buffPro")));
		}
		param.setFormula((paramMap.get("formula")));
	}

	@Override
	public void afterGetBuff(BattleBuffEntity buffEntity) {
		BuffLogicParam_37 param = (BuffLogicParam_37) buffEntity.battleBuff().getBuffParam();
		int skillLevel = buffEntity.getTriggerSoldier().skillLevel(param.getSkillId());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("target", buffEntity.getEffectSoldier());
		int value = ScriptService.getInstance().calcuInt("", param.getFormula(), params, false);
		if (param.getBuffPro() == BuffPropertyEnum.Rounds.ordinal()) {
			buffEntity.setBuffPersistRound(value);
		}
	}

}
