# utility functions
count = (list, elt) ->
  count = 0
  for member in list
    if member == elt
      count++
  count

stringify = (obj) ->
  if obj is null
    return null
  else
    return obj.toString()

# This class defines a rule-based AI, the kind that is currently popular
# for evaluating Dominion strategies. Subclass it to define new strategies.
class BasicAI
  name: 'BasicAI'

  choosePriority: (state, choices, priorityfunc) ->
    # Given a game state, a list of possible choices, and a function
    # that returns a preference order, make the best choice in that
    # preference order.

    priority = priorityfunc(state)
    bestChoice = null
    bestIndex = null
    for choice in choices
      index = priority.indexOf(stringify(choice))
      if index != -1 and (bestIndex is null or index < bestIndex)
        bestIndex = index
        bestChoice = choice
    if bestChoice is null and null not in choices
      # either no choices are available, or this AI is being forced
      # to make a decision it's not prepared for
      return choices[0] ? null
    return bestChoice

  chooseAction: (state, choices) ->
    this.choosePriority(state, choices, this.actionPriority)
  chooseTreasure: (state, choices) ->
    this.choosePriority(state, choices, this.treasurePriority)
  chooseBuy: (state, choices) ->
    this.choosePriority(state, choices, this.gainPriority)
  chooseGain: (state, choices) ->
    this.choosePriority(state, choices, this.gainPriority)
  chooseDiscard: (state, choices) ->
    this.choosePriority(state, choices, this.discardPriority)

  # The default buying strategy is Big Money Ultimate.
  gainPriority: (state) -> [
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
    "Menagerie" if state.current.menagerieDraws() == 3
    "Shanty Town" if state.current.shantyTownDraws() == 2
    "Festival"
    "Bazaar"
    "Worker's Village"
    "Village"
    "Grand Market"
    "Alchemist"
    "Laboratory"
    "Market"
    "Peddler"
    "Great Hall"
    "Smithy" if state.current.actions > 1
    "Menagerie"
    "Shanty Town" if state.current.actions == 1
    "Militia"
    "Princess"
    "Bridge"
    "Horse Traders"
    "Coppersmith" if state.current.countInHand("Copper") >= 3
    "Smithy"
    "Monument"
    "Woodcutter"
    "Coppersmith" if state.current.countInHand("Copper") >= 2
    "Moat"
    "Coppersmith"
    "Shanty Town"
    null
  ]
  
  treasurePriority: (state) -> [
    "Platinum"
    "Diadem"
    "Philosopher's Stone"
    "Gold"
    "Harem"
    "Silver"
    "Quarry"
    "Copper"
    "Potion"
    "Bank"
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
    "Potion" if state.current.turnsTaken >= 10
    "Estate" if state.gainsToEndGame() > 2
    null
    "Potion"
    "Estate"
    "Silver"
    "Duchy"
    "Gold"
    "Platinum"
    "Province"
    "Colony"
  ]

  toString: () -> this.name

class SillyAI extends BasicAI
  # Plays like BasicAI, except it always buys a card of the highest
  # value it can, at random. Good for simulating newbie play and testing
  # all cases that the simulator might run into.
  name: 'SillyAI'

  gainPriority: (state) -> 
    cards = []
    for card, count of state.supply
      # original cost
      if state.cardInfo[card].cost > 0
        cards.push(card)
    effectiveCost = (card) ->
      [coins, potions] = state.cardInfo[card].getCost(state)
      coins + potions*2 + Math.random()
    cards.sort( (c1, c2) ->
      effectiveCost(c2) - effectiveCost(c1)
    )
    cards

this.BasicAI = BasicAI
this.SillyAI = SillyAI
