package com.nucleus.logic.core.modules.battle.ai;

import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillAIConfig;
import com.nucleus.logic.core.modules.battle.logic.SkillTargetInfo;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;

/**
 * Created by Tony on 15/6/18.
 */
public class BattleAIAdapter implements BattleAI {
	@Override
	public CommandContext selectCommand() {
		return null;
	}

	protected boolean isAvailable(final BattleSoldier trigger, final Skill skill) {
		int lv = trigger.skillHolder().factionSkillLevel(skill.getFactionSkillId());
		if (skill.skillTargetInfos().isEmpty())
			return false;
		SkillTargetInfo info = skill.skillTargetInfos().get(0);
		if (lv < info.getSkillPreqLevel())
			return false;
		int mpSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, skill.getSpendMpFormula(), skill);
		mpSpent = -trigger.battle().mpSpent(null, trigger, mpSpent);
		if (mpSpent > 0 && trigger.mp() < mpSpent) {
			return false;
		}

		// 技能需要血量达到多少才能放
		int minFireHp = (int) BattleUtils.valueWithSoldierSkill(trigger, skill.getApplyHpLimitFormula(), skill);
		if (trigger.hp() < minFireHp) {
			return false;
		}

		// 技能需要扣的血量
		int hpSpent = -(int) BattleUtils.valueWithSoldierSkill(trigger, skill.getSpendHpFormula(), skill);
		if (hpSpent > 0 && trigger.hp() <= hpSpent) {
			return false;
		}
		int spSpent = -(int) BattleUtils.valueWithSoldierSkill(trigger, skill.getSpendSpFormula(), skill);
		if (spSpent > 0 && trigger.getSp() < spSpent) {
			return false;
		}
		if (skill.getCallMonsterId() > 0 && trigger.team().getCalledMonsters().size() >= trigger.battle().maxCallMonsterSize()) {
			return false;
		}

		if (!isTraningBattle()) {
			SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId());
			if (aiConfig != null && !aiConfig.isAvailable(trigger, skill, trigger.getCommandContext())) {
				return false;
			}
		}
		return true;
	}

	protected boolean isTraningBattle() {
		return false;
	}

	@Override
	public boolean onActionStart(BattleSoldier soldier, CommandContext commandContext) {
		return true;
	}

	protected Skill populatePreRequireSkill(BattleSoldier soldier, Skill skill) {
		// 如果没有变身,使用以下技能先变身
		return soldier.skillHolder().preRequireSkill(skill);
	}
}
