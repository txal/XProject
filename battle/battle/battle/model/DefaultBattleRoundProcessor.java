/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillLaunchTimingEnum;
import com.nucleus.logic.core.modules.battle.data.Skill;
import com.nucleus.logic.core.modules.battle.dto.AttackDebugInfo;
import com.nucleus.logic.core.modules.battle.dto.DebugVideoRound;
import com.nucleus.logic.core.modules.gm.manager.GmEnvironment;

/**
 * 回合处理器
 * 
 * @author Omanhom
 * 
 */
public class DefaultBattleRoundProcessor implements BattleRoundProcessor {
	private Battle battle;
	/** 所有战斗士兵 */
	private final List<BattleSoldier> soldiers = new ArrayList<BattleSoldier>();
	/** 行动队列 */
	private final List<BattleSoldier> actionQueue = new ArrayList<BattleSoldier>();
	/** 后备队列 */
	private final List<BattleSoldier> backupQueue = new ArrayList<BattleSoldier>();
	private boolean speedChange = false;
	/** 本回合调试信息 */
	private final DebugVideoRound debugInfo = new DebugVideoRound(0);
	/** 撤退玩家编号集 */
	private final Set<Long> retreatPlayerIds = Collections.newSetFromMap(new ConcurrentHashMap<Long, Boolean>());
	/** 回合上下文 */
	private final RoundContext roundContext = new RoundContext();
	/** 客户端调试信息输出开关 */
	private boolean debugEnable;

	public DefaultBattleRoundProcessor(Battle battle) {
		this.battle = battle;
		this.debugEnable = GmEnvironment.getInstance().isClientDebug();
	}

	@Override
	public void handle() {
		initRoundQueue();
		try {
			roundAction();
			if (debugEnable)
				this.battle.getVideo().getRounds().currentVideoRound().setDebugInfo(debugInfo);
		} catch (RuntimeException ex) {
			ex.printStackTrace();
			throw ex;
		}
	}

	public void resetSpeedChange() {
		this.speedChange = false;
	}

	public void speedChanged() {
		this.speedChange = true;
	}

	public List<BattleSoldier> getActionQueue() {
		return actionQueue;
	}

	/**
	 * 初始回合执行队列
	 */
	protected void initRoundQueue() {
		soldiers.clear();
		actionQueue.clear();
		backupQueue.clear();
		if (debugEnable)
			debugInfo.clear();
		battle.getVideo().getRounds().initCurrentVideoRound(battle);
		soldiers.addAll(battle.battleInfo().curRoundActionQueue());
		actionQueue.addAll(battle.battleInfo().curRoundActionQueue());
		if (debugEnable)
			debugInfo.setRound(battle.getCount());
		resetSpeedChange();
	}

	public void resort() {
		if (actionQueue.size() <= 1)
			return;
		Collections.sort(actionQueue);
	}

	/** RoundProcess */
	protected void roundAction() {
		battle.resetEstimatedPlayTime();
		this.roundContext.setState(RoundContext.RoundState.RoundStart);
		this.roundContext.setRound(battle.getCount());
		// Execute round start buffs & decrease strike rate
		for (int i = 0; i < soldiers.size(); i++) {
			BattleSoldier soldier = soldiers.get(i);
			if (null == soldier)
				continue;
			soldier.setCurRoundProcessor(this);
			soldier.clearRoundPsssiveEffect();
			soldier.executeRoundStartBuffs();
			soldier.skillHolder().passiveSkillEffectByTiming(soldier, soldier.getCommandContext(), PassiveSkillLaunchTimingEnum.RoundStart);
			// 战斗开始的处理
			if (battle.getCount() == 1) {
				soldier.skillHolder().passiveSkillEffectByTiming(soldier, soldier.getCommandContext(), PassiveSkillLaunchTimingEnum.BattleStart);
			}
			soldier.decreaseStrikeRatePerRound();
			soldier.clearRoundBeAttackTimes();
		}
		executePreActions();// 执行前置动作
		// 如果没有设置指令则重新设置
		for (int i = 0; i < soldiers.size(); i++) {
			BattleSoldier soldier = soldiers.get(i);
			if (soldier == null)
				continue;
			if (soldier.getCommandContext() == null)
				soldier.autoBattle();
			forceSkill(soldier);
			soldier.setActionDone(false);// 重新设置为未行动状态,某些单位行动的时候(如给目标加buff)可能会判断目标是否行动过而产生不同的逻辑
			soldier.team().setCurrentRoundDeadCount(0);
		}

		this.roundContext.setState(RoundContext.RoundState.RoundAction);
		// Execute soldiers rounds
		boolean isBattleOver = executeActions();

		this.roundContext.setState(RoundContext.RoundState.RoundOver);
		if (!isBattleOver) {
			// Execute round end buffs
			for (int i = 0; i < soldiers.size(); i++) {
				BattleSoldier trigger = soldiers.get(i);
				if (null == trigger)
					continue;
				trigger.setLastRoundBeAttackTimes(trigger.roundBeAttackTimes());// 回合结束的时候把本回合受击次数记录下来
				trigger.executeRoundEndBuffs();
				trigger.increateMagicEquipmentMana();
				trigger.skillHolder().passiveSkillEffectByTiming(null, null, PassiveSkillLaunchTimingEnum.RoundOver);
				trigger.destoryCommandContext();// bugfix:如果宠物未出手而死亡,导致下一回合无法下指令
			}
			this.roundContext.clear();
		}
	}

