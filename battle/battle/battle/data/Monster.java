package com.nucleus.logic.core.modules.battle.data;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.persistence.Transient;

import org.apache.commons.lang3.StringUtils;
import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.commons.utils.IdUtils;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.commons.utils.SpringUtils;
import com.nucleus.logic.core.modules.battle.model.BattlePlayer;
import com.nucleus.logic.core.modules.battle.model.BattleSkillHolder;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.BattleTeam;
import com.nucleus.logic.core.modules.battle.model.BattleUnit;
import com.nucleus.logic.core.modules.battle.model.MonsterBattleSkillHolder;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.data.Pet;
import com.nucleus.logic.core.modules.charactor.model.AptitudeProperties;
import com.nucleus.logic.core.modules.charactor.model.BattleBaseProperties;
import com.nucleus.logic.core.modules.charactor.model.BattleUnitExtraProperties;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.scene.data.Model;
import com.nucleus.logic.core.modules.scene.logic.NameLogic;
import com.nucleus.logic.core.modules.scene.manager.NameLogicManager;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.modules.spell.ISpellEffectCalculator;
import com.nucleus.logic.core.modules.spell.MonsterSpellEffectCalculator;
import com.nucleus.player.service.ScriptService;

/**
 * 怪物
 * 
 * @author liguo
 */
public class Monster implements BroadcastMessage, BattleUnit {
	public static Monster get(int id) {
		return StaticDataManager.getInstance().get(Monster.class, id);
	}

	/** 怪物类型 */
	public enum MonsterType {
		/** 非怪物 */
		None,
		/** 正常怪 */
		Regular,
		/** 头领 */
		Boss,
		/** 普通宝宝 */
		Baobao,
		/** 变异宝宝 */
		Mutate
	}

	/** 怪物编号 */
	private int id;
	/** 名称类型 */
	private int nameType;
	/** 名称 */
	private String name;
	/** 能力等级 公式 */
	private String levelFormula;
	/** 修炼等级公式 */
	private String spellLevelFormula;
	/** 对应宠物编号 */
	@DataId(value = Pet.class, cacheClass = GeneralCharactor.class)
	private int petId;
	/** 原始贴图 */
	private int texture;
	/** 模型编号 */
	@DataId(Model.class)
	private int modelId;
	/** 动作编号 */
	private int anim;
	/** 缩放比例 */
	private float scale;
	/** 变色颜色,示例: 0,0,0;1,1,1;2,2,2 */
	private String mutateColor;
	/** 变色贴图 */
	private int mutateTexture;
	/** 怪物战斗技能 */
	private BattleSkillHolder<Monster> skillHolder;
	/** 主动技能权重信息 */
	private SkillsWeight skillsWeight;
	/** 血量公式 */
	private String hp;
	/** 攻击力公式 */
	private String attack;
	/** 防御公式 */
	private String defense;
	/** 灵力公式 */
	private String magic;
	/** 速度公式 */
	private String speed;
	/** 法力公式 */
	private String mp;
	/** 暴击率公式 */
	private String critRate;
	/** 闪避率公式 */
	private String dodgeRate;
	/** 修炼id列表 */
	private int[] spellIds;
	/** 关联武器id */
	private int wpmodel;
	/** 修炼公式 */
	private String[] spellFormulas;
	/** 技能权重信息 */
	private String activeSkillsInfo;
	/** 回合前执行的技能 */
	private int preRoundSkillId;
	/** 是否魅怪 */
	private boolean mei;
	/** 被动技能 */
	private Set<Integer> passiveSkills;
	/** 武器攻击公式 */
	private String weaponAttackFormula;
	/** 装饰编号，大于0开启 */
	private int ornamentId;

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getNameType() {
		return nameType;
	}

	public void setNameType(int nameType) {
		this.nameType = nameType;
	}

	public String getLevelFormula() {
		return levelFormula;
	}

	public void setLevelFormula(String levelFormula) {
		this.levelFormula = levelFormula;
	}

	public String getSpellLevelFormula() {
		return spellLevelFormula;
	}

	public void setSpellLevelFormula(String spellLevelFormula) {
		this.spellLevelFormula = spellLevelFormula;
	}

	public int getPetId() {
		return petId;
	}

	public void setPetId(int petId) {
		this.petId = petId;
	}

	public int getTexture() {
		return texture;
	}

	public void setTexture(int texture) {
		this.texture = texture;
	}

