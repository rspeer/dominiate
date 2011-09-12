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

  chooseValue: (state, choices, valuefunc) ->
    # Given a game state, a list of possible choices, and a function that
    # returns a *value* for each choice, make the highest-valued choice.
    #
    # The null choice has value 0 when it is available, so negative-valued
    # choices will be avoided.
    bestChoice = null
    bestValue = -Infinity
    for choice in choices
      if choice is null
        value = 0
      else
        value = valuefunc(state, choice)
      if value > bestValue
        bestValue = value
        bestChoice = choice
    if bestChoice is null and null not in choices
      # Either no choices are available, or this AI is being forced
      # to make a decision it's not prepared for.
      return choices[0] ? null
    return bestChoice

  # When an AI is asked to make a choice, it has two ways of doing so that
  # we support: to rank the possible choices in a preference order, or to
  # assign a numerical value to each choice.
  chooseAction: (state, choices) ->
    if this.actionValue?
      this.chooseValue(state, choices, this.actionValue)
    else
      this.choosePriority(state, choices, this.actionPriority)
  chooseTreasure: (state, choices) ->
    if this.treasureValue?
      this.chooseValue(state, choices, this.treasureValue)
    else
      this.choosePriority(state, choices, this.treasurePriority)
  chooseGain: (state, choices) ->
    if this.gainValue?
      this.chooseValue(state, choices, this.gainValue)
    else
      this.choosePriority(state, choices, this.gainPriority)
  chooseDiscard: (state, choices) ->
    if this.discardValue?
      this.chooseValue(state, choices, this.discardValue)
    else
      this.choosePriority(state, choices, this.discardPriority)
  chooseTrash: (state, choices) ->
    if this.trashValue?
      this.chooseValue(state, choices, this.trashValue)
    else
      this.choosePriority(state, choices, this.trashPriority)

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
  
  actionPriority: (state) -> [
    "Menagerie" if state.current.menagerieDraws() == 3
    "Shanty Town" if state.current.shantyTownDraws(true) == 2
    "Trusty Steed"
    "Festival"
    "University"
    "Bazaar"
    "Worker's Village"
    "City"
    "Village"
    "Bag of Gold"
    "Grand Market"
    "Alchemist"
    "Laboratory"
    "Caravan"
    "Fishing Village"
    "Market"
    "Peddler"
    "Great Hall"
    "Smithy" if state.current.actions > 1
    "Conspirator" if state.current.inPlay.length >= 2
    "Pawn"
    "Lighthouse"
    "Warehouse"
    "Menagerie"
    "Tournament"  # should be above cards that might discard a Province
    "Cellar"
    "Shanty Town" if state.current.actions == 1
    "Nobles"
    "Followers"
    "Mountebank"
    "Witch"
    "Goons"
    "Wharf"
    "Militia"
    "Princess"
    "Steward"
    "Bridge"
    "Horse Traders"
    "Coppersmith" if state.current.countInHand("Copper") >= 3
    "Smithy"
    "Council Room"
    "Merchant Ship"
    "Baron" if state.current.countInHand("Estate") >= 1
    "Monument"
    "Adventurer"
    "Harvest"
    "Woodcutter"
    "Coppersmith" if state.current.countInHand("Copper") >= 2
    "Conspirator"
    "Moat"
    "Chapel"
    "Workshop"
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
    "Horn of Plenty" if state.current.numUniqueCardsInPlay() >= 2
  ]
  
  discardPriority: (state) -> [
    "Colony"
    "Province"
    "Duchy"
    "Curse"
    "Estate"
    "Copper"
    null   # this is where discarding-for-benefit should stop
    "Silver"
  ]

  trashPriority: (state) -> [
    "Curse"
    "Estate" if state.gainsToEndGame() > 4
    "Copper" if state.current.getTotalMoney() > 4
    "Potion" if state.current.turnsTaken >= 10
    "Estate" if state.gainsToEndGame() > 2
    null
    "Copper"
    "Potion"
    "Estate"
    "Silver"
  ]

  # The question here is: do you want to discard an Estate for +$4, rather
  # than gain an Estate? And the answer is yes.
  chooseBaronDiscard: (state) -> yes
  
  # When presented with a card with simple but variable benefits, this is
  # the default way for an AI to decide which benefit it wants.
  chooseBenefit: (state, choices) -> 
    buyValue = 1
    cardValue = 2
    coinValue = 3
    trashValue = 4      # if there are cards we want to trash
    actionValue = 10    # if we need more actions
    trashableCards = 0

    actionBalance = state.current.actionBalance()
    usableActions = Math.max(0, -actionBalance)

    # Draw cards if we have a surplus of actions
    if actionBalance >= 1
      cardValue += actionBalance

    # How many cards do we want to trash?
    for card in state.current.hand
      if this.chooseTrash(state, [card, null]) is card
        trashableCards += 1
    
    best = null
    bestValue = -1000
    for choice in choices
      value = cardValue * (choice.cards ? 0)
      value += coinValue * (choice.coins ? 0)
      value += buyValue * (choice.buys ? 0)
      trashes = (choice.trashes ? 0)
      if trashes <= trashableCards
        value += trashValue * trashes
      else
        value -= trashValue * trashes
      value += actionValue * Math.min((choice.actions ? 0), usableActions)
      if value > bestValue
        best = choice
        bestValue = value
    best

  toString: () -> this.name
this.BasicAI = BasicAI
