/**
 * 
 */
package com.nucleus.logic.core.modules.battle.model;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

import com.nucleus.logic.core.modules.battle.data.Monster;
import com.nucleus.logic.core.modules.battle.data.Skill.UserTargetScopeType;
import com.nucleus.logic.core.modules.battle.dto.VideoSoldier;
import com.nucleus.logic.core.modules.battle.dto.VideoTeam;
import com.nucleus.logic.core.modules.charactor.data.GeneralCharactor.CharactorType;
import com.nucleus.logic.core.modules.charactor.model.FormationCaseInfo;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerCharactor;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerCrew;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.formation.data.Formation;
import com.nucleus.logic.core.modules.formation.data.Formation.FormationType;
import com.nucleus.logic.core.modules.scene.data.Tollgate;
import com.nucleus.logic.core.modules.scene.data.TollgateMonster;

/**
 * @author liguo
 * 
 */
public class BattleTeam {

	private static final AtomicInteger battleTeamIdSeed = new AtomicInteger(1);

	/** 战斗队伍唯一标识 **/
	private final int id = battleTeamIdSeed.getAndIncrement();

	/** 参战玩家编号列表 */
	private LinkedList<Long> playerIds = new LinkedList<Long>();

	/** 队长编号 */
	private long leaderId;

	/** 阵形第一个进入战斗单位编号 */
	private long firstFromationSoldierId;

	/** 队伍阵型ID **/
	private int formationId;

	/** 敌方队伍 */
	private BattleTeam enemyTeam;

	/** 当前战斗 */
	private Battle battle;

	/** 所有出战单位 - battleSoldierId */
	private final Map<Long, BattleSoldier> allSoldiersMap = new ConcurrentHashMap<Long, BattleSoldier>();
	/** 留在战场上的单位 */
	private final Map<Long, BattleSoldier> soldiersMap = new ConcurrentHashMap<Long, BattleSoldier>();

	/** 所有玩家可控制士兵列表 - key:playerId */
	private final Map<Long, BattlePlayerSoldierInfo> soldierInfosMapByPlayerId = new ConcurrentHashMap<Long, BattlePlayerSoldierInfo>();

	/** 下回合新增玩家 */
	private List<BattleSoldier> nextRoundNewJoinSoldiers = new ArrayList<BattleSoldier>();

	/** 下回合替换士兵编号 */
	private List<Long> nextRoundSubstitudeSoldierIds = new ArrayList<Long>();

	private BattleFormationAdapter formationAdapter;
	/** 缓存撤退玩家id */
	private Set<Long> retreatPlayerIds = new HashSet<Long>();

	/** 召唤出来的小怪 */
	private Map<Long, BattleSoldier> calledMonsters = new ConcurrentHashMap<Long, BattleSoldier>();
	/** 本队对应videoTeam */
	private VideoTeam videoTeam;
	/** 本队战场上战斗单位数量 */
	private volatile int soldierCount;
	/** 撤退成功率扣减 */
	private float retreateReducceRate = 0;

	/** 战斗中的玩家信息 */
	private Map<Long, BattlePlayer> battlePlayers = new HashMap<>(5);
	private boolean isNpcTeam;
	/** 全队适用buff */
	private Set<Integer> teamBuffIds = new HashSet<>();
	/** 本回合死亡单位数量 */
	private int currentRoundDeadCount;
	/** key=召唤者id(BattleSoldier.id), value=该单位召唤的怪 */
	private Map<Long, Set<Long>> calledSoldiers = new HashMap<>();
	/** 援军单位 */
	private Set<Long> reinforcement = new HashSet<>();

	public BattleTeam(Collection<BattlePlayer> players, Battle battle) {
		this(players, battle, -1);
	}

	public BattleTeam(Collection<BattlePlayer> players, Battle battle, int formationId) {
		this(players, battle, formationId, false);
	}

