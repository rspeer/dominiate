// For players who have spaces in their names, a map from name to name
// rewritten to have underscores instead. Pretty ugly, but it works.
var player_rewrites = new Object();

// Map from player name to Player object.
var players = new Object();

// Places to print number of cards and points.
var deck_spot;
var points_spot;

var started = false;
var introduced = false;
var i_introduced = false;
var disabled = false;
var had_error = false;
var show_action_count = false;
var possessed_turn = false;

var last_player = null;
var last_reveal_player = null;
var last_reveal_card = null;

// Last time a status message was printed.
var last_status_print = 0;

// Watchtower support. Ugg.
var last_gain_player = null;
var watch_tower_depth = -1;

function debugString(thing) {
  return JSON.stringify(thing);
}

function handleError(text) {
  console.log(text);
  if (!had_error) {
    had_error = true;
    alert("Point counter error. Results may no longer be accurate: " + text);
  }
}

function writeText(text) {
  // Get the fields we need for being able to write text.
  var input_box = document.getElementById("entry");
  var blist = document.getElementsByTagName('button');
  var say_button = null;
  for (var button in blist) {
    if (blist[button].innerText == "Say") {
      say_button = blist[button];
      break;
    }
  }

  if (input_box == null || input_box == undefined || !say_button) {
    handleError("Can't write text -- button or input box is unknown.");
    return;
  }
  var old_input_box_value = input_box.value;
  input_box.value = text;
  say_button.click();
  input_box.value = old_input_box_value;
}

