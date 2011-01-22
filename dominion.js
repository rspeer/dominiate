// TODO(drheld): Count duchies / dukes / islands here.
var special_counts = new Object();

var scores = new Object();
var decks = new Object();

var deck_spot;
var points_spot;
var started = false;
var last_player = "";
var last_reveal_card = "";

function DebugString() {
  return "[Scores: " + JSON.stringify(scores) + "] " +
         "[Cards: " + JSON.stringify(decks) + "]";
}

function PointsForCard(card) {
  if (card == undefined) {
    alert("Undefined card for points...");
    return;
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

function GainCard(player, card, count) {
  if (player == null) return;

  if (typeof decks[player] == "undefined") {
    decks[player] = 10;
  }
  if (typeof scores[player] == "undefined") {
    scores[player] = 3;
  }

  scores[player] = scores[player] + PointsForCard(card) * count;
  decks[player] = decks[player] + count;
}

function findTrailingPlayer(text) {
  var arr = text.match(/ ([A-Za-z0-9]+)\./);
  if (arr.length == 2) {
    return arr[1];
  }
  return null;
}

function MaybeHandleTurnChange(text) {
  if (text.indexOf("---") != -1) {
    // This must be a turn start.
    if (text.match(/Your turn/) != null) {
      last_player = "You";
    } else {
      var arr = text.match(/--- (.+)'s turn ---/);
      if (arr != null && arr.length == 2) {
        last_player = arr[1];
      } else {
        alert("Couldn't handle turn change: " + text);
      }
    }
    return true;
  }
  return false;
}

function MaybeReturnToSupply(text) {
  if (text.indexOf("returning it to the supply") != -1) {
    GainCard(last_player, last_reveal_card, -1);
    return true;
  } else {
    var arr = text.match("([0-9]*) copies to the supply");
    if (arr != null && arr.length == 2) {
      GainCard(last_player, last_reveal_card, -arr[1]);
      return true;
    }
  }
  return false;
}

function MaybeHandleSwindler(elems, text) {
  if (text.indexOf("replacing your") != -1) {
    if (elems.length == 2) {
      changeScore("You", -PointsForCard(elems[0].innerText));
      changeScore("You", PointsForCard(elems[1].innerText));
    } else {
      alert("Replacing your has " + elems.length + " elements.");
    }
    return true;
  }
  if (text.indexOf("You replace") != -1) {
    if (elems.length == 2) {
      var arr = text.match("You replace ([^']*)'");
      if (arr != null && arr.length == 2) {
        changeScore(arr[1], -PointsForCard(elems[0].innerText));
        changeScore(arr[1], PointsForCard(elems[1].innerText));
      } else {
        alert("Could not split: " + text);
      }
    } else {
      alert("Replacing your has " + elems.length + " elements.");
    }
    return true;
  }
  return false;
}

function handleLogEntry(node) {
  elems = node.getElementsByTagName("span");
  if (elems.length == 0) {
    if (MaybeHandleTurnChange(node.innerText)) return;
    if (MaybeReturnToSupply(node.innerText)) return;
    return;
  }

  if (MaybeHandleSwindler(elems, node.innerText)) return;

  // Remove leading stuff from the text.
  var text = node.innerText.split(" ");
  var i = 0;
  for (i = 0; i < text.length; i++) {
    if (text[i].match(/[A-Za-z0-9]/) != null) break;
  }
  if (i == text.length) return;
  text = text.slice(i);

  if (text[0] == "trashing" ||  text[1] == "trash") {
    for (elem in elems) {
      if (elems[elem].innerText != undefined) {
        var card = elems[elem].innerText;
        var count = 1;
        var re = new RegExp("([0-9]+) " + card);
        var arr = (node.innerText.match(re));
        if (arr != null && arr.length == 2) {
          count = arr[1];
        }
        GainCard(last_player, card, -count);
      }
    }
    return;
  }

  // Expect one element from here on out.
  if (elems.length > 1) return;

  // It's a single card action.
  var card = elems[0].innerText;

  if (text[0].indexOf("gaining") == 0) {
    GainCard(last_player, card, 1);
    return;
  }

  var player = text[0];
  var action = text[1];
  var delta = 0;
  if (action.indexOf("buy") == 0 || action.indexOf("gain") == 0) {
    GainCard(player, card, 1);
  } else if (action.indexOf("pass") == 0) {
    GainCard(player, card, -1);
    var other_player = findTrailingPlayer(node.innerText);
    GainCard(other_player, card, 1);
  } else if (action.indexOf("receive") == 0) {
    GainCard(player, card, 1);
    var other_player = findTrailingPlayer(node.innerText);
    GainCard(other_player, card, -1);
  } else if (action.indexOf("reveal") == 0) {
    last_reveal_card = card;
  }
}

function UpdateScores() {
  if (points_spot == undefined) return;
  var print_scores = "Points: "
  for (var score in scores) {
    print_scores = print_scores + " " + score + "=" + scores[score];
  }
  points_spot.innerHTML = print_scores;
}

function UpdateDeck() {
  if (deck_spot == undefined) return;
  var print_deck = "Cards: "
  for (var deck in decks) {
    print_deck = print_deck + " " + deck + "=" + decks[deck];
  }
  deck_spot.innerHTML = print_deck;
}

function initialize() {
  started = true;
  special_counts = new Object();
  scores = new Object();
  decks = new Object();

  UpdateScores();
  UpdateDeck();
}

function handle(doc) {
  if (doc.constructor == HTMLDivElement &&
      doc.innerText.indexOf("Say") == 0) {
    initialize();
    deck_spot = doc.children[5];
    points_spot = doc.children[6];
  }

  if (doc.constructor == HTMLElement && doc.parentNode.id == "log" &&
      doc.innerText.indexOf("Turn order") != -1) {
    initialize();
  }

  if (started && doc.constructor == HTMLElement && doc.parentNode.id == "log") {
    handleLogEntry(doc);
  }

  if (started) {
    UpdateScores();
    UpdateDeck();
  }
}


document.body.addEventListener('DOMNodeInserted', function(ev) {
  handle(ev.target);
});
