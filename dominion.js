// For players who have spaces in their names, a map from name to name
// rewritten to have underscores instead. Pretty ugly, but it works.
var player_rewrites = new Object();

// Map from player name to Player object.
var players = new Object();

// Places to print number of cards and points.
var deck_spot;
var points_spot;

var started = false;

var last_player = null;
var last_reveal_card = "";

function debugString() {
  return "[Scores: " + JSON.stringify(scores) + "] " +
         "[Cards: " + JSON.stringify(decks) + "]";
}

function pointsForCard(card) {
  if (card == undefined) {
    alert("Undefined card for points...");
    return 0;
  }
  if (card.indexOf("Colony") == 0) return 10;
  if (card.indexOf("Province") == 0) return 6;
  if (card.indexOf("Duchy") == 0) return 3;
  if (card.indexOf("Estate") == 0) return 1;
  if (card.indexOf("Curse") == 0) return -1;

  if (card.indexOf("Island") == 0) return 2;
  if (card.indexOf("Nobles") == 0) return 2;
  if (card.indexOf("Harem") == 0) return 2;
  if (card.indexOf("Great Hall") == 0) return 1;

  return 0;
}

function Player() {
  this.score = 3;
  this.deck_size = 10;

  // Map from special card (such as gardens) to count.
  this.special_cards = new Object();

  this.getScore = function() {
    return this.score;
  }
  this.getDeckSize = function() {
    return this.deck_size;
  }

  this.changeScore = function(points) {
    this.score = this.score + parseInt(points);
  }

  this.gainCard = function(card, count) {
    count = parseInt(count);
    this.deck_size = this.deck_size + count;
    this.changeScore(pointsForCard(card) * count);
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
      var arr = text.match(/--- (.+)'s turn ---/);
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
      player.gainCard(elems[0].innerText, -1);
      player.gainCard(elems[1].innerText, 1);
    } else {
      alert("Replacing your has " + elems.length + " elements: " + text);
    }
    return true;
  }
  return false;
}

function maybeHandleSeaHag(text_arr, text) {
  if (text.indexOf("a Curse on top of") != -1) {
    getPlayer(text_arr[0]).gainCard("Curse", 1);
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
      player.gainCard(card, multiplier * count);
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

  // Remove leading stuff from the text.
  var text = node.innerText.split(" ");
  var i = 0;
  for (i = 0; i < text.length; i++) {
    if (text[i].match(/[A-Za-z0-9]/) != null) break;
  }
  if (i == text.length) return;
  text = text.slice(i);

  if (maybeHandleSwindler(elems, node.innerText)) return;
  if (maybeHandleSeaHag(text, node.innerText)) return;

  if (text[0] == "trashing") {
    return handleGainOrTrash(last_player, elems, node.innerText, -1);
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
  var card = elems[0].innerText;

  var player = getPlayer(text[0]);
  var action = text[1];
  var delta = 0;
  if (action.indexOf("buy") == 0) {
    var count = getCardCount(card, node.innerText);
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
    to_print = to_print + " " + player + "=" + players[player].getDeckSize();
  }
  deck_spot.innerHTML = to_print;
}

function initialize(doc) {
  started = true;
  special_counts = new Object();
  scores = new Object();
  decks = new Object();
  player_rewrites = new Object();

  updateScores();
  updateDeck();

  // Hack: collect player names with spaces in them. We'll rewrite them to
  // underscores and then all the text parsing works as normal.
  var p = "(?:([^,]+),? )";
  var re = new RegExp("Turn order is "+p+"?"+p+"?"+p+"?"+p+"and then (.+).");
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
    players[arr[i]] = new Player();
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

  if (doc.constructor == HTMLElement && doc.parentNode.id == "log" &&
      doc.innerText.indexOf("Turn order") != -1) {
    initialize(doc);
  }

  maybeRewriteName(doc);

  if (started && doc.constructor == HTMLElement && doc.parentNode.id == "log") {
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
