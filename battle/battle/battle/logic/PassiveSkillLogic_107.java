package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 存在指定技能时，收到的伤害为攻击次数*固定参数
 *
 * @author yzg
 */
@Service
public class PassiveSkillLogic_107 extends AbstractPassiveSkillLogic {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		context.setDamageOutput(-1 * Integer.valueOf(config.getExtraParams()[0]));
		if (soldier.monsterId() == StaticConfig.get(AppStaticConfigs.FIND_DOG_ID).getAsInt(55120)) {
			if (soldier.roundBeAttackTimes() + 1 >= StaticConfig.get(AppStaticConfigs.SCENE_DOG_GO_DIE_COUNT).getAsInt(7)) {
				soldier.battleBaseProperties().setHp(1 * Integer.valueOf(config.getExtraParams()[0]));
			}
		}
	}
}