	private void forceSkill(BattleSoldier soldier) {
		// 死亡后有可能被救活,如果有强制技能依然执行
		// if (soldier.isDead())
		// return;
		Skill forceSkill = soldier.forceSkill();
		if (null != forceSkill) {
			soldier.getCommandContext().setSkill(forceSkill);
			soldier.getCommandContext().populateTarget(soldier.getForceTarget());
			soldier.setForceTarget(null);
		}
	}

	protected boolean isAllDead(List<BattleSoldier> soldiers) {
		boolean result = true;
		if (null == soldiers || soldiers.isEmpty())
			return result;
		for (int i = 0; i < soldiers.size(); i++) {
			BattleSoldier soldier = soldiers.get(i);
			if (!soldier.isDead()) {
				result = false;
				break;
			}
		}
		return result;
	}

	protected void executePreActions() {
		List<BattleSoldier> list = new ArrayList<>(this.actionQueue);
		Collections.sort(list);
		Iterator<BattleSoldier> it = list.iterator();
		while (it.hasNext()) {
			BattleSoldier trigger = it.next();
			if (trigger != null && !trigger.isDead() && !trigger.isLeave()) {
				trigger.skillHolder().passiveSkillEffectByTiming(trigger, trigger.getCommandContext(), PassiveSkillLaunchTimingEnum.PreAction);
			}
		}
	}

	private boolean executeActions() {
		boolean isBattleOver = false;
		if (debugEnable)
			debugInfo.addReadyInfos(actionQueue);
		do {
			Collections.sort(actionQueue);
			isBattleOver = executeActionQueue();
			if (isBattleOver)
				break;
			if (!backupQueue.isEmpty()) {
				actionQueue.addAll(backupQueue);
				backupQueue.clear();
			}
		} while (!actionQueue.isEmpty() && !isAllDead(actionQueue));
		return isBattleOver;
	}

	private boolean executeActionQueue() {
		boolean isBattleOver = false;
		while (!actionQueue.isEmpty()) {
			if (this.speedChange)
				Collections.sort(actionQueue);
			BattleSoldier trigger = actionQueue.remove(actionQueue.size() - 1);
			if (null == trigger || trigger.isLeave())
				continue;
			isBattleOver = battle.isOver(false);
			if (isBattleOver || battle.isRoundOver())
				break;
			trigger.actionStart();
			if (!trigger.isActionDone() && trigger.isDead())
				backupQueue.add(trigger);
		}
		return isBattleOver;
	}

	@Override
	public void debugInfo(CommandContext commandContext, int code) {
		if (!debugEnable)
			return;
		if (code != 0) {// 技能非正常施放
			StringBuilder sb = new StringBuilder();
			sb.append("trigger:");
			sb.append(commandContext.trigger().name()).append(", skill:").append(commandContext.skill().getName());
			if (commandContext.target() != null)
				sb.append(", target:").append(commandContext.target().name());
			sb.append(", result:").append(code);
			this.debugInfo.info(sb.toString());

		} else {
			for (AttackDebugInfo info : commandContext.getDebugInfoList())
				this.debugInfo.info(info.toString());
		}
	}

	@Override
	public void degugInfo(String info) {
		if (!debugEnable)
			return;
		this.debugInfo.info(info);
	}

	@Override
	public Set<Long> retreatPlayerId() {
		return this.retreatPlayerIds;
	}

	@Override
	public void clear() {
		retreatPlayerIds.clear();
	}

	public Battle getBattle() {
		return battle;
	}

	@Override
	public RoundContext context() {
		return this.roundContext;
	}

	@Override
	public boolean debugEnable() {
		return this.debugEnable;
	}

	public void apply(BattleSoldier soldier) {
		this.soldiers.add(soldier);
	}

	public List<BattleSoldier> soldiers() {
		return this.soldiers;
	}
}
