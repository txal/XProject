/**
 * 
 */
package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.apache.commons.collections.CollectionUtils;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppErrorCodes;
import com.nucleus.logic.core.modules.AppSkillActionStatusCode;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.BattleUtils;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.PetPassiveSkill;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.data.Skill.SkillActionTypeEnum;
import com.nucleus.logic.core.modules.battle.data.Skill.SkillAttackType;
import com.nucleus.logic.core.modules.battle.data.Skill.UserTargetScopeType;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoInsideSkillAction;
import com.nucleus.logic.core.modules.battle.dto.VideoSkillAction;
import com.nucleus.logic.core.modules.battle.dto.VideoSoldier.SoldierStatus;
import com.nucleus.logic.core.modules.battle.dto.VideoTargetExceptionState;
import com.nucleus.logic.core.modules.battle.model.Battle;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battle.model.PvpBattle;
import com.nucleus.logic.core.modules.battlebuff.IBattleBuffLogic;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BuffClassTypeEnum;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_1;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_3;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_4;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_5;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_7;
import com.nucleus.logic.core.modules.formation.data.Formation;
import com.nucleus.logic.core.modules.spell.SpellEffectCalculator;
import com.nucleus.logic.core.modules.spell.data.Spell.SpellPropertyEffect;
import com.nucleus.player.service.ScriptService;

/**
 * @author Omanhom
 * 
 */