	public BattleTeam(Collection<BattlePlayer> playerSet, Battle battle, int formationId, boolean ignoreCrew) {
		final List<BattlePlayer> players = new ArrayList<>(playerSet);
		Collections.sort(players, new Comparator<BattlePlayer>() {
			@Override
			public int compare(BattlePlayer o1, BattlePlayer o2) {
				return o1.getTeamIndex() - o2.getTeamIndex();
			}
		});
		this.battle = battle;
		BattlePlayer leaderPlayer = getLeader(players);
		this.leaderId = leaderPlayer.getId();
		this.firstFromationSoldierId = leaderPlayer.getId();

		// 读取的阵型优先级这样：
		// 1、组队就读取当前队伍的阵型
		// 2、没有组队就读取伙伴布阵界面的进攻阵型
		// 另外玩家只要挂了组队并设置了队伍阵型，挂机，抓鬼等等只要其他玩家和伙伴能凑够5人出战，就调用队伍阵型，不够则都是普通阵
		final int maxTeamSize = battle.maxTeamPlayerSize();
		PersistPlayerCharactor playerCharactorInfo = leaderPlayer.persistPlayerCharactor();
		final List<PersistPlayerCrew> ppccs = ignoreCrew ? new ArrayList<>() : leaderPlayer.battleCrews();
		this.formationId = formationId;
		if (formationId <= 0) {
			int teamUnitSize = players.size();
			if (teamUnitSize + ppccs.size() >= maxTeamSize) {
				if (leaderPlayer.ifTeamLeader()) {
					this.formationId = playerCharactorInfo.getFormationOfTeam();
				} else {
					FormationCaseInfo formationCaseInfo = playerCharactorInfo.formationCaseInfo();
					this.formationId = formationCaseInfo.activeFormationId();
				}
			} else {
				this.formationId = FormationType.Regular.ordinal();
			}
		}

		this.formationAdapter = new BattleFormationAdapter(battle, this.formationId);
		List<BattlePlayer> playerList = new ArrayList<>(players);
		Collections.sort(playerList, new Comparator<BattlePlayer>() {
			@Override
			public int compare(BattlePlayer o1, BattlePlayer o2) {
				return o1.getTeamIndex() - o2.getTeamIndex();
			}
		});
		for (BattlePlayer player : playerList) {
			battlePlayers.put(player.getId(), player);
			joinTeam(player);
		}
		int curTeamSize = players.size();
		if (curTeamSize < maxTeamSize) {
			if (!ppccs.isEmpty()) {
				PersistPlayerCrew[] arr = ppccs.toArray(new PersistPlayerCrew[maxTeamSize - 1]);
				int lastRevertPos = 0;
				int crewCount = ppccs.size();
				for (int i = curTeamSize - 1; i < maxTeamSize - 1 && crewCount > 0; i++) {
					PersistPlayerCrew crewCharactor = arr[i];
					if (crewCharactor == null) {
						crewCharactor = arr[lastRevertPos];
						lastRevertPos++;
					}
					if (null == crewCharactor)
						continue;
					BattleSoldier crewSoldier = new BattleSoldier(this, crewCharactor);
					addSoldier(crewSoldier);
					this.formationAdapter.involveCrew(crewSoldier);
					crewCount--;
				}
			}
		}
	}

	public BattleTeam(BattlePlayer leaderPlayer, Battle battle, int formationId) {
		this.battle = battle;
		this.leaderId = leaderPlayer.getId();
		this.firstFromationSoldierId = leaderPlayer.getId();
		this.formationId = formationId;
		final int maxTeamSize = battle.maxTeamPlayerSize();
		this.formationAdapter = new BattleFormationAdapter(battle, this.formationId);
		battlePlayers.put(leaderPlayer.getId(), leaderPlayer);
		joinTeam(leaderPlayer);

		PersistPlayerCrew[] arr = leaderPlayer.battleCrews().toArray(new PersistPlayerCrew[maxTeamSize - 1]);
		int lastRevertPos = 0;
		int crewCount = arr.length;
		for (int i = 0; i < maxTeamSize - 1 && crewCount > 0; i++) {
			PersistPlayerCrew crewCharactor = arr[i];
			if (crewCharactor == null) {
				crewCharactor = arr[lastRevertPos];
				lastRevertPos++;
			}
			if (null == crewCharactor)
				continue;
			BattleSoldier crewSoldier = new BattleSoldier(this, crewCharactor);
			addSoldier(crewSoldier);
			this.formationAdapter.involveCrew(crewSoldier);
			crewCount--;
		}

	}

