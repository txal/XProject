package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.NpcActiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.scene.model.NpcScenePloughMonsterBattleInfo;

/**
 * 36天罡招怪
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_11 extends SkillLogicAdapter {
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
		BattleSoldier trigger = commandContext.trigger();
		Monster monster = randomMonster();
		if (monster == null)
			return;
		NpcScenePloughMonsterBattleInfo battleInfo = (NpcScenePloughMonsterBattleInfo) trigger.battle().battleInfo();
		long triggerId = trigger.getId();
		BattleSoldier oldSoldier = battleInfo.getSoldierMap().get(triggerId);
		BattleSoldier soldier = callMonsterService.replace(trigger, monster, oldSoldier.getPosition(), commandContext.skillAction(), skill);
		if (soldier == null)
			return;
		battleInfo.getSoldierMap().put(triggerId, soldier);
		Integer count = battleInfo.getCallMonsterCountMap().get(triggerId);
		count = count == null ? 1 : count + 1;
		battleInfo.getCallMonsterCountMap().put(triggerId, count);
	}

	private Monster randomMonster() {
		int min = StaticConfig.get(AppStaticConfigs.MIN_CALL_MONSTER_ID).getAsInt(30101);
		int max = StaticConfig.get(AppStaticConfigs.MAX_CALL_MONSTER_ID).getAsInt(30172);
		int monsterId = RandomUtils.nextInt(min, max);
		return Monster.get(monsterId);
	}
}
