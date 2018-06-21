/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import java.util.ArrayList;
import java.util.List;

import org.apache.commons.lang3.builder.ReflectionToStringBuilder;
import org.apache.commons.lang3.builder.ToStringStyle;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.message.BroadcastMessage;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.faction.data.Faction;
import com.nucleus.logic.core.modules.player.dto.PlayerDressInfo;
import com.nucleus.logic.core.modules.system.data.NpcAppearance;

/**
 * @author Omanhom
 */
public class VideoSoldier implements BroadcastMessage {

	/** 战斗状态 */
	public enum SoldierStatus {
		/** 正常战斗状态 */
		Normal,
		/** 自我防御 */
		SelfDefense
	}

	public VideoSoldier() {
	}

	public VideoSoldier(BattleSoldier battleSoldier) {
		this.setId(battleSoldier.id());
		this.setLeaderPlayerId(battleSoldier.battleTeam().leaderId());
		this.setPlayerId(battleSoldier.playerId());
		this.setCharactorId(battleSoldier.charactorId());
		this.setGrade(battleSoldier.grade());
		this.setMonsterId(battleSoldier.monsterId());
		this.setName(battleSoldier.name());

		this.setHp(battleSoldier.hp());
		this.setMaxHp(battleSoldier.maxHp());
		this.setMp(battleSoldier.mp());
		this.setMaxMp(battleSoldier.maxMp());

		this.setCustomId(battleSoldier.customId());
		this.setPosition(battleSoldier.getPosition());
		this.setCharactorType(battleSoldier.charactorType());
		this.setFactionId(battleSoldier.factionId());
		this.setMonsterType(battleSoldier.getMonsterType());
		this.setNpcAppearance(battleSoldier.getNpcAppearance() != null ? battleSoldier.getNpcAppearance() : null);
		if (battleSoldier.ifPet() && battleSoldier.battleUnit() instanceof PersistPlayerPet) {
			PersistPlayerPet pet = (PersistPlayerPet) battleSoldier.battleUnit();
			this.setBaobao(pet.isBaby());
			this.setWarcraft(pet.isWarcraft());
		}
		this.setMutate(battleSoldier.isMutate());
		if (battleSoldier.skillHolder().battleSkillHolder().containSkill(battleSoldier.battleUnit().defaultSkillId())) {
			this.setDefaultSkillId(battleSoldier.battleUnit().defaultSkillId());
		} else {
			this.setDefaultSkillId(1);
		}

		this.sp = battleSoldier.getSp();
		this.maxSp = battleSoldier.getMaxSp();
		for (BattleBuffEntity buff : battleSoldier.buffHolder().allBuffs().values()) {
			this.buffs.add(new VideoBuffAddTargetState(buff));
		}

		this.playerDressInfo = battleSoldier.getPlayerDressInfo();
		this.fereId = battleSoldier.fereId();
		this.spendSpDiscountRate = battleSoldier.spendSpDiscountRate();

		this.magicMana = battleSoldier.getMagicEquipmentMana();
	}

	/**
	 * 重置战斗中可变的状态
	 * 
	 * @param battleSoldier
	 */
	public void restoreState(BattleSoldier battleSoldier) {
		this.leaderPlayerId = battleSoldier.battleTeam().leaderId();
		this.grade = battleSoldier.grade();
		this.hp = battleSoldier.hp();
		this.maxHp = battleSoldier.maxHp();
		this.mp = battleSoldier.mp();
		this.maxMp = battleSoldier.maxMp();
		this.position = battleSoldier.getPosition();
		this.sp = battleSoldier.getSp();
		this.maxSp = battleSoldier.getMaxSp();
		this.buffs.clear();
		this.magicMana = battleSoldier.getMagicEquipmentMana();
		this.npcAppearance = battleSoldier.getNpcAppearance() != null ? battleSoldier.getNpcAppearance() : null;
		int buffId = StaticConfig.get(AppStaticConfigs.DRUG_RESISTANT_BUFF_ID).getAsInt(323);
		for (BattleBuffEntity buff : battleSoldier.buffHolder().allBuffs().values()) {
			if (buff.battleBuffId() == buffId && buff.getBuffEffectValue() < 5)
				continue;
			this.buffs.add(new VideoBuffAddTargetState(buff));
		}
	}

	/** 唯一编号 */
	private long id;
	/** 队长编号 */
	private long leaderPlayerId;
	/** 玩家编号 0:不可控制, >0:可控制 */
	private long playerId;
	/** 自编号 */
	private int customId;
	/** 名称 */
	private String name;
	/** 角色编号 */
	@DataId(GeneralCharactor.class)
	private int charactorId;
	/** 等级 */
	private int grade;
	/** 怪物id */
	@DataId(Monster.class)
	private int monsterId;
	/** 怪物类型 */
	private int monsterType;
	/** 怪物外观（用于替换怪物外观） */
	private NpcAppearance npcAppearance;
	/** ================ 基础战斗属性 - START================ */
	/** hp */
	private int hp;
	/** hp上限 */
	private int maxHp;
	/** mp */
	private int mp;
	/** mp上限 */
	private int maxMp;
	/** ================ 基础战斗属性 - END================ */
	/** 上阵站位,0表示没上阵，还在后备队列中 */
	private int position;
	/** 角色类型 */
	private int charactorType;
	@DataId(Faction.class)
	private int factionId;
	/** 是否变异 */
	private boolean isMutate;
	/** 默认技能id */
	private int defaultSkillId;
	/**
	 * buff列表
	 */
	private List<VideoBuffAddTargetState> buffs = new ArrayList<VideoBuffAddTargetState>();

