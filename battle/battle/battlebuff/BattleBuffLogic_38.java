/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_38;
import com.nucleus.player.service.ScriptService;

/**
 * buff会扣除玩家属性，当属性减少到0时，额外扣除第二种属性值 ；例如扣除魔法的buff，魔法为0就扣除Hp
 * 
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_38 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_38();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> paramMap = SplitUtils.split2StringMap(params, ";", ":");
		BuffLogicParam_38 param = (BuffLogicParam_38) buff.getBuffParam();
		if (paramMap.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(paramMap.get("skillId")));
		}
		if (paramMap.get("property") != null) {
			param.setProperty((Integer.parseInt(paramMap.get("property"))));
		}
		param.setFormula((paramMap.get("formula")));
	}

	@Override
	public void onRoundEnd(BattleBuffEntity buffEntity) {
		BuffLogicParam_38 param = (BuffLogicParam_38) buffEntity.battleBuff().getBuffParam();
		BattleSoldier target = buffEntity.getEffectSoldier();
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("target", target);
		params.put("skillLevel", buffEntity.getTriggerSoldier().skillLevel(param.getSkillId()));
		int[] effectProperties = buffEntity.battleBuff().getBattleBasePropertyTypes();
		String[] formulas = buffEntity.battleBuff().getBattleBasePropertyEffectFormulas();
		for (int i = 0; i < effectProperties.length; i++) {
			if (effectProperties[i] == BattleBasePropertyType.Mp.ordinal()) {
				int v = ScriptService.getInstance().calcuInt("", formulas[i], params, true);
				target.decreaseMp(v);
				target.currentVideoRound().endAction().addTargetState(new VideoActionTargetState(target, 0, v, false));
				if (target.mp() == 0) {
					extraDamage(param, target);
				}
			}
		}
		// 如果不清理掉，BattleBuffEntity.executeRoundBuff()里还会再次影响属性
		List<BattleBuffContext> contexts = buffEntity.getBuffContexts();
		if (!contexts.isEmpty())
			contexts.clear();
	}

	private void extraDamage(BuffLogicParam_38 param, BattleSoldier target) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("target", target);
		int value = ScriptService.getInstance().calcuInt("", param.getFormula(), params, true);
		if (param.getProperty() == BattleBasePropertyType.Hp.ordinal()) {
			target.decreaseHpByBuff(value);
			target.currentVideoRound().endAction().addTargetState(new VideoActionTargetState(target, value, 0, false));
		}
	}

}
