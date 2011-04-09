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
