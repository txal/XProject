package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;

/**
 * 服务端临时附加影响属性buff，客户端不需要表现
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_67 extends PassiveSkillLogic_22 {
	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (config.getTargetBuff() > 0) {
			BattleBuff buff = BattleBuff.get(config.getTargetBuff());
			if (buff != null)
				doAddBuff(buff, soldier, target, context, config, passiveSkill.getId());
		}
	}
}
