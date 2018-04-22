package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.NpcActiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 上回合死多少怪本回合招多少怪
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_12 extends SkillLogicAdapter {
	@Autowired
	private CallMonsterService callMonsterService;

	@Override
	protected int beforeFired(CommandContext commandContext) {
		int skillStatusCode = AppSkillActionStatusCode.Ordinary;
		VideoSkillAction skillAction = commandContext.skillAction();
		skillAction.setSkillStatusCode(skillStatusCode);
		skillAction.setSkillId(commandContext.skill().getId());
		return skillStatusCode;
	}

	@Override
	public void doFired(CommandContext commandContext) {
		Skill s = commandContext.skill();
		if (!(s instanceof NpcActiveSkill))
			return;
		NpcActiveSkill skill = (NpcActiveSkill) s;
		if (skill.callMonsterIds().isEmpty())
			return;
		BattleSoldier trigger = commandContext.trigger();
		int count = trigger.team().getCurrentRoundDeadCount();
		if (count <= 0)
			return;
		for (int i = 0; i < count; i++) {
			Monster monster = Monster.get(RandomUtils.next(skill.callMonsterIds()));
			if (monster == null)
				continue;
			BattleSoldier soldier = callMonsterService.doCall(trigger, monster, commandContext.skillAction(), skill, true, 0);
			if (soldier == null)
				break;
		}
	}

}
