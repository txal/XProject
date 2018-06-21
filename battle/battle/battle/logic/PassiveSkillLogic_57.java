package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 必然反击：随机选择主角或宠物反击(世界boss专用)
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_57 extends AbstractPassiveSkillLogic {
	@Override
	public boolean launchable(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!super.launchable(soldier, target, context, config, timing, passiveSkill))
			return false;
		if (context.isStrokeBack())
			return false;
		if (!context.skill().isStrikebackable())
			return false;// 当前技能不能被反击
		return true;
	}

	@Override
	protected void doApply(BattleSoldier soldier, BattleSoldier target, CommandContext context, PassiveSkillConfig config, PassiveSkillLaunchTimingEnum timing, IPassiveSkill passiveSkill) {
		if (!target.battleTeam().playerTeam())
			return;
		int[] skillIds = SplitUtils.split2IntArray(config.getExtraParams()[0], ",");
		int idx = RandomUtils.nextInt(0, skillIds.length - 1);
		int skillId = skillIds[idx];
		Skill skill = Skill.get(skillId);
		if (skill == null)
			return;
		int[] params = SplitUtils.split2IntArray(config.getExtraParams()[1], ",");
		List<BattleSoldier> mainCharactors = new ArrayList<>();
		List<BattleSoldier> pets = new ArrayList<>();
		findSuitSoldier(target.battleTeam(), mainCharactors, pets);
		BattleSoldier strokeBackTarget = null;
		boolean hitMainCharactor = RandomUtils.baseRandomHit(params[0]);// 是否反击主角
		if (hitMainCharactor && !mainCharactors.isEmpty()) {
			strokeBackTarget = RandomUtils.next(mainCharactors);
		} else {
			strokeBackTarget = RandomUtils.next(pets);
		}
		if (strokeBackTarget == null)
			return;
		VideoSkillAction strikeSkillAction = new VideoSkillAction(soldier.getId());
		context.setStrokeBack(true);
		context.skillAction().currentTargetStateGroup().setStrikeBackAction(strikeSkillAction);
		CommandContext newContext = new CommandContext(soldier, skill, strokeBackTarget);
		newContext.setStrokeBack(true);
		newContext.setHiddenFail(true);// 可以反击隐身目标
		newContext.setStrikeSkillAction(strikeSkillAction);
		newContext.setCritRatePlus(1);// 百分百暴击
		newContext.setCurDamageVaryRate(1);
		CommandContext oldContext = soldier.getCommandContext();
		soldier.initCommandContext(newContext);
		skill.fired(newContext);
		soldier.destoryCommandContext();
		if (oldContext != null)
			soldier.initCommandContext(oldContext);// 执行完反击把之前的指令设置回去
	}

	private void findSuitSoldier(BattleTeam team, List<BattleSoldier> mainCharactors, List<BattleSoldier> pets) {
		for (BattleSoldier s : team.aliveSoldiers()) {
			if (s.ifMainCharactor())
				mainCharactors.add(s);
			else if (s.ifPet())
				pets.add(s);
		}
	}
}
