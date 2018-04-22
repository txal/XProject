/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Map;

import com.nucleus.commons.logic.Logic;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * @author wgy
 * 
 */
public interface SkillAiLogic extends Logic {
	/**
	 * 获取所有可用目标
	 * 
	 * @return
	 */
	public Map<Long, BattleSoldier> availableTargets(CommandContext commandContext);

	/**
	 * 选择技能目标
	 * 
	 * @return
	 */
	public List<SkillTargetPolicy> selectTargets(CommandContext commandContext);
}
