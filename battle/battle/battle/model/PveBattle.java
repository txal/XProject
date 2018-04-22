package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;

import com.nucleus.AppServerMode;
import com.nucleus.commons.data.StaticConfig;
import com.nucleus.commons.utils.RandomUtils;
import com.nucleus.logic.core.modules.AppStaticConfigs;
import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.Monster.MonsterType;
import com.nucleus.logic.core.modules.battle.dto.VideoCaptureState;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.data.Pet;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.scene.manager.SceneManager;
import com.nucleus.logic.core.vo.BattleStartVo;
import com.nucleus.logic.core.vo.CapturePetVo;
import com.nucleus.logic.scene.SceneModeService;

/**
 * 
 * @author Omanhom
 *
 */
public abstract class PveBattle extends BattleAdapter {

	/** 记录已扣除双倍点的玩家ID */
	private List<Long> useDoubleExpPlayers = new ArrayList<Long>();
	/** 是否使用双倍点的战斗 */
	private boolean useDoubleExpBattle = false;

	public PveBattle(BattlePlayer player) {
		initTeamPlayers(player, this.battleInfo().aTeamPlayers());
	}

	public boolean isUseDoubleExpBattle() {
		return useDoubleExpBattle;
	}

	public void setUseDoubleExpBattle(boolean useDoubleExpBattle) {
		this.useDoubleExpBattle = useDoubleExpBattle;
	}

	public void addUseDoubleExp(Long playerId) {
		if (playerId != null)
			useDoubleExpPlayers.add(playerId);
	}

	protected boolean usedDoubleExp(Long playerId) {
		if (playerId != null)
			return useDoubleExpPlayers.contains(playerId);
		return false;
	}

	protected List<Long> useDoubleExpPlayers() {
		return this.useDoubleExpPlayers;
	}

	@Override
	public float retreatSuccessRate() {
		return StaticConfig.get(AppStaticConfigs.PVE_RETREAT_SUCCESS_RATE).getAsFloat(0.7f);
	}

	@Override
	protected void afterStart() {
		super.afterStart();
		List<Long> playerList = this.battleInfo().getAteam().playerIds();
		if (playerList.isEmpty())
			return;
		final BattleStartVo startVo = new BattleStartVo(this, battleInfo().getAteam(), battleInfo().getBteam());
		startVo.setUseDoubleExp(this.isUseDoubleExpBattle());
		startVo.setSceneServerId(SceneModeService.getInstance().sceneServerId());
		SceneManager.getInstance().forward(AppServerMode.Core, startVo);
	}

	@Override
	public void capturePet(CommandContext commandContext) {
		BattlePlayer player = commandContext.trigger().player();
		checkCapture(player);
		float rate = getCaptureRate(commandContext);
		boolean success = RandomUtils.baseRandomHit(rate);
		BattleSoldier target = commandContext.target();
		VideoCaptureState state = new VideoCaptureState(target, success, rate);
		commandContext.skillAction().addTargetState(state);
		if (success) {
			Monster monster = Monster.get(target.monsterId());
			Pet pet = monster.pet();
			if (pet == null)
				return;

			float min = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_MIN_LEVEL).getAsFloat(0.7f);
			float max = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_MAX_LEVEL).getAsFloat(1.0f);
			int minLevel = (int) (target.grade() * min);
			int maxlevel = (int) (target.grade() * max);
			int grade = RandomUtils.nextInt(minLevel, maxlevel);

