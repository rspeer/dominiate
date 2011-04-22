function stateStrings() {
  var state = '';
  for (var player in players) {
    player = players[player];
    state += '<b>' + player.name + "</b>: " +
        player.getScore() + " points [deck size is " +
        player.getDeckString() + "] - " +
        JSON.stringify(player.special_counts) + "<br>";
  }
  return state;
}

$('#results').append('<div id="detailed_results"></div>');
$('#detailed_results').css('display', 'none');

var game = $('#log')[0];
var detailed_results = [];
for (var i = 0; i < game.childNodes.length; ++i) {
  handle(game.childNodes[i]);
  if (game.childNodes[i].constructor == HTMLElement &&
      game.childNodes[i].innerText.match(/---.*---/)) {
    detailed_results.push(stateStrings());
    detailed_results.push('<i>' + game.childNodes[i].innerText + '</i><br>');
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
  $('#results').append('<pre>' + arr[1] +'</pre>');
})
