// Set the initial status message to the recorded one if we're handling status.
if (localStorage["status_announce"] == "t" &&
    localStorage["status_msg"] != undefined) {
  document.getElementsByName("status")[0].value = localStorage["status_msg"];
}

var inputs = document.getElementsByTagName("input");
for (var input in inputs) {
  if (inputs[input].value == "enter lobby") {
    inputs[input].addEventListener('click', function() {
      localStorage.name = document.getElementsByName("name")[0].value;
      localStorage.status_msg = document.getElementsByName("status")[0].value;
    })
    break;
  }
}
