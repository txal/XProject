package com.nucleus.logic.core.modules.battle.model;

import javax.persistence.Transient;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;
import com.nucleus.logic.core.modules.charactor.model.AptitudeProperties;
import com.nucleus.logic.core.modules.charactor.model.BattleBaseProperties;
import com.nucleus.logic.core.modules.charactor.model.EffectValues;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_10;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_11;
import com.nucleus.logic.core.modules.faction.logic.FactionBattleLogicParam_12;

import io.protostuff.Tag;

/**
 * 战斗单位属性
 *
 * Created by Tony on 4/6/16.
 */
public class BattleSoldierProperties extends EffectValues {

	/** 最大血量 */
	@Tag(500)
	private int maxHp;

	/** 最大法力 */
	@Tag(501)
	private int maxMp;

	public BattleSoldierProperties() {
	}

	public BattleSoldierProperties(BattleUnit battleUnit, BattleSoldier soldier) {
		init(battleUnit, soldier);
	}

	public BattleSoldierProperties(BattleUnit battleUnit, BattleSoldier soldier, int ring) {
		init(battleUnit, soldier, ring);
	}

	public void init(BattleUnit battleUnit, BattleSoldier soldier) {
		init(battleUnit, soldier, 0);
	}

	public void init(BattleUnit battleUnit, BattleSoldier soldier, int ring) {
		BattleBaseProperties bbp = battleUnit.battleBaseProperties(soldier.grade(), ring);
		this.setHp(bbp.getHp());
		this.setSpeed(bbp.getSpeed());
		this.setAttack(bbp.getAttack());
		this.setDefense(bbp.getDefense());
		this.setMaxHp(bbp.getMaxHp());
		this.setCritRate(bbp.getCritRate() + battleCharactorCritRate());
		this.setMagicAttack(bbp.getMagicAttack());
		this.setMagicDefense(bbp.getMagicDefense());
		this.setMagicCritRate(bbp.getMagicCritRate() + battleCharactorCritRate());
		float dodgeRate = 0F;
		if (battleUnit.charactorType() == GeneralCharactor.CharactorType.MainCharactor) {
			dodgeRate = bbp.getDodgeRate() + battleMainCharactorDodgeRate();
		} else {
			dodgeRate = bbp.getDodgeRate() + battleCharactorDodgeRate();
		}
		this.setDodgeRate(dodgeRate);
		this.setMp(bbp.getMp());
		this.setMaxMp(bbp.getMaxMp());
		this.setMagic(bbp.getMagic());
		this.setHitRate(bbp.getHitRate());
		this.setMagicDodgeRate(bbp.getMagicDodgeRate());
		this.setMagicHitRate(bbp.getMagicHitRate());
		this.setMagicDamageDecrease(bbp.getMagicDamageDecrease());
		this.setCritReduceRate(bbp.getCritReduceRate());
		this.setPhyCritReduceRate(bbp.getPhyCritReduceRate());
		this.setMagicCritReduceRate(bbp.getMagicCritReduceRate());
		switch (battleUnit.charactorType()) {
			case MainCharactor:
			case Pet:
				float minSpeedRange = battleInitNonNpcMinSpeedRange();
				float maxSpeedRange = battleInitNonNpcMaxSpeedRange();
				this.setSpeed((int) (RandomUtils.nextInt((int) (minSpeedRange * 100), (int) (maxSpeedRange * 100)) / 100F * bbp.getSpeed()));
				break;
			default:
		}
		// 门派特色
		Faction faction = soldier.faction();
		if (faction != null) {
			FactionBattleLogicParam param = faction.getFactionBattleLogicParam();
			if (param != null && !soldier.ifChild()) {
				if (param instanceof FactionBattleLogicParam_10) {
					FactionBattleLogicParam_10 p = (FactionBattleLogicParam_10) param;
					this.increaseValue(BattleBasePropertyType.CritRate, p.getCritRate());
				} else if (param instanceof FactionBattleLogicParam_11) {
					FactionBattleLogicParam_11 p = (FactionBattleLogicParam_11) param;
					this.increaseValue(BattleBasePropertyType.MagicCritRate, p.getMagicCritRate());
				} else if (param instanceof FactionBattleLogicParam_12) {
					FactionBattleLogicParam_12 p = (FactionBattleLogicParam_12) param;
					this.increaseValue(BattleBasePropertyType.SealHitReduce, p.getSealHitReduce());
				}
			}
		}

	}

	public void reset() {
		this.setAttack(0);
		this.setCritRate(0);
		this.setDefense(0);
		this.setDodgeRate(0);
		this.setHitRate(0);
		this.setHp(0);
		this.setMagic(0);
		this.setMagicCritRate(0);
		this.setMagicDodgeRate(0);
		this.setMagicHitRate(0);
		this.setMp(0);
		this.setSpeed(0);
		this.setMagicAttack(0);
		this.setMagicDefense(0);
		this.setCritReduceRate(0);
		this.setPhyCritReduceRate(0);
		this.setMagicCritReduceRate(0);
		this.maxHp = 0;
		this.maxMp = 0;
	}

