golem = require("./golem")
card_info = require("./card_info").card_info
tests = exports

SUPPLY = {
  "Province": [4,8]
  "Duchy": [3,5]
  "Estate": [2,2]
  "Curse": [3,0]
}

tests['buy no cards'] = (test) ->
  choices = golem.buyChoices(SUPPLY, 10, 0, 0)
  test.deepEqual choices, [[]]
  test.done()

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

DECK = {
  'Copper': 7
  'Estate': 3       # 3 VP     
  'Silver': 2
  'Gardens': 1      # 1 VP
  'Fairgrounds': 1  # 2 VP
  'Smithy': 2
  'vp': 8           # contains 2 chips
}

tests['card info makes sense'] = (test) ->
  test.equal card_info['Copper'].isAction, false
  test.done()

tests['deck features'] = (test) ->
  features = golem.getDeckFeatures(DECK)
  test.equal features.n, 16
  test.equal features.nUnique, 6
  test.equal features.nActions, 2
  test.equal features.knownvp, 8
  test.equal features.cardvp, 6
  test.equal features.chips, 2
  test.equal features.deck['Copper'], 7
  test.equal features.unique['Copper'], 1
  test.equal features.deck['vp'], undefined
  test.equal features.unique['vp'], undefined
  test.done()