	public int getModelId() {
		return modelId;
	}

	public void setModelId(int modelId) {
		this.modelId = modelId;
	}

	public int getAnim() {
		return anim;
	}

	public void setAnim(int anim) {
		this.anim = anim;
	}

	public float getScale() {
		return scale;
	}

	public void setScale(float scale) {
		this.scale = scale;
	}

	public String getMutateColor() {
		return mutateColor;
	}

	public void setMutateColor(String mutateColor) {
		this.mutateColor = mutateColor;
	}

	public int getMutateTexture() {
		return mutateTexture;
	}

	public void setMutateTexture(int mutateTexture) {
		this.mutateTexture = mutateTexture;
	}

	public String getHp() {
		return hp;
	}

	public void setHp(String hp) {
		this.hp = hp;
	}

	public String getAttack() {
		return attack;
	}

	public void setAttack(String attack) {
		this.attack = attack;
	}

	public String getDefense() {
		return defense;
	}

	public void setDefense(String defense) {
		this.defense = defense;
	}

	public String getMagic() {
		return magic;
	}

	public void setMagic(String magic) {
		this.magic = magic;
	}

	public String getSpeed() {
		return speed;
	}

	public void setSpeed(String speed) {
		this.speed = speed;
	}

	public String getMp() {
		return mp;
	}

	public void setMp(String mp) {
		this.mp = mp;
	}

	public String getCritRate() {
		return critRate;
	}

	public void setCritRate(String critRate) {
		this.critRate = critRate;
	}

	public String getDodgeRate() {
		return dodgeRate;
	}

	public void setDodgeRate(String dodgeRate) {
		this.dodgeRate = dodgeRate;
	}

	public int[] getSpellIds() {
		return spellIds;
	}

	public void setSpellIds(int[] spellIds) {
		this.spellIds = spellIds;
	}

	public String[] getSpellFormulas() {
		return spellFormulas;
	}

	public void setSpellFormulas(String[] spellFormulas) {
		this.spellFormulas = spellFormulas;
	}

	public int getWpmodel() {
		return wpmodel;
	}

	public void setWpmodel(int wpmodel) {
		this.wpmodel = wpmodel;
	}

	public boolean isMei() {
		return mei;
	}

	public void setMei(boolean mei) {
		this.mei = mei;
	}

	public int getOrnamentId() {
		return ornamentId;
	}

	public void setOrnamentId(int ornamentId) {
		this.ornamentId = ornamentId;
	}

	public Pet pet() {
		if (this.petId <= 0)
			return null;
		return Pet.get(this.petId);
	}

	public void setActiveSkillsInfo(String activeSkillsInfo) {
		this.activeSkillsInfo = activeSkillsInfo;
		initSkillWeight();
	}

	public void initSkillWeight() {
		if (StringUtils.isBlank(this.activeSkillsInfo))
			return;
		List<SkillWeightInfo> activeSkillWeightInfos = new ArrayList<SkillWeightInfo>();
		int skillsWeightScope = 0;
		String[] skillInfoArr = activeSkillsInfo.split(",");
		for (int i = 0; i < skillInfoArr.length; i++) {
			String skillInfoStr = skillInfoArr[i];
			if (StringUtils.isBlank(skillInfoStr)) {
				continue;
			}

			String[] skillInfo = skillInfoStr.split(":");
			if (skillInfo.length != 2) {
				continue;
			}

			int skillId = Integer.parseInt(skillInfo[0]);
			int skillWeight = Integer.parseInt(skillInfo[1]);
			activeSkillWeightInfos.add(new SkillWeightInfo(skillId, skillWeight));
			skillsWeightScope += skillWeight;
		}
		skillsWeight = new SkillsWeight(skillsWeightScope, activeSkillWeightInfos);
	}

	public String getActiveSkillsInfo() {
		return activeSkillsInfo;
	}

	@Override
	public BattleSkillHolder<Monster> battleSkillHolder() {
		if (skillHolder == null) {
			skillHolder = new MonsterBattleSkillHolder(this);
		}
		return skillHolder;
	}

	public void resetBattleSkillHolder() {
		this.skillHolder = new MonsterBattleSkillHolder(this);
	}

	public SkillsWeight skillsWeight() {
		return skillsWeight;
	}

	public void skillsWeight(SkillsWeight skillsWeight) {
		this.skillsWeight = skillsWeight;
	}

