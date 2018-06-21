package com.nucleus.logic.core.modules.battlebuff;

import org.springframework.stereotype.Service;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffRemoveTargetState;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_12;

/**
 * 抗药性buff逻辑：抗药数值达到指定值则移除buff
 * 
 * @author wgy
 *
 */
@Service
public class BattleBuffLogic_12 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_12();
	}

	@Override
	public void onRoundEnd(BattleBuffEntity buffEntity) {
		BuffLogicParam_12 param = (BuffLogicParam_12) buffEntity.battleBuff().getBuffParam();
		if (param == null)
			return;
		
		int buffId = StaticConfig.get(AppStaticConfigs.DRUG_RESISTANT_BUFF_ID).getAsInt(323);
		if (buffEntity.battleBuffId() == buffId && buffEntity.getBuffEffectValue() >= 1) {
			int buffEffectValue = 2 + (int) (buffEntity.getBuffEffectValue() / 7);
			buffEntity.decreaseBuffEffectValue(buffEffectValue);
		}
		
		if (buffEntity.getBuffEffectValue() < param.getValue())
			buffEntity.getEffectSoldier().currentVideoRound().endAction().addTargetState(new VideoBuffRemoveTargetState(buffEntity.getEffectSoldier(), buffEntity.battleBuffId()));
			//buffEntity.setBuffPersistRound(0);//回合数设置为0,清除buff
	}
}
