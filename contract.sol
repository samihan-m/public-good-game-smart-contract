// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract Game {

  // TODO: If it seems like the work is worthwhile, add events/emits for when players request tokens, submit tokens, etc. and for when admin plays round or resets something

  // TODO: Maybe add setters for the 'constant' config values
  
  struct Player {
    address id;
    uint walletTokens;
    uint potTokens;
    bool submitted;
  }
  struct Round {
    mapping(uint => Player) players;
    uint playerCount;
  }

  mapping(uint => Player) players;
  uint playerCount;
  Round[] rounds;
  uint constant STARTING_TOKEN_SUM = 20;
  uint constant MINIMUM_VALID_POT_TOTAL = 20;
  uint constant PROFIT_FACTOR = 14;

  // Reset everything!
  function completelyResetGame() public {
    for(uint i = 0; i < playerCount; i++) {
      delete players[i];
    }
    playerCount = 0;
    delete rounds;
    return;
  }

  // Reset all player finances to default values
  function resetAllPlayerFinances() public {
    for(uint i = 0; i < playerCount; i++) {
      players[i].walletTokens = STARTING_TOKEN_SUM;
      players[i].potTokens = 0;
      players[i].submitted = false;
    }
    return;
  }

  // Return the Player object in players with the same address as the sender
  function getMyPlayer() public view returns (Player memory) {
    return getPlayer(msg.sender);
  }

  // Returns the index of the player with given address id or in players or -1 if they are not there
  function getPlayerIndex(address id) private view returns (int) {
    for (uint i = 0; i < playerCount; i++) {
      if(players[i].id == id) {
        return int(i);
      }
    }
    return -1;
  }

// Return the Player object in players with the same address as the parameter id
  function getPlayer(address id) private view returns (Player memory) {
    int index = getPlayerIndex(id);
    if(index < 0) {
      // There is no player, return a player with a null address to indicate this
      return Player(address(0x0), 0, 0, false);
    }
    return players[uint(index)];
  }

  // Get all of the current player data
  function getCurrentRoundData() public view returns (Player[] memory) {
    Player[] memory playerInfo = new Player[](playerCount);
    for(uint i = 0; i < playerCount; i++) {
      playerInfo[i] = players[i];
    }
    return playerInfo;
  }

  // Get all of the player data from the given round
  function getRoundData(uint roundIndex) public view returns (Player[] memory) {
    // Ensure the given round index is within bounds
    require(roundIndex < rounds.length);
    Round storage round = rounds[roundIndex];
    Player[] memory playerInfo = new Player[](round.playerCount);
    for(uint i = 0; i < round.playerCount; i++) {
      playerInfo[i] = round.players[i];
    }
    return playerInfo;
  }

  /*
  // This is not tested LOL do not use if possible
  function getAllRoundData() public view returns (Player[][] memory) {
    Player[][] memory allPlayerInfo = new Player[][](rounds.length + 1);
    for(uint r = 0; r < rounds.length; r++) {
      Player[] memory playerInfo = getRoundData(r);
      allPlayerInfo[r] = playerInfo;
    }
    allPlayerInfo[rounds.length] = getCurrentRoundData();
    return allPlayerInfo;
  }
  */

  // Get the number of unsubmitted players
  function getUnsubmittedPlayerCount() public view returns (uint) {
    uint count = 0;
    for(uint i = 0; i < playerCount; i++) {
      if(players[i].submitted == false) {
        count++;
      }
    }
    return count;
  }

  // Get the number of initialized players
  function getPlayerCount() public view returns (uint) {
    return playerCount;
  }

  // Public callable wrapper for initPlayer
  function initMyPlayer() public {
    // Ensure player doesn't already exist
    require(getPlayerIndex(msg.sender) == -1);
    return initPlayer(msg.sender);
  }
  
  // Creates a player object and adds it to the players field
  function initPlayer(address id) private {
    // Ensure player doesn't already exist
    require(getPlayerIndex(id) == -1);
    Player memory newPlayer = Player(address(0x0), 0, 0, false);
    newPlayer.id = msg.sender;
    newPlayer.walletTokens = STARTING_TOKEN_SUM;
    players[playerCount] = newPlayer;
    playerCount++;
    return;
  }

  // Checks if can take tokenCount from sender's wallet, and does so if possible
  function addTokensToPot(uint tokenCount) public {
    int _index = getPlayerIndex(msg.sender);
    // Ensure player exists
    require(_index >= 0);
    uint playerIndex = uint(_index);
    // Ensure player has adequate funds
    require(players[playerIndex].walletTokens >= tokenCount);
    // Ensure player hasn't already submitted
    require(players[playerIndex].submitted == false);
    players[playerIndex].walletTokens -= tokenCount;
    players[playerIndex].potTokens += tokenCount;
    players[playerIndex].submitted = true;
    return;
  }

  function getCurrentRoundNumber() public view returns (uint) {
    return (rounds.length + 1);
  }

  // This value * 100% / 10 is what is multiplied to the pot total and divided among players
  function getProfitFactor() public pure returns (uint) {
    return PROFIT_FACTOR;
  }

  function getValidPotMinimum() public pure returns (uint) {
    return MINIMUM_VALID_POT_TOTAL;
  }

  // Check if all players have submitted and play round
  function playRound() public {
    // Ensure there are at least two players
    require(playerCount >= 2);
    // Ensure all players have submitted
    for(uint i = 0; i < playerCount; i++) {
      require(players[i].submitted == true);
    }
    
    // Save this state as a Round object
    Round storage round = rounds.push();
    for(uint i = 0; i < playerCount; i++) {
      round.players[i] = players[i];
    }
    round.playerCount = playerCount;

    // Calculate new token counts for everybody
    uint potTotal = 0;
    for(uint i = 0; i < playerCount; i++) {
      potTotal += players[i].potTokens;
    }
    if(potTotal < MINIMUM_VALID_POT_TOTAL) {
      // Return tokens to everybody
      for(uint i = 0; i < playerCount; i++) {
        players[i].walletTokens += players[i].potTokens;
        players[i].potTokens = 0;
        players[i].submitted = false;
      }
      return;
    }
    // Take pot tokens * 100% * PROFIT_FACTOR and divide equally
    uint revenuePerCapita = (potTotal * PROFIT_FACTOR)/10/playerCount;
    for(uint i = 0; i < playerCount; i++) {
      players[i].potTokens = 0;
      players[i].walletTokens += revenuePerCapita;
      players[i].submitted = false;
    }
    return;
  }
  
}