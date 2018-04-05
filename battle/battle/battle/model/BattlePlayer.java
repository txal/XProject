package com.nucleus.logic.core.modules.battle.model;

import java.util.List;

import com.nucleus.commons.message.GeneralResponse;
import com.nucleus.commons.message.TerminalMessage;
import com.nucleus.logic.core.modules.assistskill.model.PersistPlayerAssistSkill;
import com.nucleus.logic.core.modules.assistskill.model.PersistPlayerKongFuSkill;
import com.nucleus.logic.core.modules.assistskill.model.PersistPlayerScenarioSkill;
import com.nucleus.logic.core.modules.athletics.model.PersistPlayerAthletics;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerCharactor;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerChild;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerCrew;
import com.nucleus.logic.core.modules.charactor.model.PersistPlayerPet;
import com.nucleus.logic.core.modules.player.dto.PlayerDto.PlayerTeamStatus;
import com.nucleus.logic.core.modules.player.model.PersistPlayer;
import com.nucleus.logic.core.modules.player.model.PersistPlayerFactionSkills;
import com.nucleus.logic.core.modules.player.model.PersistPlayerFoolChange;
import com.nucleus.logic.core.modules.player.model.PersistPlayerTransform;
import com.nucleus.logic.core.modules.ride.model.PersistPlayerRide;
import com.nucleus.logic.core.modules.scene.model.Scene;
import com.nucleus.logic.core.modules.spell.model.PersistPlayerSpell;
import com.nucleus.outer.Client;
import com.nucleus.player.event.PlayerEvent;

/**
 * 战斗玩家接口定义
 *
 * Created by Tony on 15/7/13.
 */
public interface BattlePlayer extends Client<TerminalMessage, GeneralResponse> {

	long getId();

	boolean ifTeamLeader();

	boolean ifInTeam();

	int getTeamIndex();

	void setTeamIndex(int teamIndex);

	long guildId();

	PersistPlayerCharactor persistPlayerCharactor();

	int getSceneId();

	void setSceneId(int id);

	int getGrade();

	Scene currentScene();

	PersistPlayerAssistSkill persistPlayerAssistSkill();

	List<BattlePlayer> teamBattlePlayers();

	boolean isConnected();

	boolean dispatchEvent(PlayerEvent playerEvent);

	boolean openDoubleExp();

	long celebrationExpiredTime();

	long activityExpBufferTime();

	String nickname();

	PlayerTeamStatus teamStatus();

	void teamStatus(PlayerTeamStatus teamStatus);

	boolean isOffline();

	PersistPlayerSpell persistPlayerSpell();

	PersistPlayerScenarioSkill persistPlayerScenarioSkill();

	PersistPlayerKongFuSkill persistPlayerKongFuSkill();

	PersistPlayer persistPlayer();

	String teamUniqueId();

	void teamUniqueId(String teamUniqueId);

	int charactorId();

	int factionId();

	float getX();

	void setX(float x);

	float getZ();

	void setZ(float z);

	List<PersistPlayerCrew> battleCrews();

	PersistPlayerPet battlePet();

	PersistPlayerPet bonusPet();

	PersistPlayerFactionSkills persistPlayerFactionSkills();

	PersistPlayerTransform persistPlayerTransform();

	PersistPlayerFoolChange persistPlayerFoolChange();

	boolean carryPetFull();

	void carryPetFull(boolean full);

	void battlePet(PersistPlayerPet newPetCharactor);

	void battlePetDefineShout(byte[] defineShout);

	void bonusPet(PersistPlayerPet pet);

	String ip();

	boolean isCommander();

	void setCommander(boolean commander);

	int carryPetAmount();

	void carryPetAmount(int amount);

	void carryPetCapacity(int capacity);

	boolean isAutoBattle();

	void setAutoBattle(boolean autoBattle);

	public void battleEndAt(long battleEndAt);

	public long battleEndAt();

	PersistPlayerRide playerRide();

	public boolean isBro(long playerId);

	public PersistPlayerChild battleChild();

	public void battleChild(PersistPlayerChild ppc);

	PersistPlayerAthletics persistPlayerAthletics();
}
