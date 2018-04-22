package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.apache.commons.beanutils.BeanUtils;

import com.nucleus.commons.data.ErrorCodes;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

public abstract class AbstractTargetSelectLogic implements ITargetSelectLogic {

	@Override
	public BattleSoldier select(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		List<BattleSoldier> fitList = filter(availableTargets, commandContext, ignoreSoldierIds);
		if (fitList.isEmpty())
			return null;
		return doSelect(fitList, commandContext);
	}

	protected abstract BattleSoldier doSelect(List<BattleSoldier> fitList, CommandContext commandContext);

	/**
	 * 过滤不符合条件的目标
	 * 
	 * @param availableTargets
	 * @param commandContext
	 * @param ignoreSoldierIds
	 * @return
	 */
	@Override
	public List<BattleSoldier> filter(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		if (availableTargets.isEmpty())
			return Collections.emptyList();
		List<BattleSoldier> fitList = new ArrayList<BattleSoldier>();// 符合条件的id列表
		Skill skill = commandContext.skill();
		for (Iterator<BattleSoldier> it = availableTargets.values().iterator(); it.hasNext();) {
			BattleSoldier soldier = it.next();
			if (soldier == null)
				continue;
			if (!skill.isDeadTriggerSkill()) {
				if (skill.isUseAliveTarget() == soldier.isDead())
					continue;
			}
			if (ignoreSoldierIds != null && ignoreSoldierIds.contains(soldier.getId()))
				continue;
			if (soldier.buffHolder().isHidden() && !skill.isCanApplyToHiddenTarget()) {
				// 当前技能对隐身目标无效的情况下,判断是否有破隐身的被动技能,如有照打
				commandContext.trigger().skillHolder().passiveSkillEffectByTiming(soldier, commandContext, PassiveSkillLaunchTimingEnum.SelectTarget);
				if (!commandContext.isHiddenFail())
					continue;
			}
			fitList.add(soldier);
		}
		return fitList;
	}

	@Override
	public void initParams(Skill skill, String targetSelectParamStr) {
		TargetSelectLogicParam param = createParam();
		skill.TargetSelectLogicParam(param);
		doInitParam(skill, targetSelectParamStr);
	}

	protected TargetSelectLogicParam createParam() {
		// TODO Auto-generated method stub
		return null;
	}

	protected void doInitParam(Skill skill, String targetSelectParamStr) {
		try {
			Map<String, Integer> paramMap = SplitUtils.split2SIMap(targetSelectParamStr, ",", ":");
			BeanUtils.populate(skill.selectLogicParam(), paramMap);
		} catch (Exception ex) {
			throw new GeneralException(ErrorCodes.DATA_SET_NOT_NULL, skill.getClass().getSimpleName(), skill.getTargetSelectLogicId());
		}
	}

	@Override
	public List<SkillTargetInfo> skillTargetInfos(Skill skill) {
		return skill.skillTargetInfos();
	}
}
