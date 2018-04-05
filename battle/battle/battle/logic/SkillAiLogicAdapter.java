/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * @author liguo
 * 
 */
public abstract class SkillAiLogicAdapter implements SkillAiLogic {
	/** 群攻技能策略标识 */
	protected final static int MASS_TARGET_IND = 0;
	/** 主攻击目标标记 */
	protected final static int MAIN_TARGET_IND = 1;

	@Override
	public List<SkillTargetPolicy> selectTargets(CommandContext commandContext) {
		if (commandContext == null)
			return Collections.emptyList();
		Map<Long, BattleSoldier> availableTargets = this.availableTargets(commandContext);
		availableTargets = commandContext.skill().filter(availableTargets);
		if (availableTargets == null || availableTargets.isEmpty())
			return Collections.emptyList();
		// 缓存已经选择的soldierId,后续选择目标会忽略该列表中的soldier
		Set<Long> selectedSoldierIds = new HashSet<Long>();
		Skill skill = commandContext.skill();
		BattleSoldier mainTarget = commandContext.target();
		if (mainTarget == null)
			mainTarget = this.pickNextTarget(availableTargets, commandContext, selectedSoldierIds);
		else if (mainTarget.isLeave() || (skill.isUseAliveTarget() && !skill.isDeadTriggerSkill() && mainTarget.isDead())) {
			selectedSoldierIds.add(mainTarget.getId());
			mainTarget = this.pickNextTarget(availableTargets, commandContext, selectedSoldierIds);
		} else if ((mainTarget.buffHolder().isHidden() && !skill.isCanApplyToHiddenTarget())) {// 目标是隐藏的,但是该技能不能攻击隐藏目标,也要重新找目标
			// 当前技能对隐身目标无效的情况下,判断是否有破隐身的被动技能,如有照打
			commandContext.trigger().skillHolder().passiveSkillEffectByTiming(mainTarget, commandContext, PassiveSkillLaunchTimingEnum.SelectTarget);
			if (!commandContext.isHiddenFail()) {// mainTarget隐身成功,找另一个目标
				selectedSoldierIds.add(mainTarget.getId());
				mainTarget = this.pickNextTarget(availableTargets, commandContext, selectedSoldierIds);
			}
		}
		if (mainTarget == null)
			return Collections.emptyList();
		BattleSoldier trigger = commandContext.trigger();
		int lv = trigger.skillHolder().factionSkillLevel(skill.getFactionSkillId());
		List<SkillTargetPolicy> policys = new ArrayList<SkillTargetPolicy>();
		for (Iterator<SkillTargetInfo> it = skill.skillTargetInfos().iterator(); it.hasNext();) {
			SkillTargetInfo policy = it.next();
			if (policy == null)
				continue;
			// 不符合等级需求
			if (lv < policy.getSkillPreqLevel())
				continue;
			int num = policy.getTargetNum();// 第n个目标
			if (num == MASS_TARGET_IND) {// 群攻技能标识(0),一次性选择全部目标
				return possibleTargetSoldiers(commandContext, availableTargets, policy);
			} else {
				BattleSoldier target = null;
				if (num == MAIN_TARGET_IND)
					target = mainTarget;
				else
					target = this.pickNextTarget(availableTargets, commandContext, selectedSoldierIds);
				if (target == null)
					break;
				selectedSoldierIds.add(target.getId());
				policys.add(new SkillTargetPolicy(target, policy));
			}
		}
		return policys;
	}

	/**
	 * 全部符合条件目标
	 * 
	 * @param commandContext
	 * @param availableTargets
	 * @param skillTargetInfo
	 * @return
	 */
	protected List<SkillTargetPolicy> possibleTargetSoldiers(CommandContext commandContext, Map<Long, BattleSoldier> availableTargets, SkillTargetInfo skillTargetInfo) {
		List<BattleSoldier> soldiers = filter(commandContext, availableTargets);
		List<SkillTargetPolicy> targetPolicys = new ArrayList<SkillTargetPolicy>();
		boolean needAlive = commandContext.skill().isUseAliveTarget();
		boolean deadSKil = commandContext.skill().isDeadTriggerSkill();
		for (BattleSoldier soldier : soldiers) {
			if (soldier == null)
				continue;
			if (!deadSKil) {
				if (needAlive == soldier.isDead())
					continue;
			}
			targetPolicys.add(new SkillTargetPolicy(soldier, skillTargetInfo));
		}
		return targetPolicys;
	}

	private List<BattleSoldier> filter(CommandContext commandContext, Map<Long, BattleSoldier> availableTargets) {
		List<BattleSoldier> list = new ArrayList<>(availableTargets.values());
		ITargetSelectLogic logic = commandContext.skill().targetSelectLogic();
		if (logic == null)
			return list;
		return logic.filter(availableTargets, commandContext, null);
	}

	/**
	 * 随机下一个目标
	 * 
	 * @param availableTargets
	 * @param commandContext
	 * @param ignoreSoldierIds
	 * @return
	 */
	protected BattleSoldier pickNextTarget(Map<Long, BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		ITargetSelectLogic logic = commandContext.skill().targetSelectLogic();
		if (logic == null)
			return null;
		return logic.select(availableTargets, commandContext, ignoreSoldierIds);
	}
}
