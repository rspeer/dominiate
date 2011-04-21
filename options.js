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
  setupOption("f", "status_announce");
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
  if (extra_desc != "") {
    extra_desc += '<div style="line-height:6px;">&nbsp;</div>';
  }
  return "<h3>" + option_desc + "</h3>" + extra_desc +
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
                 "",
                 "allow_disable",
                 "Allow disabling.",
                 "Do not allow disabling.") +
  generateOption("Change lobby status to announce you use point counter?" +
                   " <sup><font color='red'>new</font></sup>",
                 "Mandatory if disabling is not allowed.",
                 "status_announce",
                 "Post in status message.",
                 "Do not post in status message.") +
  generateOption("Always display counts / points?",
                 "",
                 "always_display",
                 "Replace exit/faq with scores.",
                 "Only display in chat box from !status command.");

document.body.appendChild(element);
loadOptions();

$('#allow_disable_t').click(function() {
  $('#status_announce_t').attr('disabled', false);
  $('#status_announce_f').attr('disabled', false);
})

$('#allow_disable_f').click(function() {
  localStorage["status_announce"] = "t";
  $('#status_announce_t').attr('checked', true);
  $('#status_announce_t').attr('disabled', true);
})
