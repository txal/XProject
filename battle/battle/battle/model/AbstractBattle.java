package com.nucleus.logic.core.modules.battle.model;

import org.apache.commons.lang3.time.DateUtils;
import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;

/**
 * 
 * @author Omanhom
 *
 */
public abstract class AbstractBattle implements Battle {
	protected static Log battleLog = LogFactory.getLog("battle.log");
	protected static Log errorLog = LogFactory.getLog("error.log");

	private int commandOpTime = StaticConfig.get(AppStaticConfigs.BATTLE_COMMAND_OPT_SEC).getAsInt(30);

	/**
	 * 战斗操作时间
	 * 
	 * @return
	 */
	protected int commandOpTime() {
		return commandOpTime;
	}

	private int battleRoundStartCancelAuoTime = StaticConfig.get(AppStaticConfigs.BATTLE_ROUND_START_CANCEL_AUTO_SEC).getAsInt(2);

	/**
	 * 战斗回合开始取消自动时间
	 * 
	 * @return
	 */
	protected int battleRoundStartCancelAuoTime() {
		return battleRoundStartCancelAuoTime;
	}

	private float battleStrikeRateReducePerRound = StaticConfig.get(AppStaticConfigs.BATTLE_STRIKE_RATE_REDUCE_PER_ROUND).getAsFloat(0.05F);

	/**
	 * 每回合减少额外受击度
	 * 
	 * @return
	 */
	protected float battleStrikeRateReducePerRound() {
		return battleStrikeRateReducePerRound;
	}

	private float battleStrikeRateReduceRatePerRound = StaticConfig.get(AppStaticConfigs.BATTLE_STRIKE_RATE_REDUCE_RATE_PER_ROUND).getAsFloat(0.7F);

	/**
	 * 每回合减少当前受击度百分比
	 * 
	 * @return
	 */
	protected float battleStrikeRateReduceRatePerRound() {
		return battleStrikeRateReduceRatePerRound;
	}

	private float battleMinMagicAttackFloatRange = StaticConfig.get(AppStaticConfigs.BATTLE_MIN_MAGIC_ATTACK_FLOAT_RANGE).getAsFloat(0.9F);

	/**
	 * 战斗魔法攻击力最小浮动百分比
	 * 
	 * @return
	 */
	@Override
	public float battleMinMagicAttackFloatRange() {
		return battleMinMagicAttackFloatRange;
	}

	private float battleMaxMagicAttackFloatRange = StaticConfig.get(AppStaticConfigs.BATTLE_MAX_MAGIC_ATTACK_FLOAT_RANGE).getAsFloat(1.1F);

	/**
	 * 战斗魔法攻击力最大浮动百分比
	 * 
	 * @return
	 */
	@Override
	public float battleMaxMagicAttackFloatRange() {
		return battleMaxMagicAttackFloatRange;
	}

	private int maxTeamPlayerSize = StaticConfig.get(AppStaticConfigs.MAX_TEAM_MEMBER_SIZE).getAsInt(5);

	@Override
	public int maxTeamPlayerSize() {
		return maxTeamPlayerSize;
	}

	private int maxPositionSize = StaticConfig.get(AppStaticConfigs.BATTLE_FORMAT_MAX_POSITION).getAsInt(14);

	@Override
	public int maxPositionSize() {
		return maxPositionSize;
	}

	private int maxUnitSize = StaticConfig.get(AppStaticConfigs.BATTLE_FORMAT_MAX_UNIT).getAsInt(12);

	@Override
	public int maxUnitSize() {
		return maxUnitSize;
	}

	private int maxCallMonsterSize = StaticConfig.get(AppStaticConfigs.BATTLE_MAX_CALL_MONSTER).getAsInt(1);

	@Override
	public int maxCallMonsterSize() {
		return maxCallMonsterSize;
	}

	private float retreatSuccessRate = StaticConfig.get(AppStaticConfigs.MAX_RETREAT_SUCCESS_RATE).getAsFloat(0.9f);

	@Override
	public float retreatSuccessRate() {
		return retreatSuccessRate;
	}

	@Override
	public Log getLog() {
		return battleLog;
	}

	private float petEscapeHpRate1 = StaticConfig.get(AppStaticConfigs.PET_ESCAPE_HP_RATE_1).getAsFloat(0.2f);

	@Override
	public float petEscapeHpRate1() {
		return petEscapeHpRate1;
	}

	private float petEscapeHpRate2 = StaticConfig.get(AppStaticConfigs.PET_ESCAPE_HP_RATE_2).getAsFloat(0.5f);

	@Override
	public float petEscapeHpRate2() {
		return petEscapeHpRate2;
	}