function pointsForCard(card_name) {
  if (card_name == undefined) {
    handleError("Undefined card for points...");
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

    if (this.special_counts["Gardens"] != undefined) {
      var gardens = this.special_counts["Gardens"];
      var garden_points = Math.floor(this.deck_size / 10);
      score_str = score_str + "+" + gardens + "g@" + garden_points;
      total_score = total_score + gardens * garden_points;
    }

    if (this.special_counts["Duke"] != undefined) {
      var dukes = this.special_counts["Duke"];
      var duke_points = 0;
      if (this.special_counts["Duchy"] != undefined) {
        duke_points = this.special_counts["Duchy"];
      }
      score_str = score_str + "+" + dukes + "d@" + duke_points;
      total_score = total_score + dukes * duke_points;
    }

    if (this.special_counts["Vineyard"] != undefined) {
      var vineyards = this.special_counts["Vineyard"];
      var vineyard_points = 0;
      if (this.special_counts["Actions"] != undefined) {
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
    if (this.special_counts[name] == undefined) {
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
        handleError("Unknown card class: " + card.className + " for " + card.innerText);
      }
    }
  }

  this.gainCard = function(card, count) {
    // You can't gain or trash cards while possessed.
    if (possessed_turn && this == last_player) return;

    last_gain_player = this;
    count = parseInt(count);
    this.deck_size = this.deck_size + count;
    this.changeScore(pointsForCard(card.innerText) * count);
    this.recordSpecialCards(card, count);
  }
}

function getPlayer(name) {
  if (players[name] == undefined) return null;
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
    if (text.match(/--- Your (?:extra )?turn/)) {
      last_player = getPlayer("You");
    } else {
      var arr = text.match(/--- (.+)'s .*turn (?:\([^)]*\) )?---/);
      if (arr && arr.length == 2) {
        last_player = getPlayer(arr[1]);
      } else {
        handleError("Couldn't handle turn change: " + text);
      }
    }

    possessed_turn = text.match(/\(possessed by .+\)/);

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
    if (arr && arr.length == 2) {
      last_player.gainCard(last_reveal_card, -arr[1]);
      return true;
    }
  }
  return false;
}

function maybeHandleMint(elems, text) {
  if (elems.length != 1) return false;
  if (text.match("and gain(ing)? another one.")) {
    last_player.gainCard(elems[0], 1);
    return true;
  }
  return false;
}

function maybeHandleTradingPost(elems, text) {
  if (text.indexOf(", gaining a Silver in hand") == -1) {
    return false;
  }
  if (elems.length != 2 && elems.length != 3) {
    handleError("Error on trading post: " + text);
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
    if (arr && arr.length == 2) {
      player = getPlayer(arr[1]);
    } else {
      handleError("Could not split: " + text);
    }
  }

  if (player) {
    if (elems.length == 2) {
      // Note: no need to subtract out the swindled card. That was already
      // handled by maybeHandleOffensiveTrash.
      player.gainCard(elems[1], 1);
    } else {
      handleError("Replacing your has " + elems.length + " elements: " + text);
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
  if (!getPlayer(text_arr[0])) return false;
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
      handleError("Weird sea hag: " + text);
      return false;
    }
    getPlayer(text_arr[0]).gainCard(elems[1], 1);
    return true;
  }
  return false;
}

// This can be triggered by Saboteur and Swindler.
function maybeHandleOffensiveTrash(elems, text_arr, text) {
  if (elems.length == 1) {
    if (text.indexOf("is trashed.") != -1) {
      last_reveal_player.gainCard(elems[0], -1);
      return true;
    }
    if (text.indexOf("and trash it.") != -1 ||
        text.indexOf("and trashes it.") != -1) {
      getPlayer(text_arr[0]).gainCard(elems[0], -1);
      return true;
    }
    return false;
  }
}

function maybeHandleVp(text) {
  var re = new RegExp("[+]([0-9]+) ▼");
  var arr = text.match(re);
  if (arr && arr.length == 2) {
    last_player.changeScore(arr[1]);
  }
}

function getCardCount(card, text) {
  var count = 1;
  var re = new RegExp("([0-9]+) " + card);
  var arr = text.match(re);
  if (arr && arr.length == 2) {
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
  if (maybeHandleTurnChange(node.innerText)) return;

  // Duplicate stuff here. It's printed normally too.
  if (node.className == "possessed") return;

  // Gaining VP could happen in combination with other stuff.
  maybeHandleVp(node.innerText);

  elems = node.getElementsByTagName("span");
  if (elems.length == 0) {
    if (maybeReturnToSupply(node.innerText)) return;
    return;
  }

  var text = node.innerText.split(" ");

  if (maybeHandleWatchTower(node.innerText, text)) return;

  // Remove leading stuff from the text.
  var i = 0;
  for (i = 0; i < text.length; i++) {
    if (!text[i].match(/^[. ]*$/)) break;
  }
  if (i == text.length) return;
  text = text.slice(i);

  if (maybeHandleMint(elems, node.innerText)) return;
  if (maybeHandleTradingPost(elems, node.innerText)) return;
  if (maybeHandleSwindler(elems, node.innerText)) return;
  if (maybeHandlePirateShip(elems, text, node.innerText)) return;
  if (maybeHandleSeaHag(elems, text, node.innerText)) return;
  if (maybeHandleOffensiveTrash(elems, text, node.innerText)) return;

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

  // Mark down if a player reveals cards.
  if (text[1].indexOf("reveal") == 0) {
    last_reveal_player = getPlayer(text[0]);
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
      handleError("Could not find trailing player from: " + node.innerText);
    } else {
      other_player.gainCard(card, 1);
    }
  } else if (action.indexOf("receive") == 0) {
    player.gainCard(card, 1);
    var other_player = findTrailingPlayer(node.innerText);
    if (other_player == null) {
      handleError("Could not find trailing player from: " + node.innerText);
    } else {
      other_player.gainCard(card, -1);
    }
  } else if (action.indexOf("reveal") == 0) {
    last_reveal_card = card;
  }
}

function getScores() {
  var scores = "Points: ";
  for (var player in players) {
    scores = scores + " " + player + "=" + players[player].getScore();
  }
  return scores;
}

function updateScores() {
  if (points_spot == undefined) return;
  points_spot.innerHTML = getScores();
}

function getDecks() {
  var decks = "Cards: ";
  for (var player in players) {
    decks = decks + " " + player + "=" + players[player].getDeckString();
  }
  return decks;
}

function updateDeck() {
  if (deck_spot == undefined) return;
  deck_spot.innerHTML = getDecks();
}

function initialize(doc) {
  started = true;
  introduced = false;
  i_introduced = false;
  disabled = false;
  had_error = false;
  show_action_count = false;
  possessed_turn = false;
  players = new Object();
  player_rewrites = new Object();

  if (localStorage["always_display"] != "f") {
    updateScores();
    updateDeck();
  }

  // Figure out what turn we are. We'll use that to figure out how long to wait
  // before announcing the extension.
  var self_index = -1;

  // Hack: collect player names with spaces and apostrophes in them. We'll
  // rewrite them and then all the text parsing works as normal.
  var p = "(?:([^,]+), )";    // an optional player
  var pl = "(?:([^,]+),? )";  // the last player (might not have a comma)
  var re = new RegExp("Turn order is "+p+"?"+p+"?"+p+"?"+pl+"and then (.+).");
  var arr = doc.innerText.match(re);
  if (arr == null) {
    handleError("Couldn't parse: " + doc.innerText);
  }
  for (var i = 1; i < arr.length; ++i) {
    if (arr[i] == undefined) continue;
    if (arr[i] == "you") {
      self_index = i;
      arr[i] = "You";
    }
    if (arr[i].indexOf(" ") != -1 || arr[i].indexOf("'") != -1) {
      var rewritten = arr[i].replace(/ /g, "_").replace(/'/g, "’");
      player_rewrites[arr[i]] = rewritten;
      arr[i] = rewritten;
    }
    // Initialize the player.
    players[arr[i]] = new Player(arr[i]);
  }

  var wait_time = 200 * Math.floor(Math.random() * 10 + 5);
  if (self_index != -1) {
    wait_time = 200 * self_index;
  }
  setTimeout("maybeIntroducePlugin()", wait_time);
}

function maybeRewriteName(doc) {
  if (doc.innerHTML != undefined && doc.innerHTML != null) {
    for (player in player_rewrites) {
      doc.innerHTML = doc.innerHTML.replace(player, player_rewrites[player]);
    }
  }
}

function maybeIntroducePlugin() {
  if (!introduced) {
    writeText("★ Game scored by Dominion Point Counter ★");
    writeText("http://goo.gl/iDihS");
    writeText("Type !status to see the current score.");
    if (localStorage["allow_disable"] == "t") {
      writeText("Type !disable to disable the point counter.");
    }
  }
}

function maybeShowStatus(request_time) {
  if (last_status_print < request_time) {
    last_status_print = new Date().getTime();
    var to_show = ">> " + getDecks() + " | " + getScores();
    var my_name = localStorage["name"];
    if (my_name == undefined || my_name == null) my_name = "Me";
    writeText(to_show.replace(/You=/g, my_name + "="));
  }
}

function handleChatText(speaker, text) {
  if (!text) return;
  if (disabled) return;
  if (text == " !status") {
    var time = new Date().getTime();
    var command = "maybeShowStatus(" + time + ")";
    var wait_time = 200 * Math.floor(Math.random() * 10 + 1);
    // If we introduced the extension, we get first dibs on answering.
    if (i_introduced) wait_time = 100;
    setTimeout(command, wait_time);
  }
  if (localStorage["allow_disable"] == "t" && text == " !disable") {
    disabled = true;
    deck_spot.innerHTML = "exit";
    points_spot.innerHTML = "faq";
    writeText(">> Point counter disabled.");
  }

  if (text.indexOf(" >> ") == 0) {
    last_status_print = new Date().getTime();
  }
  if (!introduced && text.indexOf(" ★ ") == 0) {
    introduced = true;
    if (speaker == localStorage["name"]) {
      i_introduced = true;
    }
  }
}

function handleGameEnd(doc) {
  for (var node in doc.childNodes) {
    if (doc.childNodes[node].innerText == "game log") {
      // Reset exit / faq at end of game.
      started = false;
      deck_spot.innerHTML = "exit";
      points_spot.innerHTML = "faq";

      // Collect information about the game.
      var href = doc.childNodes[node].href;
      var game_id_str = href.substring(href.lastIndexOf("/") + 1);
      var name = localStorage["name"];
      if (name == undefined || name == null) name = "Unknown";

      // Double check the scores so we can log if there was a bug.
      var has_correct_score = true;
      var win_log = document.getElementsByClassName("em");
      if (win_log && win_log.length == 1) {
        var summary = win_log[0].previousSibling.innerText;
        for (player in players) {
          var player_name = players[player].name;
          if (player_name == "You") player_name = name;
          var re = new RegExp(player_name + " has ([0-9]+) points");
          var arr = summary.match(re);
          if (arr && arr.length == 2) {
            var score = ("" + players[player].getScore()).replace(/^.*=/, "");
            if (arr[1] != score) {
              has_correct_score = false;
              break;
            }
          }
        }
      }

      // Post the game information to app-engine for later use for tests, etc.
      chrome.extension.sendRequest({
          type: "log",
          game_id: game_id_str,
          reporter: name,
          correct_score: has_correct_score,
          log: document.body.innerHTML,
          settings: debugString(localStorage) });
      break;
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

  if (doc.constructor == HTMLElement && doc.parentNode.id == "log") {
    maybeRewriteName(doc);
    handleLogEntry(doc);
  }

  if (doc.constructor == HTMLDivElement && doc.parentNode.id == "choices") {
    handleGameEnd(doc);
  }

  if (doc.parentNode.id == "chat") {
    handleChatText(doc.childNodes[1].innerText.slice(0, -1),
                   doc.childNodes[2].nodeValue);
  }

  if (started && localStorage["always_display"] != "f") {
    if (!disabled) {
      updateScores();
      updateDeck();
    }
  }
}


document.body.addEventListener('DOMNodeInserted', function(ev) {
  handle(ev.target);
});
