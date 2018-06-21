package com.nucleus.logic.core.modules.battle.model;

import java.util.Collection;
import java.util.Map;

import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.dto.PvpVideo;
import com.nucleus.logic.core.modules.battle.dto.Video;
import com.nucleus.logic.core.modules.battle.event.BattleEvent;
import com.nucleus.logic.core.modules.charactor.event.CharactorPropertyUpdateEvent;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.player.event.TransfromStateEvent;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.vo.PvpBattleFinishVo;

/**
 * pvp战斗
 * 
 * @author wgy
 *
 */
public abstract class PvpBattle extends BattleAdapter {
	/**
	 * 通过双方队长进入战斗
	 * 
	 * @param p1
	 *            a team leader
	 * @param p2
	 *            b team leaer
	 */
	public PvpBattle(BattlePlayer p1, BattlePlayer p2) {
		initTeamPlayers(p1, this.battleInfo().aTeamPlayers());
		initTeamPlayers(p2, this.battleInfo().bTeamPlayers());
	}

	/**
	 * 两队玩家直接进入战斗,不再根据队长取整个队伍成员
	 * 
	 * @param team1Players
	 * @param team2Players
	 */
	public PvpBattle(Collection<BattlePlayer> team1Players, Collection<BattlePlayer> team2Players) {
		initTeamPlayers(team1Players, this.battleInfo().aTeamPlayers());
		initTeamPlayers(team2Players, this.battleInfo().bTeamPlayers());
	}

	protected void initTeamPlayers(Collection<BattlePlayer> readyPlayers, Map<Long, BattlePlayer> playersHolder) {
		for (BattlePlayer bp : readyPlayers) {
			playersHolder.put(bp.getId(), bp);
		}
	}

	@Override
	protected BattleTeam initBteam() {
		return new BattleTeam(this.battleInfo().bTeamPlayers().values(), this);
	}

	@Override
	public boolean needPlayerAutoBattle() {
		return false;
	}

	@Override
	protected void battleFinish(BattleTeam winTeam, BattleTeam loseTeam) {
		super.battleFinish(winTeam, loseTeam);
		propertyUpdate(this.battleInfo());
		transformStateHandle(this.battleInfo());

		if (winTeam != null && loseTeam != null) {
			finishVo().append(new PvpBattleFinishVo(this, winTeam, loseTeam));
			// final PvpBattleFinishVo finishVo = new PvpBattleFinishVo(this,
			// winTeam, loseTeam);
			// SceneManager.getInstance().forward(AppServerMode.Core, finishVo);
		}
	}

	protected void propertyUpdate(BattleInfo battleInfo) {
		this.propertyUpdateOfTeam(battleInfo.getAteam());
		this.propertyUpdateOfTeam(battleInfo.getBteam());
	}

	protected void propertyUpdateOfTeam(BattleTeam team) {
		if (team == null)
			return;
		for (BattleSoldier soldier : team.allSoldiersMap().values()) {
			BattleUnit bu = soldier.battleUnit();
			if (bu instanceof PersistPlayerPet || bu instanceof PersistPlayer) {
				// 属性变化才通知
				if (bu.hp() != soldier.hp() || bu.mp() != soldier.mp()) {
					BattlePlayer player = soldier.player();
					if (player != null) {
						player.dispatchEvent(new CharactorPropertyUpdateEvent(bu.playerId(), bu, true));// 2015.07.23统一恢复满
					}
				}
			}
		}
	}

	protected void transformStateHandle(BattleInfo battleInfo) {
		transformStateHandleOfTeam(battleInfo.getAteam());
		transformStateHandleOfTeam(battleInfo.getBteam());
	}

	protected void transformStateHandleOfTeam(BattleTeam team) {
		for (BattlePlayer player : team.players()) {
			// player.dispatchEvent(BattleEvent.wrap(new
			// TransfromStateEvent(true)));
			finishVo().addEvent(BattleEvent.wrap(player.getId(), new TransfromStateEvent(true)));
		}
	}

	@Override
	public float retreatSuccessRate() {
		return StaticConfig.get(AppStaticConfigs.PVP_RETREAT_SUCCESS_RATE).getAsFloat(0.5f);
	}

	@Override
	protected Video createVideo() {
		return new PvpVideo(this.maxRound(), this.getType());
	}

	@Override
	protected void afterStart() {
		super.afterStart();
		// transformStateHandle(this.battleInfo().getAteam());
	}

	@Override
	protected BattleRoundProcessor createBattleRoundProcessor() {
		return new PvpBattleRoundProcessor(this);
	}

	public abstract int getType();

	@Override
	public boolean barrage() {
		return true;
	}

	/**
	 * 计算胜利的队
	 * 
	 * @return
	 */
	protected BattleTeam calcWinTeam() {
		BattleInfo battleInfo = this.battleInfo();
		BattleTeam aTeam = battleInfo.getAteam();
		BattleTeam bTeam = battleInfo.getBteam();
		int aliveCountOfA = aTeam.aliveSoldiers().size();
		int aliveCountOfB = bTeam.aliveSoldiers().size();
		if (aliveCountOfA > aliveCountOfB)
			return aTeam;
		else if (aliveCountOfA < aliveCountOfB)
			return bTeam;
		else {
			int hpOfA = calcHp(aTeam);
			int hpOfB = calcHp(bTeam);
			if (hpOfA > hpOfB)
				return aTeam;
			else if (hpOfB > hpOfA)
				return bTeam;
			else {
				int rnd = RandomUtils.nextInt(1, 2);
				if (rnd == 1)
					return aTeam;
				else
					return bTeam;
			}
		}
	}

	/**
	 * 计算队伍血量
	 * 
	 * @param team
	 * @return
	 */
	protected int calcHp(BattleTeam team) {
		int hp = 0;
		for (BattleSoldier soldier : team.soldiersMap().values()) {
			if (soldier.isDead())
				continue;
			hp += soldier.hp();
		}
		return hp;
	}
}
