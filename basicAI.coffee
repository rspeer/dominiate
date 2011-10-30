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
  
  # used for not calling actionPriority to often when result would not change
  # for caching, use chacheActionPriority(state, my)
  # use cachedActionPriority(state, my) to obtain cache
  @cachedAP = []
  
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

  # Decision-making machinery
  # -------------------------
  # Make the AI's preferred choice, first by checking its explicit priority
  # list. If no valid choices are on the list, ask the value function instead.
  #
  # The priority function returns an ordered list of choices it will want to
  # make when they are available. If 'null' is on the priority list, that
  # represents an explicit preference to choose "none of the above" when it's
  # an option.
  #
  # The value list assigns a numerical value to every possible choice. 'null'
  # automatically has a value of 0. Here you can represent actions you will
  # only take when forced to, by giving them negative values.
  #
  # If a choice should be made entirely using the value function, make the
  # priority function return an empty list.
  #
  # This function replaces two older functions called `choosePriority` and
  # `chooseValue`.
  chooseByPriorityAndValue: (state, choices, priorityfunc, valuefunc) ->
    my = this.myPlayer(state)
    
    # Are there no choices? We follow the rule that makes the null choice
    # available in that situation, and choose it.
    if choices.length == 0
      return null

    # First, try the priority function. If the priority function reaches
    # the end of its list, it is treated as "none of the above".
    if priorityfunc?
      # Construct an object with the choices as keys, so we can look them
      # up quickly.
      choiceSet = {}
      for choice in choices
        choiceSet[choice] = choice
      
      # Get the priority list.
      priority = priorityfunc.bind(this)(state, my)
      # Now look up all the preferences in that list. The moment we encounter
      # a valid choice, we can return it.
      for preference in priority
        if preference is null and null in choices
          return null
        if choiceSet[preference]?
          return choiceSet[preference]
  
    # The priority list doesn't want any of these choices (perhaps because
    # it doesn't exist). Now try the value list.
    if valuefunc?
      bestChoice = null
      bestValue = -Infinity
    
      for choice in choices
        if (choice is null) or (choice is no)
          value = 0
        else
          value = valuefunc.bind(this)(state, choice, my)
        if value > bestValue
          bestValue = value
          bestChoice = choice
      
      # If we got a valid choice, return it.
      if bestChoice in choices
        return bestChoice
    
    # If we get here, the AI probably wants to choose none of the above.
    if null in choices
      return null
    
    # Hmm. None of the above isn't an option, and neither the priority list nor
    # the value list gave us anything. First complain about it, then make an
    # arbitrary choice.
    state.warn("#{this} has no idea what to choose from #{choices}")
    return choices[0]
  
  # Sometimes we need to compare choices in a strictly numeric way. This takes
  # a particular choice for a particular choice type, and gets its numeric value.
  # If the value comes from a priority list, it will be 1000 - (index in list).
  #
  # So, for example, the default choiceToValue of discarding a Colony is 999, while
  # the choiceToValue of discarding an extra terminal is 1.
  choiceToValue: (type, state, choice) ->
    return 0 if choice is null
    my = this.myPlayer(state)
    priorityfunc = this[type+'Priority']
    valuefunc = this[type+'Value']
    if priorityfunc?
      priority = priorityfunc.bind(this)(state, my)
    else
      priority = []

    index = priority.indexOf(stringify(choice))
    if index != -1
      return (priority.length - index) * 100
    else if valuefunc?
      return valuefunc.bind(this)(state, choice, my)
    else
      return 0
 
  # The top-level "choose" function takes a decision type, the current state,
  # and a list of choices. It delegates to other functions with the appropriate
  # names automatically: for example, if the type is 'foo', the AI will check
  # its fooValue and fooPriority functions.
  choose: (type, state, choices) ->
    # Get the priority and value functions. If one doesn't exist, that's okay,
    # we'll pass on the 'undefined' value and chooseByPriorityAndValue will
    # know what to do.
    priorityfunc = this[type+'Priority']
    valuefunc = this[type+'Value']
    this.chooseByPriorityAndValue(state, choices, priorityfunc, valuefunc)
  
  #### Backwards-compatible choices
  # 
  # To avoid having to rewrite all the code at once, we support these functions
  # that pass `chooseAction` onto `choose('action')`, and so on.
  chooseAction: (state, choices) -> this.choose('action', state, choices)
  chooseTreasure: (state, choices) -> this.choose('treasure', state, choices)
  chooseGain: (state, choices) -> this.choose('gain', state, choices)
  chooseDiscard: (state, choices) -> this.choose('discard', state, choices)
  chooseTrash: (state, choices) -> this.choose('trash', state, choices)

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
  ]
  
  # The default action-playing strategy, which aims to include a usable plan
  # for playing every action card, so that most AIs don't need to override it.
  actionPriority: (state, my, skipMultipliers = false) -> 
    wantsToTrash = this.wantsToTrash(state)
    countInHandCopper = my.countInHand("Copper")
    currentAction = my.getCurrentAction()
    multiplier = 1
    if currentAction?.isMultiplier
      multiplier = currentAction.multiplier
    
    wantsToPlayMultiplier = false
    unless skipMultipliers
      mults = (card for card in my.hand when card.isMultiplier)
      if mults.length > 0
        # We've got a multiplier in hand. Figure out if we want to play it.
        mult = mults[0]
        choices = my.hand.slice(0)
        choices.remove(mult)
        if choices.length > 1
          choices.push("wait")
        choices.push(null)
        choice = this.choose('multipliedAction', state, choices)
        if choice != "wait"
          wantsToPlayMultiplier = true

    # Priority 1: cards that succeed if we play them now, and might
    # not if we play them later.
    ["Menagerie" if my.menagerieDraws() == 3
    "Shanty Town" if my.shantyTownDraws(true) == 2
    "Tournament" if my.countInHand("Province") > 0
    
    # 2: Multipliers that do something sufficiently cool.
    "Throne Room" if wantsToPlayMultiplier
    "King's Court" if wantsToPlayMultiplier

    # 3: cards that stack the deck.
    "Lookout" if state.gainsToEndGame() >= 5 or state.cardInfo.Curse in my.draw
    "Bag of Gold"
    "Apothecary"
    "Scout"
    "Spy"

    # 4: cards that give +2 actions.
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
    "Border Village"

    # 5: cards that give +1 action and are almost always good.
    "Grand Market"
    "Hunting Party"
    "Alchemist"
    "Laboratory"
    "Caravan"
    "Market"
    "Peddler"
    "Treasury"
    "Conspirator" if my.inPlay.length >= 2 or multiplier > 1
    "Familiar"
    "Highway"
    "Wishing Well"
    "Great Hall" if state.cardInfo.Crossroads not in my.hand
    "Stables" if this.choose('stablesDiscard', state, my.hand.concat([null]))
    "Lighthouse"
    "Haven"

    # 6: terminal card-drawers, if we have actions to spare.
    "Library" if my.actions > 1 and my.hand.length <= 4
    "Torturer" if my.actions > 1
    "Margrave" if my.actions > 1
    "Rabble" if my.actions > 1
    "Smithy" if my.actions > 1
    "Embassy" if my.actions > 1
    "Watchtower" if my.actions > 1 and my.hand.length <= 4
    "Library" if my.actions > 1 and my.hand.length <= 5
    "Courtyard" if my.actions > 1 and (my.discard.length + my.draw.length) <= 3

    # 7: Let's insert here an overly simplistic idea of how to play Crossroads.
    # Or if we don't have a Crossroads, play a Great Hall that we might otherwise
    # have played in priority level 5.
    "Crossroads" unless my.crossroadsPlayed
    "Great Hall"

    # 8: card-cycling that might improve the hand.
    "Upgrade" if wantsToTrash >= multiplier
    "Oasis"
    "Pawn"
    "Warehouse"
    "Cellar"
    "Library" if my.actions > 1 and my.hand.length <= 6

    # 9: non-terminal cards that don't succeed but at least give us something.
    "King's Court"
    "Tournament"
    "Menagerie"
    "Shanty Town" if my.actions < 2

    # 10: terminals. Of course, Nobles might be a non-terminal
    # if we decide we need the actions more than the cards.
    "Crossroads"
    "Nobles"
    "Treasure Map" if my.countInHand("Treasure Map") >= 2
    "Followers"
    "Mountebank"
    "Witch"
    "Torturer"
    "Margrave"
    "Sea Hag"
    "Tribute" # after Cursers but before other terminals, there is probably a better spot for it
    "Goons"
    "Wharf"
    # Tactician needs a play condition, but I don't know what it would be.
    "Tactician"
    "Masquerade"
    "Vault"
    "Princess"
    "Explorer" if my.countInHand("Province") >= 1
    "Library" if my.hand.length <= 3
    "Expand"
    "Remodel"
    "Jester"
    "Militia"
    "Mandarin"
    "Cutpurse"
    "Bridge"
    "Horse Traders"
    "Jack of All Trades"
    "Steward"
    "Moneylender" if countInHandCopper >= 1
    "Mine"
    "Coppersmith" if countInHandCopper >= 3
    "Library" if my.hand.length <= 4
    "Rabble"
    "Envoy"
    "Smithy"
    "Embassy"
    "Watchtower" if my.hand.length <= 3
    "Council Room"
    "Library" if my.hand.length <= 5
    "Watchtower" if my.hand.length <= 4
    "Courtyard" if (my.discard.length + my.draw.length) > 0
    "Merchant Ship"
    "Baron" if my.countInHand("Estate") >= 1
    "Monument"
    "Remake" if wantsToTrash >= multiplier * 2   # has a low priority so it'll mostly be played early in the game
    "Adventurer"
    "Harvest"
    "Explorer"
    "Woodcutter"
    "Nomad Camp"
    "Chancellor"
    "Counting House"
    "Coppersmith" if countInHandCopper >= 2
    "Outpost" if state.extraturn == false
    # Play an Ambassador if our hand has something we'd want to discard.
    "Ambassador" if wantsToTrash
    "Trading Post" if wantsToTrash + my.countInHand("Silver") >= 2 * multiplier
    "Chapel" if wantsToTrash
    "Trader" if wantsToTrash >= multiplier
    "Trade Route" if wantsToTrash >= multiplier
    "Mint" if my.ai.choose('mint', state, my.hand)
    "Pirate Ship"
    "Noble Brigand"
    "Thief"
    "Island"  # could be moved
    "Fortune Teller"
    "Bureaucrat"
    "Navigator"
    "Conspirator" if my.actions < 2
    "Herbalist"
    "Moat"
    "Library" if my.hand.length <= 6
    "Watchtower" if my.hand.length <= 5
    "Ironworks" # should have higher priority if condition can see it will gain an Action card
    "Workshop"
    "Smugglers" if state.smugglerChoices().length > 1
    "Feast"
    "Coppersmith"
    "Saboteur"
    "Duchess"
    "Library" if my.hand.length <= 7

    # 11: cards that have become useless. Maybe they'll decrease
    # the cost of Peddler, trigger Conspirator, or something.
    "Treasure Map" if my.countInDeck("Gold") >= 4 and state.current.countInDeck("Treasure Map") == 1
    "Shanty Town"
    "Stables"
    "Chapel"
    "Library"

    # 12: Conspirator when +actions remain.
    "Conspirator"

    # At this point, we take no action if that choice is available.
    null
    # Nope, something is forcing us to take an action.
    #
    # Last priority: cards that are actively harmful to play at this point,
    # in order of increasing badness.
    "Watchtower"
    "Trade Route"
    "Treasure Map"
    "Ambassador"
    "Throne Room"
  ]
  
  multipliedActionPriority: (state, my) ->
    [
      "King's Court"
      "Throne Room"
      "Followers" if my.actions > 0
      "Grand Market"
      "Mountebank"
      "Witch" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Sea Hag" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Crossroads" if (not my.crossroadsPlayed) or (my.actions > 0)
      "Torturer" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Margrave" if my.actions > 0
      "Wharf" if my.actions > 0
      "Bridge" if my.actions > 0
      "Jester" if my.actions > 0
      "Horse Traders" if my.actions > 0
      "Mandarin" if my.actions > 0
      "Rabble" if my.actions > 0
      "Council Room" if my.actions > 0
      "Smithy" if my.actions > 0
      "Embassy" if my.actions > 0
      "Merchant Ship" if my.actions > 0
      "Pirate Ship" if my.actions > 0
      "Saboteur" if my.actions > 0
      "Noble Brigand" if my.actions > 0
      "Thief" if my.actions > 0
      "Monument" if my.actions > 0
      "Conspirator"
      "Feast" if my.actions > 0
      "Nobles"
      "Tribute" # after Cursers but before other terminals, there is probably a better spot for it
      "Steward" if my.actions > 0
      "Goons" if my.actions > 0
      "Mine" if my.actions > 0
      "Masquerade" if my.actions > 0
      "Vault" if my.actions > 0
      "Cutpurse" if my.actions > 0
      "Coppersmith" if my.actions > 0 and my.countInHand("Copper") >= 2
      "Ambassador" if my.actions > 0 and this.wantsToTrash(state)
      "wait"
      # We could add here some more cards that would be nice to play with a
      # multiplier. Nicer than Lookout, let's say, which appears pretty high
      # on the regular action priority list.
      #
      # But at this point, just fall back on that priority list.
    ].concat(this.actionPriority(state, my, skipMultipliers=true))
  
  # Most of the order of `treasurePriority` has no effect on gameplay. The
  # important part is that Bank and Horn of Plenty are last.
  treasurePriority: (state, my) -> [
    "Platinum"
    "Diadem"
    "Philosopher's Stone"
    "Gold"
    "Cache"
    "Hoard"
    "Royal Seal"
    "Harem"
    "Silver"
    "Fool's Gold"
    "Quarry"
    "Talisman"
    "Copper"
    "Ill-Gotten Gains"
    "Potion"
    "Loan"
    "Venture"
    "Bank"
    "Horn of Plenty" if my.numUniqueCardsInPlay() >= 2
  ]

  cachedActionPriority: (state, my) ->
    my.ai.cachedAP
    
  cacheActionPriority: (state, my) ->
    @cachedAP = my.ai.actionPriority(state, my)

  # `chooseOrderOnDeck` handles situations where multiple cards are returned
  # to the deck, such as Scout and Apothecary.
  #
  # This decision doesn't fit into the xPriority / xValue framework, as there
  # are a number of mostly indistinguishable choices. Instead of listing all
  # the permutations of cards as choices, we just list the cards to arrange.
  #
  # The default decision is to put the cards with the lowest discard value on
  # top.
  chooseOrderOnDeck: (state, cards, my) ->
    sorter = (card1, card2) ->
      my.ai.choiceToValue('discard', state, card1)\
      - my.ai.choiceToValue('discard', state, card2)
    
    choice = cards.slice(0)
    return choice.sort(sorter)

  mintValue: (state, card, my) -> 
    # Mint anything but Copper and Diadem. Otherwise, go mostly by the card's base cost.
    # There is only 1 Diadem, never any available to gain, so never Mint it.
    return card.cost - 1
  
  # The default `discardPriority` is tuned for Big Money where the decisions
  # are obvious. But many strategies would probably prefer a different
  # priority list, especially one that knows about action cards.
  #
  # It doesn't understand
  # discarding cards to make Shanty Town or Menagerie work, for example.
  discardPriority: (state, my) -> [
    "Tunnel"
    "Vineyard"
    "Colony"
    "Duke"
    "Duchy"
    "Fairgrounds"
    "Gardens"
    "Province"  # Provinces are occasionally useful in hand
    "Curse"
    "Estate"
  ]

  discardValue: (state, card, my) ->
    # If we can discard excess actions, do so. Otherwise, discard the cheapest
    # cards. Victory cards would already have been discarded by discardPriority,
    # but if Tunnel fell through somehow we discard it here.
    # 
    # First, check to see if it's our turn. That changes whether we want to discard
    # actions.
    myTurn = (state.current == my)
    if card.name == 'Tunnel'
      25
    else if card.isAction and myTurn and \
         ((card.actions == 0 and my.actionBalance() <= 0) or (my.actions == 0))
      20 - card.cost
    else
      0 - card.cost
  
  discardForEnvoyValue: (state, card, my) ->
    # Choose a card to discard from your opponent's hand when it's their turn.
    opp = state.current
    if card.name == 'Tunnel'
      return -25
    else if not (card.isAction) and not (card.isTreasure)
      return -10
    else if opp.actions == 0 and card.isAction
      return -5
    else if opp.actions >= 2
      return card.cards + card.coins + card.cost + 2*card.isAttack
    else
      return card.coins + card.cost + 2*card.isAttack

  # Changed Priorities for putting cards back on deck.  Only works well for putting back 1 card, and for 1 buy.
  #
  putOnDeckPriority: (state, my) -> 
    putBack = []
    # 1) If no actions left, put back the best Action.
    #    Take card from hand which are actions, sort them by ActionPriority.
    #
    if my.countPlayableTerminals(state) == 0
      # take actions from hand
      # and sort them by actionPriority (highest first)
      
      putBackOptions = (card for card in my.hand when card.isAction)
      
    # 2) If not enough actions left, put back best Terminal you can't play.
    #    Take cards from hand which are Actions and Terminals, sort them by ActionPriority.
    #    Then, ignore as many terminals as you can play this turn; return the others.
    #
    else
      putBackOptions = (card for card in my.hand \
                        when (card.isAction and card.getActions(state)==0))
    
    putBack = (card for card in my.ai.actionPriority(state, my) \
                    when (state.cardInfo[card] in putBackOptions))

    putBack = putBack[my.countPlayableTerminals(state) ... putBack.length]

    # 3) Put back as much money as you can
    if putBack.length == 0
      # Get a list of all distinct treasures in hand, in order.
      treasures = []
      for card in my.hand
        if (card.isTreasure) and (not (card in treasures))
          treasures.push card
      treasures.sort( (x, y) -> x.coins - y.coins)

      # Get the margin of how much money we're willing to discard.
      margin = my.ai.coinLossMargin(state)

      # Find the treasure cards worth less than that.
      for card in treasures
        if my.ai.coinsDueToCard(state, card) <= margin
          putBack.push(card)

      # Don't put back last Potion if Alchemists are in play
      if my.countInPlay(state.cardInfo["Alchemist"])>0
        if "Potion" in putBack
          putBack.remove(state.cardInfo["Potion"])
    
    # 4) Put back the worst card (take priority for discard)
    #
    if putBack.length==0
      putBack = [my.ai.chooseDiscard(state, my.hand)]
    putBack
  
  putOnDeckValue: (state, card, my) =>
    this.discardValue(state, card, my)
  
  # The `herbalist` decision puts a treasure card back on the deck. It sounds
  # the same as `putOnDeck`, but it's for a different
  # situation -- the card is coming from in play, not from your hand. So
  # actually we use the `mintValue` by default.
  herbalistValue: (state, card, my) =>
    this.mintValue(state, card, my)

  trashPriority: (state, my) -> [
    "Curse"
    "Estate" if state.gainsToEndGame() > 4
    "Copper" if my.getTotalMoney() > 4
    "Potion" if my.turnsTaken >= 10
    "Estate" if state.gainsToEndGame() > 2
  ]

  # If we have to trash a card we don't want to, assign a value to each card.
  # By default, we want to trash the card with the lowest (cost + VP).
  trashValue: (state, card, my) ->
    0 - card.vp - card.cost
    
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
      # Handle a silly case:
      "Ambassador,2"
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
    ].concat (card+",1" for card in my.ai.trashPriority(state, my) when card?)
  
  # islandPriority chooses which card to set aside with Island. At present this
  # list is incomplete, but covers just about everything that we would want to set aside
  # with an Island.
  islandPriority: (state, my) ->
    [
      "Colony"
      "Province"
      "Fairgrounds"
      "Duchy"
      "Duke"
      "Gardens"
      "Vineyard"
      "Estate"
      "Copper"
      "Curse"
      "Island"
      "Tunnel"
    ]
  
  islandValue: (state, card, my) -> this.discardValue(state, card, my)
  
  # Taking into account gain priorities, gain values, trash priorities, and
  # trash values, how much do we like having this card in our deck overall?
  cardInDeckValue: (state, card, my) ->
    endgamePower = 1
    
    # Are we in the late game? If so, we care much more about getting cards
    # at the top of our priority order.
    if state.gainsToEndGame() <= 5
      endgamePower = 3

    return -(this.choiceToValue('trash', state, card)) + \
           Math.pow(this.choiceToValue('gain', state, card), endgamePower)

  # upgradeValue measures the benefit of choices on Remodel, Upgrade,
  # and so on, where you exchange one card for a better one.
  # 
  # So here's a really basic thing that might work.
  upgradeValue: (state, choice, my) ->
    [oldCard, newCard] = choice
    return my.ai.cardInDeckValue(state, newCard, my) - \
           my.ai.cardInDeckValue(state, oldCard, my)
  
  # The question here is: do you want to discard an Estate using a Baron?
  # And the answer is yes.
  baronDiscardPriority: (state, my) -> [yes]

  # Do you want to discard a Province to win a Tournament? The answer is
  # *very* yes.
  tournamentDiscardPriority: (state, my) -> [yes]

  # Which treasure, if any, should be discarded to feed Stables? Defaults
  # to a list of generally crappy treasures. Doesn't include $1 Fool's Gold
  # because you presumably have another one you're trying to draw.
  stablesDiscardPriority: (state, my) -> [
    "Copper"
    "Potion" if my.countInPlay(state.cardInfo["Alchemist"]) == 0
    "Ill-Gotten Gains"
    "Silver"
    "Horn of Plenty"
  ]

  # Some cards give you a choice to discard an opponent's deck. These are
  # evaluated with `discardFromOpponentDeckValue`.
  discardFromOpponentDeckValue: (state, card, my) ->
    if card.name == 'Tunnel'
      return -25
    else if not (card.isAction) and not (card.isTreasure)
      return -10
    else
      return card.coins + card.cost + 2*card.isAttack

  # Do you want to gain a copper from Ill-Gotten Gains? It's quite possible
  # in endgame situations, but for now the answer is no.
  gainCopperPriority: (state, my) -> [no]

  # `wishValue` prefers to wish for the card its draw pile contains
  # the most of.
  #
  # The fact that this doesn't make a hypothetical copy is a shortcut. We are
  # technically "peeking" at the deck, but we don't use any information except
  # the count of each card, which would be the same in any hypothetical version.
  wishValue: (state, card, my) ->
    pile = my.draw
    if pile.length == 0
      pile = my.discard
    return countInList(pile, card)

  # `foolsGoldTrashPriority` will trash a Fool's Gold for a real Gold if
  # it's nearing the endgame (5 gains or less), there is one FG in hand,
  # and losing it will not change its buy.
  foolsGoldTrashPriority: (state, my) ->
    if my.countInHand(state.cardInfo["Fool's Gold"]) == 1 and my.ai.coinLossMargin(state) >= 1
      [yes]
    else
      [no]
  
  # Prefer to gain action and treasure cards on the deck. Give other cards
  # a value of -1 so that `null` is a better choice.
  gainOnDeckValue: (state, card, my) ->
    if (card.isAction or card.isTreasure)
      1
    else
      -1
  
  # How much does the AI want to discard its deck right now (for Chancellor)?
  # Here, we decide to reshuffle (returning a reshuffleValue over 0) when most
  # of the non-Action, non-Treasure cards are in the draw pile, or when there
  # are no such cards in the deck.
  reshuffleValue: (state, choice, my) ->
    junkToDraw = 0
    totalJunk = 0
    for card in my.draw
      if not (card.isAction or card.isTreasure)
        junkToDraw++
    for card in my.getDeck()
      if not (card.isAction or card.isTreasure)
        totalJunk++
    return 1 if (totalJunk == 0)
    proportion = junkToDraw/totalJunk
    return (proportion - 0.5)

  # Choose to discard or to gain a curse when attacked by Torturer.
  torturerPriority: (state, my) -> [
    'curse' if state.countInSupply("Curse") == 0
    'discard' if my.ai.wantsToDiscard(state) >= 2
    'discard' if my.hand.length <= 1
    'curse' if my.trashingInHand() > 0
    'curse' if my.hand.length <= 3
    'discard'
    'curse'
  ]

  discardHandValue: (state, hand, my) ->
    return 0 if hand is null
    deck = my.getDeck()
    shuffle(deck)
    randomHand = deck[0...5]
    # If a random hand from this deck is better, discard this hand.
    return my.ai.compareByDiscarding(state, randomHand, hand)

  # Choose to attack or use available coins when playing Pirate Ship.
  # Current strategy is basically Geronimoo's attackUntil5Coins play strategy,
  # but only with Provinces--or technically, cards costing 8 or more.
  pirateShipPriority: (state, my) -> [
    'coins' if state.current.mats.pirateShip >= 5 and state.current.getAvailableMoney()+state.current.mats.pirateShip >= 8
    'attack'
  ]

  librarySetAsideValue: (state, card, my) -> [
    if my.actions == 0 and card.isAction
      1
    else
      -1
  ]
  
  # Choose opponent treasure to trash; go by the card's base cost.
  # Diadems are comparable to the cost-5 treasures.
  trashOppTreasureValue: (state, card, my) =>
    if card is 'Diadem'
      return 5
    return card.cost

  #### Informational methods

  # When presented with a card with simple but variable benefits, such as
  # Nobles, this is the default way for an AI to decide which benefit it wants.
  # This function should actually handle a number of common situations.
  benefitValue: (state, choice, my) ->
    buyValue = 1
    cardValue = 2
    coinValue = 3
    trashValue = 4      # if there are cards we want to trash
    actionValue = 10    # if we need more actions

    actionBalance = my.actionBalance()
    usableActions = Math.max(0, -actionBalance)

    if actionBalance >= 1
      cardValue += actionBalance
    if my.ai.wantsToTrash(state) < (choice.trash ? 0)
      trashValue = -4
    
    value = cardValue * (choice.cards ? 0)
    value += coinValue * (choice.coins ? 0)
    value += buyValue * (choice.buys ? 0)
    value += trashValue * (choice.trash ? 0)
    value += actionValue * Math.min((choice.actions ? 0), usableActions)
    #state.log("Benefit: #{JSON.stringify(choice)} / Value: #{value} / wants to trash: #{my.ai.wantsToTrash(state)}")
    value

  # `wantsToTrash` returns the number of cards in hand that we would trash
  # for no benefit.
  wantsToTrash: (state) ->
    my = this.myPlayer(state)
    trashableCards = 0
    for card in my.hand
      if this.chooseTrash(state, [card, null]) is card
        trashableCards += 1
    return trashableCards
  
  # `wantsToDiscard` returns the number of cards in hand that we would
  # freely discard.
  wantsToDiscard: (state) ->
    my = this.myPlayer(state)
    discardableCards = 0
    for card in my.hand
      if this.chooseDiscard(state, [card, null]) is card
        discardableCards += 1
    return discardableCards

  # `pessimisticMoneyInHand` establishes a minimum on how much money the
  # player will be able to spend in this game state. It assumes the player
  # will draw no money from the deck.
  pessimisticMoneyInHand: (state) ->
    # Don't recurse more than once. If we're already in a hypothetical
    # situation, use the stupid version instead.
    if state.depth > 0
      return this.myPlayer(state).getAvailableMoney()

    buyPhase = this.pessimisticBuyPhase(state)
    return buyPhase.current.coins
  
  # Look ahead to the buy phase, assuming we draw no money from the deck.
  #
  # TODO: when we can handle known cards on top of the deck, take them
  # into account.
  pessimisticBuyPhase: (state) ->
    if state.depth > 0
      # A last-ditch effort to avoid recursion, by simply fast-forwarding
      # to the next phase.
      if state.phase == 'action'
        state.phase = 'treasure'
      else if state.phase == 'treasure'
        state.phase = 'buy'
    
    [hypothesis, hypothetically_my] = state.hypothetical(this)
    #  We need to save draw and discard before emptying and restore them before buyPhase, to be able to choose the right buys in actionPriority(state)
    oldDraws   = hypothetically_my.draw.slice(0)
    oldDiscard = hypothetically_my.discard.slice(0)
    hypothetically_my.draw = []
    hypothetically_my.discard = []
    
    while hypothesis.phase != 'buy'
      hypothesis.doPlay()
      
    hypothetically_my.draw = oldDraws
    hypothetically_my.discard = oldDiscard

    return hypothesis
  
  pessimisticCardsGained: (state) ->
    newState = this.pessimisticBuyPhase(state)
    newState.doPlay()
    return newState.current.gainedThisTurn
  
  # coinLossMargin determines how much treasure the player can lose
  # "for free" (because it won't change their buy decision). Intended to be
  # more efficient than calling pessimisticCardsGained on a number
  # of different states.
  #
  # TODO: do we need an equivalent for potions?
  coinLossMargin: (state) ->
    newState = this.pessimisticBuyPhase(state)
    coins = newState.coins
    cardToBuy = newState.getSingleBuyDecision()
    return 0 if cardToBuy is null
    [coinsCost, potionsCost] = cardToBuy.getCost(newState)
    return coins - coinsCost
  
  # Estimate the number of coins we'd lose by discarding/trashing/putting back
  # a card.
  coinsDueToCard: (state, card) ->
    c = state.cardInfo
    value = card.getCoins(state)
    if card.isTreasure
      banks = state.current.countInHand(state.cardInfo.Bank)
      value += banks
      if card is state.cardInfo.Bank
        nonbanks = (aCard for aCard in state.current.hand when aCard.isTreasure).length
        value += nonbanks
    value
  
  # Figure out whether hand1 or hand2 is better by discarding their cards
  # in priority order. Returns a -1 or 1 that can be used in sorting; it's
  # positive if the first hand is better.
  compareByDiscarding: (state, hand1, hand2) ->
    # Guard against accidental mutation; we're going to be messing with
    # these lists.
    hand1 = hand1.slice(0)
    hand2 = hand2.slice(0)
    
    # Preserve our number of actions.
    savedActions = state.current.actions
    state.current.actions = 1

    #state.log("hand1 = #{hand1}")
    #state.log("hand2 = #{hand2}")
    counter = 0
    loop
      counter++
      if counter >= 100
        throw new Error("got stuck in a loop")
      # Figure out whether we'd rather discard from hand1 or hand2.
      discard1 = this.choose('discard', state, hand1)
      value1 = this.choiceToValue('discard', state, discard1)
      discard2 = this.choose('discard', state, hand2)
      value2 = this.choiceToValue('discard', state, discard2)
      if value1 > value2
        hand1.remove(discard1)
      else if value2 > value1
        hand2.remove(discard2)
      else
        hand1.remove(discard1)
        hand2.remove(discard2)
      if hand1.length == 0 and hand2.length == 0
        state.current.actions = savedActions
        return 0      
      if hand1.length == 0
        #state.log("hand2 is better")
        state.current.actions = savedActions
        return -1
      if hand2.length == 0
        #state.log("hand1 is better")
        state.current.actions = savedActions
        return 1

  #### Utility methods
  #
  # `copy` makes a copy of the AI. It will have the same behavior but a
  # different name, and will not be equal to this AI.
  copy: () =>
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
countInList = (list, elt) ->
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

# General function to randomly shuffle a list.
shuffle = (v) ->
  i = v.length
  while i
    j = parseInt(Math.random() * i)
    i -= 1
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
  v
