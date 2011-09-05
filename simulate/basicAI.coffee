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

  # The default strategy is Big Money Ultimate.

  buyPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.supply.Colony <= 6
    "Duchy" if state.supply.Colony <= 5
    "Estate" if state.supply.Colony <= 2
    "Platinum"
    "Gold"
    "Silver"
  ]

  actionPriority: (state) -> [
  ]
  
  treasurePriority: (state) -> [
    "Platinum"
    "Gold"
    "Silver"
    "Copper"
  ]
  
  discardPriority: (state) -> [
    "Colony"
    "Province"
    "Duchy"
    "Estate"
    "Copper"
    "Silver"
    "Gold"
    "Platinum"
  ]

  toString: () -> this.name

this.BasicAI = BasicAI
