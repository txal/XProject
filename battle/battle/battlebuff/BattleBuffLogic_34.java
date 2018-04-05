/**
 * 
 */
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
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_34;

/**
 * 执行某动作就扣除一次buff作用次数
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_34 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_34();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> properties = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_34 param = (BuffLogicParam_34) buff.getBuffParam();
		param.setBattleCommandTypes(SplitUtils.split2IntSet(properties.get("commandTypes"), "\\|"));
	}

	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam p = buffEntity.battleBuff().getBuffParam();
		if (!(p instanceof BuffLogicParam_34))
			return;
		BuffLogicParam_34 param = (BuffLogicParam_34) p;
		if (CollectionUtils.isEmpty(param.getBattleCommandTypes()))
			return;
		if (param.getBattleCommandTypes().contains(commandContext.skill().battleCommandType().ordinal())) {
			String key = "buffCount";
			Map<String, Object> meta = buffEntity.getBattleMeta();
			int buffCount = (Integer) meta.getOrDefault(key, buffEntity.battleBuff().getBuffsEffectTimes());
			buffCount -= 1;
			meta.put(key, buffCount);
			if (buffCount == 0) {
				buffEntity.getEffectSoldier().buffHolder().removeBuffById(buffEntity.battleBuffId());
				commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(buffEntity.getEffectSoldier(), buffEntity.battleBuffId()));
			}

		}
	}

}