	public BattleTeam(List<Integer> monsterIds, List<Integer> monsterTypes, Battle battle) {
		this.battle = battle;
		int useFormationId = FormationType.Regular.ordinal();
		this.formationAdapter = new BattleFormationAdapter(battle, useFormationId);
		this.setFormationId(useFormationId);
		int pos = 0;
		for (int i = 0; i < monsterIds.size(); i++) {
			Monster curMonster = Monster.get(monsterIds.get(i));
			if (null == curMonster)
				continue;
			if (this.outOfPositionSize()) {
				this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
				break;
			}
			BattleSoldier monsterSoldier = new BattleSoldier(this, curMonster, pos++);
			monsterSoldier.monsterVary(monsterTypes.get(i));
			addSoldier(monsterSoldier);
			this.formationAdapter.involveMonster(monsterSoldier);
			if (i == 0)
				this.firstFromationSoldierId = monsterSoldier.getId();
		}
	}

	public BattleTeam(Monster monster, int amount, Battle battle) {
		this.battle = battle;
		int useFormationId = FormationType.Regular.ordinal();
		this.formationAdapter = new BattleFormationAdapter(battle, useFormationId);
		this.setFormationId(useFormationId);
		int pos = 0;
		for (int i = 0; i < amount; i++) {
			if (this.outOfPositionSize()) {
				this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
				break;
			}
			BattleSoldier monsterSoldier = new BattleSoldier(this, monster, pos++);
			addSoldier(monsterSoldier);
			this.formationAdapter.involveMonster(monsterSoldier);
			if (i == 0)
				this.firstFromationSoldierId = monsterSoldier.getId();
		}
	}

	public BattleTeam(Tollgate tollgate, int playerSize, Battle battle) {
		this(tollgate, playerSize, battle, -1, null);
	}

	public BattleTeam(Tollgate tollgate, int playerSize, Battle battle, int formationId, List<BattleSoldier> addSoldierHolder) {
		this.battle = battle;
		formationId = formationId < 1 ? tollgate.getFormationId() : formationId;
		this.formationAdapter = new BattleFormationAdapter(battle, formationId);
		this.setFormationId(formationId);
		int maxBattleUnitSize = battle.maxUnitSize();
		int battleUnitCount = 0;
		List<TollgateMonster> monsters = tollgate.getMonsters();
		for (int i = 0; i < monsters.size(); i++) {
			TollgateMonster tollgateMonster = monsters.get(i);
			int[] monsterIds = tollgateMonster.getMonsterIds();
			if (monsterIds.length == 0)
				continue;
			int count = tollgateMonster.count(playerSize);
			for (int j = 0; j < count; j++) {
				int monsterId = tollgateMonster.monsterId();
				Monster curMonster = Monster.get(monsterId);
				if (null == curMonster)
					continue;
				if (this.outOfPositionSize()) {
					this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
					break;
				}
				battleUnitCount++;
				BattleSoldier monsterSoldier = new BattleSoldier(this, curMonster, battleUnitCount);
				addSoldier(monsterSoldier);
				if (addSoldierHolder != null)
					addSoldierHolder.add(monsterSoldier);
				this.formationAdapter.involveMonster(monsterSoldier);
				if (battleUnitCount == 1)
					this.firstFromationSoldierId = monsterSoldier.getId();
				if (battleUnitCount >= maxBattleUnitSize)
					break;
			}
			if (battleUnitCount >= maxBattleUnitSize)
				break;
		}
	}

	private BattlePlayer getLeader(Collection<BattlePlayer> players) {
		if (players.isEmpty())
			return null;
		if (players.size() > 1) {
			for (BattlePlayer p : players) {
				if (p.ifTeamLeader())
					return p;
			}
		} else
			return players.iterator().next();
		return null;
	}

	private boolean outOfPositionSize() {
		return this.soldierCount >= this.battle.maxPositionSize();
	}

