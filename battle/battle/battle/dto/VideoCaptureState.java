/**
 * 
 */
package com.nucleus.logic.core.modules.battle.dto;

import com.nucleus.commons.data.DataId;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor;

/**
 * 捕获状态
 * 
 * @author wgy
 * 
 */
public class VideoCaptureState extends VideoTargetState {
	/**
	 * 抓捕是否成功
	 */
	private boolean success;
	/**
	 * 成功机率
	 */
	private float rate;
	/**
	 * 由野生变成的宝宝
	 */
	private boolean wildToBaobao;
	/**
	 * 抓到的宠物
	 */
	@DataId(GeneralCharactor.class)
	private int petId;

	public VideoCaptureState() {
	}

	public VideoCaptureState(BattleSoldier target, boolean success, float rate) {
		super(target);
		this.success = success;
		this.rate = rate;
	}

	public boolean isSuccess() {
		return success;
	}

	public void setSuccess(boolean success) {
		this.success = success;
	}

	public float getRate() {
		return rate;
	}

	public void setRate(float rate) {
		this.rate = rate;
	}

	public boolean isWildToBaobao() {
		return wildToBaobao;
	}

	public void setWildToBaobao(boolean wildToBaobao) {
		this.wildToBaobao = wildToBaobao;
	}

	public int getPetId() {
		return petId;
	}

	public void setPetId(int petId) {
		this.petId = petId;
	}
}
