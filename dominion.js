// For players who have spaces in their names, a map from name to name
// rewritten to have underscores instead. Pretty ugly, but it works.
var player_rewrites = new Object();

// Map from player name to Player object.
var players = new Object();

// Places to print number of cards and points.
var deck_spot;
var points_spot;

var started = false;
var show_action_count = false;

var last_player = null;
var last_reveal_card = null;

// Text writing support.
var input_box = null;
var say_button = null;

// Watchtower support. Ugg.
var last_gain_player = null;
var watch_tower_depth = -1;

function debugString(thing) {
  return JSON.stringify(thing);
}

function writeText(text) {
  if (!input_box || !say_button) {
    alert("Can't write text -- button or input box us unknown.");
    return;
  }
  var old_input_box_value = input_box.value;
  input_box.value = text;
  say_button.click();
  input_box.value = old_input_box_value;
}

function pointsForCard(card_name) {
  if (card_name == undefined) {
    alert("Undefined card for points...");
    return 0;
  }
  if (card_name.indexOf("Colony") == 0) return 10;
  if (card_name.indexOf("Province") == 0) return 6;
  if (card_name.indexOf("Duchy") == 0) return 3;
  if (card_name.indexOf("Estate") == 0) return 1;
  if (card_name.indexOf("Curse") == 0) return -1;

  if (card_name.indexOf("Island") == 0) return 2;
  if (card_name.indexOf("Nobles") == 0) return 2;
  if (card_name.indexOf("Harem") == 0) return 2;
  if (card_name.indexOf("Great Hall") == 0) return 1;

  return 0;
}

function Player(name) {
  this.name = name;
  this.score = 3;
  this.deck_size = 10;

  // Map from special counts (such as number of gardens) to count.
  // TODO(drheld): Should we just track all cards?
  this.special_counts = { "Treasure" : 7, "Victory" : 3 }

  this.getScore = function() {
    var score_str = this.score;
    var total_score = this.score;

    if (typeof this.special_counts["Gardens"] != "undefined") {
      var gardens = this.special_counts["Gardens"];
      var garden_points = Math.floor(this.deck_size / 10);
      score_str = score_str + "+" + gardens + "g@" + garden_points;
      total_score = total_score + gardens * garden_points;
    }

    if (typeof this.special_counts["Duke"] != "undefined") {
      var dukes = this.special_counts["Duke"];
      var duke_points = 0;
      if (typeof this.special_counts["Duchy"] != "undefined") {
        duke_points = this.special_counts["Duchy"];
      }
      score_str = score_str + "+" + dukes + "d@" + duke_points;
      total_score = total_score + dukes * duke_points;
    }

    if (typeof this.special_counts["Vineyard"] != "undefined") {
      var vineyards = this.special_counts["Vineyard"];
      var vineyard_points = 0;
      if (typeof this.special_counts["Actions"] != "undefined") {
        vineyard_points = Math.floor(this.special_counts["Actions"] / 3);
      }
      score_str = score_str + "+" + vineyards + "v@" + vineyard_points;
      total_score = total_score + vineyards * vineyard_points;
    }

    if (total_score != this.score) {
      score_str = score_str + "=" + total_score;
    }
    return score_str;
  }

  this.getDeckString = function() {
    var str = this.deck_size;
    if (show_action_count && this.special_counts["Actions"]) {
      str += "(" + this.special_counts["Actions"] + "a)";
    }
    return str;
  }

  this.changeScore = function(points) {
    this.score = this.score + parseInt(points);
  }

  this.changeSpecialCount = function(name, delta) {
    if (typeof this.special_counts[name] == "undefined") {
      this.special_counts[name] = 0;
    }
    this.special_counts[name] = this.special_counts[name] + delta;
  }

  this.recordSpecialCards = function(card, count) {
    var name = card.innerHTML;
    if (name.indexOf("Gardens") == 0) {
      this.changeSpecialCount("Gardens", count);
    }
    if (name.indexOf("Duke") == 0) {
      this.changeSpecialCount("Duke", count);
    }
    if (name.indexOf("Duchy") == 0 || name.indexOf("Duchies") == 0) {
      this.changeSpecialCount("Duchy", count);
    }
    if (name.indexOf("Vineyard") == 0) {
      this.changeSpecialCount("Vineyard", count);
    }

    var types = card.className.split("-").slice(1);
    for (type_i in types) {
      var type = types[type_i];
      if (type == "none" || type == "duration" ||
          type == "action" || type == "reaction") {
        this.changeSpecialCount("Actions", count);
      } else if (type == "curse") {
        this.changeSpecialCount("Curse", count);
      } else if (type == "victory") {
        this.changeSpecialCount("Victory", count);
      } else if (type == "treasure") {
        this.changeSpecialCount("Treasure", count);
      } else {
        alert("Unknown card class: " + card.className + " for " + card.innerText);
      }
    }
  }

  this.gainCard = function(card, count) {
    last_gain_player = this;
    count = parseInt(count);
    this.deck_size = this.deck_size + count;
    this.changeScore(pointsForCard(card.innerText) * count);
    this.recordSpecialCards(card, count);
  }
}

