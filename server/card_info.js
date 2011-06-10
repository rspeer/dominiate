var card_list = require("../card_list").card_list;
var card_info = {};

function parseValue(value) {
  if (value === "P") return 0;
  var parsed = parseInt(value.replace(/P/, ''));
  if (isNaN(parsed)) return value;
  else return parsed;
}

for (var i=0; i<card_list.length; i++) {
  card_data = card_list[i];
  info = {};
  info.isAction = (card_data.Action === "1");
  info.isVictory = (card_data.Victory === "1");
  info.isTreasure = (card_data.Treasure === "1");
  info.isAttack = (card_data.Attack === "1");
  info.isReaction = (card_data.Reaction === "1");
  info.coins = parseValue(card_data.Coins);
  info.potion = card_data.Singular === "Potion" ? 1 : 0;
  info.duration = parseValue(card_data.Duration);
  info.actions = parseValue(card_data.Actions);
  info.vp = parseValue(card_data.VP);
  info.cost = parseValue(card_data.Cost);
  info.potionCost = card_data.Cost.match(/P/) ? 1 : 0;
  info.buys = parseValue(card_data.Buys);
  info.cards = parseValue(card_data.Cards);
  info.trash = parseValue(card_data.Trash);
  card_info[card_data.Singular] = info;
}

function numCopiesPerGame(card, nPlayers) {
  if (card == "Province" && nPlayers >= 5) return 15;
  if (card == "Colony" && nPlayers >= 5) return 15;
  else if (card_info[card].isVictory) {
    if (nPlayers >= 3) return 12;
    else return 8;
  }
  else if (card == "Curse") return 10 * (nPlayers - 1);
  else if (card == "Potion") return 16;
  else if (card == "Platinum") return 12;
  else if (card == "Gold") return 30;
  else if (card == "Silver") return 40;
  else if (card == "Copper") return 60;
  else return 10;
}

// Rough estimates for computing deck statistics
card_info["Bank"].coins = 3;
card_info["Diadem"].coins = 2;
card_info["Tribute"].actions = 2;
card_info["Mint"].trash = 0;
card_info["Philosopher's Stone"].coins = 4;
exports.everySetCards = ["Estate", "Duchy", "Province", "Copper", "Silver", "Gold", "Curse"];
exports.card_info = card_info;
exports.numCopiesPerGame = numCopiesPerGame;
