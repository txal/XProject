/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.List;
import java.util.Map;

import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.model.AptitudeProperties;
import com.nucleus.logic.core.modules.charactor.model.BattleBaseProperties;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.spell.ISpellEffectCalculator;

/**
 * 战斗单元
 * 
 * @author liguo
 */
public interface BattleUnit {
	/** 唯一编号 */
	public long uid();

	/** 玩家编号 0:不可控制, >0:可控制 */
	public long playerId();

	/** 名称 */
	public String name();

	/** 等级 */
	public int grade();

	/** 角色编号 */
	public int charactorId();

	/** 怪物编号 */
	public int monsterId();

	/** 武器模型 */
	public int wpmodel();

	/** 基础战斗属性 */
	public BattleBaseProperties battleBaseProperties(int lv);

	/** 基础战斗属性(与环数相关时额外使用) */
	public BattleBaseProperties battleBaseProperties(int lv, int ring);

	/** 角色经验 */
	public long exp();

	/** 人物类型 */
	public CharactorType charactorType();

	/** 战斗技能Holder */
	public BattleSkillHolder<?> battleSkillHolder();

	/** 门派 */
	public Faction faction();

	/**
	 * 是否变异
	 * 
	 * @return
	 */
	public boolean mutate();

	/**
	 * 装备影响战斗属性
	 * 
	 * @return
	 */
	public BattleBaseProperties equipmentProperties();

	public ISpellEffectCalculator spellEffectCalculator();

	/** 衣服染色 */
	public int dressDyeId();

	/** 头发染色 */
	public int hairDyeId();

	/** 饰物染色 */
	public int accoutermentDyeId();

	/** 初始化怒气 */
	public int initSp();

	/** 资质属性 */
	public AptitudeProperties aptitudeProperties();

	/**
	 * 装备附加资质属性
	 * 
	 * @return
	 */
	public AptitudeProperties equipmentAptitudeProperties();

	/**
	 * 根据等级额外增加闪避(物理/法术闪避)
	 * 
	 * @param level
	 * @return
	 */
	public float extraGeneralDodgeRate(int level);

	/**
	 * 根据等级额外增加命中(物理/法术命中)
	 * 
	 * @param level
	 * @return
	 */
	public float extraGeneralHitRate(int level);

	/** 变身后的模型 */
	public int transformModelId();

	/** 默认技能编号 */
	public int defaultSkillId();

	public void defaultSkillId(int skillId);

	/** 设置持久层hp */
	public void hp(int hp);

	/** 获取持久层hp */
	public int hp();

	/** 设置持久层mp */
	public void mp(int mp);

	/** 获取持久层mp */
	public int mp();

	/** 时装编号 */
	public int fashionId();

	/** 武器攻击 */
	public int weaponAttack(int level, Map<String, Object> params);

	/** 染色方案id */
	public int dyeCaseId();

	/** 装饰id */
	public int ornamentId();

	/** 所穿时装 */
	public List<Integer> fashionDressIds();

	/** 时装ID是否显示 */
	public boolean showDress();

	/** 伴侣id */
	public long fereId();

	/** 与目标友好度 */
	public int friendlyWith(long targetId);

	/** 武器特效 */
	public int weaponEffect();

	/** 初始化普通属性后,其它设置 */
	public void afterBattlePropertiesInit(BattleSoldier soldier);

	/** 目标是否我师傅 */
	public boolean ifMyMaster(long targetId);

	/** 翅膀ID */
	public int wingId();
	
	/** 翅膀染色id */
	public int wingDyeId();
}
