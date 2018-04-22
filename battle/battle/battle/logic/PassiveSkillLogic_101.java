package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.log.LogUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;

/**
 * 给宠物增加buff
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLogic_101 extends PassiveSkillLogic_31 {

	@Override
	protected int curRounds(BattleSoldier soldier, PassiveSkillConfig config) {
		int persistRound = 0;
		try {
			persistRound = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			LogUtils.errorLog(e);
		}
		return persistRound;
	}
}
