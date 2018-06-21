package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.apache.commons.beanutils.BeanUtils;

import com.nucleus.commons.data.ErrorCodes;
import com.nucleus.commons.exception.GeneralException;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;

/**
 * buff逻辑
 * 
 * @author wgy
 *
 */
public abstract class BattleBuffLogicAdapter implements IBattleBuffLogic {

	protected BuffLogicParam newParam() {
		return null;
	}

	@Override
	public void initParam(BattleBuff buff, String paramStr) {
		BuffLogicParam buffParam = newParam();
		buff.setBuffParam(buffParam);
		doInitParam(buff, paramStr);
	}

	protected void doInitParam(BattleBuff buff, String params) {
		if (buff.getBuffParam() == null)
			return;
		try {
			Map<String, String> paramMap = SplitUtils.split2StringMap(params, ",", ":");
			BeanUtils.populate(buff.getBuffParam(), paramMap);
		} catch (Exception ex) {
			throw new GeneralException(ErrorCodes.DATA_SET_NOT_NULL, buff.getClass().getSimpleName(), buff.getBuffLogicId());
		}
	}

	@Override
	public void onActionStart(CommandContext commandContext, BattleBuffEntity buffEntity) {
	}

	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
	}

	@Override
	public void onRemove(BattleBuffEntity buffEntity) {
	}

	@Override
	public void attackDead(CommandContext commandContext, BattleBuffEntity buffEntity) {
	}

	@Override
	public void underAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
	}

	@Override
	public void beforeSkillFire(CommandContext commandContext, BattleBuffEntity buffEntity) {
	}

	@Override
	public void antiBuff(CommandContext commandContext, BuffLogicParam logicParam) {
	}

	@Override
	public boolean propertyEffectable(CommandContext commandContext, BattleBasePropertyType propertyType) {
		return true;
	}

	@Override
	public void onRoundStart(BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

	@Override
	public void onRoundEnd(BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

	@Override
	public boolean antiItem(BuffLogicParam logicParam, int itemId) {
		return false;
	}

	@Override
	public void onBeforeRemove(CommandContext commandContext, BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

	@Override
	public void beforeAttack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

	@Override
	public void onStrikeBack(CommandContext commandContext, BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

	@Override
	public void afterGetBuff(BattleBuffEntity buffEntity) {
		// TODO Auto-generated method stub

	}

}
