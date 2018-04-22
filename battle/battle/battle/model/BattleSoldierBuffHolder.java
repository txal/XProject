/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battlebuff.IBattleBuffLogic;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffBanStateTipsEnum;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffExecuteStage;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBuffType;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BuffClassTypeEnum;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.constants.CommonEnums.BattleCommandType;

/**
 * @author liguo
 * 
 */
public class BattleSoldierBuffHolder {

	/** ============================所有buff分类 - START============================ */
	/** 所有非特殊buff - key:battleBuffId */
	private final Map<Integer, BattleBuffEntity> nonSpecialbuffsMap = new HashMap<Integer, BattleBuffEntity>();

	/** 所有特殊buff列表 - key:battleBuffId */
	private final Map<Integer, BattleBuffEntity> specialBuffsMap = new HashMap<Integer, BattleBuffEntity>();

	/** 所有异常状态buff列表 - key:battleBuffId */
	private final Map<Integer, BattleBuffEntity> abnormalBuffsMap = new HashMap<Integer, BattleBuffEntity>();

	/** 所有辅助状态buff列表 - key:battleBuffId */
	private final Map<Integer, BattleBuffEntity> assistBuffsMap = new HashMap<Integer, BattleBuffEntity>();

	/** 所有临时状态buff列表 - key:battleBuffId */
	private final Map<Integer, BattleBuffEntity> temporaryBuffsMap = new HashMap<Integer, BattleBuffEntity>();

	/**
	 * 隐身buff
	 */
	private final Map<Integer, BattleBuffEntity> hiddenBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** ============================所有buff分类 - END============================ */

	/** ============================buff结算分类 - START============================ */
	/** 回合开始buff */
	private Map<Integer, BattleBuffEntity> roundStartBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();

	/** 行动开始封印buff - key:battleBuffId 通常只存在一个 */
	private Map<Integer, BattleBuffEntity> actionStartBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();

	/** 行动结束buff列表 - key:battleBuffId */
	private Map<Integer, BattleBuffEntity> actionEndBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();

	/** 回合结束buff - key:battleBuffId */
	private Map<Integer, BattleBuffEntity> roundEndBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();

	/** 属性buff */
	private Map<Integer, BattleBuffEntity> basePropertyBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();

	/** 反击buff */
	private Map<Integer, BattleBuffEntity> strikeBackBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** 反弹buff */
	private Map<Integer, BattleBuffEntity> reboundBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** 受击死亡触发buff */
	private Map<Integer, BattleBuffEntity> deadBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** 攻击之前触发buff */
	private Map<Integer, BattleBuffEntity> beforeAttackBuffsMap = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** ============================buff结算分类 - END============================ */
	/**
	 * 缓存全部buff
	 */
	private Map<Integer, BattleBuffEntity> allBuffs = new ConcurrentHashMap<Integer, BattleBuffEntity>();
	/** buff影响对象 */
	protected BattleSoldier battleSoldier;

	public BattleSoldierBuffHolder(BattleSoldier battleSoldier) {
		this.battleSoldier = battleSoldier;
	}