	@Override
	public long playerId() {
		return 0;
	}

	@Override
	public int charactorId() {
		return 0;
	}

	@Override
	public Faction faction() {
		return null;
	}

	@Override
	public long uid() {
		return IdUtils.generateLongId("Monster");
	}

	@Override
	public String name() {
		NameLogic nameLogic = NameLogicManager.getInstance().getLogic(nameType);
		if (nameLogic == null)
			return name;
		return nameLogic.handle(name, modelId);
	}

	@Override
	public int grade() {
		return 0;
	}

	@Override
	public int monsterId() {
		return getId();
	}

	@Override
	public BattleBaseProperties battleBaseProperties(int lv) {
		return battleBaseProperties(lv, 0);
	}

	@Override
	public BattleBaseProperties battleBaseProperties(int lv, int ring) {
		BattleBaseProperties baseProperties = new BattleBaseProperties();
		calcPropertiesFromFormula(lv, ring, baseProperties);
		baseProperties.monsterVary();
		baseProperties.setMaxHp(baseProperties.getHp());
		baseProperties.setMaxMp(baseProperties.getMp());
		baseProperties.setMagicAttack(baseProperties.getMagic());
		baseProperties.setMagicDefense(baseProperties.getMagic());
		return baseProperties;
	}

	private void calcPropertiesFromFormula(int lv, int ring, BattleBaseProperties baseProperties) {
		final String desc = "Monster.calcPropertiesFromFormula";
		Map<String, Object> paramMap = new HashMap<String, Object>();

		paramMap.put("level", lv);
		paramMap.put("ring", ring);

		baseProperties.setHp(ScriptService.getInstance().calcuInt(desc, this.hp, paramMap, false));
		baseProperties.setAttack(ScriptService.getInstance().calcuInt(desc, this.attack, paramMap, false));
		baseProperties.setDefense(ScriptService.getInstance().calcuInt(desc, this.defense, paramMap, false));
		baseProperties.setMagic(ScriptService.getInstance().calcuInt(desc, this.magic, paramMap, false));
		baseProperties.setSpeed(ScriptService.getInstance().calcuInt(desc, this.speed, paramMap, false));
		baseProperties.setMp(ScriptService.getInstance().calcuInt(desc, this.mp, paramMap, false));
		baseProperties.setCritRate(ScriptService.getInstance().calcuFloat(desc, this.critRate, paramMap, false));
		baseProperties.setDodgeRate(ScriptService.getInstance().calcuFloat(desc, this.dodgeRate, paramMap, false));
	}

	/**
	 * 能力等级
	 * 
	 * @param enemyTeam
	 * @return
	 */
	public int level(BattleTeam enemyTeam) {
		return calcLv(enemyTeam, this.levelFormula);
	}

	/**
	 * 修炼等级
	 * 
	 * @param enemyTeam
	 * @return
	 */
	public int spellLevel(BattleTeam enemyTeam) {
		return calcLv(enemyTeam, this.spellLevelFormula);
	}

	/**
	 * 计算等级
	 * 
	 * @param team
	 *            怪物对方队伍
	 * @param formula
	 *            等级公式
	 * @return
	 */
	public static int calcLv(BattleTeam team, String formula) {
		if (StringUtils.isBlank(formula))
			return 0;
		// 计算最大等级
		int leaderLv = 0;// 队长等级
		int maxLv = 0;// 队伍中玩家最大等级
		int avgLv = 0;// 队伍中玩家平均等级
		int minLv = 0;// 队伍中玩家最小等级
		int sceneLv = 0; // 场景等级
		int sumLv = 0; // 等级和
		if (team != null) {
			int size = team.playerIds().size();
			BattlePlayer leader = team.leader();
			if (leader != null) {
				leaderLv = leader.getGrade();
				maxLv = avgLv = minLv = leaderLv;
				Scene scene = leader.currentScene();
				if (scene != null) {
					sceneLv = scene.sceneMap().getLevelLimit();
				}
				if (size > 1) {
					for (BattlePlayer p : team.players()) {
						final int lv = p.getGrade();
						maxLv = Math.max(maxLv, lv);
						minLv = Math.min(minLv, lv);
						sumLv += lv;
					}
					avgLv = sumLv / size;// 平均等级
				}
			}
		}

		Map<String, Object> paramMap = new HashMap<String, Object>();
		paramMap.put("LV", leaderLv);
		paramMap.put("MLV", maxLv);
		paramMap.put("ALV", avgLv);
		paramMap.put("SLV", minLv);
		paramMap.put("SceneLV", sceneLv);
		paramMap.put("RandomUtil", RandomUtils.getInstance());
		return ScriptService.getInstance().calcuInt("Monster.calcLv", formula, paramMap, false);
	}

