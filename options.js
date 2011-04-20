function setupOption(default_value, name) {
  var enable = localStorage[name];
  if (enable == undefined) {
    enable = default_value;
  }

  var name_to_select = document.getElementById(name + "_" + enable);
  name_to_select.checked = true
}

function loadOptions() {
  setupOption("t", "allow_disable");
  setupOption("t", "always_display");
}

function generateOptionButton(name, value, desc) {
  var id = name + "_" + value;
  return "<label for='" + id + "'>" +
    "<input type='radio' name='" + name + "' id='" + id + "'" +
        "onclick='saveOption(\"" + name + "\", \"" + value + "\")'>" +
      desc +
    "</label><br>";
}

function generateOption(option_desc, extra_desc, name, yes_desc, no_desc) {
  return "<h3>" + option_desc + "</h3>" +
         extra_desc + (extra_desc == "" ? "" : "<br><br>") +
         generateOptionButton(name, "t", yes_desc) +
         generateOptionButton(name, "f", no_desc);
}

var js_element = document.createElement("script");
js_element.id = "pointCounterOptionsJavascript";
js_element.type = "text/javascript";
js_element.innerHTML = "function saveOption(name, value) { localStorage[name] = value; }"
document.body.appendChild(js_element);

var element = document.createElement("div");
element.id = "pointCounterOptions";

element.innerHTML =
  "<h1>Dominion Point Counter Options</h1>" +
  generateOption("Allow opponents to disable point counter with !disable?",
                 "If you don't allow disabling, your status message in the lobby will mention the point counter.",
                 "allow_disable",
                 "Allow disabling.",
                 "Do not allow disabling. Show a status message instead.") +
  generateOption("Always display counts / points?",
                 "",
                 "always_display",
                 "Replace exit/faq with scores.",
                 "Only display in chat box from !status command.");

document.body.appendChild(element);
loadOptions();
