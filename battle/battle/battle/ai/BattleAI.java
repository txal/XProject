package com.nucleus.logic.core.modules.battle.ai;

import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 *
 * Created by Tony on 15/6/17.
 */
public interface BattleAI {

	CommandContext selectCommand();

	boolean onActionStart(BattleSoldier soldier, CommandContext commandContext);
}
