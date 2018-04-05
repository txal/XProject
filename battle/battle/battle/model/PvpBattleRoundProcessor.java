package com.nucleus.logic.core.modules.battle.model;

import java.util.HashMap;
import java.util.Map;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.PvpType;
import com.nucleus.logic.core.modules.battle.dto.VideoActionTargetState;
import com.nucleus.logic.core.modules.battle.dto.VideoRoundAction;
import com.nucleus.player.service.ScriptService;

/**
 * pvp战斗回合处理器,针对handle特殊处理，增加达到指定回合后的处理逻辑
 * 
 * @author wgy
 *
 */
public class PvpBattleRoundProcessor extends DefaultBattleRoundProcessor {

	public PvpBattleRoundProcessor(Battle battle) {
		super(battle);
	}

	@Override
	public void handle() {
		super.handle();
		final boolean isBattleOver = getBattle().isOver(true);
		if (!isBattleOver) {
			roundEndHandle();
		}
	}

	private void roundEndHandle() {
		if (!(getBattle() instanceof PvpBattle))
			return;
		PvpBattle battle = (PvpBattle) getBattle();
		PvpType bt = PvpType.get(battle.getType());

		float punishRate = this.calPunishRate(bt.getPunishRate(), battle.getCount());
		if (bt == null || bt.getPunishRound() <= 0 || punishRate <= 0)
			return;
		if (battle.getCount() > bt.getPunishRound())
			godsPunish(battle, punishRate);
	}

	private void godsPunish(PvpBattle battle, float punishRate) {
		VideoRoundAction endAction = battle.currentVideoRound().afterEndAction();
		for (BattleSoldier soldier : soldiers()) {
			if (soldier.isDead())
				continue;
			int hp = (int) (soldier.maxHp() * punishRate);
			if (hp <= 0)
				continue;
			hp = -hp;
			VideoActionTargetState state = new VideoActionTargetState(soldier, hp, 0, false);
			endAction.addTargetState(state);
			boolean willDie = soldier.hp() + hp <= 0;
			state.setDead(willDie);
			soldier.decreaseHp(hp);
			state.setLeave(soldier.isLeave());
		}
		float sec = StaticConfig.get(AppStaticConfigs.GOD_PUNISH_TIME_SEC).getAsFloat(1.f);
		battle.addEstimatedPlaySec(sec);
	}

	private float calPunishRate(String punishRate, int round) {
		Map<String, Object> params = new HashMap<String, Object>();
		params.put("round", round);
		return ScriptService.getInstance().calcuFloat("PvpBattleRoundProcessor", punishRate, params, false);
	}

}