	private float petEscapeRate1 = StaticConfig.get(AppStaticConfigs.PET_ESCAPE_RATE_1).getAsFloat(0.3f);

	@Override
	public float petEscapeRate1() {
		return petEscapeRate1;
	}

	private float petEscapeRate2 = StaticConfig.get(AppStaticConfigs.PET_ESCAPE_RATE_2).getAsFloat(0.15f);

	@Override
	public float petEscapeRate2() {
		return petEscapeRate2;
	}

	private float petEscapePlusRate = StaticConfig.get(AppStaticConfigs.PET_ESCAPE_PLUS_RATE).getAsFloat(0.15f);

	@Override
	public float petEscapePlusRate() {
		return petEscapePlusRate;
	}

	public void forceOver(long playerId) {
	}

	private float petAutoEscapeSuccessRate = StaticConfig.get(AppStaticConfigs.PET_AUTO_ESCAPE_SUCCESS_RATE).getAsFloat(0.5f);

	@Override
	public float petAutoEscapeSuccessRate() {
		return petAutoEscapeSuccessRate;
	}

	private float certificatedSkillEffectRate = StaticConfig.get(AppStaticConfigs.CERTIFICATED_SKILL_EFFECT_RATE).getAsFloat(0.2f);

	@Override
	public float certificatedSkillEffectRate() {
		return certificatedSkillEffectRate;
	}

	private float battleMinAttackFloatRange = StaticConfig.get(AppStaticConfigs.BATTLE_MIN_ATTACK_FLOAT_RANGE).getAsFloat(0.9F);

	/**
	 * 战斗攻击力最小浮动百分比
	 * 
	 * @return
	 */
	@Override
	public float battleMinAttackFloatRange() {
		return battleMinAttackFloatRange;
	}

	private float battleMaxAttackFloatRange = StaticConfig.get(AppStaticConfigs.BATTLE_MAX_ATTACK_FLOAT_RANGE).getAsFloat(1.1F);

	/**
	 * 战斗攻击力最大浮动百分比
	 * 
	 * @return
	 */
	@Override
	public float battleMaxAttackFloatRange() {
		return battleMaxAttackFloatRange;
	}
	
	private float friendProtectHpRate = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_HP_RATE).getAsFloat(0.3f);
	private int friendProtectDegreeLimit = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_DEGREE_LIMIT).getAsInt(1000);
	private String friendProtectRateFormula = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_RATE_FORMULA).getValue();
	private float friendProtectPlusRate1 = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_RATE_PLUS_1).getAsFloat(0.04f);
	private float friendProtectPlusRate2 = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_RATE_PLUS_2).getAsFloat(0.02f);
	private float friendProtectPlusRate3 = StaticConfig.get(AppStaticConfigs.FRIEND_PROTECT_RATE_PLUS_3).getAsFloat(0.05f);
	@Override
	public float friendProtectHpRate() {
		return friendProtectHpRate;
	}
	
	@Override
	public int friendProtectDegreeLimit() {
		return friendProtectDegreeLimit;
	}
	
	@Override
	public String friendProtectRateFormula() {
		return friendProtectRateFormula;
	}
	
	@Override
	public float friendProtectPlusRate1() {
		return friendProtectPlusRate1;
	}
	@Override
	public float friendProtectPlusRate2() {
		return friendProtectPlusRate2;
	}
	
	@Override
	public float friendProtectPlusRate3() {
		return friendProtectPlusRate3;
	}
	
	private float battleRoundTimeFix = StaticConfig.get(AppStaticConfigs.BATTLE_ROUND_TIME_FIX_FACTOR).getAsFloat(0.2f);
	
	@Override
	public float battleRoundTimeFix() {
		return battleRoundTimeFix;
	}
	
	private long manualRoundReadyTolerantMills = StaticConfig.get(AppStaticConfigs.BATTLE_ROUND_READY_TOLERENT).getAsInt(2) * DateUtils.MILLIS_PER_SECOND;
	@Override
	public long manualRoundReadyTolerant() {
		return manualRoundReadyTolerantMills;
	}
	
	private int maxMagicEquipPower = StaticConfig.get(AppStaticConfigs.MAGIC_EQUIPMENT_MAX_POWER).getAsInt(10);
	@Override
	public int maxMagicEquipPower() {
		return maxMagicEquipPower;
	}
	
	private int roundAddMagicEquipPower = StaticConfig.get(AppStaticConfigs.MAGIC_EQUIPMENT_ROUND_ADD_POWER).getAsInt(1);
	
	@Override
	public int roundAddMagicEquipPower() {
		return roundAddMagicEquipPower;
	}
}
