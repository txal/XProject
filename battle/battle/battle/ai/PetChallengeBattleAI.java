package com.nucleus.logic.core.modules.battle.ai;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * 宠物竞技场战斗中ai(防守方)
 * 
 * @author wgy
 *
 */
public class PetChallengeBattleAI extends BattleAIAdapter {
	private final BattleSoldier soldier;

	public PetChallengeBattleAI(final BattleSoldier soldier) {
		this.soldier = soldier;
	}

	@Override
	public CommandContext selectCommand() {
		Skill skill = randomSkill();
		CommandContext commandContext = new CommandContext(this.soldier, skill, null);
		return commandContext;
	}

	private Skill randomSkill() {
		// 有主动技能则随机,没有则默认平砍
		List<Skill> skills = new ArrayList<Skill>();
		for (Skill skill : this.soldier.skillHolder().battleSkillHolder().activeSkills()) {
			if (skill.isActiveSkill() && skill.getId() > 10) {
				skills.add(skill);
			}
		}
		if (skills.isEmpty())
			return Skill.defaultActiveSkill();
		Iterator<Skill> it = skills.iterator();
		while (it.hasNext()) {
			if (!isAvailable(soldier, it.next()))
				it.remove();
		}
		if (skills.isEmpty())
			return Skill.defaultActiveSkill();
		Skill skill = RandomUtils.next(skills);
		return skill;
	}
}
