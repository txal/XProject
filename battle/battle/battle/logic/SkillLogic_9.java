package com.nucleus.logic.core.modules.battle.logic;

import java.util.Set;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.VideoCallSoldierState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.spell.PlayerSpellEffectCalculator;

/**
 * 技能召唤怪物
 * 
 * @author wgy
 *
 */
@Service
public class SkillLogic_9 extends SkillLogicAdapter {

	@Override
	protected int beforeFired(CommandContext commandContext) {
		int code = super.beforeFired(commandContext);
		if (code != AppSkillActionStatusCode.Ordinary)
			return code;
		BattleTeam battleTeam = commandContext.trigger().battleTeam();
		if (battleTeam.soldiersMap().size() >= battleTeam.battle().maxPositionSize())
			code = AppSkillActionStatusCode.TeamFull;
		else if (battleTeam.getCalledMonsters().size() >= battleTeam.battle().maxCallMonsterSize())
			code = AppSkillActionStatusCode.NoMoreMonsterCall;
		commandContext.skillAction().setSkillStatusCode(code);
		return code;
	}

	@Override
	public void doFired(CommandContext commandContext) {
		Skill skill = commandContext.skill();
		if (skill.getCallMonsterId() <= 0)
			return;
		Monster monster = Monster.get(skill.getCallMonsterId());
		if (monster == null)
			return;
		BattleSoldier trigger = commandContext.trigger();
		BattleSoldier soldier = trigger.battleTeam().addCalledMonster(trigger, monster, false);
		if (soldier == null)
			return;
		soldier.joinRoundProcessor(trigger.getCurRoundProcessor());
		if (trigger.charactorType() != CharactorType.Monster.ordinal()) {
			// 玩家方召唤出来的小怪
			// 等级=技能等级
			soldier.setGrade(trigger.skillHolder().battleSkillHolder().skillLevel(skill.getId()));
			// 使用宠物的修为规则
			soldier.setSpellEffectCalculator(SpringUtils.getBeanOfType(PlayerSpellEffectCalculator.class));
			soldier.setPlayerId(trigger.playerId());
		} else {
			// 怪物方召唤的小怪
			soldier.setGrade(monster.level(soldier.battleTeam().getEnemyTeam()));
			soldier.setSpellLevel(monster.spellLevel(soldier.battleTeam().getEnemyTeam()));
		}
		soldier.initProperties();
		// 新加入战斗需要判断是否有被动技能可触发,如进入战斗就要附带buff
		soldier.skillHolder().passiveSkillEffectByTiming(soldier, commandContext, PassiveSkillLaunchTimingEnum.BattleReady);
		// 队伍buff
		Set<Integer> teamBuffIdSet = trigger.battleTeam().getTeamBuffIds();
		if (!teamBuffIdSet.isEmpty()) {
			for (int buffId : teamBuffIdSet) {
				BattleBuff buff = BattleBuff.get(buffId);
				if (buff != null) {
					int persistRound = Integer.parseInt(buff.getBuffsPersistRoundFormula());
					soldier.buffHolder().addBuff(new BattleBuffEntity(buff, trigger, soldier, skill.getId(), persistRound));
				}
			}
		}
		commandContext.skillAction().addTargetState(new VideoCallSoldierState(soldier));
		// 召唤出来的小怪有生命周期(持续回合数), 通过附加一个特定buff的方式来实现, 把技能表的目标buff字段配置成该特殊buff,仅有一个
		addTargetBuff(commandContext, soldier);
	}

}
