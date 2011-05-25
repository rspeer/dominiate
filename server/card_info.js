var card_list = require("../card_list").card_list;
var card_info = {};

function parseValue(value) {
  var parsed = parseInt(value);
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
  info.duration = parseValue(card_data.Duration);
  info.actions = parseValue(card_data.Actions);
  info.vp = parseValue(card_data.VP);
  info.cost = parseValue(card_data.Cost);
  info.buys = parseValue(card_data.Buys);
  info.cards = parseValue(card_data.Cards);
  info.trash = parseValue(card_data.Trash);
  card_info[card_data["Singular"]] = info;
}
exports.card_info = card_info;
