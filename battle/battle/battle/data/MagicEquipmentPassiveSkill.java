/**
 * 
 */
package com.nucleus.logic.core.modules.battle.data;

import java.beans.Transient;
import java.util.Set;

import com.nucleus.commons.data.DataId;
import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.logic.IPassiveSkill;
import com.nucleus.logic.core.modules.player.data.Props;
import com.nucleus.player.data.GeneralItem;

/**
 * 法宝被被动技能
 * 
 * @author xitao.huang
 *
 */
public class MagicEquipmentPassiveSkill extends MagicEquipmentSkill implements IPassiveSkill {

	public static MagicEquipmentPassiveSkill get(int id) {
		return StaticDataManager.getInstance().get(MagicEquipmentPassiveSkill.class, id);
	}

	public enum MagicPassiveSkillApplyType {
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

	public enum MagicPassiveSkillType {
		/** 0 未知 */
		Unknow,
		/** 1 阴阳 */
		YinYang,
		/** 2 四象 */
		SiXiang,
		/** 3 八卦 */
		BaGua
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
	/** 技能分类1阴阳，2四象，3 八卦 */
	private int passiveType;
	/** 满级重置时需要的道具数量 */
	private int extraConsumeAmt;
	/** 消耗点数 */
	private int spendAmt;
	/** 影响效果系数 */
	private String effectRateStr;
	/** 适用类型 0通用1主人物2子女3伙伴4宠物5对方 */
	private Set<Integer> applyType;
	/** 效果公式 **/
	private String effectFormula;

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

	public int getUpgradePropsId() {
		return upgradePropsId;
	}

	public void setUpgradePropsId(int upgradePropsId) {
		this.upgradePropsId = upgradePropsId;
	}

	public int[] getExtraSkillIds() {
		return extraSkillIds;
	}

	public void setExtraSkillIds(int[] extraSkillIds) {
		this.extraSkillIds = extraSkillIds;
	}

	public int[] getExtraSkillRates() {
		return extraSkillRates;
	}

	public void setExtraSkillRates(int[] extraSkillRates) {
		this.extraSkillRates = extraSkillRates;
	}

	public int getPassiveType() {
		return passiveType;
	}

	public void setPassiveType(int passiveType) {
		this.passiveType = passiveType;
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
	
	public String getEffectFormula() {
		return effectFormula;
	}

	public void setEffectFormula(String effectFormula) {
		this.effectFormula = effectFormula;
	}

	@Transient
	public void setApplyTypeStr(String applyTypeStr) {
		this.applyType = SplitUtils.split2IntSet(applyTypeStr, ",");
	}
}