	public boolean addBuff(BattleBuffEntity buffEntity) {
		if (buffEntity == null) {
			return false;
		}
		if (battleSoldier.immuneBuffer()) {
			return false;
		}
		// 如果当前buff是封印buff且目标已经行动完毕,则回合数+1
		buffAddRoundCheck(buffEntity);
		BattleBuff battleBuff = buffEntity.battleBuff();
		int battleBuffId = battleBuff.getId();
		int battleBuffType = battleBuff.getBuffType();
		/** ============================进行buff分类 - START============================ */
		if (battleBuffType == BattleBuffType.Hidden.ordinal()) {// 隐身buff特殊处理
			if (!this.hiddenBuffsMap.isEmpty())
				return false;
			this.hiddenBuffsMap.put(battleBuffId, buffEntity);
		} else if (BattleBuffType.SpecialStatus.ordinal() == battleBuffType) { // 添加特殊状态buff
			if (specialBuffsMap.containsKey(battleBuffId)) {
				return false;
			}
			specialBuffsMap.put(battleBuffId, buffEntity);
		} else { // 添加非特殊状态buff
			if (nonSpecialbuffsMap.containsKey(battleBuffId)) {
				return false;
			}
			boolean success = false;
			if (BattleBuffType.AbnormalStatus.ordinal() == battleBuffType) {
				success = addStatusBuff(abnormalBuffsMap, abnormalStatusMaxBuff(), buffEntity);
			} else if (BattleBuffType.AssistStatus.ordinal() == battleBuffType) {
				success = addStatusBuff(assistBuffsMap, assistStatusMaxBuff(), buffEntity);
			} else if (BattleBuffType.TemporaryStatus.ordinal() == battleBuffType) {
				success = addStatusBuff(temporaryBuffsMap, temporaryStatusMaxBuff(), buffEntity);
			}
			if (!success)
				return false;
		}

		/** ============================进行buff分类 - END============================ */

		/** ============================进行buff结算分类 - START============================ */
		buffEntity.setEffectSoldier(battleSoldier);
		for (int buffExecuteState : battleBuff.buffsExecuteStageSet()) {
			if (buffExecuteState == BattleBuffExecuteStage.BaseProperty.ordinal()) {
				basePropertyBuffsMap.put(battleBuffId, buffEntity);
				if (buffEntity.battleBuff().hasSpeedChange()) {
					if (battleSoldier.getCurRoundProcessor() != null)
						battleSoldier.getCurRoundProcessor().speedChanged();
				}
			} else if (buffExecuteState == BattleBuffExecuteStage.RoundStart.ordinal()) {
				roundStartBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.ActionStart.ordinal()) {
				actionStartBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.ActionEnd.ordinal()) {
				actionEndBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.RoundEnd.ordinal()) {
				roundEndBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.StrikeBack.ordinal()) {
				if (!strikeBackBuffsMap.isEmpty()) {
					return false;
				}
				strikeBackBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.Rebound.ordinal()) {
				this.reboundBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.Dead.ordinal()) {
				this.deadBuffsMap.put(battleBuffId, buffEntity);
			} else if (buffExecuteState == BattleBuffExecuteStage.BeforeAttack.ordinal()) {
				this.beforeAttackBuffsMap.put(battleBuffId, buffEntity);
			}
		}

		/** ============================进行buff结算分类 - END============================ */

		this.allBuffs.put(battleBuffId, buffEntity);
		buffEntity.effectWhenGetBuff();
		return true;
	}

	/**
	 * 如果当前buff目标已经行动完毕,给该目标施加封印类buff的时候回合数要+1
	 * 
	 * @param buffEntity
	 */
	private void buffAddRoundCheck(BattleBuffEntity buffEntity) {
		if (buffEntity.battleBuff().getBuffClassType() == BuffClassTypeEnum.Ban.ordinal()) {
			if (battleSoldier.isActionDone()) {
				int round = buffEntity.getBuffPersistRound();
				round += 1;
				buffEntity.setBuffPersistRound(round);
			}
		}

	}

	/**
	 * 添加状态buff
	 * 
	 * @param statusBuffsMap
	 * @param maxBuffCount
	 * @param buffEntity
	 */
	private boolean addStatusBuff(Map<Integer, BattleBuffEntity> statusBuffsMap, int maxBuffCount, BattleBuffEntity buffEntity) {
		// 已存在同类且不能叠加的情况
		if (!buffEntity.battleBuff().isSameClassTypePileable() && sameClassTypeBuffExist(statusBuffsMap, buffEntity.battleBuff().getBuffClassType()))
			return false;
		int curAbnormalBuffSize = statusBuffsMap.size();
		if (curAbnormalBuffSize >= maxBuffCount) {
			BattleBuffEntity removeBuffEntity = statusBuffsMap.remove(statusBuffsMap.keySet().iterator().next());
			nonSpecialbuffsMap.remove(removeBuffEntity.battleBuffId());
		}
		int battleBuffId = buffEntity.battleBuffId();
		statusBuffsMap.put(battleBuffId, buffEntity);
		nonSpecialbuffsMap.put(battleBuffId, buffEntity);
		return true;
	}

