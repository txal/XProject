/**
 * 
 */
package com.nucleus.logic.core.modules.battlebuff;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.stereotype.Service;

import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.commons.utils.SplitUtils;
import com.nucleus.logic.core.modules.battle.dto.VideoBuffAddTargetState;
import com.nucleus.logic.core.modules.battle.model.BattleSoldier;
import com.nucleus.logic.core.modules.battlebuff.data.BattleBuff;
import com.nucleus.logic.core.modules.battlebuff.model.BattleBuffEntity;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam;
import com.nucleus.logic.core.modules.battlebuff.model.BuffLogicParam_36;
import com.nucleus.player.service.ScriptService;

/**
 * 将buff传染给任意队友
 * 
 * @author wangyu
 *
 */
@Service
public class BattleBuffLogic_36 extends BattleBuffLogicAdapter {

	@Override
	protected BuffLogicParam newParam() {
		return new BuffLogicParam_36();
	}

	@Override
	protected void doInitParam(BattleBuff buff, String params) {
		Map<String, String> paramMap = SplitUtils.split2StringMap(params, ",", ":");
		BuffLogicParam_36 param = (BuffLogicParam_36) buff.getBuffParam();
		if (paramMap.get("buffId") != null) {
			param.setBuffId(Integer.parseInt(paramMap.get("buffId")));
		}
		if (paramMap.get("skillId") != null) {
			param.setSkillId(Integer.parseInt(paramMap.get("skillId")));
		}
		param.setRate((paramMap.get("rate")));
	}

	@Override
	public void onRoundStart(BattleBuffEntity buffEntity) {
		BattleSoldier currentSoldier = buffEntity.getEffectSoldier();
		List<BattleSoldier> allAlive = currentSoldier.team().aliveSoldiers();
		if (allAlive.size() <= 1)
			return;
		BuffLogicParam_36 param = (BuffLogicParam_36) buffEntity.battleBuff().getBuffParam();
		BattleBuff battleBuff = BattleBuff.get(param.getBuffId());
		if (battleBuff == null)
			return;
		BattleSoldier s = chooseSoldier(allAlive, currentSoldier, battleBuff);
		if (s == null)
			return;
		float rate = calValue(param.getRate(), param.getSkillId(), buffEntity.getTriggerSoldier());
		if (!RandomUtils.baseRandomHit(rate))
			return;
		int round = (int) calValue(battleBuff.getBuffsPersistRoundFormula(), buffEntity.skillId(), currentSoldier);
		if (round <= 0)
			return;
		BattleBuffEntity buf = new BattleBuffEntity(battleBuff, currentSoldier, s, buffEntity.skillId(), buffEntity.getBuffPersistRound());
		if (s.buffHolder().addBuff(buf))
			s.currentVideoRound().readyAction().addTargetState(new VideoBuffAddTargetState(buf));

	}

	private float calValue(String formula, int skillId, BattleSoldier soldier) {
		int skillLevel = soldier.skillLevel(skillId);
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("skillLevel", skillLevel);
		params.put("target", soldier);
		float value = ScriptService.getInstance().calcuFloat("", formula, params, false);
		return value;
	}

	/**
	 * 选择一个队友，不能选中自己或者已经有该buff的队友
	 * 
	 * @param allSoldiers
	 * @param currentSoldier
	 * @return
	 */
	private BattleSoldier chooseSoldier(List<BattleSoldier> allSoldiers, BattleSoldier currentSoldier, BattleBuff buff) {
		BattleSoldier s = null;
		for (int i = 0; i < allSoldiers.size(); i++) {
			int hit = RandomUtils.nextInt(allSoldiers.size());
			s = allSoldiers.get(hit);
			if (s.getId() == currentSoldier.getId() || s.buffHolder().hasBuff(buff.getId())) {
				allSoldiers.remove(hit);
			}
		}
		return s;
	}
}