	/**
	 * 增加召唤的怪物
	 * 
	 * @param caller
	 * @param monster
	 * @param ignoreCallLimit
	 *            是否忽略战斗中召唤怪物的限制
	 * @return
	 */
	public BattleSoldier addCalledMonster(BattleSoldier caller, Monster monster, boolean ignoreCallLimit) {
		if (outOfPositionSize()) {
			this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
			return null;
		}
		if (!ignoreCallLimit) {
			// 指定怪已经存在的数量
			int calledCount = getCalledCountOf(monster);
			if (calledCount >= this.battle.maxCallMonsterSize())
				return null;
		}
		int index = this.formationAdapter.findEmptyIndex(ignoreCallLimit);
		if (index < 0)
			return null;
		BattleSoldier soldier = new BattleSoldier(this, monster);
		this.addSoldier(soldier);
		this.calledMonsters.put(soldier.getId(), soldier);
		this.addCalledSoldier(caller.getId(), soldier.getId());
		this.formationAdapter.addCalledMonster(soldier, index);
		if (this.videoTeam != null)
			this.videoTeam.getTeamSoldiers().add(new VideoSoldier(soldier));
		return soldier;
	}

	/**
	 * 替换旧位置上的小怪
	 * 
	 * @param monster
	 * @param position
	 * @return
	 */
	public BattleSoldier replaceCalledMonster(BattleSoldier caller, Monster monster, int position) {
		BattleSoldier soldier = new BattleSoldier(this, monster);
		this.soldiersMap.put(soldier.id(), soldier);
		this.allSoldiersMap.put(soldier.getId(), soldier);
		this.calledMonsters.put(soldier.getId(), soldier);
		this.addCalledSoldier(caller.getId(), soldier.getId());
		this.formationAdapter.addCalledMonster(soldier, position - 1);
		if (this.videoTeam != null)
			this.videoTeam.getTeamSoldiers().add(new VideoSoldier(soldier));
		return soldier;
	}

	private int getCalledCountOf(Monster monster) {
		int count = 0;
		for (Entry<Long, BattleSoldier> entry : this.calledMonsters.entrySet()) {
			BattleSoldier soldier = entry.getValue();
			if (!(soldier.battleUnit() instanceof Monster))
				continue;
			Monster m = (Monster) soldier.battleUnit();
			if (m.getId() == monster.getId())
				count++;
		}
		return count;
	}

	/**
	 * 增加援军
	 * 
	 * @param monster
	 * @return
	 */
	public BattleSoldier addReinforcement(Monster monster) {
		if (outOfPositionSize()) {
			this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
			return null;
		}
		int index = this.formationAdapter.findEmptyIndex(false);
		if (index < 0)
			return null;
		BattleSoldier soldier = new BattleSoldier(this, monster);
		this.addSoldier(soldier);
		this.formationAdapter.addCalledMonster(soldier, index);
		this.reinforcement.add(soldier.getId());
		return soldier;
	}

	/**
	 * 增加援军
	 *
	 * @param playerCrew
	 * @return
	 */
	public BattleSoldier addReinforcement(PersistPlayerCrew playerCrew) {
		if (outOfPositionSize()) {
			this.battle.getLog().info("out of position size:" + this.soldierCount + "/" + this.battle.maxPositionSize());
			return null;
		}
		int index = this.formationAdapter.findEmptyIndex(false);
		if (index < 0)
			return null;
		BattleSoldier soldier = new BattleSoldier(this, playerCrew);
		this.addSoldier(soldier);
		this.formationAdapter.addCalledMonster(soldier, index);
		this.reinforcement.add(soldier.getId());
		return soldier;
	}

	public boolean validateTarget(UserTargetScopeType scopeType, long triggerSoldierId, long targetId) {
		if (!this.hasSoldier(triggerSoldierId))
			return false;

		boolean result = false;
		BattleSoldier target = null;
		switch (scopeType) {
			case Enemy:
				result = this.hasEnemy(targetId);
				break;
			case Self:
				result = triggerSoldierId == targetId || targetId == 0;
				break;
			case FriendsExceptSelfWithPet:
				result = triggerSoldierId != targetId && this.hasSoldier(targetId);
				break;
			case FriendsWithPet:
				result = this.hasSoldier(targetId);
				break;
			case FriendPets:
				BattleSoldier petSoldier = soldiersMap().get(targetId);
				result = null != petSoldier && petSoldier.charactorType() == CharactorType.Pet.ordinal();
				break;
			case ExceptSelf:
				result = triggerSoldierId != targetId && (this.hasSoldier(targetId) || this.hasEnemy(targetId));
				break;
			case Fere:
				result = targetId > 0 && targetId == this.soldier(triggerSoldierId).fereId();
				break;
			case EnemyPlayer:
				target = this.enemyTeam.soldiersMap().get(targetId);
				result = target != null && target.isMainCharactor();
				break;
			case MyTeamPlayer:
				target = this.soldier(targetId);
				result = target != null && target.isMainCharactor();
				break;
			case EnemyPets:
				target = this.enemyTeam.soldiersMap().get(targetId);
				result = target != null && target.charactorType() == CharactorType.Pet.ordinal();
				break;
			default:
		}
		return result;
	}