	public void increaseValue(int propertyType, float effectValue) {
		increaseValue(BattleBuff.BattleBasePropertyType.values()[propertyType], effectValue);
	}

	public void increaseValue(BattleBaseProperties battleBaseProperties) {
		applyOf(battleBaseProperties);
		this.maxHp += battleBaseProperties.getMaxHp();
		this.maxMp += battleBaseProperties.getMaxMp();
	}

	public void increaseValue(AptitudeProperties aptitudeProperties) {
		final int hp = aptitudeProperties.hp();
		final int mp = aptitudeProperties.mp();
		this.maxHp += hp;
		this.maxMp += mp;

		applyOf(BattleBuff.BattleBasePropertyType.Hp, hp);
		applyOf(BattleBuff.BattleBasePropertyType.Mp, mp);
		applyOf(BattleBuff.BattleBasePropertyType.Speed, aptitudeProperties.speed());
		applyOf(BattleBuff.BattleBasePropertyType.Attack, aptitudeProperties.attack());
		applyOf(BattleBuff.BattleBasePropertyType.Defense, aptitudeProperties.defense());
		applyOf(BattleBuff.BattleBasePropertyType.Magic, aptitudeProperties.magic());
	}

	public void increaseValue(BattleBuff.BattleBasePropertyType propertyType, float effectValue) {
		if (propertyType == BattleBuff.BattleBasePropertyType.Hp) {
			applyOf(BattleBuff.BattleBasePropertyType.Hp, effectValue);
			this.maxHp += effectValue;
		} else if (propertyType == BattleBuff.BattleBasePropertyType.Mp) {
			applyOf(BattleBuff.BattleBasePropertyType.Mp, effectValue);
			this.maxMp += effectValue;
		} else {
			applyOf(propertyType, effectValue);
		}
	}

	public void monsterVary() {
		this.setHp((int) (getHp() * monsterVaryRate()));
		this.setSpeed((int) (getSpeed() * monsterVaryRate()));
		this.setAttack((int) (getAttack() * monsterVaryRate()));
		this.setDefense((int) (getDefense() * monsterVaryRate()));
		this.setMp((int) (getMp() * monsterVaryRate()));
		this.setMagic((int) (getMagic() * monsterVaryRate()));
	}

	private float monsterVaryRate() {
		return RandomUtils.nextInt(95, 106) / 100f;
	}

	public int getSpeed() {
		return getInt(BattleBuff.BattleBasePropertyType.Speed);
	}

	public void setSpeed(int speed) {
		set(BattleBuff.BattleBasePropertyType.Speed, speed);
	}

	public int getAttack() {
		return getInt(BattleBuff.BattleBasePropertyType.Attack);
	}

	public void setAttack(int attack) {
		set(BattleBuff.BattleBasePropertyType.Attack, attack);
	}

	public int getDefense() {
		return getInt(BattleBuff.BattleBasePropertyType.Defense);
	}

	public void setDefense(int defense) {
		set(BattleBuff.BattleBasePropertyType.Defense, defense);
	}

	public int getHp() {
		return getInt(BattleBuff.BattleBasePropertyType.Hp);
	}

	public void setHp(int hp) {
		set(BattleBuff.BattleBasePropertyType.Hp, hp);
	}

	public int getMp() {
		return getInt(BattleBuff.BattleBasePropertyType.Mp);
	}

	public void setMp(int mp) {
		set(BattleBuff.BattleBasePropertyType.Mp, mp);
	}

