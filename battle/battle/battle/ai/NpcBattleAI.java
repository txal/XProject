package com.nucleus.logic.core.modules.battle.ai;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import com.google.common.collect.ImmutableSet;
import com.nucleus.commons.log.LogUtils;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget;
import com.nucleus.logic.core.modules.battle.ai.rules.SkillAITarget_0;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.SkillAIConfig;
import com.nucleus.logic.core.modules.battle.data.SkillWeightInfo;
import com.nucleus.logic.core.modules.battle.data.SkillsWeight;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleSkillHolder;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.CrewBattleSkillHolder;
import com.nucleus.logic.core.modules.battle.model.NpcBattleSkillHolder;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.constants.CommonEnums;
import com.nucleus.logic.core.modules.scene.model.SceneMineBattle;

/**
 * 伙伴AI/
 * <p>
 * Created by Tony on 15/6/17.
 */
public class NpcBattleAI extends BattleAIAdapter {

	/** 练级类型战斗 **/
	private static final Set<Class<? extends Battle>> trainingBattleTypes = ImmutableSet.of(
			// TollgateBattle.class,
			SceneMineBattle.class // ,
	/*
	 * NpcSceneGeneralMonsterBattle.class , DemoBattle.class
	 */
	);
	/** 练级类型战斗加血技能 */
	private static final Set<Integer> traningHealSkillIds = ImmutableSet.of(1613, 1212, 1213);

	/** 解封技能 */
	private static final int unbanSkillId = 1416;

	private final BattleSoldier soldier;

	private final NpcBattleSkillHolder<?> skillHolder;

	private final SkillAITarget defaultAITarget = new SkillAITarget_0("");

	private final boolean trainingBattle;

	private int trainingSkillId;

	/** 用于重新选择技能时过滤前一次不能使用的技能 */
	private Skill preSkill;

	public NpcBattleAI(BattleSoldier soldier, BattleSkillHolder<?> battleSkillHolder) {
		this.soldier = soldier;
		this.skillHolder = (NpcBattleSkillHolder<?>) battleSkillHolder;
		this.trainingBattle = (trainingBattleTypes.contains(soldier.battle().getClass()) && (soldier.ifMainCharactor() || soldier.ifCrew()));
		if (trainingBattle && battleSkillHolder instanceof CrewBattleSkillHolder) {
			trainingSkillId = ((CrewBattleSkillHolder) battleSkillHolder).getTrainingSkillId();
		}
	}

	@Override
	protected boolean isTraningBattle() {
		return this.trainingBattle;
	}

	@Override
	public CommandContext selectCommand() {

		final SkillsWeight skillsWeight = skillHolder.getSkillsWeight();
		final List<SkillWeightInfo> availableSkills = new ArrayList<>(skillsWeight.skillWeightInfos().size());
		final Set<Integer> availableSkillIds = new HashSet<>(skillsWeight.skillWeightInfos().size());
		// 先过滤不能施放的
		for (SkillWeightInfo info : skillsWeight.skillWeightInfos()) {
			final Skill skill = info.skill();
			if (preSkill != null && preSkill.getId() == skill.getId()) {
				continue;
			}
			if (!isAvailable(this.soldier, skill)) {
				continue;
			}
			/*
			 * SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId()); if (aiConfig != null && !aiConfig.isAvailable(soldier,skill,null)) { continue; }
			 */
			availableSkills.add(info);
			availableSkillIds.add(info.getSkillId());
		}
		// 有单位倒地，则判断自身是否有复活类技能，如有则优先使用
		CommandContext cc = tryRelive(this.soldier, availableSkills);
		if (cc != null)
			return cc;
		final List<BattleSoldier> myTeamSoldiers = new ArrayList<>(this.soldier.team().soldiersMap().values());
		boolean hasBanFriend = false;
		Skill unbanSkill = skillHolder.activeSkill(unbanSkillId);
		for (BattleSoldier actor : myTeamSoldiers) {
			if (actor.isDead()) {
				continue;
			}

			if (isTraningBattle()) {
				// 有单位生命值低于50%，则判断自身是否有治疗类技能，如有则优先使用
				if (!actor.isGhost() && actor.hpRate() < 0.5F) {
					int skillId = 0;
					for (SkillWeightInfo info : availableSkills) {
						if (traningHealSkillIds.contains(info.getSkillId())) {
							skillId = info.getSkillId();
							break;
						}
					}
					if (skillId > 0) {
						return new CommandContext(this.soldier, Skill.get(skillId), actor);
					}
				}
			}

			// 玩家进行了捕捉操作，则进行防御
			final CommandContext commandContext = actor.getCommandContext();
			if (actor.ifMainCharactor() && commandContext != null) {
				final Skill useCommand = commandContext.skill();
				if (useCommand != null && useCommand.getBattleCommandType() == CommonEnums.BattleCommandType.Capture.ordinal()) {
					// 防御
					return makeCommandContext(null, Skill.get(2));
				}
			}
			if (unbanSkill != null && !hasBanFriend) {
				hasBanFriend = hasBanState(actor);
			}
		}

		if (unbanSkill != null) {
			int banCount = (int) myTeamSoldiers.stream().filter(banSoldier -> hasBanState(banSoldier)).count();
			if (banCount > 0) {
				// 解封处理: 被封人数>0; 机率=40% + 人数 * 10%
				boolean hit = Math.random() < (0.4 + 0.1 * banCount);
				if (hit) {
					cc = tryUnban(this.soldier, unbanSkill);
					if (cc != null)
						return cc;
				}
			}
		}

		// 其它技能处理
		Skill skill = Skill.get(1); // 平砍

		// 练级战斗
		if (isTraningBattle()) {
			if (availableSkillIds.contains(trainingSkillId)) {
				skill = Skill.get(trainingSkillId);
			}
		} else {
			int skillsTotalWeight = 0;
			final List<SkillWeightInfo> attackSkills = new ArrayList<>(availableSkills.size());
			for (SkillWeightInfo availableSkillInfo : availableSkills) {
				final Skill availableSkill = availableSkillInfo.skill();
				if (!availableSkill.isUseAliveTarget() && !availableSkill.isDeadTriggerSkill()) {
					continue;
				}
				skillsTotalWeight += availableSkillInfo.getSkillWeight();
				attackSkills.add(availableSkillInfo);
			}
			int skillId = BattleUtils.randomActiveSkillId(new SkillsWeight(skillsTotalWeight, attackSkills));
			if (skillId > 0) {
				skill = Skill.get(skillId);
				skill = populatePreRequireSkill(this.soldier, skill);
			}
		}
		BattleSoldier target = selectTarget(skill);
		CommandContext context = makeCommandContext(target, skill);
		soldier.skillHolder().passiveSkillEffectByTiming(soldier, context, PassiveSkillLaunchTimingEnum.AiTarget);
		if (context.target() != null && target != null && context.target().getId() != target.getId()) {
			this.soldier.roundContext().clear();
			this.soldier.roundContext().putTarget(context.target().getId(), this.soldier.getId(), skill.getId());
		}
		return context;
	}