	@Override
	public long exp() {
		return 0;
	}

	@Override
	public CharactorType charactorType() {
		return CharactorType.Monster;
	}

	@Override
	public boolean mutate() {
		// 有变异贴图则变异
		return this.mutateTexture > 0;
	}

	@Override
	public int wpmodel() {
		return this.wpmodel;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	@Override
	public BattleBaseProperties equipmentProperties() {
		return null;
	}

	@Override
	public ISpellEffectCalculator spellEffectCalculator() {
		return SpringUtils.getBeanOfType(MonsterSpellEffectCalculator.class);
	}

	@Override
	public int dressDyeId() {
		return 0;
	}

	@Override
	public int hairDyeId() {
		return 0;
	}

	@Override
	public int accoutermentDyeId() {
		return 0;
	}

	@Override
	public int initSp() {
		return Integer.MAX_VALUE;
	}

	@Override
	public AptitudeProperties aptitudeProperties() {
		// 怪物没有资质属性
		return null;
	}

	@Override
	public AptitudeProperties equipmentAptitudeProperties() {
		return null;
	}

	public int getPreRoundSkillId() {
		return preRoundSkillId;
	}

	public void setPreRoundSkillId(int preRoundSkillId) {
		this.preRoundSkillId = preRoundSkillId;
	}

	public Skill preRoundSkill() {
		if (this.preRoundSkillId <= 0)
			return null;
		return Skill.get(this.preRoundSkillId);
	}

	@Override
	public float extraGeneralDodgeRate(int level) {
		return BattleUnitExtraProperties.getInstance().generalDodgeRate(level);
	}

	@Override
	public float extraGeneralHitRate(int level) {
		return BattleUnitExtraProperties.getInstance().generalHitRate(level);
	}

	@Override
	public int transformModelId() {
		return 0;
	}

	@Override
	public int defaultSkillId() {
		return 0;
	}

	@Override
	public void defaultSkillId(int skillId) {
		// TODO Auto-generated method stub

	}

	@Override
	public void hp(int hp) {

	}

	@Override
	public int hp() {
		return 0;
	}

	@Override
	public void mp(int mp) {

	}

	@Override
	public int mp() {
		return 0;
	}

	@Transient
	public void setPassiveSkillStr(String passiveSkillStr) {
		this.passiveSkills = SplitUtils.split2IntSet(passiveSkillStr, ",");
	}

	public Set<Integer> getPassiveSkills() {
		return passiveSkills;
	}

	public void setPassiveSkills(Set<Integer> passiveSkills) {
		this.passiveSkills = passiveSkills;
	}

	@Override
	public int fashionId() {
		return 0;
	}

	@Override
	public int weaponAttack(int level, Map<String, Object> params) {
		if (StringUtils.isBlank(this.weaponAttackFormula))
			return 0;
		Map<String, Object> paramMap = new HashMap<>();
		paramMap.put("level", level);
		if (params != null)
			paramMap.putAll(params);
		int v = ScriptService.getInstance().calcuInt("Monster.weaponAttack", this.weaponAttackFormula, paramMap, false);
		return v;
	}

	public String getWeaponAttackFormula() {
		return weaponAttackFormula;
	}

	public void setWeaponAttackFormula(String weaponAttackFormula) {
		this.weaponAttackFormula = weaponAttackFormula;
	}

	@Override
	public int dyeCaseId() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int ornamentId() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public List<Integer> fashionDressIds() {
		return null;
	}

	@Override
	public boolean showDress() {
		return false;
	}

	@Override
	public long fereId() {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int friendlyWith(long targetId) {
		// TODO Auto-generated method stub
		return 0;
	}

	@Override
	public int weaponEffect() {
		return 0;
	}

	@Override
	public void afterBattlePropertiesInit(BattleSoldier soldier) {

	}

	@Override
	public boolean ifMyMaster(long targetId) {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public int wingId() {
		return 0;
	}

	@Override
	public int wingDyeId() {
		// TODO Auto-generated method stub
		return 0;
	}
}
