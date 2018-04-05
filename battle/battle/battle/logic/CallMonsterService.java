package com.nucleus.logic.core.modules.battle.logic;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoAction;
import com.nucleus.logic.core.modules.battle.dto.VideoCallSoldierState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.spell.PlayerSpellEffectCalculator;

/**
 * 召唤小怪
 * 
 * @author wgy
 *
 */
@Service
public class CallMonsterService {
	public BattleSoldier doCall(BattleSoldier trigger, int monsterId, VideoAction actionHolder, Skill skill, boolean ignoreCallLimit, int skillId) {
		return this.doCall(trigger, Monster.get(monsterId), actionHolder, skill, ignoreCallLimit, skillId);
	}

	public BattleSoldier doCall(BattleSoldier trigger, Monster monster, VideoAction actionHolder, Skill skill, boolean ignoreCallLimit, int skillId) {
		if (monster == null)
			return null;
		BattleSoldier soldier = trigger.battleTeam().addCalledMonster(trigger, monster, ignoreCallLimit);
		if (soldier == null)
			return null;
		soldier = handle(trigger, monster, actionHolder, skill, soldier, skillId);
		return soldier;
	}

	public BattleSoldier replace(BattleSoldier trigger, Monster monster, int position, VideoAction actionHolder, Skill skill) {
		if (monster == null)
			return null;
		BattleSoldier soldier = trigger.battleTeam().replaceCalledMonster(trigger, monster, position);
		if (soldier == null)
			return null;
		soldier = handle(trigger, monster, actionHolder, skill, soldier, 0);
		return soldier;
	}

	private BattleSoldier handle(BattleSoldier trigger, Monster monster, VideoAction actionHolder, Skill skill, BattleSoldier soldier, int skillId) {
		soldier.joinRoundProcessor(trigger.getCurRoundProcessor());
		if (trigger.charactorType() == CharactorType.Monster.ordinal()) {
			// 怪物方召唤的小怪
			soldier.setGrade(monster.level(soldier.battleTeam().getEnemyTeam()));
			soldier.setSpellLevel(monster.spellLevel(soldier.battleTeam().getEnemyTeam()));
		} else if (trigger.charactorType() == CharactorType.Crew.ordinal()) {
			soldier.setGrade(monster.level(soldier.battleTeam()));
			// 使用宠物的修为规则
			soldier.setSpellEffectCalculator(SpringUtils.getBeanOfType(PlayerSpellEffectCalculator.class));
			soldier.setPlayerId(trigger.playerId());
		} else {
			// 玩家方召唤出来的小怪
			// 等级=技能等级
			int grade = 0;
			if (skill != null)
				grade = trigger.skillLevel(skill.getId());
			else
				grade = monster.level(soldier.battleTeam());
			soldier.setGrade(grade);
			// 使用宠物的修为规则
			soldier.setSpellEffectCalculator(SpringUtils.getBeanOfType(PlayerSpellEffectCalculator.class));
			soldier.setPlayerId(trigger.playerId());
		}
		soldier.initProperties();
		// 新加入战斗需要判断是否有被动技能可触发,如进入战斗就要附带buff
		soldier.skillHolder().passiveSkillEffectByTiming(soldier, null, PassiveSkillLaunchTimingEnum.BattleReady);
		VideoCallSoldierState vdeoCallSoldierState = new VideoCallSoldierState(soldier);
		if (trigger.charactorType() == CharactorType.Pet.ordinal() && trigger.isDead()) {
			// 宠物死了
			vdeoCallSoldierState.setSkillId(skillId);
		}
		actionHolder.addTargetState(vdeoCallSoldierState);
		// 召唤出来的小怪有生命周期(持续回合数), 通过附加一个特定buff的方式来实现, 把技能表的目标buff字段配置成该特殊buff,仅有一个
		// addTargetBuff(commandContext, soldier);
		return soldier;
	}
}
