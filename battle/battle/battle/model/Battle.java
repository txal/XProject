/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.Collection;
import java.util.List;
import java.util.Set;

import org.apache.commons.logging.Log;

import com.nucleus.commons.message.TerminalMessage;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 战斗接口
 * 
 * @author liguo
 * 
 */
public interface Battle {
	/** 游戏ID */
	public long getId();

	/** 游戏当前进行的回合数 */
	public int getCount();

	/** 战斗信息 */
	public BattleInfo battleInfo();

	public void setBattleInfo(BattleInfo battleInfo);

	/** 战斗录制 */
	public Video getVideo();

	/** 战斗回合处理器 */
	public BattleRoundProcessor battleRoundProcessor();

	/**
	 * 战斗是否结束
	 * 
	 * @param currentRoundAsMaxCheck
	 * @return
	 */
	public boolean isOver(boolean currentRoundAsMaxCheck);

	/** 回合是否结束 */
	public boolean isRoundOver();

	/** 验证指令时间 */
	public void checkStart();

	/** 检查战斗开始 */
	public boolean checkNotifyStart(long curTime);

	/** 当前是否正在回合计算中 */
	public boolean isRoundRunning();

	/** 回合开始 */
	public void roundStart();

	/** 本次自动战斗下发时间 */
	public long curAutoNotifyTime();

	/** 本次手动战斗下发时间 */
	public long curManualNotifyTime();

	/** 本回合播放时长 */
	public long curEstimatedPlayTime();

	/** 重置回合播放时长 */
	public void resetEstimatedPlayTime();

	/** 增加回合播放时长 */
	public void addEstimatedPlaySec(float seconds);

	/** 新增战斗成员 */
	public List<BattleSoldier> newJoinBattleSoldiers();

	/** 替换成员 */
	public List<Long> substitudeSoldierIds();

	/** 观战,返回被观看的队伍ID */
	public int joinWatch(long playerId, final Set<Long> watchPlayerIds);

	/** 退出观战 */
	public void exitWatch(final Set<Long> watchPlayerIds, boolean notify);

	/** 战斗阵形最大位置数 */
	public int maxPositionSize();

	/** 战斗阵形最大出战单位数 */
	public int maxUnitSize();

	/** 最多允许召唤小怪数量 */
	public int maxCallMonsterSize();

	/** 队伍最大玩家数 */
	public int maxTeamPlayerSize();

	/** 撤退成功率 */
	public float retreatSuccessRate();

	/** 下发场景是否在战斗 */
	public void broadcastSceneInBattle(boolean inBattle);

	/** 战斗从缓存清理后处理 */
	public void clear();

	/** 添加撤退玩家 */
	public void addRetreatPlayerId(long playerId);

	public Log getLog();

	/** 初始化战斗中玩家上阵的全部宠物 */
	public void initPetsOfPlayer();

	/** 抓宠 */
	public void capturePet(CommandContext commandContext);

	public Collection<Long> allPlayerIds();

	public void broadcast(TerminalMessage message, Long... excludePlayerIds);

	public float petEscapeHpRate1();

	public float petEscapeHpRate2();

	public float petEscapeRate1();

	public float petEscapeRate2();

	public float petEscapePlusRate();

	public void populateDefaultSkill(BattlePlayer player, int mainCharactorDefaultBattleSkillId, int petDefaultBattleSkillId);

	public void forceOver(long playerId);

	public void manualRoundReady(long playerId);

	/** 宠物自动逃跑成功率 */
	public float petAutoEscapeSuccessRate();

	/** 认证技能影响物理伤害输出比例 */
	public float certificatedSkillEffectRate();

	/** (物理)战斗攻击力最小浮动百分比 */
	public float battleMinAttackFloatRange();

	/** (物理)战斗攻击力最大浮动百分比 */
	public float battleMaxAttackFloatRange();

	/** (魔法)攻击力最小浮动百分比 */
	public float battleMinMagicAttackFloatRange();

	/** (魔法)攻击力最大浮动百分比 */
	public float battleMaxMagicAttackFloatRange();

	/** 是否进入战斗自动 */
	public boolean needPlayerAutoBattle();

	/** 计算战斗结束时间点 */
	public long getBattleEndTime();

	/** 获取战斗开始时间 */
	public long beginTime();

	/** hp低于指定值可以触发好友保护 */
	public float friendProtectHpRate();

	/** 触发好友保护需求好友度 */
	public int friendProtectDegreeLimit();

	/** 触发好友保护机率基础公式 */
	public String friendProtectRateFormula();

	/** 结拜关系附加保护机率 */
	public float friendProtectPlusRate1();

	/** 师徒关系附加保护机率 */
	public float friendProtectPlusRate2();

	/** 夫妻关系附加保护机率 */
	public float friendProtectPlusRate3();

	/**
	 * 战斗类型对魔法消耗的影响
	 * 
	 * @param context
	 * @param trigger
	 * @param mpSpent
	 */
	public int mpSpent(CommandContext context, BattleSoldier trigger, int mpSpent);

	void onBuffAdd(CommandContext context, BattleSoldier trigger, BattleSoldier target, List<BattleBuffEntity> addBuffs);

	/** 是否可以进行弹幕 */
	public boolean barrage();
	/** 是否可撤退*/
	public boolean retreatable();
	/** 每回合时间修正*/
	public float battleRoundTimeFix();
	/** 客户端调用回合准备就绪允许容错时间*/
	public long manualRoundReadyTolerant();
	/** 最大法力*/
	public int maxMagicEquipPower();
	/** 每回合增加法力*/
	public int roundAddMagicEquipPower();
}
