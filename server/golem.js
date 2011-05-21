var exec = require("child_process").exec;

function gainHandler(request, responder, query) {
  responder.fail("Not implemented");
  // Determine the set of available cards / sets of cards.
  //   (Get this from tableau / cost.)
  //
  // For each possibility:
  //   Add those cards to the current hand.
  //   Update VP, card count, etc. accordingly.
  //   Normalize to cards per hand.
  //   Convert to a VW string.
  //
  // Run the file through VW. Sort the results. Do the best thing.
}
exports.gain = gainHandler;

function trashHandler(request, responder, query) {
  responder.fail("Not implemented");
}
exports.trash = trashHandler;