public abstract class SkillLogicAdapter implements SkillLogic {
	/**
	 * 展示技能图标时长
	 */
	protected float battleSkillShowTime() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_SKILL_SHOW_TIME).getAsFloat(1F);
	}

	/**
	 * 战斗最小命中率
	 */
	protected float battleMinHitRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_MIN_HIT_RATE).getAsFloat(0.2F);
	}

	/**
	 * 无法发动技能时发呆时长
	 */
	protected float battleActionIdleTime() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_ACTION_IDLE_TIME).getAsFloat(0.5F);
	}

	/**
	 * 防御伤害减少百分率
	 */
	protected float battleDefenseDamageVaryRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_DEFENSE_DAMAGE_VARY_RATE).getAsFloat(0.5F);
	}

	/**
	 * 战斗暴击伤害率(2倍)
	 * 
	 * @return
	 */
	protected float battleCritRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_CRIT_RATE).getAsFloat(2.0F);
	}

	/**
	 * 受保护方伤害率
	 * 
	 * @return
	 */
	protected float battlePassiveProtectDamageRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_PASSIVE_PROTECT_DAMAGE_RATE).getAsFloat(0.35F);
	}

	/**
	 * 保护方伤害率
	 * 
	 * @return
	 */
	protected float battleActiveProtectDamageRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_ACTIVE_PROTECT_DAMAGE_RATE).getAsFloat(0.75F);
	}

	/**
	 * 战斗法术命中率
	 * 
	 * @return
	 */
	protected float battleMagicHitRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_MAGIC_HIT_RATE).getAsFloat(1F);
	}

	/**
	 * 战斗最小法术闪避率
	 * 
	 * @return
	 */
	protected float battleMinMagicDodgeRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_MIN_MAGIC_DODGE_RATE).getAsFloat(0.2F);
	}

	/**
	 * 攻击多个目标移动时长
	 * 
	 * @return
	 */
	protected float multiTargetMoveTimeSec() {
		return StaticConfig.get(AppStaticConfigs.MULTI_TARGET_MOVE_TIME).getAsFloat(0.2f);
	}

	/**
	 * 单次行动时间修正
	 * 
	 * @return
	 */
	protected float singleTimeFixSec() {
		return StaticConfig.get(AppStaticConfigs.SINGLE_TIME_FIX).getAsFloat(0.2f);
	}

	/**
	 * 每回合时间修正
	 * 
	 * @return
	 */
	protected float roundTimeFixSec() {
		return StaticConfig.get(AppStaticConfigs.ROUND_TIME_FIX).getAsFloat(0.5f);
	}

	@Override
	public void fired(CommandContext commandContext) {
		int skillStatusCode = beforeFired(commandContext);
		if (skillStatusCode == 0) {
			doFired(commandContext);
			afterFired(commandContext);
			commandContext.battle().battleRoundProcessor().debugInfo(commandContext, 0);
		} else {
			Battle curBattle = commandContext.battle();
			// curBattle.addEstimatedPlaySec(battleActionIdleTime());
			curBattle.battleRoundProcessor().debugInfo(commandContext, skillStatusCode);
		}
	}

	public abstract void doFired(CommandContext commandContext);

	private void afterFired(CommandContext commandContext) {
		Skill skill = commandContext.skill();
		BattleSoldier trigger = commandContext.trigger();
		skill.afterFired(trigger, commandContext.skillAction());
		int totalAttackCount = commandContext.totalAttackCount();
		if (totalAttackCount < 1) {
			return;
		}
		// 受击度结算
		for (BattleSoldier soldier : commandContext.getBeAttackedTargets().values())
			soldier.increaseStrikeRate();

		Battle battle = commandContext.battle();
		float showSkillTime = battleSkillShowTime();
		if (skill.getId() < 10) {// 普攻/防御/保护/召唤/捕捉/撤退/物品
			showSkillTime = 0F;
		}
		boolean multiDiffTargets = (skill.getSkillAiId() == UserTargetScopeType.Enemy.ordinal()) && !skill.isAtOnce() && (commandContext.getTargetIds().size() > 1);// 攻击敌方多个不同目标
		float multiAttackMoveTime = 0;// 攻击多人移动时间,如攻击3个人,第一个不计,只计算对剩下两个目标的移动耗时,多次攻击同一个目标无需移动,该值为0
		if (multiDiffTargets)
			multiAttackMoveTime = multiTargetMoveTimeSec() * (totalAttackCount - 1);
		float totalTime = skill.getActionReadyPlaySec() + skill.getSingleActionPlaySec() * totalAttackCount + multiAttackMoveTime + showSkillTime + skill.getActionEndPlaySec() + singleTimeFixSec();
		battle.addEstimatedPlaySec(totalTime);
		// 施放完技能再结算hp消耗
		int hpSpent = (int) BattleUtils.valueWithSoldierSkill(trigger, skill.getSpendHpFormula(), skill);
		if (hpSpent < 0) {
			trigger.decreaseHp(hpSpent);
			commandContext.skillAction().setHpSpent(hpSpent);
			float hpSpentShowTime = trigger.underAttackShowTime();
			battle.addEstimatedPlaySec(hpSpentShowTime);
		}
		// 2016-08-03 Fixed:竞技场战斗使用万物复苏出现mp不足提示,把spendMpFormula配置改成selfSuccessMpEffectFormula
		int mp = (int) BattleUtils.valueWithSoldierSkill(trigger, skill.getSelfSuccessMpEffectFormula(), skill);
		if (mp < 0) {
			trigger.decreaseMp(mp);
			commandContext.skillAction().setMpSpent(mp);
		}
		// changed by yifan.chen 增加死亡也需要触发添加的buff
		if (!trigger.isDead()) {
			addSelfBuff(commandContext);
			removeSelfBuffs(commandContext, trigger);
		} else {
			addSelfBuffWhenDie(commandContext, trigger);
		}
		// 被动技能:法术连击
		trigger.skillHolder().passiveSkillEffectByTiming(commandContext.target(), commandContext, PassiveSkillLaunchTimingEnum.AttackEnd);
		for (BattleSoldier s : trigger.team().soldiersMap().values())
			s.skillHolder().passiveSkillEffectByTiming(commandContext.target(), commandContext, PassiveSkillLaunchTimingEnum.TeammateAttackEnd);
	}

	protected int beforeFired(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		Skill skill = commandContext.skill();

		VideoSkillAction skillAction = commandContext.skillAction();
		int skillStatusCode = skill.beforeFire(trigger, skillAction);
		skillAction.setSkillStatusCode(skillStatusCode);
		if (skillStatusCode == AppSkillActionStatusCode.Ordinary) {
			skillAction.setSkillId(skill.getId());
		}
		return skillStatusCode;
	}

	/**
	 * 是否命中
	 *
	 * @param commandContext
	 * @param target
	 * @return
	 */
	protected boolean hit(CommandContext commandContext, BattleSoldier target) {
		Skill skill = commandContext.skill();
		BattleSoldier trigger = commandContext.trigger();
		if (!skill.isNeedDodge()) {
			return true;
		}
		if (skillMustHitFactionEffect(commandContext))
			return true;
		if (skill.isMustFirstTarget() && commandContext.ifFirstTarget(target))
			return true;
		if (skillHidingDragonEffect(skill, trigger)) {
			return true;
		}
		if (skillTargetDodgeFactionEffect(commandContext, target))
			return false;
		if (skillTargetFullDefenseFactionEffect(commandContext, target))
			return false;
		if (target.isDodgeSuccess()) {
			target.setDodgeSuccess(false);
			return false;
		}
		// 被动技能：命中率影响
		float passiveSkillEffect = trigger.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.HitRate);
		int skillLevel = trigger.skillLevel(skill.getId());
		float hitRate = trigger.hitRate() + skill.gainHitRate(skillLevel) + passiveSkillEffect - target.dodgeRate();
		if (skill.ifMagicSkill()) {
			passiveSkillEffect = trigger.skillHolder().passiveSkillPropertyEffect(BattleBasePropertyType.MagicHitRate);
			hitRate = battleMagicHitRate() + trigger.magicHitRate() + passiveSkillEffect - battleMinMagicDodgeRate() - target.magicDodgeRate();
		}
		float minHitRate = battleMinHitRate();
		if (hitRate < minHitRate) {
			hitRate = minHitRate;
		}
		boolean isHit = RandomUtils.baseRandomHit(hitRate);
		if (commandContext.debugEnable()) {
			commandContext.debugInfo().setHit(isHit);
			commandContext.debugInfo().setHitRate(hitRate);
		}
		return isHit;
	}

	protected int critCal(CommandContext commandContext, BattleSoldier target, int varyAmount) {
		return crit(commandContext, target, varyAmount);
	}

	/**
	 * 暴击结算
	 *
	 * @param commandContext
	 * @param target
	 * @param varyAmount
	 * @return
	 */
	private int crit(CommandContext commandContext, BattleSoldier target, int varyAmount) {
		int resultHpVaryAmount = varyAmount;
		Skill skill = commandContext.skill();
		commandContext.setCrit(false);

		if (!skill.isNeedCrit()) {
			return resultHpVaryAmount;
		}
		BattleSoldier trigger = commandContext.trigger();
		commandContext.setAntiCrit(false);
		// 保留原本附加暴击率（处理物理群攻时个别目标抗暴率）
		float oldCritRate = commandContext.getCritRatePlus();

		target.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.BeforeCrit);
		if (commandContext.isAntiCrit())
			return resultHpVaryAmount;
		boolean isCrit = false;
		float critRate = commandContext.skill().ifMagicSkill() ? trigger.magicCritRate() : trigger.critRate();
		float critReduceRate = commandContext.skill().ifMagicSkill() ? target.magicCritReduceRate() : target.critReduceRate();
		trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.CritRatePlus);
		critRate += commandContext.getCritRatePlus();
		critRate -= critReduceRate;
		if (critRate > 0) {
			isCrit = RandomUtils.baseRandomHit(critRate);
		}
		if (commandContext.debugEnable()) {
			commandContext.debugInfo().setCrit(isCrit);
			commandContext.debugInfo().setCritRate(critRate);
		}
		commandContext.setCrit(isCrit);

		if (isCrit) {
			float battleCritRate = this.battleCritRate() + trigger.battleBaseProperties().getFloat(BattleBasePropertyType.CritHurtRate);
			battleCritRate += trigger.critHurtRate();
			battleCritRate -= target.critHurtReduceRate();
			commandContext.setCritHurtRate(battleCritRate);
			trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.OnCrit);
			target.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.OnCrit);
			battleCritRate = commandContext.getCritHurtRate();
			if (battleCritRate < 1) {
				battleCritRate = 1;
			}
			resultHpVaryAmount *= battleCritRate;
			// 增加影响伤害效果
			int oriDamageOutput = commandContext.getDamageOutput();
			commandContext.setDamageOutput(resultHpVaryAmount);
			// 被动技能：暴击后影响
			trigger.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.AfterCrit);
			target.skillHolder().passiveSkillEffectByTiming(trigger, commandContext, PassiveSkillLaunchTimingEnum.BeAfterCrit);
			// 连击会用到DamageOutput，所以加CritDamageOutput给暴击附加伤害专用
			resultHpVaryAmount -= commandContext.getCritDamageOutput();
			if (oriDamageOutput != resultHpVaryAmount)
				commandContext.setDamageOutput(oriDamageOutput);
			if (commandContext.debugEnable())
				commandContext.debugInfo().setCritHurtRate(battleCritRate);
		}
		// 还原附加暴击率
		commandContext.setCritRatePlus(oldCritRate);
		return resultHpVaryAmount;
	}

	/**
	 * Hp结算
	 * 
	 * @param commandContext
	 *            技能上下文
	 * @param target
	 *            技能目标
	 * @return
	 */
	protected int calculateHpVaryAmount(CommandContext commandContext, BattleSoldier target, int hpVaryAmount) {
		// 战斗公式B类系数
		float factorOfB = 0F;
		// 阵型效果
		factorOfB += formationDamageIncreaseRate(commandContext, target);
		// 门派特色
		factorOfB += damageIncreaseFactionEffect(commandContext, target);
		factorOfB += healIncreaseFactionEffect(commandContext, target, hpVaryAmount);
		// 装备特效
		// 被动技能,各种BUFF
		BattleSoldier trigger = commandContext.trigger();
		factorOfB += trigger.buffHolder().propertyValueEffect(commandContext, BattleBasePropertyType.DamageIncrease);
		// 目标治疗增益buff
		if (hpVaryAmount > 0) {
			factorOfB += trigger.propFloat(BattleBasePropertyType.HpBuffEffectEnhance);
			factorOfB += target.buffHolder().propertyValueEffect(commandContext, BattleBasePropertyType.HpBuffEffectEnhance);
			factorOfB += trigger.playerBuffEffect(BattleBasePropertyType.HpBuffEffectEnhance);
		} else {
			factorOfB += trigger.propFloat(BattleBasePropertyType.DamageIncrease);
			factorOfB += trigger.playerBuffEffect(BattleBasePropertyType.DamageIncrease);
		}
		if (commandContext.skill().ifMagicSkill()) {
			// 法术伤害增加
			factorOfB += trigger.propFloat(BattleBasePropertyType.MagicDamageIncrease);
			factorOfB += trigger.buffHolder().propertyValueEffect(commandContext, BattleBasePropertyType.MagicDamageIncrease);
		} else {
			// 物理伤害增加
			factorOfB += trigger.propFloat(BattleBasePropertyType.PhysicalDamageIncrease);
			factorOfB += trigger.buffHolder().propertyValueEffect(commandContext, BattleBasePropertyType.PhysicalDamageIncrease);
		}
		hpVaryAmount = (int) (hpVaryAmount * (1 + factorOfB));

		// 连击，反击，追击。。。
		float skillDamageVaryRate = commandContext.getCurDamageVaryRate();
		hpVaryAmount *= skillDamageVaryRate;

		// 修炼影响
		Skill skill = commandContext.skill();
		if (!skill.isIgnoreSpellEffect()) {
			if (hpVaryAmount < 0) {
				hpVaryAmount = spellDamageEffect(skill, trigger, target, hpVaryAmount);
			} else if (hpVaryAmount > 0) {
				int skillActionType = skill.getSkillActionType();
				// 辅助技能的治疗效果也要受到加成
				if (skillActionType == SkillActionTypeEnum.Heal.ordinal() || skillActionType == SkillActionTypeEnum.Support.ordinal()) {
					hpVaryAmount = spellHealEffect(trigger, hpVaryAmount);
				}
			}
		}
		SoldierStatus targetSoldierStatus = target.soldierStatus();

		// 认证法术修正(A类)
		hpVaryAmount = certificatedSkillEffect(commandContext, hpVaryAmount);
		// 暴击 A类系数
		hpVaryAmount = crit(commandContext, target, hpVaryAmount);

		float battleDefenseDamageVaryRate = 1F;
		if (skill.skillDefensable() && !skill.isCannotDefense()) {
			if (targetSoldierStatus == SoldierStatus.SelfDefense) {
				battleDefenseDamageVaryRate = battleDefenseDamageVaryRate();
				// 防御时减伤
				commandContext.setDefenseDamageRate(battleDefenseDamageVaryRate);
				target.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.DefenseDamageRate);
				battleDefenseDamageVaryRate = commandContext.getDefenseDamageRate();
			}
			if (!skill.unableProtect() && !skill.isCannotProtect()) {
				int protectDamage = (int) (hpVaryAmount * battleDefenseDamageVaryRate * battlePassiveProtectDamageRate());
				tryAutoProtect(target, commandContext, protectDamage);
				List<Long> protectedBySoldierIds = target.protectedBySoldierIds();
				BattleTeam battleTeam = target.battleTeam();
				if (!protectedBySoldierIds.isEmpty()) {
					long protectedBySoldierId = protectedBySoldierIds.remove(0);
					BattleSoldier protectedBySoldier = battleTeam.battleSoldier(protectedBySoldierId);
					if (protectedBySoldier != null && !protectedBySoldier.isDead()) {
						protectedBySoldier.skillHolder().passiveSkillEffectByTiming(protectedBySoldier, commandContext, PassiveSkillLaunchTimingEnum.BeforeProtect);
						int activeProtectorHpAmount = (int) (hpVaryAmount * battleDefenseDamageVaryRate * (battleActiveProtectDamageRate() - commandContext.getProtectorDefenseDamageRate()));
						protectedBySoldier.decreaseHp(activeProtectorHpAmount, trigger);
						commandContext.skillAction().currentTargetStateGroup()
								.setProtectAction(new VideoInsideSkillAction(new VideoActionTargetState(protectedBySoldier, activeProtectorHpAmount, 0, commandContext.isCrit())));
						commandContext.skillAction().currentTargetStateGroup().setProtectSoldierId(protectedBySoldierId);
						battleDefenseDamageVaryRate *= battlePassiveProtectDamageRate();
					}
				}
			}
		}
		if (hpVaryAmount < 0) {
			hpVaryAmount *= battleDefenseDamageVaryRate;

			// 战斗公式C类系数,减伤＊
			float factorOfC = 0F;
			// 阵型效果
			factorOfC += target.propFloat(commandContext.skill().ifMagicSkill() ? BattleBasePropertyType.MagicDamageDecrease : BattleBasePropertyType.PhysicalDamageDecrease);
			factorOfC += formationDamageDecreaseRate(commandContext, target);
			hpVaryAmount = (int) (hpVaryAmount * (1 - factorOfC));
		}
		if (hpVaryAmount == 0) {
			hpVaryAmount = skill.ifHpLossFunction() ? -1 : 0;
		}

		// commandContext.skillAction().setTargetSoldierStatus(targetSoldierStatus.ordinal());

		return hpVaryAmount;
	}

	/**
	 * 宠物认证技能影响伤害输出
	 * 
	 * @param commandContext
	 * @param hpVaryAmount
	 * @return
	 */
	private int certificatedSkillEffect(CommandContext commandContext, int hpVaryAmount) {
		if (!commandContext.skill().ifMagicSkill()) {// 物理伤害减弱
			BattleSoldier trigger = commandContext.trigger();
			if (trigger.battleUnit() instanceof PersistPlayerPet) {
				PersistPlayerPet pet = (PersistPlayerPet) trigger.battleUnit();
				if (pet.getCertificatedSkillId() > 0) {
					float rate = trigger.battle().certificatedSkillEffectRate();
					hpVaryAmount *= rate;
				}
			}
		}
		return hpVaryAmount;
	}

	private void tryAutoProtect(BattleSoldier target, CommandContext context, int hpVaryAmount) {
		for (BattleSoldier s : target.team().aliveSoldiers()) {
			if (s.getId() != target.getId())
				s.skillHolder().passiveSkillEffectByTiming(target, context, PassiveSkillLaunchTimingEnum.TryAutoProtect);
		}
		friendProtect(target, hpVaryAmount);
	}

	private void friendProtect(BattleSoldier target, int hpVaryAmount) {
		// 友好度触发保护
		float hpRateLimit = target.battle().friendProtectHpRate();
		// 目标血量比例符合预设,且受保护之后不会死
		if (target.hpRate() <= hpRateLimit && Math.abs(hpVaryAmount) < target.hp()) {
			Set<Long> avaliableFriends = gainProtectFriends(target);
			if (!avaliableFriends.isEmpty()) {
				long protectPlayerId = RandomUtils.next(avaliableFriends);
				target.addProtectedBySoldierId(protectPlayerId);
			}
		}
	}

	/**
	 * 特殊好友(夫妻/师徒/结拜)
	 * 
	 * @param s
	 * @param target
	 * @return
	 */
	private boolean specialFriend(BattleSoldier s, BattleSoldier target) {
		return s.fereId() == target.getId() || s.ifMyMaster(target.getId()) || target.ifMyMaster(s.getId()) || s.isBro(target);
	}

	private Set<Long> gainProtectFriends(BattleSoldier target) {
		final int friendDegreeLimit = target.battle().friendProtectDegreeLimit();
		final Set<Long> friends = new HashSet<>();
		final BattleCommandType commandType = Skill.defaultProtectSkill().battleCommandType();
		for (BattleSoldier s : target.team().aliveSoldiers()) {
			if (s.getId() == target.getId() || !s.ifMainCharactor())
				continue;
			if (s.buffHolder().buffBanState(commandType) > 0)
				continue;
			if (s.friendlyWith(target.getId()) < friendDegreeLimit && !specialFriend(s, target))
				continue;
			float r = calcFriendProtectRate(s, target);
			if (RandomUtils.baseRandomHit(r))
				friends.add(s.getId());
		}
		return friends;
	}

	private float calcFriendProtectRate(BattleSoldier s, BattleSoldier target) {
		Map<String, Object> params = new HashMap<>();
		params.put("friendly", s.friendlyWith(target.getId()));
		float rate = ScriptService.getInstance().calcuFloat("SkillLogicAdapter.calcFriendProtectRate", s.battle().friendProtectRateFormula(), params, false);
		float fereRate = 0F, masterRate = 0F, broRate = 0F;
		if (s.fereId() == target.getId())
			fereRate = s.battle().friendProtectPlusRate3();
		if (s.ifMyMaster(target.getId()) || target.ifMyMaster(s.getId()))
			masterRate = s.battle().friendProtectPlusRate2();
		// 结拜关系
		if (s.isBro(target))
			broRate = s.battle().friendProtectPlusRate1();
		rate += Math.max(fereRate, Math.max(masterRate, broRate));
		return rate;
	}

	/**
	 * 阵型伤害效果计算
	 *
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private float formationDamageIncreaseRate(CommandContext commandContext, BattleSoldier target) {
		// 阵型克制
		final Formation triggerFormation = commandContext.trigger().battleTeam().formation();
		final Formation targetFormation = target.battleTeam().formation();
		Float restraint = triggerFormation.debuffTargets().get(targetFormation.getId());
		restraint = restraint == null ? 0 : restraint;
		float damageIncrease = 0;
		if (commandContext.skill().ifMagicSkill()) {
			// 魔法伤害加
			damageIncrease = triggerFormation.effectRate(commandContext.trigger().getFormationIndex(), BattleBasePropertyType.MagicDamageIncrease);
		} else {
			// 物理伤害加
			damageIncrease = triggerFormation.effectRate(commandContext.trigger().getFormationIndex(), BattleBasePropertyType.PhysicalDamageIncrease);
		}
		return restraint + damageIncrease;
	}

	/**
	 * 阵型减伤效果计算，包含克制效果
	 *
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private float formationDamageDecreaseRate(CommandContext commandContext, BattleSoldier target) {
		// 阵型克制
		final Formation triggerFormation = commandContext.trigger().battleTeam().formation();
		final Formation targetFormation = target.battleTeam().formation();
		Float restraint = targetFormation.debuffTargets().get(triggerFormation.getId());
		restraint = restraint == null ? 0 : restraint;
		float targetDamageDecrease = 0;
		if (commandContext.skill().ifMagicSkill()) {
			// 魔法伤害减
			targetDamageDecrease = targetFormation.effectRate(target.getFormationIndex(), BattleBasePropertyType.MagicDamageDecrease);
		} else {
			// 物理伤害减
			targetDamageDecrease = targetFormation.effectRate(target.getFormationIndex(), BattleBasePropertyType.PhysicalDamageDecrease);
		}
		return restraint + targetDamageDecrease;
	}

	/**
	 * 修炼效果
	 *
	 * @param skill
	 * @param trigger
	 * @param target
	 * @param hpVaryAmount
	 * @return
	 */
	private int spellDamageEffect(Skill skill, BattleSoldier trigger, BattleSoldier target, int hpVaryAmount) {
		if (hpVaryAmount >= 0)
			return 0;
		/*
		 * if (skill.ifMagicSkill()) { hpVaryAmount = (int) trigger.spellEffectCalculator().calcSpellEffect(trigger, SpellPropertyEffect.MagicDamageIncrease, hpVaryAmount);
		 * hpVaryAmount = (int) target.spellEffectCalculator().calcSpellEffect(target, SpellPropertyEffect.MagicDamageDecrease, hpVaryAmount); } else { hpVaryAmount = (int)
		 * trigger.spellEffectCalculator().calcSpellEffect(trigger, SpellPropertyEffect.PhyDamageIncrease, hpVaryAmount); hpVaryAmount = (int)
		 * target.spellEffectCalculator().calcSpellEffect(target, SpellPropertyEffect.PhyDamageDecrease, hpVaryAmount); }
		 */
		hpVaryAmount = (int) SpellEffectCalculator.getInstance().damageEffect(skill, trigger, target, hpVaryAmount);
		return hpVaryAmount;
	}

	/**
	 * 修炼技能 治疗加成
	 * 
	 * @param skill
	 * @param trigger
	 * @param target
	 * @param hpVaryAmount
	 * @return
	 */
	protected int spellHealEffect(BattleSoldier soldier, int hpVaryAmount) {
		if (hpVaryAmount < 0) {
			return hpVaryAmount;
		}
		float finalValue = SpellEffectCalculator.getInstance().healEffect(soldier, hpVaryAmount);
		return (int) finalValue;
	}

	/**
	 * 封印机率影响
	 * 
	 * @param trigger
	 *            触发者
	 * @param target
	 *            目标
	 * @param buff
	 *            施放buff
	 * @param rate
	 *            原始机率
	 * @return
	 */
	private float banRateEffect(BattleSoldier trigger, BattleSoldier target, BattleBuff buff, float rate) {
		// 判断是否是封禁类buff
		if (buff.banBattleCommandTypes().isEmpty())
			return rate;
		// 触发者提升封印成功率
		rate = trigger.spellEffectCalculator().calcSpellEffect(trigger, SpellPropertyEffect.BanRateIncrease, rate);
		rate += trigger.propFloat(BattleBasePropertyType.SealHitRate);
		rate += trigger.buffHolder().baseEffects(BattleBasePropertyType.SealHitRate);
		// 受击方减少成功率
		rate = target.spellEffectCalculator().calcSpellEffect(target, SpellPropertyEffect.AntiBanIncrease, rate);
		rate -= target.propFloat(BattleBasePropertyType.SealHitReduce);
		rate -= target.buffHolder().baseEffects(BattleBasePropertyType.SealHitReduce);
		return rate;
	}

	/**
	 * 怪物类型加成
	 * 
	 * @param commandContext
	 * @param target
	 * @param hpVaryAmount
	 * @return
	 */
	protected int monsterTypeVary(CommandContext commandContext, BattleSoldier target, int hpVaryAmount) {
		// 2015/12/25调整为对pve战斗且玩家方有效
		if (commandContext.battle() instanceof PvpBattle || (commandContext.trigger().battleTeam().isNpcTeam()))
			return hpVaryAmount;
		float rate = commandContext.skill().getDamagePlusRate();
		if (rate != 0)
			hpVaryAmount *= rate;
		return hpVaryAmount;
	}

	/**
	 * 是否获得buff
	 * 
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private boolean buffAcquirable(CommandContext commandContext, BattleSoldier target, BattleBuff battleBuff) {
		if (commandContext.skill().isMustFirstTarget() && commandContext.ifFirstTarget(target))
			return true;
		float buffRate = BattleUtils.skillBuff(commandContext, target, battleBuff.getBuffsAcquireRateFormula());
		// 自己对自己施放buff不附加修炼影响,对敌施放buff才附加
		if (commandContext.trigger().getId() != target.getId()) {
			// 影响效果
			buffRate = banRateEffect(commandContext.trigger(), target, battleBuff, buffRate);
		}
		// target.skillHolder().passiveSkillEffectByTiming(target,
		// commandContext, PassiveSkillLaunchTimingEnum.BeBuffRate);
		buffRate += commandContext.getBeBuffRate();
		if (buffRate <= 0)
			return false;
		return RandomUtils.baseRandomHit(buffRate);
	}

	/**
	 * 添加目标buff
	 * 
	 * @param commandContext
	 *            - 技能上下文
	 * @param target
	 *            - 技能目标
	 */
	protected List<BattleBuffEntity> addTargetBuff(CommandContext commandContext, BattleSoldier target) {
		target.buffHolder().antiBuff(commandContext);
		if (commandContext.isAntiBuff()) {
			commandContext.setAntiBuff(false);// 重置标记,避免群攻情况下影响其他目标
			return Collections.emptyList();
		}
		List<BattleBuffEntity> list = addBuff(commandContext, target, commandContext.skill().targetBattleBuffIds());
		// 针对头号目标额外附加buff
		if (CollectionUtils.isNotEmpty(commandContext.skill().mainTargetPlusBuffs()) && commandContext.getFirstTarget() != null && commandContext.getFirstTarget().getId() == target.getId()) {
			list.addAll(addBuff(commandContext, target, commandContext.skill().mainTargetPlusBuffs()));
		}
		if (commandContext.debugEnable() && commandContext.debugInfo() != null)
			commandContext.debugInfo().getTargetBuffs().addAll(list);
		return list;
	}

	/**
	 * 死亡也需要添加目标buff
	 * 
	 * @param commandContext
	 * @param target
	 */
	protected void addTargetBuffWhenDie(CommandContext commandContext, BattleSoldier target) {
		Skill skill = commandContext.skill();
		if (skill.isDeadTriggerBuff()) {
			target.buffHolder().antiBuff(commandContext);
			if (commandContext.isAntiBuff()) {
				commandContext.setAntiBuff(false);// 重置标记,避免群攻情况下影响其他目标
				return;
			}
			List<BattleBuffEntity> list = addBuff(commandContext, target, commandContext.skill().targetBattleBuffIds());
			// 针对头号目标额外附加buff
			if (CollectionUtils.isNotEmpty(commandContext.skill().mainTargetPlusBuffs()) && commandContext.getFirstTarget() != null && commandContext.getFirstTarget().getId() == target.getId()) {
				list.addAll(addBuff(commandContext, target, commandContext.skill().mainTargetPlusBuffs()));
			}
			if (commandContext.debugEnable() && commandContext.debugInfo() != null)
				commandContext.debugInfo().getTargetBuffs().addAll(list);
		}
	}

	/**
	 * 添加自己buff
	 * 
	 * @param commandContext
	 *            - 技能上下文
	 */
	protected void addSelfBuff(CommandContext commandContext) {
		List<BattleBuffEntity> list = addBuff(commandContext, commandContext.trigger(), commandContext.skill().selfBattleBuffIds());
		if (commandContext.debugEnable() && commandContext.debugInfo() != null)
			commandContext.debugInfo().getTriggerBuffs().addAll(list);
	}

	/**
	 * 死亡也需要添加的buff
	 * 
	 * @param commandContext
	 *            - 技能上下文
	 */
	protected void addSelfBuffWhenDie(CommandContext commandContext, BattleSoldier trigger) {
		Skill skill = commandContext.skill();
		if (skill.isDeadTriggerBuff()) {
			List<BattleBuffEntity> list = addBuff(commandContext, commandContext.trigger(), skill.selfBattleBuffIds());

			if (commandContext.debugEnable() && commandContext.debugInfo() != null)
				commandContext.debugInfo().getTriggerBuffs().addAll(list);

			// 移除buff
			removeSelfBuffs(commandContext, trigger);
		}
	}

	private List<BattleBuffEntity> addBuff(CommandContext commandContext, BattleSoldier target, Set<Integer> targetBattleBuffIds) {
		List<BattleBuffEntity> list = new ArrayList<BattleBuffEntity>();
		Skill skill = commandContext.skill();
		boolean banSkill = skill.getSkillActionType() == SkillActionTypeEnum.Seal.ordinal();
		for (int battleBuffId : targetBattleBuffIds) {
			BattleBuff battleBuff = BattleBuff.get(battleBuffId);
			if (null == battleBuff) {
				continue;
			}
			// 目标buff抵抗
			commandContext.setBeAddBuffId(battleBuffId);
			commandContext.setBeBuffRate(0);// 重置buff命中
			commandContext.trigger().skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BeforeBuffOutput);
			target.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BeforeBuff);
			if (commandContext.getBeAddBuffId() <= 0) {
				continue;
			}
			boolean isBuffAcquired = buffAcquirable(commandContext, target, battleBuff);
			if (!isBuffAcquired) {
				if (banSkill && battleBuff.getBuffClassType() == BuffClassTypeEnum.Ban.ordinal())
					commandContext.trigger().skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BanFaild);
				continue;
			}
			int persistRound = BattleUtils.buffRounds(commandContext, target, battleBuff.getBuffsPersistRoundFormula());
			if (persistRound > 0) {
				BattleBuffEntity buffEntity = new BattleBuffEntity(battleBuff, commandContext, target, persistRound);
				commandContext.setTargetBuff(buffEntity);
				// 被动技能影响buff效果
				target.skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BuffEnhance);
				if (target.buffHolder().addBuff(buffEntity)) {
					if (banSkill && target.getId() != commandContext.trigger().getId()) {
						commandContext.trigger().skillHolder().passiveSkillEffectByTiming(target, commandContext, PassiveSkillLaunchTimingEnum.BanSuccess);
					}
					commandContext.skillAction().addTargetState(new VideoBuffAddTargetState(buffEntity));
					list.add(buffEntity);
				} else {
					if (battleBuff.getBuffClassType() == BattleBuff.BuffClassTypeEnum.Ban.ordinal()) {
						commandContext.skillAction().addTargetState(new VideoTargetExceptionState(commandContext.trigger(), AppErrorCodes.TARGET_BAN));
					}
				}
			}
		}
		return list;
	}

	/**
	 * 有机率移除目标buff
	 * 
	 * @param commandContext
	 * @param target
	 */
	public void removeTargetBuffs(CommandContext commandContext, BattleSoldier target) {
		Map<Integer, Float> beRemovedBuffs = commandContext.skill().targetRemoveBuffs();
		this.removeBuffs(commandContext, target, beRemovedBuffs);
		this.removeBuffsByType(commandContext, target, commandContext.skill().targetRemoveBuffTypes());
		this.removeOneBuffByType(commandContext, target, commandContext.skill().targetRemoveOneBuffByType());
	}

	/**
	 * 有机率移除自身buff
	 * 
	 * @param commandContext
	 * @param trigger
	 */
	public void removeSelfBuffs(CommandContext commandContext, BattleSoldier trigger) {
		Map<Integer, Float> beRemovedBuffs = commandContext.skill().selfRemoveBuffs();
		this.removeBuffs(commandContext, trigger, beRemovedBuffs);
	}

	/**
	 * 移除指定类型的buff
	 * 
	 * @param commandContext
	 * @param soldier
	 * @param buffTypes
	 */
	private void removeBuffsByType(CommandContext commandContext, BattleSoldier soldier, Set<Integer> buffTypes) {
		if (buffTypes == null || buffTypes.isEmpty())
			return;
		Set<Integer> beRemoved = new HashSet<>();
		for (BattleBuffEntity buffEntity : soldier.buffHolder().allBuffs().values()) {
			if (buffTypes.contains(buffEntity.battleBuffType()))
				beRemoved.add(buffEntity.battleBuffId());
		}
		if (!beRemoved.isEmpty()) {
			for (Integer buffId : beRemoved) {
				soldier.buffHolder().removeBuffById(buffId);
			}
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(soldier, beRemoved.toArray(new Integer[] {})));
		}
	}

	/**
	 * 有机率移除指定soldier的buff
	 * 
	 * @param commandContext
	 * @param soldier
	 * @param beRemovedBuffs
	 */
	private void removeBuffs(CommandContext commandContext, BattleSoldier soldier, Map<Integer, Float> beRemovedBuffs) {
		if (beRemovedBuffs == null || beRemovedBuffs.isEmpty())
			return;
		List<Integer> removedBuffIds = new ArrayList<Integer>();
		for (Entry<Integer, Float> entry : beRemovedBuffs.entrySet()) {
			int buffId = entry.getKey();
			float rate = entry.getValue();
			if (!RandomUtils.baseRandomHit(rate))
				continue;
			BattleBuffEntity buff = soldier.buffHolder().removeBuffById(buffId);
			if (buff == null)
				continue;
			IBattleBuffLogic buffLogic = buff.battleBuff() != null ? buff.battleBuff().buffLogic() : null;
			if (buffLogic != null)
				buffLogic.onBeforeRemove(commandContext, buff);

			removedBuffIds.add(buffId);
		}
		if (!removedBuffIds.isEmpty())
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(soldier, removedBuffIds.toArray(new Integer[] {})));
	}

	/**
	 * 有机率移除指定soldier的某类型的其中一个buff
	 * 
	 * @param commandContext
	 * @param soldier
	 * @param beRemovedBuffs
	 */
	private void removeOneBuffByType(CommandContext commandContext, BattleSoldier soldier, Map<Integer, Float> beRemovedBuffTypes) {
		if (beRemovedBuffTypes == null || beRemovedBuffTypes.isEmpty())
			return;
		Set<Integer> beRemoved = new HashSet<>();
		List<Integer> selectedBuffs = new ArrayList<Integer>();
		for (Entry<Integer, Float> entry : beRemovedBuffTypes.entrySet()) {
			int type = entry.getKey();
			float rate = entry.getValue();
			if (!RandomUtils.baseRandomHit(rate))
				continue;
			for (BattleBuffEntity buffEntity : soldier.buffHolder().allBuffs().values()) {
				if (type == buffEntity.battleBuffType()) {
					selectedBuffs.add(buffEntity.battleBuffId());
				}
			}
			if (selectedBuffs.size() > 0) {
				int rdm = RandomUtils.nextInt(selectedBuffs.size());
				beRemoved.add(selectedBuffs.get(rdm));
			}
		}
		if (!beRemoved.isEmpty()) {
			for (Integer buffId : beRemoved) {
				soldier.buffHolder().removeBuffById(buffId);
			}
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(soldier, beRemoved.toArray(new Integer[] {})));
		}
	}

	/**
	 * 门派特色(大唐)：增伤
	 * 
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private float damageIncreaseFactionEffect(CommandContext commandContext, BattleSoldier target) {
		BattleSoldier trigger = commandContext.trigger();
		Faction f = trigger.faction();
		float rate = 0F;
		if (f != null && trigger != null && target != null) {
			if (trigger.ifMainCharactor() && target.ifPet()) {
				FactionBattleLogicParam param = f.getFactionBattleLogicParam();
				if (param != null && param instanceof FactionBattleLogicParam_1) {
					FactionBattleLogicParam_1 p = (FactionBattleLogicParam_1) param;
					rate += p.getPetExtraDamagePercentage();
				}
			}
		}
		return rate;
	}

	/**
	 * 门派特色(天宫)：负面法术闪避
	 * 
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private boolean skillTargetDodgeFactionEffect(CommandContext commandContext, BattleSoldier target) {
		if (commandContext.skill().getSkillType() != Skill.SkillType.Negative.ordinal())
			return false;
		if (target == null || target.ifChild())
			return false;
		Faction f = target.faction();
		if (f == null)
			return false;
		FactionBattleLogicParam param = f.getFactionBattleLogicParam();
		if (param == null || !(param instanceof FactionBattleLogicParam_4))
			return false;
		FactionBattleLogicParam_4 p = (FactionBattleLogicParam_4) param;
		return RandomUtils.baseRandomHit(p.getDodgeRate());
	}

	/**
	 * 门派特色(龙宫)：法术必中
	 * 
	 * @param commandContext
	 * @return
	 */
	private boolean skillMustHitFactionEffect(CommandContext commandContext) {
		BattleSoldier trigger = commandContext.trigger();
		if (trigger == null)
			return false;
		Faction f = trigger.faction();
		if (f == null)
			return false;
		if (trigger.ifChild())
			return false;
		FactionBattleLogicParam param = f.getFactionBattleLogicParam();
		if (param != null && param instanceof FactionBattleLogicParam_5) {
			FactionBattleLogicParam_5 p = (FactionBattleLogicParam_5) param;
			boolean hit = RandomUtils.baseRandomHit(p.getRate());
			return hit;
		}
		return false;
	}

	/**
	 * 门派特色(魔王寨)：完全招架攻击
	 * 
	 * @param commandContext
	 * @param target
	 * @return
	 */
	private boolean skillTargetFullDefenseFactionEffect(CommandContext commandContext, BattleSoldier target) {
		if (target == null || target.ifChild())
			return false;
		Skill skill = commandContext.skill();
		if (skill == null)
			return false;
		Faction f = target.faction();
		if (f == null)
			return false;
		FactionBattleLogicParam param = f.getFactionBattleLogicParam();
		if (param == null || !(param instanceof FactionBattleLogicParam_7))
			return false;
		FactionBattleLogicParam_7 p = (FactionBattleLogicParam_7) param;
		if (skill.getId() == Skill.defaultActiveSkillId()) {
			return RandomUtils.baseRandomHit(p.getDefenseRate1());
		} else if (skill.getSkillAttackType() == SkillAttackType.Phy.ordinal()) {
			return RandomUtils.baseRandomHit(p.getDefenseRate2());
		}
		return false;
	}

	/**
	 * 方寸山门派特色
	 * 
	 * @param commandContext
	 * @param target
	 * @param hp
	 * @return
	 */
	private float healIncreaseFactionEffect(CommandContext commandContext, BattleSoldier target, int hp) {
		float addRate = 0F;
		if (target == null || target.ifChild())
			return addRate;
		if (hp > 0) {// 受法术加血
			Faction f = target.faction();
			if (f != null) {
				FactionBattleLogicParam param = f.getFactionBattleLogicParam();
				if (param != null && param instanceof FactionBattleLogicParam_3) {
					FactionBattleLogicParam_3 p = (FactionBattleLogicParam_3) param;
					addRate = p.getHpIncreaePercentage();
				}
			}
		} else if (hp < 0 && target.isGhost()) {// 对鬼魂伤害
			Faction f = commandContext.trigger().faction();
			if (f != null) {
				FactionBattleLogicParam param = f.getFactionBattleLogicParam();
				if (param != null && param instanceof FactionBattleLogicParam_3) {
					FactionBattleLogicParam_3 p = (FactionBattleLogicParam_3) param;
					addRate = p.getHurtIncreasePercentage();
				}
			}
		}
		return addRate;
	}

	/**
	 * 被动技能潜龙在渊影响物理攻击必中
	 * 
	 * @param trigger
	 * @return
	 */
	public boolean skillHidingDragonEffect(Skill skill, BattleSoldier trigger) {
		if (skill.ifPhyAttack()) {
			int dragonSkillId = StaticConfig.get(AppStaticConfigs.HIDING_DRAGON_SKILL_ID).getAsInt(5323);
			if (trigger.skillHolder().battleSkillHolder().containPassiveSkill(dragonSkillId)) {
				IPassiveSkill dragonSkill = PetPassiveSkill.get(dragonSkillId);
				int[] configIds = dragonSkill.getConfigId();
				// 潜龙在渊第一个技能配置，用于设置物理攻击必中
				PassiveSkillConfig config = PassiveSkillConfig.get(configIds[0]);
				String[] params = config.getExtraParams();
				float rate = Integer.parseInt(params[0]);
				return RandomUtils.baseRandomHit(rate);
			}
		}
		return false;
	}
}
