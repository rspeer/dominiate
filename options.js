function setupOption(default_value, name) {
  var enable = localStorage[name];
  if (enable == undefined) {
    enable = default_value;
  }

	var name_to_select = document.getElementById(name + "_" + enable);
  name_to_select.checked = true
}

function loadOptions() {
  setupOption("f", "allow_disable");
  setupOption("f", "status_announce");
  setupOption("t", "always_display");
  setupOption("t", "game_announce");
}

function generateOptionButton(name, value, desc) {
  var id = name + "_" + value;
  return "<label for='" + id + "'>" +
    "<input type='radio' name='" + name + "' id='" + id + "'" +
        "onclick='saveOption(\"" + name + "\", \"" + value + "\")'>" +
      desc +
    "</label><br>";
}

function generateOption(option_desc, name, yes_desc, no_desc) {
  return "<h3>" + option_desc + "</h3>" +
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
  "	<h1>Dominion Point Counter Options</h1>" +
  generateOption("Allow users to disable point counter with !disable?",
                 "allow_disable",
                 "Allow disabling.",
                 "Do not allow disabling.") +
  generateOption("Announce you use point counter in lobby status message?",
                 "status_announce",
                 "Post in status message.",
                 "Do not post in status message.") + 
  generateOption("Always display counts / points",
                 "always_display",
                 "Replace exit/faq with scores.",
                 "Only display in chat box from !status command.") + 
  generateOption("Display a message showing commands at game start.",
                 "game_announce",
                 "Announce at game start.",
                 "No, I want to use this extension to cheat.");

document.body.appendChild(element);
loadOptions();
