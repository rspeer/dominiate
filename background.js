function handleLogRequest(request) {
  console.log("Posting: " + JSON.stringify(request))
  $.post("http://dominion-point-counter.appspot.com/log_game", request);
}

chrome.extension.onRequest.addListener(
function(request, sender, sendResponse) {
  var type = request.type;
  delete request.type;

  if (type == "log") {
    handleLogRequest(request);
  } else {
    console.log("Unknown request type '" + type + "' in: " +
                JSON.stringify(request));
  }
});