	public List<BattleSoldier> nextRoundNewJoinSoldiers() {
		return this.nextRoundNewJoinSoldiers;
	}

	public void clearNextRoundNewJoinSoldiers() {
		this.nextRoundNewJoinSoldiers.clear();
	}

	public List<Long> nextRoundSubstitudeSoldierIds() {
		return this.nextRoundSubstitudeSoldierIds;
	}

	public void clearNextRoundSubstitudeSoldierIds() {
		this.nextRoundSubstitudeSoldierIds.clear();
	}

	public boolean hasPlayer(long playerId) {
		return playerIds.contains(playerId);
	}

	public boolean hasSoldier(long battleSoldierId) {
		return soldiersMap.containsKey(battleSoldierId);
	}

	public boolean hasEnemy(long battleSoldierId) {
		return enemyTeam.hasSoldier(battleSoldierId);
	}

	public Map<Long, BattleSoldier> soldiersMap() {
		return this.soldiersMap;
	}

	public boolean ifPlayerLeader(long playerId) {
		return playerId > 0 && playerId == leaderId;
	}

	private List<BattleSoldier> joinTeam(BattlePlayer player) {
		if (null == player)
			return null;
		playerIds.add(player.getId());
		// return init(PlayerCharactorInfoHolderManager.getInstance().load(player));
		return init(player);
	}

	public void playerLeave(long playerId) {
		this.playerIds.remove(playerId);
		this.soldierInfosMapByPlayerId.remove(playerId);
	}

	public void soldierLeave(BattleSoldier soldier) {
		if (this.soldiersMap.containsKey(soldier.getId())) {
			this.soldiersMap.remove(soldier.getId());
			this.formationAdapter.getSoldierIdsFormation()[soldier.getPosition() - 1] = 0;
			this.calledMonsters.remove(soldier.getId());
			this.soldierCount--;
			if (this.videoTeam != null) {
				for (Iterator<VideoSoldier> it = this.videoTeam.getTeamSoldiers().iterator(); it.hasNext();) {
					VideoSoldier vs = it.next();
					if (vs.getId() == soldier.getId()) {
						it.remove();
						break;
					}
				}
			}
		}

	}

	private List<BattleSoldier> init(BattlePlayer player) {
		PersistPlayerCharactor holder = player.persistPlayerCharactor();
		List<BattleSoldier> newJoinSoldiers = new ArrayList<BattleSoldier>();

		BattleSoldier mainCharactorSoldier = new BattleSoldier(this, player.persistPlayer());
		newJoinSoldiers.add(mainCharactorSoldier);
		this.addSoldier(mainCharactorSoldier);
		BattleSoldier petCharactorSoldier = null;
		PersistPlayerPet petCharactor = player.battlePet();
		player.bonusPet(petCharactor);
		if (null != petCharactor) {
			petCharactorSoldier = new BattleSoldier(this, petCharactor);
			newJoinSoldiers.add(petCharactorSoldier);
			this.addSoldier(petCharactorSoldier);
		}

		BattlePlayerSoldierInfo soldierInfo = new BattlePlayerSoldierInfo(mainCharactorSoldier.getId(), null == petCharactorSoldier ? 0 : petCharactorSoldier.getId());
		soldierInfosMapByPlayerId.put(holder.ownerId(), soldierInfo);

		this.formationAdapter.involvePlayer(mainCharactorSoldier, petCharactorSoldier);

		return newJoinSoldiers;
	}

	public BattleSoldier battleSoldier(long soldierId) {
		return soldiersMap.get(soldierId);
	}

	public BattlePlayerSoldierInfo soldiersByPlayer(long playerId) {
		return soldierInfosMapByPlayerId.get(playerId);
	}

	public Map<Long, BattlePlayerSoldierInfo> soldierInfosMap() {
		return soldierInfosMapByPlayerId;
	}

