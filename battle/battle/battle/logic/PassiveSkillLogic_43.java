package com.nucleus.logic.core.modules.battle.logic;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.logic.core.modules.battle.data.PassiveSkillConfig;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battle.model.CommandContext;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff.BattleBasePropertyType;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffContext;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.player.service.ScriptService;

/**
 * 孤军奋战
 * 
 * @author wgy
 *
 */
@Service
public class PassiveSkillLogic_43 extends PassiveSkillLogic_22 {
	@Override
	protected BattleBuffEntity doAddBuff(BattleBuff buff, BattleSoldier triggerSoldier, BattleSoldier effectSoldier, CommandContext context, PassiveSkillConfig config, int skillId) {
		if (config.getPropertys() != null && config.getPropertyEffectFormulas() != null) {
			int property = config.getPropertys()[0];
			String formula = config.getPropertyEffectFormulas()[0];
			int persistRound = 1;
			try {
				if (config.getExtraParams() != null)
					persistRound = Integer.parseInt(config.getExtraParams()[0]);
			} catch (Exception e) {
				e.printStackTrace();
			}
			String valueFormula = formula;
			Map<String, Object> params = new HashMap<String, Object>();
			params.put("deadCount", getDeadCount(effectSoldier));
			float v = ScriptService.getInstance().calcuFloat("", formula, params, false);
			valueFormula = String.valueOf(v);
			BattleBuffContext buffContext = new BattleBuffContext(buff.getId(), BattleBasePropertyType.values()[property], valueFormula);
			List<BattleBuffContext> buffContextList = new ArrayList<BattleBuffContext>();
			buffContextList.add(buffContext);

			BattleBuffEntity buffEntity = effectSoldier.buffHolder().getBuff(buff.getId());
			if (buffEntity == null) {
				buffEntity = new BattleBuffEntity(buff, triggerSoldier, effectSoldier, skillId, persistRound, buffContextList);
				if (effectSoldier.buffHolder().addBuff(buffEntity))
					return buffEntity;
			} else {
				buffEntity.setBuffContexts(buffContextList);
				return buffEntity;
			}
		}
		return null;
	}

	private int getDeadCount(BattleSoldier effectSoldier) {
		int count = 0;
		for (BattleSoldier s : effectSoldier.team().allSoldiersMap().values()) {
			if (s.isDead())
				count++;
		}
		return count;
	}
}
