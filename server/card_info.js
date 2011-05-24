var card_list = require("../card_list").card_list;
var card_map = {};

function parseValue(value) {
  var parsed = parseInt(value);
  if (isNaN(parsed)) return value;
  else return parsed;
}

for (var card_info in card_list) {
  info = {};
  info.isAction = parseValue(card_info.Action);
  info.isVictory = parseValue(card_info.Victory);
  info.isTreasure = (card_info.Treasure === "1");
  info.isAttack = parseValue(card_info.Attack);
  info.isReaction = (card_info.Reaction === "1");
  info.coins = parseValue(card_info.Coins);
  info.duration = parseValue(card_info.Duration);
  info.actions = parseValue(card_info.Actions);
  info.vp = parseValue(card_info.VP);
  info.cost = parseValue(card_info.Cost);
  info.buys = parseValue(card_info.Buys);
  info.cards = parseValue(card_info.Cards);
  info.trash = parseValue(card_info.Trash);
  card_map[card_info["Singular"]] = info;
}
exports.card_map = card_map;