	public boolean isPlayerSoldiersReady() {
		boolean isSoldiersReady = true;
		if (this.isNpcTeam || soldierInfosMapByPlayerId.isEmpty()) {
			return isSoldiersReady;
		}

		boolean isAfterCurAutoNotifyTime = System.currentTimeMillis() > battle.curAutoNotifyTime();
		for (BattlePlayerSoldierInfo playerSoldersInfo : soldierInfosMapByPlayerId.values()) {
			BattleSoldier mainCharactorSoldier = soldiersMap().get(playerSoldersInfo.mainCharactorSoldierId());
			BattleSoldier petSoldier = soldiersMap().get(playerSoldersInfo.petSoldierId());
			if (!ifSoldierReady(mainCharactorSoldier, isAfterCurAutoNotifyTime) || !ifSoldierReady(petSoldier, isAfterCurAutoNotifyTime)) {
				isSoldiersReady = false;
				break;
			}
		}
		return isSoldiersReady;
	}

	private boolean ifSoldierReady(BattleSoldier soldier, boolean isAfterCurAutoNotifyTime) {
		if (null == soldier || soldier.isLeave()) {
			return true;
		}

		if (soldier.isAutoBattle() && isAfterCurAutoNotifyTime) {
			soldier.initCommandContextIfAbsent();
		}

		if (null == soldier.getCommandContext()) {
			return false;
		}
		return true;
	}

	private void addSoldier(BattleSoldier soldier) {
		this.soldiersMap.put(soldier.id(), soldier);
		this.allSoldiersMap.put(soldier.getId(), soldier);
		this.soldierCount++;
	}

	/*
	 * public void broadcastLeaderPlayer(BroadcastMessage notifyMessage) { long leaderPlayerId = playerIds.getFirst(); H1PlayerManager playerManager =
	 * H1PlayerManager.getInstance(); Player leaderPlayer = playerManager.getOnlinePlayerById(leaderPlayerId); if (null == leaderPlayer) { return; }
	 * leaderPlayer.deliver(notifyMessage); }
	 */

	public Set<Long> onlineTeamPlayerIds() {
		return new HashSet<>(playerIds);
		/*
		 * Set<Long> onlineTeamPlayerIds = new HashSet<Long>(); H1PlayerManager playerManager = H1PlayerManager.getInstance(); for (Iterator<Long> it = playerIds.iterator();
		 * it.hasNext();) { long playerId = it.next(); Player curPlayer = playerManager.getOnlinePlayerById(playerId); if (null == curPlayer) { continue; }
		 * onlineTeamPlayerIds.add(curPlayer.getId()); } return onlineTeamPlayerIds;
		 */
	}

	public BattleTeam getEnemyTeam() {
		return enemyTeam;
	}

	public void setEnemyTeam(BattleTeam enemyTeam) {
		this.enemyTeam = enemyTeam;
	}

	public Battle battle() {
		return battle;
	}

	public BattleSoldier soldier(long soldierUniqueId) {
		return soldiersMap.get(soldierUniqueId);
	}

	/**
	 * 
	 * @return
	 */
	public Collection<BattleSoldier> roundQueue() {
		if (soldiersMap.isEmpty()) {
			return Collections.emptyList();
		}
		return this.soldiersMap.values();
	}

	/**
	 * 战斗过程中获得阵上活着的角色
	 *
	 * @return
	 */
	public List<BattleSoldier> aliveSoldiers() {
		if (this.soldiersMap.isEmpty())
			return Collections.emptyList();
		List<BattleSoldier> soldiers = new ArrayList<BattleSoldier>();
		for (BattleSoldier soldier : this.soldiersMap.values()) {
			if (!soldier.isDead()) {
				soldiers.add(soldier);
			}
		}
		return soldiers;
	}

	public VideoTeam toVideoTeam() {
		return new VideoTeam(this);
	}

	public boolean isAllDead() {
		for (BattleSoldier soldier : this.soldiersMap.values()) {
			if (!soldier.isDead() && !soldier.isLeave()) {
				return false;
			}
		}
		return true;
	}

	public List<Long> playerIds() {
		return playerIds;
	}

	/**
	 * 获取在战斗中没有逃跑的玩家ID集合
	 *
	 * @return
	 */
	public Set<Long> inBattlePlayerIds() {
		final Set<Long> inBattlePlayerIds = new HashSet<>(playerIds);
		inBattlePlayerIds.removeAll(retreatPlayerIds);
		return inBattlePlayerIds;
	}