			boolean mutate = isMutate(target);
			boolean baby = target.getMonsterType() == MonsterType.Baobao.ordinal() || mutate;
			boolean wildToBaby = false;
			if (!baby) {
				float wildToBabyRate = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_BE_BAOBAO_RATE).getAsFloat(0.1f);
				if (RandomUtils.baseRandomHit(wildToBabyRate)) {
					wildToBaby = true;
				}
			}

			final CapturePetVo capturePetVo = new CapturePetVo(monster.getId(), grade, baby, wildToBaby, mutate, player.getId());
			SceneManager.getInstance().forward(AppServerMode.Core, capturePetVo);

			state.setWildToBaobao(wildToBaby);
			state.setPetId(pet.getId());
			target.leaveTeam();
			player.carryPetAmount(player.carryPetAmount() + 1);
		}
	}

	protected void checkCapture(BattlePlayer player) {
		// empty
	}

	protected boolean isMutate(BattleSoldier target) {
		return target.getMonsterType() == MonsterType.Mutate.ordinal();
	}

	protected float getCaptureRate(CommandContext commandContext) {
		BattleSoldier target = commandContext.target();
		Monster monster = Monster.get(target.monsterId());
		if (monster == null)
			return 0;
		Pet pet = monster.pet();
		if (pet == null)
			return 0;
		float rate = pet.getCaptureRate();
		int hp = target.hp(), maxHp = target.maxHp();
		if (hp <= 0 || maxHp <= 0)
			return 0;
		float v = (float) hp / maxHp;
		float factor1 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_1).getAsFloat(0.05f);
		float factor2 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_2).getAsFloat(0.2f);
		float factor3 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_3).getAsFloat(0.5f);
		float factor4 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_4).getAsFloat(0.8f);

		float factor11 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_11).getAsFloat(3.5f);
		float factor12 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_12).getAsFloat(0.4f);

		float factor21 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_21).getAsFloat(2.5f);
		float factor22 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_22).getAsFloat(0.15f);

		float factor31 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_31).getAsFloat(2);
		float factor32 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_32).getAsFloat(0.1f);

		float factor41 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_41).getAsFloat(1.5f);
		float factor42 = StaticConfig.get(AppStaticConfigs.HIDDEN_MONSTER_CAPTURE_FACTOR_42).getAsFloat(0.05f);

		if (v < factor1)
			rate = rate * factor11 + factor12;
		else if (v < factor2)
			rate = rate * factor21 + factor22;
		else if (v < factor3)
			rate = rate * factor31 + factor32;
		else if (v < factor4)
			rate = rate * factor41 + factor42;
		return rate;
	}

	@Override
	protected void afterInitBattleInfo() {
		super.afterInitBattleInfo();
		// 怪物的属性在敌方确定后重新设置
		initTeamSoldiersProperty(this.battleInfo().getBteam());
		this.battleInfo().getBteam().setNpcTeam(true);
	}

	@Override
	protected void battleFinish(BattleTeam winTeam, BattleTeam loseTeam) {
		super.battleFinish(winTeam, loseTeam);
		loseDuration(battleInfo().getAteam());
		hpHandle(battleInfo().getAteam());
		if (this.useDoubleExpPlayers != null && !this.useDoubleExpPlayers.isEmpty()) {
			finishVo().setUseDoubleExpPlayers(new HashSet<>(this.useDoubleExpPlayers));
		}
		finishMetaData(finishVo().getMetaData());
	}

	private void hpHandle(BattleTeam team) {
		// 将持久化对象同步最新数据
		for (BattleSoldier soldier : team.allSoldiersMap().values()) {
			if (soldier.charactorType() == CharactorType.MainCharactor.ordinal() || soldier.charactorType() == CharactorType.Pet.ordinal()) {
				soldier.battleUnit().hp(soldier.hp());
				soldier.battleUnit().mp(soldier.mp());
			}
		}
	}

	protected void finishMetaData(Map<String, Object> metaData) {
		// subclass fill meta data;
	}

	@Override
	protected BattleTeam initAteam() {
		BattleTeam t = super.initAteam();
		// 重设主角/宠物的hp和mp
		for (BattleSoldier soldier : t.allSoldiersMap().values()) {
			BattleUnit bu = soldier.battleUnit();
			if (bu instanceof PersistPlayerPet || bu instanceof PersistPlayer) {
				soldier.battleBaseProperties().setHp(bu.hp());
				soldier.battleBaseProperties().setMp(bu.mp());
			}
		}
		return t;
	}

	@Override
	public boolean barrage() {
		return false;
	}
}
