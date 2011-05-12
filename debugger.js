$('#results').append('<div id="detailed_results"></div>');
$('#detailed_results').css('display', 'none');

debug_mode = true;

var game = $('#log')[0];
var detailed_results = [];
var debug_gain_messages = [];
for (var i = 0; i < game.childNodes.length; ++i) {
  var node = game.childNodes[i];
  var turn_change = node.constructor == HTMLElement &&
                    node.innerText.match(/---.*---/);
  if (turn_change) {
    node.innerHTML = node.innerHTML.replace(/[0-9]+ ---/, '---');
  }
  handle(game.childNodes[i]);
  if (turn_change) {
    detailed_results.push(debug_gain_messages);
    debug_gain_messages = '';
    detailed_results.push(stateStrings());

    // Show this turn's information.
    detailed_results.push('<br><i>' + game.childNodes[i].innerText + '</i><br>');
  } else {
    var gains = $('div.gain_debug');
    for (var j = 0; j < gains.length; ++j) {
      gains[j].className = 'gain_details';
      game.insertBefore(gains[j], game.childNodes[i].nextSibling);
      i++;
      debug_gain_messages += gains[j].innerHTML + '<br>';
    }
  }
}
$('#detailed_results').append(detailed_results.join('') + '<br><br>');

$('#results').append(stateStrings());
console.log(players);

$('body').append('<button id="show_details">Show Details</button>');
$('#show_details').click(function () {
  $('#detailed_results').css('display', '');
});
$('body').append('<button id="show_raw_log">Show Raw Logs</button>');
$('#show_raw_log').click(function () {
  $('#log_data').css('display', '');
});

var url = $('#game_link').attr('href')
chrome.extension.sendRequest({ type: "fetch", url: url }, function(response) {
  var data = response.data;
  var arr = data.match(/----------------------([\s\S]*[\S])[\s]*----------------------/);
  $('#results').append("<pre id='actual_score'>" + arr[1] +'</pre>');
  var results = $('#actual_score').text();

  // Ugg. Results have rewritten player names so we don't actually see it.
  // We need to rewrite again here.
  var names = $('#actual_score').children('b');
  for (var i = 0; i < names.length; ++i) {
    var name = names[i].innerText.slice(names[i].innerText.indexOf(" ") + 1);
    results = results.replace(name, rewriteName(name));
  }

  var error_found = false;
  var reporter_name = $('#header').text().match(/Reporter: (.*)/)[1];
  for (var player in players) {
    var score = ("" + players[player].getScore()).replace(/^.*=/, "");
    if (score.indexOf("+") != -1) {
      score = ("" + players[player].getScore()).replace(/^([0-9]+)\+.*/, "$1");
    }
    var player_name = players[player].name;
    if (player_name == "You") {
      player_name = rewriteName(reporter_name);
    }
    var re = new RegExp(RegExp.quote(player_name) + ": ([0-9]+) points", "m");
    var arr = results.match(re);
    if (!arr || arr.length != 2 || arr[1] != score) {
      var error = "Wrong score for " + player_name + " (expected " + score + ")";
      if (!arr || arr.length != 2) {
        error = "Couldn't find score for " + player_name;
      }
      error_found = true;
      $('#header').append("<div id='correct_now'>Error: " + error + ".</div>");
      $('#correct_now').css("color", "red");
      break;
    }
  }
  if (!error_found) {
    $('#header').append("<div id='correct_now'>OK Now!</div>");
    $('#correct_now').css("color", "green");
  }
})