	public Collection<BattlePlayerSoldierInfo> playerSoldierInfos() {
		return this.soldierInfosMapByPlayerId.values();
	}

	/**
	 * 移除队伍中队长的全部伙伴
	 */
	@Deprecated
	public void allCrewLeave() {
		for (Iterator<BattleSoldier> it = this.soldiersMap.values().iterator(); it.hasNext();) {
			BattleSoldier soldier = it.next();
			if (soldier.charactorType() == CharactorType.Crew.ordinal()) {
				it.remove();
				this.soldierCount--;
				soldier.setLeave(true);
				soldier.getCurRoundProcessor().getActionQueue().remove(soldier);
				this.formationAdapter.getSoldierIdsFormation()[soldier.getPosition() - 1] = 0;
				if (this.videoTeam != null) {
					for (Iterator<VideoSoldier> it2 = this.videoTeam.getTeamSoldiers().iterator(); it2.hasNext();) {
						VideoSoldier vs = it2.next();
						if (vs.getId() == soldier.getId()) {
							it2.remove();
							break;
						}
					}
				}
			}
		}

	}

	public Set<Long> retreatPlayerIds() {
		return this.retreatPlayerIds;
	}

	public void addRetreatPlayerId(long playerId) {
		this.retreatPlayerIds.add(playerId);
	}

	public Map<Long, BattleSoldier> getCalledMonsters() {
		return calledMonsters;
	}

	public void setCalledMonsters(Map<Long, BattleSoldier> calledMonsters) {
		this.calledMonsters = calledMonsters;
	}

	/**
	 * 队长
	 * 
	 * @return
	 */
	public BattlePlayer leader() {
		return player(this.leaderId);
	}

	public BattlePlayer player(long playerId) {
		return battlePlayers.get(playerId);
	}

	/**
	 * 战斗小队使用的阵型
	 *
	 * @return
	 */
	public Formation formation() {
		return Formation.get(this.formationId);
	}

	/**
	 * 换宠
	 * 
	 * @param newPetCharactor
	 * @return
	 */
	public BattleSoldier switchPet(BattleUnit newPetCharactor) {
		BattlePlayerSoldierInfo info = soldiersByPlayer(newPetCharactor.playerId());
		BattleSoldier oldPet = battleSoldier(info.petSoldierId());
		int position = 0;
		if (oldPet != null) {
			if (oldPet.getId() == newPetCharactor.uid())
				return null;
			position = oldPet.getPosition();
			// 旧宠离开
			oldPet.leaveTeam();
		} else {
			// 找回玩家id所在索引
			int idx = this.playerIds.indexOf(newPetCharactor.playerId());
			// 宠物的位置=该玩家在队列中的位置(>=1)+阵型的最大玩家数量
			position = (idx + 1) + this.formationAdapter.getMaxPlayerSize();
		}
		BattleSoldier newPet = new BattleSoldier(this, newPetCharactor, position);
		if (oldPet != null)
			newPet.setFormationIndex(oldPet.getFormationIndex());
		else
			newPet.setFormationIndex(Formation.PET_FORMATION_EFFECT_ID);
		this.addSoldier(newPet);
		info.setPetSoldierId(newPet.getId());
		// 新宠上阵
		this.formationAdapter.getSoldierIdsFormation()[newPet.getPosition() - 1] = newPet.getId();
		if (this.videoTeam != null)
			this.videoTeam.getTeamSoldiers().add(new VideoSoldier(newPet));
		return newPet;
	}

	/** 队长编号，怪物则为0 */
	public long leaderId() {
		return this.leaderId;
	}

	public boolean playerTeam() {
		return this.leaderId > 0;
	}

	public void setLeaderId(long playerId) {
		this.leaderId = playerId;
	}

	/** 阵形第一个进入战斗单位编号，主要用于替换明雷怪外观和名字 */
	public long firstFromationSoldierId() {
		return this.firstFromationSoldierId;
	}

	public VideoTeam getVideoTeam() {
		return videoTeam;
	}

	public void setVideoTeam(VideoTeam videoTeam) {
		this.videoTeam = videoTeam;
	}

	public Map<Long, BattleSoldier> allSoldiersMap() {
		return this.allSoldiersMap;
	}

