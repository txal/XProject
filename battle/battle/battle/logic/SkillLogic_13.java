package com.nucleus.logic.core.modules.battle.logic;

import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetStateGroup;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 恐吓宠物
 * 
 * @author hwy
 * 
 */
@Service
public class SkillLogic_13 extends SkillLogicAdapter {

	@Override
	public void doFired(CommandContext commandContext) {
		Skill skill = commandContext.skill();
		BattleSoldier trigger = commandContext.trigger();
		BattleSoldier target = commandContext.target();

		if (target == null) {
			if (skill.getSelfNextRoundForceSkillId() > 0) {
				trigger.initForceSkill(skill.getSelfNextRoundForceSkillId());
				trigger.setForceTarget(commandContext.target());
			}
			SkillAiLogic skillAiLogic = skill.skillAi().skillAiLogic();
			List<SkillTargetPolicy> targetPolicys = skillAiLogic.selectTargets(commandContext);
			if (targetPolicys.isEmpty())
				return;
			commandContext.setFirstTarget(commandContext.target() != null ? commandContext.target() : targetPolicys.get(0).getTarget());
			target = targetPolicys.get(0).getTarget();
		}
		if (!target.ifPet())
			return;

		int skillLevel = trigger.skillLevel(skill.getId());
		boolean success = RandomUtils.baseRandomHit(skill.gainHitRate(skillLevel));
		if (success) {
			target.forceLeaveBattle(true);
			target.initForceSkill(Skill.retreatSkillId());
		}

		commandContext.skillAction().addTargetStateGroup(new VideoTargetStateGroup());
		commandContext.skillAction().addFirstTargetState(new VideoActionTargetState(target, 0, 0, commandContext.isCrit()));
		trigger.addAttackTimes(commandContext.totalAttackCount(), skill.ifMagicAttack());
	}
}
