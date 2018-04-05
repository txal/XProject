package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 随机选择
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_0 extends AbstractTargetSelectLogic {
	@Override
	protected BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext) {
		int idx = RandomUtils.nextInt(fitList.size());
		return fitList.get(idx);
	}
}
