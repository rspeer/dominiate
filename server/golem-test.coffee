golem = require("./golem")
tests = exports

SUPPLY = {
  "Province": [4,8]
  "Duchy": [3,5]
  "Estate": [2,2]
  "Curse": [3,0]
}

tests['buy one card for 6'] = (test) ->
  choices = golem.buyChoices(SUPPLY, 6, 0, 1)
  choices.sort()
  test.deepEqual choices, [[], ["Curse"], ["Duchy"], ["Estate"]]

  test.done()

tests['buy two cards for 8'] = (test) ->
  choices = golem.buyChoices(SUPPLY, 8, 0, 2)
  choices.sort()
  test.deepEqual choices, [
    []
    ["Curse"]
    ["Curse", "Curse"]
    ["Curse", "Duchy"]
    ["Curse", "Estate"]
    ["Curse", "Province"]
    ["Duchy"]
    ["Estate"]
    ["Estate", "Duchy"]
    ["Estate", "Estate"]
    ["Province"]
  ]

  test.done()

tests['buy out the estates'] = (test) ->
  choices = golem.buyChoices(SUPPLY, 6, 2, 6)
  choices.sort()
  test.deepEqual choices, [
    []
    ["Duchy"]
    ["Estate"]
    ["Estate", "Estate"]
  ]
  test.done()
