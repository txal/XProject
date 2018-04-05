package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 随机对对目标的队友进行溅射伤害
 * 
 * @author wangyu
 *
 */
@Service
public class PassiveSkillLogic_93 extends AbstractPassiveSkillLogic {

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		int damage = 0;
		List<BattleSoldier> seleTarget = seleTarget(soldier, target, context, config);
		for (BattleSoldier battleSoldier : seleTarget) {
			damage = curDamage(soldier, target, context, config, passiveSkill);
			if (damage == 0) {
				continue;
			}
			VideoActionTargetState state = new VideoActionTargetState(battleSoldier, damage, 0, context.isCrit(), 0);
			context.skillAction().addTargetState(state);
			battleSoldier.decreaseHp(damage, soldier);
			// 可能扣血之前是没有leave，扣血后就leave了，所以要做同步
			state.setLeave(battleSoldier.isLeave());
		}
	}

	protected int curDamage(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, IPassiveSkill passiveSkill) {
		String[] params = config.getExtraParams();
		if (params == null || params.length == 0) {
			return 0;
		}
		float[] rateArr = SplitUtils.split2FloatArray(params[0], ",");
		float damageNum = 0;
		if (target.isDead()) {
			damageNum = rateArr[1];
		} else {
			damageNum = rateArr[0];
		}
		int damage = (int) (context.getDamageOutput() * damageNum);
		return damage;
	}

	protected List<BattleSoldier> seleTarget(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config) {
		List<BattleSoldier> allSele = new ArrayList<BattleSoldier>();
		String[] params = config.getExtraParams();
		if (params == null || params.length <= 1) {
			return allSele;
		}
		int[] seleCondition = SplitUtils.split2IntArray(params[1], ",");
		if (target != null) {
			Set<Long> ignoreMembers = new HashSet<Long>();
			ignoreMembers.add(soldier.getId());
			ignoreMembers.add(target.getId());
			List<BattleSoldier> filteredMember = filter(target.team().aliveSoldiers(), context, ignoreMembers);

			for (int i = 0; i < seleCondition[0]; i++) {
				BattleSoldier teamMember = minHpSoldier(filteredMember, ignoreMembers);
				if (teamMember != null && !teamMember.isDead() && !teamMember.isLeave()) {
					allSele.add(teamMember);
					ignoreMembers.add(teamMember.getId());
				}
			}
		}
		return allSele;
	}

	public List<BattleSoldier> filter(List<BattleSoldier> availableTargets, CommandContext commandContext, Set<Long> ignoreSoldierIds) {
		if (availableTargets.isEmpty())
			return Collections.emptyList();
		List<BattleSoldier> fitList = new ArrayList<BattleSoldier>();// 符合条件的id列表
		Skill skill = commandContext.skill();
		for (Iterator<BattleSoldier> it = availableTargets.iterator(); it.hasNext();) {
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

	protected BattleSoldier minHpSoldier(List<BattleSoldier> allMember, Set<Long> ignoreSoldierIds) {
		BattleSoldier seleSoldier = null;
		int minHp = 0;
		if (allMember == null || allMember.isEmpty()) {
			return seleSoldier;
		}
		for (BattleSoldier battleSoldier : allMember) {
			if (ignoreSoldierIds.contains(battleSoldier.getId()))
				continue;
			if (minHp == 0) {
				minHp = battleSoldier.hp();
				seleSoldier = battleSoldier;
				continue;
			}
			if (battleSoldier.hp() < minHp) {
				minHp = battleSoldier.hp();
				seleSoldier = battleSoldier;
			}
		}
		return seleSoldier;
	}
}
