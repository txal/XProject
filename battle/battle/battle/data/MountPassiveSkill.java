package com.nucleus.logic.core.modules.battle.data;

import java.beans.Transient;
import java.util.Set;

import org.apache.commons.lang3.ArrayUtils;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.player.data.Props;
import com.nucleus.player.data.GeneralItem;

/**
 * 坐骑通用被动技能
 *
 * @author zhanhua.xu
 */
public class MountPassiveSkill extends MountSkill implements IPassiveSkill {
	public static MountPassiveSkill get(int id) {
		return StaticDataManager.getInstance().get(MountPassiveSkill.class, id);
	}

	public enum ApplyType {
		/** 0通用 */
		All,
		/** 1主人物 */
		MainCharactor,
		/** 2子女 */
		Child,
		/** 3伙伴 */
		Crew,
		/** 4宠物 */
		Pet
	}

	private int type;
	/** 技能配置 */
	private int[] configId;
	/** 升级或重置时道具 */
	@DataId(value = Props.class, cacheClass = GeneralItem.class)
	private int upgradePropsId;
	/** 满级额外可能获得技能 */
	private int[] extraSkillIds;
	/** 满级额外获得技能概率 */
	private int[] extraSkillRates;
	/** 技能分类1分配的通用被动，2不分配用于额外增加1级，3 不分配用于额外增加技能 */
	private int passiveType;
	/** 满级重置时需要的道具数量 */
	private int extraConsumeAmt;
	/** 消耗点数 */
	private int spendAmt;
	/** 影响效果系数 */
	private String effectRateStr;
	/** 适用类型 0通用1主人物2子女3伙伴4宠物 */
	private Set<Integer> applyType;

	@Override
	public int[] getConfigId() {
		return configId;
	}

	public void setConfigId(int[] configId) {
		this.configId = configId;
	}

	@Override
	public int getType() {
		return this.type;
	}

	public void setType(int type) {
		this.type = type;
	}

	public int[] getExtraSkillIds() {
		return extraSkillIds;
	}

	public void setExtraSkillIds(int[] extraSkillIds) {
		this.extraSkillIds = extraSkillIds;
	}

	public int getUpgradePropsId() {
		return upgradePropsId;
	}

	public void setUpgradePropsId(int upgradePropsId) {
		this.upgradePropsId = upgradePropsId;
	}

	public int getPassiveType() {
		return passiveType;
	}

	public void setPassiveType(int passiveType) {
		this.passiveType = passiveType;
	}

	public int[] getExtraSkillRates() {
		return extraSkillRates;
	}

	public void setExtraSkillRates(int[] extraSkillRates) {
		this.extraSkillRates = extraSkillRates;
	}

	public int getExtraConsumeAmt() {
		return extraConsumeAmt;
	}

	public void setExtraConsumeAmt(int extraConsumeAmt) {
		this.extraConsumeAmt = extraConsumeAmt;
	}

	public int getSpendAmt() {
		return spendAmt;
	}

	public void setSpendAmt(int spendAmt) {
		this.spendAmt = spendAmt;
	}

	public String getEffectRateStr() {
		return effectRateStr;
	}

	public void setEffectRateStr(String effectRateStr) {
		this.effectRateStr = effectRateStr;
	}

	public Set<Integer> getApplyType() {
		return applyType;
	}

	public void setApplyType(Set<Integer> applyType) {
		this.applyType = applyType;
	}
	
	@Transient
	public void setApplyTypeStr(String applyTypeStr) {
		this.applyType = SplitUtils.split2IntSet(applyTypeStr, ",");
	}

	@Transient
	public void setExtraSkillIdsStr(String extraSkillIdsStr) {
		this.extraSkillIds = SplitUtils.split2IntArray(extraSkillIdsStr, ",");
	}

	@Transient
	public void setExtraSkillRatesStr(String extraSkillRatesStr) {
		this.extraSkillRates = SplitUtils.split2IntArray(extraSkillRatesStr, ",");
	}

	@Transient
	public boolean openLearn() {
		return this.passiveType == 1;
	}

	@Transient
	public boolean ifAddOneLevel() {
		return this.passiveType == 2;
	}

	@Transient
	public int radomExtraSkill(int excludeExtraId) {
		int excludeIndex = ArrayUtils.indexOf(this.extraSkillIds, excludeExtraId);
		int[] tmpId = this.extraSkillIds;
		int[] tmpRate = this.extraSkillRates;
		if (excludeIndex > 0) {
			tmpId = ArrayUtils.remove(this.extraSkillIds, excludeIndex);
			tmpRate = ArrayUtils.remove(this.extraSkillRates, excludeIndex);
		}
		int base = 0;
		for (int i : tmpRate) {
			base += i;
		}
		int index = 0;
		int randomValue = RandomUtils.nextInt(base);
		int countRate = 0;
		for (int i = 0; i < tmpRate.length; i++) {
			countRate += tmpRate[i];
			if (randomValue <= countRate) {
				index = i;
				break;
			}
		}
		return tmpId[index];
	}
}
