package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;
import java.util.Map;
import java.util.Set;

import com.nucleus.commons.logic.Logic;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

public interface ITargetSelectLogic extends Logic {
	/**
	 * 按某种规则选择一个目标
	 * 
	 * @param availableTargets
	 *            备选目标集合
	 * @param commandContext
	 *            技能指令上下文
	 * @param ignoreSoldierIds
	 *            忽略目标id列表
	 * @return 符合条件的一个目标
	 */
	public BattleSoldier select(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds);

	public List<BattleSoldier> filter(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds);

	public List<SkillTargetInfo> skillTargetInfos(Skill skill);

	public void initParams(Skill skill, String targetSelectParamStr);
}
