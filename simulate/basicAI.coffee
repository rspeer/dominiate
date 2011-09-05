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

  buyPriority: (state) -> [
    "Colony"
    "Platinum"
    "Province" if state.supply.Colony <= 5
    "Duchy" if state.supply.Province <= 6
    "Gold"
    "Smithy" if state.current.countInDeck("Smithy") == 0
    "Silver"
    "Estate" if state.supply.Province <= 2
  ]

  actionPriority: (state) -> [
    "Smithy"
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
    "Smithy"
    "Gold"
    "Platinum"
  ]

  toString: () -> this.name

this.BasicAI = BasicAI