	private boolean sameClassTypeBuffExist(Map<Integer, BattleBuffEntity> statusBuffsMap, int classType) {
		for (Iterator<BattleBuffEntity> it = statusBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().getBuffClassType() == classType)
				return true;
		}
		// 2016-07-04 同类判断增加特殊buff判断
		for (Iterator<BattleBuffEntity> it = this.specialBuffsMap.values().iterator(); it.hasNext();) {
			if (it.next().battleBuff().getBuffClassType() == classType)
				return true;
		}
		return false;
	}

	public BattleBuffEntity strikeBackBuffEntity() {
		BattleBuffEntity strikeBackBuffEntity = null;
		if (strikeBackBuffsMap.isEmpty()) {
			return strikeBackBuffEntity;
		}

		BattleBuffEntity buffEntity = this.strikeBackBuffsMap.values().iterator().next();
		if (null != buffEntity) {
			strikeBackBuffEntity = buffEntity;
		}

		return strikeBackBuffEntity;
	}

	public boolean isCommandBanned(BattleCommandType commandType) {
		boolean isBanned = false;
		if (this.actionStartBuffsMap.isEmpty()) {
			return isBanned;
		}
		for (BattleBuffEntity buffEntity : this.actionStartBuffsMap.values()) {
			List<BattleCommandType> banCommandTypeList = buffEntity.battleBuff().banBattleCommandTypes();
			if (banCommandTypeList.contains(commandType)) {
				isBanned = true;
				break;
			}
		}
		return isBanned;
	}

	public boolean isAttackBanned() {
		boolean isBanned = false;
		if (this.actionStartBuffsMap.isEmpty()) {
			return isBanned;
		}
		for (BattleBuffEntity buffEntity : this.actionStartBuffsMap.values()) {
			List<BattleCommandType> banCommandTypeList = buffEntity.battleBuff().banBattleCommandTypes();
			if (banCommandTypeList.contains(BattleCommandType.Normal) || banCommandTypeList.contains(BattleCommandType.Skill) || banCommandTypeList.contains(BattleCommandType.SpecialSkill)) {
				isBanned = true;
				break;
			}
		}
		return isBanned;
	}

	/**
	 * 是否封禁指令,如果封禁,是否提示,1不提示,2提示
	 * 
	 * @param commandType
	 * @return
	 */
	public int buffBanState(BattleCommandType commandType) {
		int state = BattleBuffBanStateTipsEnum.NO.ordinal();// 默认状态不封指令
		if (this.actionStartBuffsMap.isEmpty())
			return state;
		for (BattleBuffEntity buffEntity : this.actionStartBuffsMap.values()) {
			List<BattleCommandType> list = buffEntity.battleBuff().banBattleCommandTypes();
			if (!list.contains(commandType))
				continue;
			state = buffEntity.battleBuff().getSkillActionStatusCode();
			// if (buffEntity.battleBuff().isShowTips())
			// state = BattleBuffBanStateTipsEnum.BanWithTips.ordinal();// 提示封禁状态
			// else
			// state = BattleBuffBanStateTipsEnum.BanWithoutTips.ordinal();
			break;
		}
		return state;
	}

	public float baseEffects(BattleBasePropertyType battleBasePropertyType) {
		float effectValue = 0;
		for (BattleBuffEntity buffEntity : basePropertyBuffsMap.values()) {
			effectValue += buffEntity.basePropertyEffect(battleBasePropertyType);
		}
		return effectValue;
	}

	public float propertyValueEffect(CommandContext commandContext, BattleBasePropertyType propertyType) {
		float effectValue = 0;
		for (BattleBuffEntity buffEntity : basePropertyBuffsMap.values()) {
			BattleBuff buff = buffEntity.battleBuff();
			IBattleBuffLogic logic = buff.buffLogic();
			if (logic != null && !logic.propertyEffectable(commandContext, propertyType))
				continue;
			effectValue += buffEntity.basePropertyEffect(propertyType);
		}
		return effectValue;
	}

	/** 结算回合开始buffs */
	public void executeRoundStartBuffs() {
		for (Iterator<BattleBuffEntity> it = this.roundStartBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			buff.executeRoundStartBuff();
		}
	}

	/** 结算回合结束buffs */
	public void executeRoundEndBuffs() {
		boolean soldierDead = this.battleSoldier.isDead();
		for (Iterator<BattleBuffEntity> it = this.roundEndBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			BattleBuff battleBuff = buff.battleBuff();
			if (!soldierDead || battleBuff.isDeadTreatment())
				buff.executeRoundEndBuff();
		}
		// reduce buffs
		reduceBuffs(this.allBuffs);
	}

	/** 结算行动开始buff */
	public void executeActionStartBuffs() {
		if (this.actionStartBuffsMap.isEmpty())
			return;
		for (BattleBuffEntity buff : this.actionStartBuffsMap.values()) {
			IBattleBuffLogic logic = buff.battleBuff().buffLogic();
			if (logic != null)
				logic.onActionStart(this.battleSoldier.getCommandContext(), buff);
		}
	}

	/** 结算行动结束buff */
	public void executeActionEndBuffs() {
		if (this.actionEndBuffsMap.isEmpty())
			return;
		for (BattleBuffEntity buf : this.actionEndBuffsMap.values()) {
			IBattleBuffLogic logic = buf.battleBuff().buffLogic();
			if (logic != null)
				logic.onActionEnd(this.battleSoldier.getCommandContext(), buf);
		}
	}

	/**
	 * 受击反弹
	 * 
	 * @param commandContext
	 */
	public void buffEffectWhenUnderAttack(CommandContext commandContext) {
		if (this.reboundBuffsMap.isEmpty())
			return;
		for (Iterator<BattleBuffEntity> it = this.reboundBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buffEntity = it.next();
			IBattleBuffLogic logic = buffEntity.battleBuff().buffLogic();
			if (logic != null)
				logic.underAttack(commandContext, buffEntity);
		}
	}

	/**
	 * 受击死亡
	 * 
	 * @param commandContext
	 */
	public void buffEffectWhenAttackDead(CommandContext commandContext) {
		if (this.deadBuffsMap.isEmpty())
			return;
		for (Iterator<BattleBuffEntity> it = this.deadBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buffEntity = it.next();
			IBattleBuffLogic logic = buffEntity.battleBuff().buffLogic();
			if (logic != null)
				logic.attackDead(commandContext, buffEntity);
		}
	}

	/**
	 * 攻击之前
	 * 
	 * @param commandContext
	 */
	public void buffEffectBeforeAttack(CommandContext commandContext) {
		if (this.beforeAttackBuffsMap.isEmpty())
			return;
		for (Iterator<BattleBuffEntity> it = this.beforeAttackBuffsMap.values().iterator(); it.hasNext();) {
			BattleBuffEntity buffEntity = it.next();
			IBattleBuffLogic logic = buffEntity.battleBuff().buffLogic();
			if (logic != null)
				logic.beforeAttack(commandContext, buffEntity);
		}
	}

	public void antiSkill(CommandContext commandContext) {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			IBattleBuffLogic logic = buff.battleBuff().buffLogic();
			if (logic != null)
				logic.beforeSkillFire(commandContext, buff);
		}
	}

	public void antiBuff(CommandContext commandContext) {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			IBattleBuffLogic logic = buff.battleBuff().buffLogic();
			if (logic != null)
				logic.antiBuff(commandContext, buff.battleBuff().getBuffParam());
		}
	}

	/**
	 * 结算buffs
	 * 
	 * @param stateBuffsMap
	 */
	private void reduceBuffs(Map<Integer, BattleBuffEntity> stateBuffsMap) {
		if (stateBuffsMap.isEmpty()) {
			return;
		}
		for (BattleBuffEntity buffEntity : stateBuffsMap.values()) {
			buffEntity.reduceBuffRound();
		}
	}

	public Map<Integer, BattleBuffEntity> allBuffs() {
		return this.allBuffs;
	}

	/**
	 * 移除指定buff
	 * 
	 * @param buffId
	 * @return
	 */
	public BattleBuffEntity removeBuffById(int buffId) {
		// 先从全局里面移除，然后再根据buff自身所在map去移除
		BattleBuffEntity buff = this.allBuffs.remove(buffId);
		this.nonSpecialbuffsMap.remove(buffId);
		this.specialBuffsMap.remove(buffId);
		this.hiddenBuffsMap.remove(buffId);

		this.abnormalBuffsMap.remove(buffId);
		this.assistBuffsMap.remove(buffId);
		this.temporaryBuffsMap.remove(buffId);

		this.roundStartBuffsMap.remove(buffId);
		this.actionStartBuffsMap.remove(buffId);
		this.actionEndBuffsMap.remove(buffId);
		this.roundEndBuffsMap.remove(buffId);
		this.basePropertyBuffsMap.remove(buffId);
		this.strikeBackBuffsMap.remove(buffId);
		this.reboundBuffsMap.remove(buffId);
		this.deadBuffsMap.remove(buffId);
		this.beforeAttackBuffsMap.remove(buffId);
		return buff;
	}

	/**
	 * 是否隐身
	 * 
	 * @return
	 */
	public boolean isHidden() {
		return !this.hiddenBuffsMap.isEmpty();
	}

	/**
	 * 是否存在指定buff
	 * 
	 * @param buffId
	 * @return
	 */
	public boolean hasBuff(int buffId) {
		return this.allBuffs.containsKey(buffId);
	}

	/**
	 * 是否存在阻止复活的buff
	 * 
	 * @return
	 */
	public boolean hasPreventReliveBuff() {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().isPreventRelive())
				return true;
		}
		return false;
	}

	/**
	 * 是否有阻止治疗的buff
	 * 
	 * @return
	 */
	public boolean hasPreventHealBuff() {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().isPreventHeal())
				return true;
		}
		return false;
	}

	/**
	 * 有阻止离开的buff(亦即有死亡时生效的buff)
	 * 
	 * @return
	 */
	public boolean hasPreventLeaveBuff() {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().isForDead())
				return true;
		}
		return false;
	}

	/**
	 * 异常状态最大buff数
	 * 
	 * @return
	 */
	private int abnormalStatusMaxBuff() {
		return StaticConfig.get(AppStaticConfigs.ABNORMAL_STATUS_MAX_BUFF).getAsInt(3);
	}

	/**
	 * 辅助状态最大buff数
	 * 
	 * @return
	 */
	private int assistStatusMaxBuff() {
		return StaticConfig.get(AppStaticConfigs.ASSIST_STATUS_MAX_BUFF).getAsInt(3);
	}

	/**
	 * 临时状态最大buff数
	 * 
	 * @return
	 */
	private int temporaryStatusMaxBuff() {
		return StaticConfig.get(AppStaticConfigs.TEMPORARY_STATUS_MAX_BUFF).getAsInt(3);
	}

	public BattleBuffEntity getBuff(int buffId) {
		return this.allBuffs.get(buffId);
	}

	public boolean hasPreventAutoEscapeBuff() {
		for (Iterator<BattleBuffEntity> it = this.allBuffs.values().iterator(); it.hasNext();) {
			BattleBuffEntity buff = it.next();
			if (buff.battleBuff().isPreventAutoEscape())
				return true;
		}
		return false;
	}

	/**
	 * 中了封印buff
	 * 
	 * @return
	 */
	public boolean hasBanBuff() {
		return this.allBuffs.values().stream().anyMatch(buff -> buff.battleBuff().getBuffClassType() == BuffClassTypeEnum.Ban.ordinal());
	}

	/**
	 * 能否接受使用物品
	 * 
	 * @param itemId
	 * @return
	 */
	public boolean antiItem(int itemId) {
		return this.allBuffs.values().stream().anyMatch(buff -> buff.battleBuff().antiItem(itemId));
	}
}
