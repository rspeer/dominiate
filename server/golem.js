var exec = require("child_process").exec;

function gainHandler(request, responder, query) {
  responder.fail("Not implemented");
}
exports.gain = gainHandler;

function trashHandler(request, responder, query) {
  responder.fail("Not implemented");
}
exports.trash = trashHandler;
