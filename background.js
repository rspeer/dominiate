function getVersion() {
  var version = 'Unknown';
  var xhr = new XMLHttpRequest();
  xhr.open('GET', chrome.extension.getURL('manifest.json'), false);
  xhr.send(null);
  var manifest = JSON.parse(xhr.responseText);
  return manifest.version;
}

function handleLogRequest(request) {
  $.post("http://dominion-point-counter.appspot.com/log_game", request);
}

function handleFetchRequest(request, sendResponse) {
  $.get(request.url, function(response) {
      console.log("response");
    sendResponse({ data: response });
  })
}

chrome.extension.onRequest.addListener(
function(request, sender, sendResponse) {
  var type = request.type;
  delete request.type;

  if (type == "log") {
    handleLogRequest(request);
  } else if (type == "version") {
    sendResponse(getVersion());
  } else if (type == "fetch") {
    handleFetchRequest(request, sendResponse);
  } else {
    console.log("Unknown request type '" + type + "' in: " +
                JSON.stringify(request));
  }
});