	public int getFormationId() {
		return formationId;
	}

	public void setFormationId(int formationId) {
		this.formationId = formationId;
	}

	public float getRetreateReducceRate() {
		return retreateReducceRate;
	}

	public void setRetreateReducceRate(float retreateReducceRate) {
		this.retreateReducceRate = retreateReducceRate;
	}

	public int getId() {
		return id;
	}

	public Collection<BattlePlayer> players() {
		return battlePlayers.values();
	}

	public Collection<BattlePlayer> memberlayers() {
		Collection<BattlePlayer> allMembers = battlePlayers.values();
		List<BattlePlayer> cpAllMembers = new ArrayList<BattlePlayer>();
		for (BattlePlayer battlePlayer : allMembers) {
			if (!battlePlayer.ifTeamLeader()) {
				cpAllMembers.add(battlePlayer);
			}
		}
		return cpAllMembers;
	}

	public boolean isNpcTeam() {
		return isNpcTeam;
	}

	public void setNpcTeam(boolean isNpcTeam) {
		this.isNpcTeam = isNpcTeam;
	}

	public Set<Integer> getTeamBuffIds() {
		return teamBuffIds;
	}

	public void setTeamBuffIds(Set<Integer> teamBuffIds) {
		this.teamBuffIds = teamBuffIds;
	}

	public int getCurrentRoundDeadCount() {
		return currentRoundDeadCount;
	}

	public void setCurrentRoundDeadCount(int currentRoundDeadCount) {
		this.currentRoundDeadCount = currentRoundDeadCount;
	}

	public void increaseRoundDeadCount(int count) {
		this.currentRoundDeadCount += count;
	}

	public Map<Long, Set<Long>> calledSoldiers() {
		return this.calledSoldiers;
	}

	public List<Integer> monsterIds() {
		List<Integer> monsterIds = new ArrayList<Integer>();
		if (this.soldiersMap() != null) {
			for (Iterator<BattleSoldier> iterator = this.soldiersMap().values().iterator(); iterator.hasNext();) {
				BattleSoldier battleSoldier = iterator.next();
				monsterIds.add(battleSoldier.monsterId());
			}
		}
		return monsterIds;
	}

	public void onRetreat(BattleSoldier battleSoldier, Set<Long> retreatSoldierHolder, boolean retreat) {
		callerRetreat(battleSoldier, retreatSoldierHolder, retreat);
		if (!battleSoldier.ifMainCharactor())
			return;
		long playerId = battleSoldier.playerId();
		BattlePlayerSoldierInfo info = this.soldiersByPlayer(playerId);
		if (info != null) {
			BattleSoldier pet = this.battleSoldier(info.petSoldierId());
			if (pet != null) {
				callerRetreat(pet, retreatSoldierHolder, retreat);
			}
		}
		if (this.ifPlayerLeader(playerId)) {
			for (Iterator<BattleSoldier> it = this.soldiersMap.values().iterator(); it.hasNext();) {
				BattleSoldier soldier = it.next();
				if (soldier.charactorType() == CharactorType.Crew.ordinal()) {
					callerRetreat(soldier, retreatSoldierHolder, retreat);
				}
			}
		}
		this.addRetreatPlayerId(playerId);
		this.playerLeave(playerId);
	}

	private void callerRetreat(BattleSoldier caller, Set<Long> retreatSoldierHolder, boolean retreat) {
		retreatSoldierHolder.add(caller.getId());
		Set<Long> calledSoldiers = this.calledSoldiers.get(caller.getId());
		if (calledSoldiers != null && (caller.ifMainCharactor() || retreat)) {// 主角撤退才会带走召唤小怪
			for (Long id : calledSoldiers) {
				BattleSoldier soldier = this.soldiersMap.get(id);
				if (soldier != null) {
					callerRetreat(soldier, retreatSoldierHolder, retreat);
				}
			}
		}
		caller.leaveTeam();
	}

	private void addCalledSoldier(long callerId, long calledSoldierId) {
		Set<Long> called = this.calledSoldiers.get(callerId);
		if (called == null) {
			called = new HashSet<>();
			this.calledSoldiers.put(callerId, called);
		}
		called.add(calledSoldierId);
	}

	public Set<Long> reinforcementSet() {
		return this.reinforcement;
	}
}
