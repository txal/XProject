/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import com.nucleus.commons.logic.Logic;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * @author Omanhom
 * 
 */
public interface SkillLogic extends Logic {
	void fired(CommandContext commandContext);
}