	private CommandContext tryUnban(BattleSoldier trigger, Skill skill) {
		SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId());
		if (aiConfig != null) {
			final BattleSoldier target = aiConfig.selectTarget(trigger, skill, null);
			if (target != null)
				return makeCommandContext(target, skill);
		}
		return null;
	}

	private CommandContext tryRelive(BattleSoldier trigger, List<SkillWeightInfo> availableSkills) {
		for (SkillWeightInfo info : availableSkills) {
			Skill skill = info.skill();
			if (!skill.isUseAliveTarget() || (skill.isDeadTriggerSkill() && skill.ifHpIncreaseFunction())) {
				SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId());
				if (aiConfig != null) {
					final BattleSoldier target = aiConfig.selectTarget(trigger, skill, null);
					if (target != null)
						return makeCommandContext(target, skill);
				}
			}
		}
		return null;
	}

	public CommandContext makeCommandContext(BattleSoldier target, Skill skill) {
		if (target != null) {
			this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId());
		}
		return new CommandContext(this.soldier, skill, target);
	}

	public BattleSoldier selectTarget(Skill skill) {
		BattleSoldier target;
		SkillAIConfig aiConfig = SkillAIConfig.get(skill.getId());
		if (aiConfig != null) {
			target = aiConfig.selectTarget(soldier, skill, null);
		} else {
			target = defaultAITarget.select(soldier, skill, null);
		}
		return target;
	}

	private boolean hasBanState(BattleSoldier soldier) {
		if (soldier == null)
			return false;
		for (BattleBuffEntity buffEntity : soldier.buffHolder().allBuffs().values()) {
			if (buffEntity.battleBuff().getBuffClassType() == BattleBuff.BuffClassTypeEnum.Ban.ordinal()) {
				return true;
			}
		}
		return false;
	}

	@Override
	public boolean onActionStart(BattleSoldier soldier, CommandContext commandContext) {
		if (commandContext == null) {
			LogUtils.errorLog("NpcBattleAI onActionStart get null command context, monster:" + soldier.monsterId() + ", charactor:" + soldier.charactorId() + ", player:" + soldier.playerId());
			return false;
		}
		Skill skill = commandContext.skill();
		BattleSoldier target = commandContext.target();

		// 如果自己已被封印
		if (soldier.buffHolder().isCommandBanned(skill.battleCommandType())) {
			return false;
		}

		if (skill.getSkillActionType() == Skill.SkillActionTypeEnum.Seal.ordinal() && hasBanState(target)) {
			preSkill = skill;
			// 重新选择技能与目标
			CommandContext ctx = selectCommand();
			if (ctx != null) {
				commandContext.setSkill(ctx.skill());
				commandContext.populateTarget(ctx.target());
				skill = ctx.skill();
				target = ctx.target();
				if (target != null) {
					this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId());
				}
			}
			preSkill = null;
		}

		if (!isAvailable(soldier, skill)) {
			commandContext.populateTarget(null);// 目标无效的情况下先清除旧目标
			// 重新选择技能与目标
			CommandContext ctx = selectCommand();
			if (ctx != null) {
				commandContext.setSkill(ctx.skill());
				commandContext.populateTarget(ctx.target());
				skill = ctx.skill();
				target = ctx.target();
				if (target != null) {
					this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId());
				}
			}
			// 平砍
			/*
			 * skill = Skill.get(1); target = selectTarget(skill); commandContext.setSkill(skill); commandContext.populateTarget(target); if (target != null) {
			 * this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId()); }
			 */
		}

		// 如果目标已挂
		if (target != null && target.isDead()) {
			if (!skill.isUseAliveTarget() || (skill.isDeadTriggerSkill() && skill.ifHpIncreaseFunction())) {
				target = selectTarget(skill);
				commandContext.populateTarget(target);
				// TODO: 还是没有目标的话，就不作行动
				if (target == null || !target.isDead()) {
					return false;
				}
			} else {
				// 重新选择技能与目标
				CommandContext ctx = selectCommand();
				if (ctx != null) {
					commandContext.setSkill(ctx.skill());
					commandContext.populateTarget(ctx.target());
					target = ctx.target();
					if (target != null) {
						this.soldier.roundContext().putTarget(target.getId(), this.soldier.getId(), skill.getId());
					}
				} else {
					return false;
				}
			}
		}
		return true;
	}
}
