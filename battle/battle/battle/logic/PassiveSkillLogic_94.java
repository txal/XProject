package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 叠加累计次数buff,有上限
 * 
 * @author hwy
 *
 */
@Service
public class PassiveSkillLogic_94 extends PassiveSkillLogic_22 {
	@Override
	protected BattleBuffEntity doAddBuff(BattleBuff buff, BattleSoldier triggerSoldier, BattleSoldier effectSoldier, CommandContext context, PassiveSkillConfig config, int skillId) {
		int limit = 0;
		try {
			limit = Integer.parseInt(config.getExtraParams()[0]);
		} catch (Exception e) {
			e.printStackTrace();
		}
		BattleBuffEntity buffEntity = effectSoldier.buffHolder().getBuff(buff.getId());
		if (buffEntity != null) {
			if (buffEntity.getBuffContexts().size() >= limit) {
				return null;
			} else {
				// 单纯用于累计次数
				buffEntity.getBuffContexts().add(new BattleBuffContext());
			}
		} else {
			buffEntity = addBuff(triggerSoldier, effectSoldier, skillId, buff);
		}
		return buffEntity;
	}

	@Override
	protected BattleBuffEntity addBuff(BattleSoldier triggerSoldier, BattleSoldier effectSoldier, int skillId, BattleBuff buff) {
		int persistRound = Integer.parseInt(buff.getBuffsPersistRoundFormula());
		if (persistRound > 0) {
			List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
			// 单纯用于累计次数
			buffContextList.add(new BattleBuffContext());
			BattleBuffEntity buffEntity = new BattleBuffEntity(buff, triggerSoldier, effectSoldier, skillId, persistRound, buffContextList);
			if (effectSoldier.buffHolder().addBuff(buffEntity)) {
				return buffEntity;
			}
		}
		return null;
	}
}
