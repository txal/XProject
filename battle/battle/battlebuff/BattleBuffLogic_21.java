package com.nucleus.logic.core.modules.battlebuff;

import java.util.Map;

import org.apache.commons.collections.CollectionUtils;
import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_21;

/**
 * 挂buff的目标如果执行相应动作则移除该buff
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_21 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_21();
	}
	
	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> properties = SplitUtils.split2StringMap(params, ",", ":");
		BuffLogicParam_21 param = (BuffLogicParam_21) buff.getBuffParam();
		param.setBattleCommandTypes(SplitUtils.split2IntSet(properties.get("commandTypes"), "\\|"));
	}
	
	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam p = buffEntity.battleBuff().getBuffParam();
		if (!(p instanceof BuffLogicParam_21))
			return;
		BuffLogicParam_21 param = (BuffLogicParam_21) p;
		if (CollectionUtils.isEmpty(param.getBattleCommandTypes()))
			return;
		if (param.getBattleCommandTypes().contains(commandContext.skill().battleCommandType())) {
			buffEntity.getEffectSoldier().buffHolder().removeBuffById(buffEntity.battleBuffId());
			commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(buffEntity.getEffectSoldier(), buffEntity.battleBuffId()));
		}
	}
}
