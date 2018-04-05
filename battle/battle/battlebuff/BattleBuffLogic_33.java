/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_33;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;
import com.nucleus.player.service.ScriptService;

/**
 * 影响法术攻击魔法值消耗
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_33 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_33();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> properties = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_33 param = (BuffLogicParam_33) buff.getBuffParam();
		param.setMpSpendFormula(properties.get("mpSpendFormula"));
		if (properties.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(properties.get("skillId")));
		}
	}

	@Override
	public void beforeAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (commandContext.skill().battleCommandType() != BattleCommandType.Skill) {
			return;
		}
		BuffLogicParam_33 param = (BuffLogicParam_33) buffEntity.battleBuff().getBuffParam();
		BattleSoldier trigger = buffEntity.getTriggerSoldier();
		int skillLevel = trigger.skillLevel(param.getSkillId());
		int mpSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, commandContext.skill().getSpendMpFormula(), commandContext.skill());
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("mpSpend", mpSpent);

		int mpValue = ScriptService.getInstance().calcuInt("", param.getMpSpendFormula(), params, false);
		commandContext.setMpSpent(mpValue);
	}

}
