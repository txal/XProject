package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Optional;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 选择特定主角
 * 
 * @author wgy
 *
 */
@Service
public class TargetSelectLogic_6 extends AbstractTargetSelectLogic {

	@Override
	protected BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext) {
		Optional<BattleSoldier> opt = fitList.stream().filter(s -> s.getId() == commandContext.trigger().playerId()).findFirst();
		if (opt.isPresent())
			return opt.get();
		return null;
	}

}