	/** 怒气 */
	private int sp;
	/** 最大怒气值 */
	private int maxSp;
	/** 战士着装信息（衣服染色,头发染色,饰物染色,武器模型,变身后的新模型,角色编号) */
	private PlayerDressInfo playerDressInfo;
	/** 伴侣id */
	private long fereId;
	/** 怒气消耗减免率 */
	private float spendSpDiscountRate;
	/** 法宝法力 */
	private int magicMana;
	/** 是否魔兽 */
	private boolean isWarcraft;
	/** 是否是宝宝 */
	private boolean isBaobao;

	public boolean isWarcraft() {
		return isWarcraft;
	}

	public void setWarcraft(boolean isWarcraft) {
		this.isWarcraft = isWarcraft;
	}

	public boolean isBaobao() {
		return isBaobao;
	}

	public void setBaobao(boolean isBaobao) {
		this.isBaobao = isBaobao;
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getCharactorId() {
		return charactorId;
	}

	public void setCharactorId(int charactorId) {
		this.charactorId = charactorId;
	}

	public int getCustomId() {
		return customId;
	}

	public void setCustomId(int customId) {
		this.customId = customId;
	}

	public int getMonsterId() {
		return monsterId;
	}

	public void setMonsterId(int monsterId) {
		this.monsterId = monsterId;
	}

	public int getPosition() {
		return position;
	}

	public void setPosition(int position) {
		this.position = position;
	}

	public int getGrade() {
		return grade;
	}

	public void setGrade(int grade) {
		this.grade = grade;
	}

	public long getId() {
		return id;
	}

	public void setId(long id) {
		this.id = id;
	}

	public long getPlayerId() {
		return playerId;
	}

	public void setPlayerId(long playerId) {
		this.playerId = playerId;
	}

	public int getHp() {
		return hp;
	}

	public void setHp(int hp) {
		this.hp = hp;
	}

	public int getMaxHp() {
		return maxHp;
	}

	public void setMaxHp(int maxHp) {
		this.maxHp = maxHp;
	}

	public int getMp() {
		return mp;
	}

	public void setMp(int mp) {
		this.mp = mp;
	}

	public int getMaxMp() {
		return maxMp;
	}

	public void setMaxMp(int maxMp) {
		this.maxMp = maxMp;
	}

	@Override
	public String toString() {
		return ReflectionToStringBuilder.toString(this, ToStringStyle.SHORT_PREFIX_STYLE);
	}

	public int getCharactorType() {
		return charactorType;
	}

	public void setCharactorType(int charactorType) {
		this.charactorType = charactorType;
	}

	public int getFactionId() {
		return factionId;
	}

	public void setFactionId(int factionId) {
		this.factionId = factionId;
	}

	public long getLeaderPlayerId() {
		return leaderPlayerId;
	}

	public void setLeaderPlayerId(long leaderPlayerId) {
		this.leaderPlayerId = leaderPlayerId;
	}

	public int getMonsterType() {
		return monsterType;
	}

	public void setMonsterType(int monsterType) {
		this.monsterType = monsterType;
	}

	public boolean isMutate() {
		return isMutate;
	}

	public void setMutate(boolean isMutate) {
		this.isMutate = isMutate;
	}

	public int getDefaultSkillId() {
		return defaultSkillId;
	}

	public void setDefaultSkillId(int defaultSkillId) {
		this.defaultSkillId = defaultSkillId;
	}

	public List<VideoBuffAddTargetState> getBuffs() {
		return buffs;
	}

	public void setBuffs(List<VideoBuffAddTargetState> buffs) {
		this.buffs = buffs;
	}

	public int getSp() {
		return sp;
	}

	public void setSp(int sp) {
		this.sp = sp;
	}

	public int getMaxSp() {
		return maxSp;
	}

	public void setMaxSp(int maxSp) {
		this.maxSp = maxSp;
	}

	public PlayerDressInfo getPlayerDressInfo() {
		return playerDressInfo;
	}

	public void setPlayerDressInfo(PlayerDressInfo playerDressInfo) {
		this.playerDressInfo = playerDressInfo;
	}

	public long getFereId() {
		return fereId;
	}

	public void setFereId(long fereId) {
		this.fereId = fereId;
	}

	public float getSpendSpDiscountRate() {
		return spendSpDiscountRate;
	}

	public void setSpendSpDiscountRate(float spendSpDiscountRate) {
		this.spendSpDiscountRate = spendSpDiscountRate;
	}

	public int getMagicMana() {
		return magicMana;
	}

	public void setMagicMana(int magicMana) {
		this.magicMana = magicMana;
	}

	public NpcAppearance getNpcAppearance() {
		return npcAppearance;
	}

	public void setNpcAppearance(NpcAppearance npcAppearance) {
		this.npcAppearance = npcAppearance;
	}

}
