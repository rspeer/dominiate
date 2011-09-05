count = (list, elt) ->
  count = 0
  for member in list
    if member == elt
      count += 1
  count

class BasicAI
  name: 'BasicAI'
  choosePriority: (state, choices, priorityfunc) ->
    priority = priorityfunc(state)
    bestChoice = null
    bestIndex = null
    for choice in choices
      index = priority.indexOf(choice.toString())
      if index != -1 and (bestIndex is null or index < bestIndex)
        bestIndex = index
        bestChoice = choice
    return bestChoice

  chooseAction: (state, choices) ->
    this.choosePriority(state, choices, this.actionPriority)
  chooseTreasure: (state, choices) ->
    this.choosePriority(state, choices, this.treasurePriority)
  chooseBuy: (state, choices) ->
    this.choosePriority(state, choices, this.buyPriority)
  chooseDiscard: (state, choices) ->
    this.choosePriority(state, choices, this.discardPriority)

  # The default buying strategy is Big Money Ultimate.
  buyPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
    null
  ]
  
  # TODO: expand this to cover all defined actions
  actionPriority: (state) -> [
    "Festival"
    "Village"
    "Laboratory"
    "Smithy"
    null
  ]
  
  treasurePriority: (state) -> [
    "Platinum"
    "Gold"
    "Harem"
    "Silver"
    "Quarry"
    "Copper"
    "Potion"
  ]
  
  discardPriority: (state) -> [
    "Colony"
    "Province"
    "Duchy"
    "Estate"
    "Copper"
    null   # this is where discarding-for-benefit should stop
    "Silver"
    "Gold"
    "Platinum"
  ]

  trashPriority: (state) -> [
    "Curse"
    "Estate" if state.gainsToEndGame() > 4
    "Copper"
    "Estate" if state.gainsToEndGame() > 2
    null
    "Estate"
    "Silver"
    "Duchy"
    "Gold"
    "Platinum"
    "Province"
    "Colony"
  ]

  toString: () -> this.name

this.BasicAI = BasicAI