	public float getCritRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.CritRate);
	}

	@Transient
	public void setCritRate(float critRate) {
		set(BattleBuff.BattleBasePropertyType.CritRate, critRate);
	}

	public float getDodgeRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.DodgeRate);
	}

	@Transient
	public void setDodgeRate(float dodgeRate) {
		set(BattleBuff.BattleBasePropertyType.DodgeRate, dodgeRate);
	}

	public float getMagicCritRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.MagicCritRate);
	}

	@Transient
	public void setMagicCritRate(float magicCritRate) {
		set(BattleBuff.BattleBasePropertyType.MagicCritRate, magicCritRate);
	}

	public float getMagicHitRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.MagicHitRate);
	}

	@Transient
	public void setMagicHitRate(float magicHitRate) {
		set(BattleBuff.BattleBasePropertyType.MagicHitRate, magicHitRate);
	}

	public float getMagicDodgeRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.MagicDodgeRate);
	}

	@Transient
	public void setMagicDodgeRate(float magicDodgeRate) {
		set(BattleBuff.BattleBasePropertyType.MagicDodgeRate, magicDodgeRate);
	}

	public int getMagic() {
		return getInt(BattleBuff.BattleBasePropertyType.Magic);
	}

	public void setMagic(int magic) {
		set(BattleBuff.BattleBasePropertyType.Magic, magic);
	}

	public int getMaxHp() {
		return maxHp;
	}

	public void setMaxHp(int maxHp) {
		this.maxHp = maxHp;
	}

	public int getMaxMp() {
		return maxMp;
	}

	public void setMaxMp(int maxMp) {
		this.maxMp = maxMp;
	}

	public float getHitRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.HitRate);
	}

	@Transient
	public void setHitRate(float hitRate) {
		set(BattleBuff.BattleBasePropertyType.HitRate, hitRate);
	}

	public int getMagicAttack() {
		return getInt(BattleBuff.BattleBasePropertyType.MagicAttack);
	}

	public void setMagicAttack(int magicAttack) {
		set(BattleBuff.BattleBasePropertyType.MagicAttack, magicAttack);
	}

	public int getMagicDefense() {
		return getInt(BattleBuff.BattleBasePropertyType.MagicDefense);
	}

	public void setMagicDefense(int magicDefense) {
		set(BattleBuff.BattleBasePropertyType.MagicDefense, magicDefense);
	}

	public void setMagicDamageDecrease(float magicDamageDecrease) {
		set(BattleBuff.BattleBasePropertyType.MagicDamageDecrease, magicDamageDecrease);
	}

	public float getCritReduceRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.CritRateReduce);
	}

	@Transient
	public void setCritReduceRate(float critReduceRate) {
		set(BattleBuff.BattleBasePropertyType.CritRateReduce, critReduceRate);
	}

	public float getPhyCritReduceRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.PhyCritReduceRate);
	}

	@Transient
	public void setPhyCritReduceRate(float phyCritReduceRate) {
		set(BattleBuff.BattleBasePropertyType.PhyCritReduceRate, phyCritReduceRate);
	}

	public float getMagicCritReduceRate() {
		return getFloat(BattleBuff.BattleBasePropertyType.MagicCritReduceRate);
	}

	@Transient
	public void setMagicCritReduceRate(float magicCritReduceRate) {
		set(BattleBuff.BattleBasePropertyType.MagicCritReduceRate, magicCritReduceRate);
	}

	public String logInfo() {
		StringBuilder builder = new StringBuilder(256);
		builder.append("BattleBaseProperties [speed=");
		builder.append(getSpeed());
		builder.append(", attack=");
		builder.append(getAttack());
		builder.append(", defense=");
		builder.append(getDefense());
		builder.append(", hp=");
		builder.append(getHp());
		builder.append(", maxHp=");
		builder.append(maxHp);
		builder.append(", critRate=");
		builder.append(getCritRate());
		builder.append(", dodgeRate=");
		builder.append(getDodgeRate());
		builder.append(", hitRate=");
		builder.append(getHitRate());
		builder.append(", mp=");
		builder.append(getMp());
		builder.append(", maxMp=");
		builder.append(maxMp);
		builder.append(", magicCritRate=");
		builder.append(getMagicCritRate());
		builder.append(", magicHitRate=");
		builder.append(getMagicHitRate());
		builder.append(", magicDodgeRate=");
		builder.append(getMagicDodgeRate());
		builder.append(", magic=");
		builder.append(getMagic());
		builder.append(", magicAttack=");
		builder.append(getMagicAttack());
		builder.append(", magicDefense=");
		builder.append(getMagicDefense());
		builder.append("]");
		return builder.toString();
	}

	/**
	 * 主人物战斗闪避率
	 *
	 * @return
	 */
	private float battleMainCharactorDodgeRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_MAIN_CHARACTOR_DODGE_RATE).getAsFloat(0.1F);
	}

	/**
	 * 人物战斗闪避率
	 *
	 * @return
	 */
	private float battleCharactorDodgeRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_CHARACTOR_DODGE_RATE).getAsFloat(0.05F);
	}

	/**
	 * 战斗初始化非npc速度最小范围
	 *
	 * @return
	 */
	private float battleInitNonNpcMinSpeedRange() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_INIT_NON_NPC_MIN_SPEED_RANGE).getAsFloat(0.9F);
	}

	/**
	 * 战斗初始化非npc速度最大范围
	 *
	 * @return
	 */
	private float battleInitNonNpcMaxSpeedRange() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_INIT_NON_NPC_MAX_SPEED_RANGE).getAsFloat(1.1F);
	}

	/**
	 * 通用战斗角色暴击率
	 *
	 * @return
	 */
	private float battleCharactorCritRate() {
		return StaticConfig.get(AppStaticConfigs.BATTLE_CHARACTOR_CRIT_RATE).getAsFloat(0.03F);
	}
}
