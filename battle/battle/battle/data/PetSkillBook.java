package com.nucleus.logic.core.modules.battle.data;

import com.nucleus.commons.data.StaticDataManager;
import com.nucleus.logic.core.modules.player.data.Props;

/**
 * 宠物技能书
 * 
 * @author liguo
 * 
 */
public class PetSkillBook extends Props {

	public enum PetSkillBookType {
		/** 未知 */
		Unknown,
		/** 低级兽诀 */
		LowClass,
		/** 随机可用技能兽决 */
		RandomPbb,
		/** 高级兽决 */
		HighClass,
		/** 子女技能 */
		ChildSkill,
		/** 魔兽兽决 */
		WarcraftClass
	}

	/** 兽决类型 */
	private int petSkillBookType;

	/** 宠物技能编号 */
	private int petSkillId;

	/** 禁用快速购买 */
	private boolean banBuy;

	public static PetSkillBook get(int id) {
		return StaticDataManager.getInstance().get(PetSkillBook.class, id);
	}

	public int getPetSkillBookType() {
		return petSkillBookType;
	}

	public void setPetSkillBookType(int petSkillBookType) {
		this.petSkillBookType = petSkillBookType;
	}

	public int getPetSkillId() {
		return petSkillId;
	}

	public void setPetSkillId(int petSkillId) {
		this.petSkillId = petSkillId;
	}

	public boolean isBanBuy() {
		return banBuy;
	}

	public void setBanBuy(boolean banBuy) {
		this.banBuy = banBuy;
	}

}
