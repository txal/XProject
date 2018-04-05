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
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_39;

/**
 * 使用某技能后就扣除一次buff作用次数
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_39 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_39();
	}

	@Override
	public void doInitParam(BattleBuff buff, String paramStr) {
		Map<String, String> properties = SplitUtils.split2StringMap(paramStr, ",", ":");
		BuffLogicParam_39 param = (BuffLogicParam_39) buff.getBuffParam();
		param.setSkillIds(SplitUtils.split2IntSet(properties.get("skillIds"), "\\|"));
	}

	@Override
	public void onActionEnd(CommandContext commandContext, BattleBuffEntity buffEntity) {
		BuffLogicParam p = buffEntity.battleBuff().getBuffParam();
		if (!(p instanceof BuffLogicParam_39))
			return;
		BuffLogicParam_39 param = (BuffLogicParam_39) p;
		if (CollectionUtils.isEmpty(param.getSkillIds()))
			return;
		if (param.getSkillIds().contains(commandContext.skill().getId())) {
			String key = "buffCount";
			Map<String, Object> meta = buffEntity.getBattleMeta();
			int buffCount = buffEntity.battleBuff().getBuffsEffectTimes();
			buffCount -= 1;
			meta.put(key, buffCount);
			if (buffCount == 0) {
				buffEntity.getEffectSoldier().buffHolder().removeBuffById(buffEntity.battleBuffId());
				commandContext.skillAction().addTargetState(new VideoBuffRemoveTargetState(buffEntity.getEffectSoldier(), buffEntity.battleBuffId()));
			}

		}
	}

}