function getPlayer(name) {
  if (typeof players[name] == "undefined") {
    return null;
  }
  return players[name];
}

function findTrailingPlayer(text) {
  var arr = text.match(/ ([A-Za-z0-9]+)\./);
  if (arr.length == 2) {
    return getPlayer(arr[1]);
  }
  return null;
}

function maybeHandleTurnChange(text) {
  if (text.indexOf("---") != -1) {
    // This must be a turn start.
    if (text.match(/Your turn/) != null) {
      last_player = getPlayer("You");
    } else {
      var arr = text.match(/--- (.+)'s .*turn ---/);
      if (arr != null && arr.length == 2) {
        last_player = getPlayer(arr[1]);
      } else {
        alert("Couldn't handle turn change: " + text);
      }
    }
    return true;
  }
  return false;
}

function maybeHandleWatchTower(text, text_arr) {
  var depth = 0;
  for (var t in text_arr) {
    if (text_arr[t] == "...") ++depth;
  }
  if (depth != watch_tower_depth) watch_tower_depth = -1; 

  if (text.indexOf("revealing a Watchtower") != -1 ||
      text.indexOf("You reveal a Watchtower") != -1) {
    watch_tower_depth = depth;
    return true;
  }
  return false;
}

function maybeReturnToSupply(text) {
  if (text.indexOf("it to the supply") != -1) {
    last_player.gainCard(last_reveal_card, -1);
    return true;
  } else {
    var arr = text.match("([0-9]*) copies to the supply");
    if (arr != null && arr.length == 2) {
      last_player.gainCard(last_reveal_card, -arr[1]);
      return true;
    }
  }
  return false;
}

function maybeHandleTradingPost(elems, text) {
  if (text.indexOf(", gaining a Silver in hand") == -1) {
    return false;
  }
  if (elems.length != 2 && elems.length != 3) {
    alert("Error on trading post: " + text);
    return true;
  }
  var elem = 0;
  last_player.gainCard(elems[0], -1);
  if (elems.length == 3) elem++;
  last_player.gainCard(elems[elem++], -1);
  last_player.gainCard(elems[elem], 1);
  return true;
}

function maybeHandleSwindler(elems, text) {
  var player = null;
  if (text.indexOf("replacing your") != -1) {
    player = getPlayer("You");
  }
  if (text.indexOf("You replace") != -1) {
    var arr = text.match("You replace ([^']*)'");
    if (arr != null && arr.length == 2) {
      player = getPlayer(arr[1]);
    } else {
      alert("Could not split: " + text);
    }
  }

  if (player != null) {
    if (elems.length == 2) {
      player.gainCard(elems[0], -1);
      player.gainCard(elems[1], 1);
    } else {
      alert("Replacing your has " + elems.length + " elements: " + text);
    }
    return true;
  }
  return false;
}

function maybeHandlePirateShip(elems, text_arr, text) {
  // Swallow gaining pirate ship tokens.
  // It looks like gaining a pirate ship otherwise.
  if (text.indexOf("a Pirate Ship token") != -1) return true;

  if (text_arr.length < 4) return false;
  if (getPlayer(text_arr[0]) == null) return false;
  if (text_arr[1].indexOf("trash") != 0) return false;

  var player = null;
  if (text_arr[2] == "your") {
    player = getPlayer("You");
  } else {
    player = getPlayer(text_arr[2].slice(0, -2));
  }

  if (player != null) {
    player.gainCard(elems[0], -1);
    return true;
  }
  return false;
}

function maybeHandleSeaHag(elems, text_arr, text) {
  if (text.indexOf("a Curse on top of") != -1) {
    if (elems.length != 2 || elems[1].innerHTML != "Curse") {
      alert("Weird sea hag: " + text);
      return false;
    }
    getPlayer(text_arr[0]).gainCard(elems[1], 1);
    return true;
  }
  return false;
}

function maybeHandleVp(text) {
  var re = new RegExp("[+]([0-9]+) ▼");
  var arr = text.match(re);
  if (arr != null && arr.length == 2) {
    last_player.changeScore(arr[1]);
  }
}

function getCardCount(card, text) {
  var count = 1;
  var re = new RegExp("([0-9]+) " + card);
  var arr = text.match(re);
  if (arr != null && arr.length == 2) {
    count = arr[1];
  }
  return count;
}

function handleGainOrTrash(player, elems, text, multiplier) {
  for (elem in elems) {
    if (elems[elem].innerText != undefined) {
      var card = elems[elem].innerText;
      var count = getCardCount(card, text);
      player.gainCard(elems[elem], multiplier * count);
    }
  }
}

function handleLogEntry(node) {
  // Gaining VP could happen in combination with other stuff.
  maybeHandleVp(node.innerText);

  elems = node.getElementsByTagName("span");
  if (elems.length == 0) {
    if (maybeHandleTurnChange(node.innerText)) return;
    if (maybeReturnToSupply(node.innerText)) return;
    return;
  }

  var text = node.innerText.split(" ");

  if (maybeHandleWatchTower(node.innerText, text)) return;

  // Remove leading stuff from the text.
  var i = 0;
  for (i = 0; i < text.length; i++) {
    if (text[i].match(/[A-Za-z0-9]/) != null) break;
  }
  if (i == text.length) return;
  text = text.slice(i);

  if (maybeHandleTradingPost(elems, node.innerText)) return;
  if (maybeHandleSwindler(elems, node.innerText)) return;
  if (maybeHandlePirateShip(elems, text, node.innerText)) return;
  if (maybeHandleSeaHag(elems, text, node.innerText)) return;

  if (text[0] == "trashing") {
    var player = last_player;
    if (watch_tower_depth >= 0) player = last_gain_player;
    return handleGainOrTrash(player, elems, node.innerText, -1);
  }
  if (text[1].indexOf("trash") == 0) {
    return handleGainOrTrash(getPlayer(text[0]), elems, node.innerText, -1);
  }
  if (text[0] == "gaining") {
    return handleGainOrTrash(last_player, elems, node.innerText, 1);
  }
  if (text[1].indexOf("gain") == 0) {
    return handleGainOrTrash(getPlayer(text[0]), elems, node.innerText, 1);
  }

  // Expect one element from here on out.
  if (elems.length > 1) return;

  // It's a single card action.
  var card = elems[0];
  var card_text = elems[0].innerText;

  var player = getPlayer(text[0]);
  var action = text[1];
  var delta = 0;
  if (action.indexOf("buy") == 0) {
    var count = getCardCount(card_text, node.innerText);
    player.gainCard(card, count);
  } else if (action.indexOf("pass") == 0) {
    player.gainCard(card, -1);
    var other_player = findTrailingPlayer(node.innerText);
    if (other_player == null) {
      alert("Could not find trailing player from: " + node.innerText);
    } else {
      other_player.gainCard(card, 1);
    }
  } else if (action.indexOf("receive") == 0) {
    player.gainCard(card, 1);
    var other_player = findTrailingPlayer(node.innerText);
    if (other_player == null) {
      alert("Could not find trailing player from: " + node.innerText);
    } else {
      other_player.gainCard(card, -1);
    }
  } else if (action.indexOf("reveal") == 0) {
    last_reveal_card = card;
  }
}

function updateScores() {
  if (points_spot == undefined) return;
  var to_print = "Points: "
  for (var player in players) {
    to_print = to_print + " " + player + "=" + players[player].getScore();
  }
  points_spot.innerHTML = to_print;
}

function updateDeck() {
  if (deck_spot == undefined) return;
  var to_print = "Cards: "
  for (var player in players) {
    to_print = to_print + " " + player + "=" + players[player].getDeckString();
  }
  deck_spot.innerHTML = to_print;
}

function initialize(doc) {
  // Get the fields we need for being able to write text.
  input_box = document.getElementById("entry");
  var blist = document.getElementsByTagName('button');
  for (var button in blist) {
    if (blist[button].innerText == "Say") {
      say_button = blist[button];
      break;
    }
  }

  started = true;
  show_action_count = false;
  players = new Object();
  player_rewrites = new Object();

  updateScores();
  updateDeck();

  // Hack: collect player names with spaces in them. We'll rewrite them to
  // underscores and then all the text parsing works as normal.
  var p = "(?:([^,]+), )";    // an optional player
  var pl = "(?:([^,]+),? )";  // the last player (might not have a comma)
  var re = new RegExp("Turn order is "+p+"?"+p+"?"+p+"?"+pl+"and then (.+).");
  var arr = doc.innerText.match(re);
  if (arr == null) {
    alert("Couldn't parse: " + doc.innerText);
  }
  for (var i = 1; i < arr.length; ++i) {
    if (arr[i] == undefined) continue;
    if (arr[i] == "you") arr[i] = "You";
    if (arr[i].indexOf(" ") != -1) {
      var rewritten = arr[i].replace(/ /g, "_");
      player_rewrites[arr[i]] = rewritten;
      arr[i] = rewritten;
    }
    // Initialize the player.
    players[arr[i]] = new Player(arr[i]);
  }
}

function maybeRewriteName(doc) {
  if (doc.innerHTML != undefined && doc.innerHTML != null) {
    for (player in player_rewrites) {
      doc.innerHTML = doc.innerHTML.replace(player, player_rewrites[player]);
    }
  }
}

function handle(doc) {
  if (doc.constructor == HTMLDivElement &&
      doc.innerText.indexOf("Say") == 0) {
    deck_spot = doc.children[5];
    points_spot = doc.children[6];
  }

  if (doc.parentNode.id == "supply") {
    elems = doc.getElementsByTagName("span");
    for (var elem in elems) {
      if (elems[elem].innerText == "Vineyard") show_action_count = true;
    }
  }

  if (doc.constructor == HTMLElement && doc.parentNode.id == "log" &&
      doc.innerText.indexOf("Turn order") != -1) {
    initialize(doc);
  }

  if (started && doc.constructor == HTMLElement && doc.parentNode.id == "log") {
    maybeRewriteName(doc);
    handleLogEntry(doc);
  }

  if (started) {
    updateScores();
    updateDeck();
  }
}


document.body.addEventListener('DOMNodeInserted', function(ev) {
  handle(ev.target);
});
