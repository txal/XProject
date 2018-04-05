package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.NpcActiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.scene.model.NpcSceneStarMonsterBattle;

/**
 * (28星宿boss)一次召唤多个小怪
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_10 extends SkillLogicAdapter {
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
		int count = skill.getCallMonsterCount();
		if (count <= 0)
			return;
		BattleSoldier trigger = commandContext.trigger();
		int maxCount = skill.getMaxCall();
		if (trigger.battle() instanceof NpcSceneStarMonsterBattle) {
			NpcSceneStarMonsterBattle battle = (NpcSceneStarMonsterBattle) trigger.battle();
			maxCount = battle.maxCallMonsterCount();
		}
		for (int i = 0; i < count; i++) {
			if (maxCount > 0 && trigger.battleTeam().getCalledMonsters().size() >= maxCount)
				break;
			Monster monster = Monster.get(RandomUtils.next(skill.callMonsterIds()));
			if (monster == null)
				continue;
			BattleSoldier soldier = callMonsterService.doCall(trigger, monster, commandContext.skillAction(), skill, true, 0);
			if (soldier == null)
				break;
			// 召唤出来的小怪有生命周期(持续回合数), 通过附加一个特定buff的方式来实现, 把技能表的目标buff字段配置成该特殊buff,仅有一个
			addTargetBuff(commandContext, soldier);
		}
		BattleSoldier target = commandContext.target();
		if (target != null) {
			int hp = BattleUtils.skillEffect(commandContext, target, skill.getTargetSuccessHpEffect(), null);
			if (hp > 0) {
				target.increaseHp(hp);
				commandContext.skillAction().addTargetState(new VideoActionTargetState(target, hp, 0, false));
			}
		}
		commandContext.updateTotalAttackCount(1);
	}

}
