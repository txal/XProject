package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.List;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;

/**
 * 叠加buff,有上限
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_53 extends PassiveSkillLogic_22 {
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
			int len = buffEntity.battleBuff().getBattleBasePropertyTypes().length;
			limit *= len;// 影响多个属性的情况
			if (buffEntity.getBuffContexts().size() >= limit) {
				return null;
			} else {
				for (int i = 0; i < len; i++) {
					int property = buff.getBattleBasePropertyTypes()[i];
					String formula = buff.getBattleBasePropertyEffectFormulas()[i];
					buffEntity.getBuffContexts().add(new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], formula));
				}
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
			int len = buff.getBattleBasePropertyTypes().length;
			List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
			for (int i = 0; i < len; i++) {
				int property = buff.getBattleBasePropertyTypes()[i];
				String formula = buff.getBattleBasePropertyEffectFormulas()[i];
				BattleBuffContext buffContext = new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], formula);
				buffContextList.add(buffContext);
			}
			BattleBuffEntity buffEntity = new BattleBuffEntity(buff, triggerSoldier, effectSoldier, skillId, persistRound, buffContextList);
			if (effectSoldier.buffHolder().addBuff(buffEntity))
				return buffEntity;
		}
		return null;
	}
}
