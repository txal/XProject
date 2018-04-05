/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.Map;

import org.apache.commons.lang3.StringUtils;
import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 伤害吸收
 * 
 * @author xitao.huang
 *
 */
@Service
public class BattleBuffLogic_13 extends BattleBuffLogicAdapter {

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		if (buffEntity == null)
			return;
		BattleSoldier target = commandContext.target();
		BattleBuff battleBuff = buffEntity.battleBuff();
		int damage = Math.abs(commandContext.getDamageOutput());
		int skillId = buffEntity.skillId();
		int skillLevel = target.skillLevel(skillId);
		int[] basePropertyTypes = battleBuff.getBattleBasePropertyTypes();
		for (int i = 0; i < basePropertyTypes.length; i++) {
			int basePropertyType = basePropertyTypes[i];
			String formula = battleBuff.getBattleBasePropertyEffectFormulas()[i];
			int effectValue = 0;
			if (StringUtils.isNotBlank(formula)) {
				Map<String, Object> params = new HashMap<String, Object>();
				params.put("damage", damage);
				params.put("skillLevel", skillLevel);
				effectValue = ScriptService.getInstance().calcuInt("BattleBuffLogic_13.underAttack", formula, params, false);
			}
			if (basePropertyType == BattleBasePropertyType.Hp.ordinal()) {
				target.increaseHp(effectValue);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(target, effectValue, 0, false));
			} else if (basePropertyType == BattleBasePropertyType.Mp.ordinal()) {
				target.increaseMp(effectValue);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(target, 0, effectValue, false));
			} else if (basePropertyType == BattleBasePropertyType.Sp.ordinal()) {
				target.increaseSp(effectValue);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(target, 0, 0, false, effectValue));
			}
		}
	}

}
