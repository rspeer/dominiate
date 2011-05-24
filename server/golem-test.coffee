golem = require("golem")

SUPPLY = {
  "Province": [4,8]
  "Duchy": [3,5]
  "Estate": [2,2]
}

exports['buy one card for 6'] = (test) ->
  test.equal buyChoices(SUPPLY, 6, 0, 1) [[], ["Duchy"], ["Estate"]]

