# The Basic AI
# ------------
# This class defines a rule-based AI of the kind that is popular
# for evaluating Dominion strategies. It can be subclassed -- or simply
# have its methods overwritten on an instance -- to play new strategies.
#
# Every time the player needs to make a meaningful decision, a method called
# `chooseX` (for some X) will be called on the AI, which can examine the game
# state and make a decision accordingly.
#
# In any case that is not a simple yes/no decision, the method will be 
# given a list of choices. It will delegate to the `xValue` method to assign a
# value to each possible choice, and choose the one with the highest value
# (earlier options win ties).
#
# If the `xValue` method does not exist (as will often be the case), it will
# try a different method called `xPriority`, which takes in the state and
# returns an ordered list of choices. The player will make the first valid
# choice in that list. Priority functions are usually easier to define than
# value functions.
#
# The BasicAI has a default decision function for every decision, so
# every AI that derives from it will have *some* way to decide what to do in
# any situation. However, when defining an AI, you will often want to override
# some of these decision functions.
class BasicAI
  name: 'Basic AI'
  author: 'rspeer'

  # Referring to `state.current` to find information about one's own state is
  # not always safe! Some of these decisions may be made during other players'
  # turns. In those cases, what we want is `this.myPlayer(state)`.
  #
  # This is passed in as an argument `my` to the decision functions, because
  # it's convenient and it creates nice idioms such as `my.hand`.
  myPlayer: (state) ->
    for player in state.players
      if player.ai is this
        return player
    throw new Error("#{this} is being asked to make a decision, but isn't playing the game...?")

  # Given a game state, a list of possible choices, and a function
  # that returns a preference order, make the best choice in that
  # preference order.
  choosePriority: (state, choices, priorityfunc) ->
    my = this.myPlayer(state)
    priority = priorityfunc(state, my)
    bestChoice = null
    bestIndex = null
    for choice in choices
      index = priority.indexOf(stringify(choice))
      if index != -1 and (bestIndex is null or index < bestIndex)
        bestIndex = index
        bestChoice = choice
    if bestChoice is null and null not in choices
      # The AI chose `null` when it wasn't in the list of choices.
      # That means either no choices are available, or this AI is being
      # forced to make a decision it's not prepared for.
      #
      # In that case, if there are any choices, it will arbitrarily choose
      # the first one. If there are no choices, then choosing nothing becomes
      # the one legal choice, so it chooses that.
      return choices[0] ? null
    return bestChoice

  # Given a game state, a list of possible choices, and a function that
  # returns a *value* for each choice, make the highest-valued choice.
  #
  # The null choice has value 0 when it is available, so negative-valued
  # choices will be avoided.
  chooseValue: (state, choices, valuefunc) ->
    my = this.myPlayer(state)
    bestChoice = null
    bestValue = -Infinity
    for choice in choices
      if choice is null
        value = 0
      else
        value = valuefunc(state, choice, my)
      if value > bestValue
        bestValue = value
        bestChoice = choice
    if bestChoice is null and null not in choices
      # This should only happen when there are no choices, but to be sure,
      # we check if there is a `choices[0]` and choose it if so.
      return choices[0] ? null
    return bestChoice
  
  # Decisions
  # ---------
  #### Common decisions
  # 
  # These are decisions each AI has to make on most turns.
  #
  # These delegate to the `...Value` or `...Priority` functions, as described.
  # You could override these functions directly, but that will probably make
  # your AI code unnecessarily complicated.
  #
  # `chooseAction`: choose an action card from the hand to play.
  chooseAction: (state, choices) ->
    if this.actionValue?
      this.chooseValue(state, choices, this.actionValue)
    else
      this.choosePriority(state, choices, this.actionPriority)
  
  # `chooseTreasure`: choose a treasure card from the hand to play.
  chooseTreasure: (state, choices) ->
    if this.treasureValue?
      this.chooseValue(state, choices, this.treasureValue)
    else
      this.choosePriority(state, choices, this.treasurePriority)
  
  # `chooseGain`: choose a card to gain (possibly in the buy phase, or possibly
  # as a card effect). The AI is allowed to assume it is the current player,
  # so this can't be used for Saboteur.
  chooseGain: (state, choices) ->
    if this.gainValue?
      this.chooseValue(state, choices, this.gainValue)
    else
      this.choosePriority(state, choices, this.gainPriority)

  # `chooseDiscard`: choose a card to discard. Discards that are ranked 
  # higher than `null` will be discarded voluntarily on cards such as Cellar.
  chooseDiscard: (state, choices) ->
    if this.discardValue?
      this.chooseValue(state, choices, this.discardValue)
    else
      this.choosePriority(state, choices, this.discardPriority)
  
  # `chooseTrash`: choose a card to trash (for no further effect).
  chooseTrash: (state, choices) ->
    if this.trashValue?
      this.chooseValue(state, choices, this.trashValue)
    else
      this.choosePriority(state, choices, this.trashPriority)

  #### Decisions for specific action cards
  #
  # `chooseAmbassador` chooses from a list of two-item arrays of
  # [card, quantity], selecting the card to ambassador and the number to
  # return to the supply.
  chooseAmbassador: (state, choices) ->
    if this.ambassadorValue?
      this.chooseValue(state, choices, this.ambassadorValue)
    else
      this.choosePriority(state, choices, this.ambassadorPriority)

  # The question `chooseBaronDiscard` asks is: do you want to discard an
  # Estate for +$4, rather than gain an Estate? And the answer is almost
  # certainly yes.
  #
  # An AI can replace this function directly to make a different
  # decision.
  chooseBaronDiscard: (state) -> yes

  # Default strategies
  # ------------------
  # The default buying strategy is a form of Big Money that has, by now,
  # been beaten by the newer one in BigMoney.coffee.
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
    null
  ]
  
  # The default action-playing strategy, which aims to include a usable plan
  # for playing every action card, so that most AIs don't need to override it.
  actionPriority: (state, my) -> [
    # First priority: cards that succeed if we play them now, and might
    # not if we play them later.
    "Menagerie" if my.menagerieDraws() == 3
    "Shanty Town" if my.shantyTownDraws(true) == 2
    "Tournament" if my.countInHand("Province") > 0
    # Second priority: cards that give +2 actions.
    "Trusty Steed"
    "Festival"
    "University"
    "Farming Village"
    "Bazaar"
    "Worker's Village"
    "City"
    "Walled Village"
    "Fishing Village"
    "Village"
    # Third priority: cards that give +1 action and are almost always good.
    "Bag of Gold"
    "Grand Market"
    "Hunting Party"
    "Alchemist"
    "Laboratory"
    "Caravan"
    "Market"
    "Peddler"
    "Great Hall"
    "Conspirator" if my.inPlay.length >= 2
    # Fourth priority: terminal card-drawers, if we have actions to spare.
    "Smithy" if my.actions > 1
    "Familiar" # after other non-terminals in case non-terminal draws KC/TR
    "Lighthouse"
    "Pawn"
    # Fifth priority: cards that can fix a bad hand.
    "Warehouse"
    "Cellar"
    # Sixth priority: non-terminal cards that don't succeed but at least
    # give us something.
    "Menagerie"
    "Tournament"  # should be above cards that might discard a Province
    "Shanty Town" if my.actions == 1
    # Seventh priority: terminals. Of course, Nobles might be a non-terminal
    # if we decide we need the actions more than the cards.
    "Nobles"
    "Treasure Map" if my.countInHand("Treasure Map") >= 2
    "Followers"
    "Mountebank"
    "Witch"
    "Sea Hag"
    "Tribute" # after Cursers but before other terminals, there is probably a better spot for it
    "Goons"
    "Wharf"
    "Militia"
    "Princess"
    "Explorer" if my.countInHand("Province") >= 1
    "Steward"
    "Moneylender" if my.countInHand("Copper") >= 1
    "Bridge"
    "Horse Traders"
    "Coppersmith" if my.countInHand("Copper") >= 3
    "Smithy"
    "Council Room"
    "Merchant Ship"
    "Baron" if my.countInHand("Estate") >= 1
    "Monument"
    "Adventurer"
    "Harvest"
    "Explorer"
    "Woodcutter"
    "Coppersmith" if my.countInHand("Copper") >= 2
    "Conspirator"
    # Play an Ambassador if our hand has something we'd want to discard.
    #
    # Here the AI has to refer to itself indirectly, as `my.ai`. `this`
    # actually has the wrong value right now because JavaScript is weird.
    "Ambassador" if my.ai.wantsToTrash(state)
    "Chapel" if my.ai.wantsToTrash(state)
    "Trade Route" if my.ai.wantsToTrash(state)
    "Moat"
    "Ironworks" # should have higher priority if condition can see it will gain an Action card
    "Workshop"
    "Coppersmith"
    # Eighth priority: cards that have become useless. Maybe they'll decrease
    # the cost of Peddler or something.
    "Treasure Map" if my.countInDeck("Gold") >= 4 and state.current.countInDeck("Treasure Map") == 1
    "Shanty Town"
    "Chapel"
    # At this point, we take no action if that choice is available.
    null
    # Nope, something is forcing us to take an action.
    #
    # Last priority: cards that are actively harmful to play at this point,
    # in order of increasing badness.
    "Trade Route"
    "Treasure Map"
    "Ambassador"
  ]
  
  # Most of the order of `treasurePriority` has no effect on gameplay. The
  # important part is that Bank and Horn of Plenty are last.
  treasurePriority: (state, my) -> [
    "Platinum"
    "Diadem"
    "Philosopher's Stone"
    "Gold"
    "Harem"
    "Venture"
    "Silver"
    "Quarry"
    "Copper"
    "Potion"
    "Bank"
    "Horn of Plenty" if my.numUniqueCardsInPlay() >= 2
    null
  ]
  
  # The default `discardPriority` is tuned for Big Money where the decisions
  # are obvious. But many strategies would probably prefer a different
  # priority list, especially one that knows about action cards.
  #
  # It doesn't understand
  # discarding cards to make Shanty Town or Menagerie work, for example, and
  # It doesn't recognize when dead terminal actions would be good to discard.
  # Defining that may require a `discardValue` function.
  discardPriority: (state, my) -> [
    "Vineyard"
    "Colony"
    "Duchy"
    "Gardens"
    "Province"  # Provinces are occasionally useful in hand
    "Curse"
    "Estate"
    "Copper"
    # The above cards are the only ones that will be discarded in Cellar.
    null
    # At this point, we're being forced to discard. Hopefully we can discard
    # a Silver...
    "Silver"
    # Nope. We've got other cards and the strategy hasn't dealt with how to
    # discard them. Pick the first option and hope.
  ]
  
  # Like the `discardPriority`, the default `trashPriority` is sufficient for
  # Big Money but won't be able to handle tough decisions for other
  # strategies.
  trashPriority: (state, my) -> [
    "Curse"
    "Estate" if state.gainsToEndGame() > 4
    "Copper" if my.getTotalMoney() > 4
    "Potion" if my.turnsTaken >= 10
    "Estate" if state.gainsToEndGame() > 2
    null
    "Copper"
    "Potion"
    "Estate"
    "Silver"
  ]

  # When presented with a card with simple but variable benefits, such as
  # Nobles, this is the default way for an AI to decide which benefit it wants.
  # This function should actually handle a number of common situations.
  chooseBenefit: (state, choices) ->
    my = this.myPlayer(state)
    buyValue = 1
    cardValue = 2
    coinValue = 3
    trashValue = 4      # if there are cards we want to trash
    actionValue = 10    # if we need more actions
    trashableCards = 0

    actionBalance = my.actionBalance()
    usableActions = Math.max(0, -actionBalance)

    # Draw cards if we have a surplus of actions
    if actionBalance >= 1
      cardValue += actionBalance

    # How many cards do we want to trash?
    for card in my.hand
      if this.chooseTrash(state, [card, null]) is card
        trashableCards += 1
    
    best = null
    bestValue = -1000
    for choice in choices
      value = cardValue * (choice.cards ? 0)
      value += coinValue * (choice.coins ? 0)
      value += buyValue * (choice.buys ? 0)
      trashes = (choice.trashes ? 0)
      if trashes <= this.wantsToTrash(state)
        value += trashValue * trashes
      else
        value -= trashValue * trashes
      value += actionValue * Math.min((choice.actions ? 0), usableActions)
      if value > bestValue
        best = choice
        bestValue = value
    best
  
  # `ambassadorPriority` chooses a card to Ambassador and how many of it to
  # return.
  #
  # These choices may look odd: remember that choices are evaluated as strings.
  # So if we return lists, they won't match any of the choices. We need to
  # return their joined string versions.
  #
  # This is a moderately acceptable way to deal with the fact that, in
  # JavaScript, lists are never "equal" to other lists anyway.
  ambassadorPriority: (state, my) ->
    [
      "Curse,2"
      "Curse,1"
      "Curse,0"
      "Estate,2"
      "Estate,1"
      # Make sure we have at least $5 in the deck, including if we buy a Silver.
      "Copper,2" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 5
      "Copper,2" if my.getTreasureInHand() >= 5
      "Copper,2" if my.getTreasureInHand() == 3 and my.getTotalMoney() >= 7
      "Copper,1" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 4
      "Copper,1" if my.getTreasureInHand() >= 4
      "Estate,0"
      "Copper,0"
    ]

  #### Informational methods
  #
  # `wantsToTrash` returns the number of cards in hand that we would trash
  # for no benefit.
  wantsToTrash: (state) ->
    my = this.myPlayer(state)
    trashableCards = 0
    for card in my.hand
      if this.chooseTrash(state, [card, null]) is card
        trashableCards += 1
    return trashableCards
  
  #### Utility methods
  #
  # `copy` makes a copy of the AI. It will have the same behavior but a
  # different name, and will not be equal to this AI.
  copy: () ->
    ai = new BasicAI()
    for key, value of this
      ai[key] = value
    ai.name = this.name+'*'
    ai

  toString: () -> this.name
this.BasicAI = BasicAI

# Utility functions
# -----------------
# `count` counts the number of times `elt` appears in `list`.
count = (list, elt) ->
  count = 0
  for member in list
    if member == elt
      count++
  count

# `stringify` turns an object into a string, while handling `null` safely.
stringify = (obj) ->
  if obj is null
    return null
  else
    return obj.toString()

