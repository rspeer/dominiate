{c} = require './cards' if exports?

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
# given a list of choices. It will first check a method called `xPriority`,
# which takes in the state and returns an ordered list of choices.
# The player will make the first valid choice in that list. Choices are
# skipped when they have an "if" clause that fails.
#
# If the priority list doesn't choose anything, or if there is no priority
# function, it will consult the `xValue` method instead, which takes in
# a specific choice and assigns it a numerical value.
#
# Priority functions are usually easier to define than value functions, but
# value functions can easily cover every possible case.
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
  choose: (type, state, choices) ->
    my = this.myPlayer(state)
    
    # Are there no choices? We follow the rule that makes the null choice
    # available in that situation, and choose it.
    if choices.length == 0
      return null

    # First, try the priority function. If the priority function reaches
    # the end of its list, it is treated as "none of the above".
    priorityfunc = this[type+'Priority']
    if priorityfunc?
      # Construct an object with the choices as keys, so we can look them
      # up quickly.
      choiceSet = {}
      for choice in choices
        choiceSet[choice] = choice

      nullable = null in choices
      
      # Get the priority list.
      priority = priorityfunc.call(this, state, my)
      # Now look up all the preferences in that list. The moment we encounter
      # a valid choice, we can return it.
      for preference in priority
        if preference is null and nullable
          return null
        if choiceSet[preference]?
          return choiceSet[preference]
  
    # The priority list doesn't want any of these choices (perhaps because
    # it doesn't exist). Now try the value function.
    bestChoice = null
    bestValue = -Infinity
  
    for choice in choices
      value = this.getChoiceValue(type, state, choice, my)
      if value > bestValue
        bestValue = value
        bestChoice = choice
      
    # If we got a valid choice, return it.
    if bestChoice in choices
      return bestChoice
    
    # If we get here, the AI probably wants to choose none of the above.
    if null in choices
      return null

    throw new Error("#{this} somehow failed to make a choice")
  
  getChoiceValue: (type, state, choice, my) ->
    if choice is null or choice is no
      return 0

    specificValueFunc = this[type+'Value']
    if specificValueFunc?
      result = specificValueFunc.call(this, state, choice, my)
      if result is undefined
        throw new Error("#{this} has an undefined #{type} value for #{choice}")
      if result isnt null
        return result

    defaultValueFunc = choice['ai_'+type+'Value']
    if defaultValueFunc?
      result = defaultValueFunc.call(choice, state, my)
      if result is undefined
        throw new Error("#{this} has an undefined #{type} value for #{choice}")
      if result isnt null
        return result

    state.warn("#{this} doesn't know how to make a #{type} decision for #{choice}")
    return -1000

  # Sometimes we need to compare choices in a strictly numeric way. This takes
  # a particular choice for a particular choice type, and gets its numeric value.
  # If the value comes from a priority list, it will be 100 * (distance from end
  # of list).
  #
  # So, for example, the default choiceToValue of discarding a Colony is 999, while
  # the choiceToValue of discarding an extra terminal is 1.
  choiceToValue: (type, state, choice) ->
    return 0 if choice is null or choice is no
    my = this.myPlayer(state)
    priorityfunc = this[type+'Priority']
    if priorityfunc?
      priority = priorityfunc.bind(this)(state, my)
    else
      priority = []
    index = priority.indexOf(stringify(choice))
    if index != -1
      return (priority.length - index) * 100
    else
      return this.getChoiceValue(type, state, choice, my)

  # Originally implemented in the `Rebuild.coffee` strategy, this method gets
  # the difference in score if the game were to end now.
  getScoreDifference: (state, my) -> 
    for status in state.getFinalStatus()
      [name, score, turns] = status
      if name == my.ai.toString()
        myScore = score
      else
        opponentScore = score
    return myScore - opponentScore

  # More utilities from the Rebuild strategy.
  countNotInHand: (my, card) ->
    return my.countInDeck(card) - my.countInHand(card)

  countInDraw: (my, card) ->
    return my.countInDeck(card) - my.countInHand(card) - my.countInDiscard(card)



  #### Backwards-compatible choices
  # 
  # To avoid having to rewrite all the code at once, we support these functions
  # that pass `chooseAction` onto `choose('action')`, and so on.
  chooseAction: (state, choices) -> this.choose('play', state, choices)
  chooseTreasure: (state, choices) -> this.choose('play', state, choices)
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

  # gainValue covers cases where a strategy has to gain a card that isn't in
  # its priority list. The default is to favor more expensive cards,
  # particularly action and treasure cards.
  # 
  # It is important for all these values to be negative, to avoid giving defined
  # strategies cards they don't actually want.
  gainValue: (state, card, my) ->
    card.cost + 2*card.costPotion + card.isTreasure + card.isAction - 20
  
  # This used to be the default action-playing priority. Now the value of playing
  # a card is defined on the "ai_playValue" function of each card.
  old_actionPriority: (state, my, skipMultipliers = false) -> 
    wantsToTrash = this.wantsToTrash(state)
    countInHandCopper = my.countInHand("Copper")
    currentAction = my.getCurrentAction()
    multiplier = 1
    if currentAction?.isMultiplier
      multiplier = currentAction.multiplier
    
    wantsToPlayMultiplier = false
    okayToPlayMultiplier = false

    unless skipMultipliers
      mults = (card for card in my.hand when card.isMultiplier)
      if mults.length > 0
        # We've got a multiplier in hand. Figure out if we want to play it.
        mult = mults[0]
        choices = my.hand.slice(0)
        choices.remove(mult)
        choices.push(null)

        # Determine if it's better than nothing.
        choice1 = this.choose('multipliedAction', state, choices)
        if choice1 isnt null
          okayToPlayMultiplier = true
        
        # Now add the "wait" option and see if we want to multiply an action
        # *right now*.
        if choices.length > 1
          choices.push("wait")
        choice = this.choose('multipliedAction', state, choices)
        if choice != "wait"
          wantsToPlayMultiplier = true

    # Priority 1: cards that succeed if we play them now, and might
    # not if we play them later. (950-999)

    ["Menagerie" if my.menagerieDraws() == 3
    "Shanty Town" if my.shantyTownDraws(true) == 2
    "Tournament" if my.countInHand("Province") > 0
    "Library" if my.hand.length <= 3 and my.actions > 1
    
    # 2: Multipliers that do something sufficiently cool. (900-949)
    "Throne Room" if wantsToPlayMultiplier
    "King's Court" if wantsToPlayMultiplier

    # 3: cards that stack the deck. (850-899)
    "Lookout" if state.gainsToEndGame() >= 5 or state.cardInfo.Curse in my.draw
    "Cartographer"
    "Bag of Gold"
    "Apothecary"
    "Scout"
    "Scrying Pool"
    "Spy"

    # 4: cards that give +2 actions. (800-849)
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
    "Mining Village"

    # 5: cards that give +1 action and are almost always good. (700-800)
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
    "Scheme"
    "Wishing Well"
    "Golem"  # seems to be reasonable to expect +1 action from Golem
    "Great Hall" if state.cardInfo.Crossroads not in my.hand
    "Spice Merchant" if state.cardInfo.Copper in my.hand
    "Stables" if this.choose('stablesDiscard', state, my.hand.concat([null]))
    "Apprentice"
    "Pearl Diver"
    "Hamlet"
    "Lighthouse"
    "Haven"
    "Minion"

    # 6: terminal card-drawers, if we have actions to spare. (600-699)
    "Library" if my.actions > 1 and my.hand.length <= 4  # 695
    "Torturer" if my.actions > 1
    "Margrave" if my.actions > 1
    "Rabble" if my.actions > 1
    "Witch" if my.actions > 1
    "Ghost Ship" if my.actions > 1
    "Smithy" if my.actions > 1
    "Embassy" if my.actions > 1
    "Watchtower" if my.actions > 1 and my.hand.length <= 4
    "Library" if my.actions > 1 and my.hand.length <= 5 # 620
    "Council Room" if my.actions > 1
    "Courtyard" if my.actions > 1 and (my.discard.length + my.draw.length) <= 3
    "Oracle" if my.actions > 1

    # 7: Let's insert here an overly simplistic idea of how to play Crossroads.
    # Or if we don't have a Crossroads, play a Great Hall that we might otherwise
    # have played in priority level 5. (500-599)
    "Crossroads" unless my.countInPlay(state.cardInfo.Crossroads) > 0
    "Great Hall"

    # 8: card-cycling that might improve the hand. (400-499)
    "Upgrade" if wantsToTrash >= multiplier
    "Oasis"
    "Pawn"
    "Warehouse"
    "Cellar"
    "Library" if my.actions > 1 and my.hand.length <= 6
    "Spice Merchant" if this.choose('spiceMerchantTrash', state, my.hand.concat([null]))

    # 9: non-terminal cards that don't succeed but at least give us something. (300-399)
    "King's Court"
    "Throne Room" if okayToPlayMultiplier
    "Tournament"
    "Menagerie"
    "Shanty Town" if my.actions < 2

    # 10: terminals. Of course, Nobles might be a non-terminal
    # if we decide we need the actions more than the cards. (100-299)
    "Crossroads"
    "Nobles"
    "Treasure Map" if my.countInHand("Treasure Map") >= 2
    "Followers"
    "Mountebank" # 290
    "Witch"
    "Sea Hag"
    "Torturer"
    "Young Witch"
    "Tribute" # after Cursers but before other terminals, there is probably a better spot for it
    "Margrave" # 280
    "Goons"
    "Wharf"
    # Tactician needs a play condition, but I don't know what it would be.
    "Tactician" 
    "Masquerade" # 270
    "Vault" 
    "Ghost Ship"
    "Princess" 
    "Explorer" if my.countInHand("Province") >= 1
    "Library" if my.hand.length <= 3  # 260
    "Jester"
    "Militia"
    "Cutpurse"  # 250
    "Bridge"
    "Bishop"
    "Horse Traders"  # 240
    "Jack of All Trades"
    "Steward"
    "Moneylender" if countInHandCopper >= 1 # 230
    "Expand"
    "Remodel"  
    "Salvager" # 220
    "Mine"
    "Coppersmith" if countInHandCopper >= 3
    "Library" if my.hand.length <= 4  # 210
    "Rabble"
    "Envoy"
    "Smithy"   # 200
    "Embassy"
    "Watchtower" if my.hand.length <= 3
    "Council Room"
    "Library" if my.hand.length <= 5
    "Watchtower" if my.hand.length <= 4  # 190
    "Courtyard" if (my.discard.length + my.draw.length) > 0
    "Merchant Ship"
    "Baron" if my.countInHand("Estate") >= 1
    "Monument"
    "Oracle" # 180
    "Remake" if wantsToTrash >= multiplier * 2   # has a low priority so it'll mostly be played early in the game
    "Adventurer"
    "Harvest"
    "Haggler" # probably needs to make sure the gained card will be wanted; 170
    "Mandarin"
    "Explorer"
    "Woodcutter"
    "Nomad Camp"
    "Chancellor" # 160
    "Counting House"
    "Coppersmith" if countInHandCopper >= 2
    "Outpost" if state.extraturn == false
    "Ambassador" if wantsToTrash # 150
    "Trading Post" if wantsToTrash + my.countInHand("Silver") >= 2 * multiplier
    "Chapel" if wantsToTrash
    "Trader" if wantsToTrash >= multiplier
    "Trade Route" if wantsToTrash >= multiplier
    "Mint" if my.ai.choose('mint', state, my.hand) # 140
    "Secret Chamber"
    "Pirate Ship"
    "Noble Brigand"
    "Thief"
    "Island"  # could be moved
    "Fortune Teller" # 130
    "Bureaucrat"
    "Navigator"
    "Conspirator" if my.actions < 2
    "Herbalist"
    "Moat"  # 120
    "Library" if my.hand.length <= 6
    "Ironworks" # should have higher priority if condition can see it will gain an Action card
    "Workshop"
    "Smugglers" if state.smugglerChoices().length > 1 # 110
    "Feast"
    "Transmute" if wantsToTrash >= multiplier
    "Coppersmith"
    "Saboteur"
    "Poor House"
    "Duchess"
    "Library" if my.hand.length <= 7
    "Thief"  # 100

    # 11: cards that have become useless. Maybe they'll decrease
    # the cost of Peddler, trigger Conspirator, or something. (20-99)
    "Treasure Map" if my.countInDeck("Gold") >= 4 and state.current.countInDeck("Treasure Map") == 1
    "Spice Merchant"
    "Shanty Town"
    "Stables" # 50
    "Chapel"
    "Library"

    # 12: Conspirator when +actions remain. (10)
    "Conspirator"
    #    "Baron"

    # At this point, we take no action if that choice is available.
    null
    # Nope, something is forcing us to take an action.
    #
    # Last priority: cards that are actively harmful to play at this point,
    # in order of increasing badness.
    "Baron"
    "Mint"
    "Watchtower"
    "Outpost"
    "Ambassador" # -20
    "Trader"
    "Transmute"
    "Trade Route"
    "Upgrade"  # -30
    "Remake"
    "Trading Post"
    "Treasure Map" # -40
    "Throne Room"
    ]
  
  # `multipliedActionPriority` is similar to `actionPriority`, but is used when
  # we have played a Throne Room or King's Court.
  #
  # This list emphasizes cards that are really good when multiplied, especially
  # terminals when there are +actions left. At the end, it falls back on the
  # usual actionPriority list.
  old_multipliedActionPriority: (state, my) ->
    [
      "King's Court"  # 2000
      "Throne Room"   # 1900
      "Followers" if my.actions > 0 
      "Grand Market"
      "Mountebank" if my.actions > 0
      "Witch" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Sea Hag" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Torturer" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Young Witch" if my.actions > 0 and state.countInSupply("Curse") >= 2
      "Crossroads" if my.actions > 0 or my.countInPlay(state.cardInfo.Crossroads) == 0  # 1800
      "Scheme" if my.countInDeck("King's Court") >= 2
      # Scrying Pool was here once, but I think you'd rather use it to *draw*
      # actions for your KC
      "Wharf" if my.actions > 0
      "Bridge" if my.actions > 0
      "Minion"  # 1700
      "Ghost Ship" if my.actions > 0
      "Jester" if my.actions > 0
      "Horse Traders" if my.actions > 0
      "Mandarin" if my.actions > 0
      "Rabble" if my.actions > 0  # 1600
      "Council Room" if my.actions > 0
      "Margrave" if my.actions > 0
      "Smithy" if my.actions > 0
      "Embassy" if my.actions > 0
      "Merchant Ship" if my.actions > 0  # 1500
      "Pirate Ship" if my.actions > 0
      "Saboteur" if my.actions > 0
      "Noble Brigand" if my.actions > 0
      "Thief" if my.actions > 0
      "Monument" if my.actions > 0  # 1400
      "Feast" if my.actions > 0
      "Conspirator"
      "Nobles"
      "Tribute"
      "Steward" if my.actions > 0  # 1300
      "Goons" if my.actions > 0
      "Mine" if my.actions > 0
      "Masquerade" if my.actions > 0
      "Vault" if my.actions > 0
      "Oracle" if my.actions > 0  # 1200
      "Cutpurse" if my.actions > 0
      "Coppersmith" if my.actions > 0 and my.countInHand("Copper") >= 2
      "Ambassador" if my.actions > 0 and this.wantsToTrash(state)  # 1100
      "wait"
      # We could add here some more cards that would be nice to play with a
      # multiplier. Nicer than Lookout, let's say, which appears pretty high
      # on the regular action priority list.
      #
      # But at this point, just fall back on that priority list.
    ].concat(this.old_actionPriority(state, my, skipMultipliers=true))
  
  # `treasurePriority` determines what order to play treasures in.
  # Most of the order has no effect on gameplay. The
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
    "Masterpiece"
    "Potion"  # 100 from here up
    "Loan"    # 90
    "Venture" # 80
    "Ill-Gotten Gains"
    "Bank"
    "Horn of Plenty" if my.numUniqueCardsInPlay() >= 2
    "Spoils" if this.wantsToPlaySpoils(state)
    null
  ]
  
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

  #developPriority: (state, my) => 
  #   trashPriority(state, my)
     
  #developValue: (state, card, my) =>
  #  this.trashValue(state, card, my)

  # Some cards give you a choice to discard an opponent's deck. These are
  # evaluated with `discardFromOpponentDeckValue`.
  discardFromOpponentDeckValue: (state, card, my) ->
    if card.name == 'Tunnel'
      return -2000
    else if not (card.isAction) and not (card.isTreasure)
      return -10
    else
      return card.coins + card.cost + 2*card.isAttack  

  # `discardHandValue` decides whether to discard an entire hand of cards.
  discardHandValue: (state, hand, my, nCards = 5) ->
    return 0 if hand is null
    deck = my.discard.concat(my.draw)
    total = 0
    for i in [0...5]
      shuffle(deck)
      randomHand = deck[0...nCards]
      # If a random hand from this deck is better, discard this hand.
      total += my.ai.compareByDiscarding(state, randomHand, hand)
    return total
    
  # Prefer to gain action and treasure cards on the deck, assuming we want
  # them at all. Give other cards a value of -1 so that `null` is a better
  # choice.
  gainOnDeckValue: (state, card, my) ->
    if (card.isAction or card.isTreasure)
      this.getChoiceValue('gain', state, card, my)
    else
      -1
  
  # Changed Priorities for putting cards back on deck.  Only works well for putting back 1 card, and for 1 buy.
  #
  putOnDeckPriority: (state, my) -> 
    # Make a priority order of:
    # 
    # 1. Actions we can't or don't intend to play, from best to worst
    # 2. Treasures we can afford to put back
    # 3. Junk cards

    # 1) Actions
    actions = (card for card in my.hand when card.isAction)
    getChoiceValue = this.getChoiceValue
    byPlayValue = (x, y) ->
      getChoiceValue('play', state, y, my) - getChoiceValue('play', state, x, my)

    actions.sort(byPlayValue)
    putBack = actions[my.countPlayableTerminals(state) ...]

    # 2) Put back as much money as you can
    if putBack.length == 0
      # Get a list of all distinct treasures in hand, in order.
      treasures = []
      for card in my.hand
        if (card.isTreasure) and (not (card in treasures))
          treasures.push card
      treasures.sort( (x, y) -> y.coins - x.coins )

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
    
    # 3) Put back the worst card (take priority for discard)
    if putBack.length == 0
      putBack = [my.ai.choose('discard', state, my.hand)]

    putBack
  
  putOnDeckValue: (state, card, my) =>
    this.discardValue(state, card, my)  
  
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

  # Choose opponent treasure to trash; go by the card's base cost.
  # Diadems are comparable to the cost-5 treasures.
  trashOppTreasureValue: (state, card, my) =>
    if card is 'Diadem'
      return 5
    return card.cost    

  #### Decisions for particular cards

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
      "[Curse, 2]"
      "[Curse, 1]"
      "[Curse, 0]"
      # Handle a silly case:
      "[Ambassador, 2]"
      "[Estate, 2]"
      "[Estate, 1]"
      # Make sure we have at least $5 in the deck, including if we buy a Silver.
      "[Copper, 2]" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 5
      "[Copper, 2]" if my.getTreasureInHand() >= 5
      "[Copper, 2]" if my.getTreasureInHand() == 3 and my.getTotalMoney() >= 7
      "[Copper, 1]" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 4
      "[Copper, 1]" if my.getTreasureInHand() >= 4
      "[Estate, 0]"
      "[Copper, 0]"
      "[Potion, 2]"
      "[Potion, 1]"
      null
    ].concat ("[#{card}, 1]" for card in my.ai.trashPriority(state, my) when card?)\
    .concat ("[#{card}, 0]" for card in my.hand)
  
  apprenticeTrashPriority: (state, my) ->
    "Border Village"
    "Mandarin"
    "Ill-Gotten Gains" if this.coinLossMargin(state) > 0
    "Feodum"
    "Estate"
    "Curse"
    "Apprentice"
  
  apprenticeTrashValue: (state, card, my) ->
    vp = card.getVP(my)
    [coins, potions] = card.getCost(state)
    drawn = Math.min(my.draw.length + my.discard.length, coins+2*potions)
    return this.choiceToValue('trash', state, card) + 2*drawn - vp    

  # The question here is: do you want to discard an Estate using a Baron?
  # And the answer is yes.
  baronDiscardPriority: (state, my) -> [yes]
  
  # `bishopTrashPriority` lists cards that are especially good to trash.
  bishopTrashPriority: (state, my) -> [
    "Farmland"
    "Duchy" if this.goingGreen(state) < 3
    "Border Village"
    "Mandarin"
    "Feodum"
    "Bishop"
    "Ill-Gotten Gains" if this.coinLossMargin(state) > 0
    "Curse"
  ]

  bishopTrashValue: (state, card, my) ->
    [coins, potions] = card.getCost(state)
    value = Math.floor(coins/2) - card.getVP(my)

    # if we're going for victory points, that's all we care about.
    if this.goingGreen(state) >= 3
      return value

    # otherwise, focus on what we want to trash
    else
      if card in this.trashPriority(state, my)
        value += 1
      if card.isAction and ((card.actions == 0 and my.actionBalance() <= 0) or (my.actions == 0))
        value += 1
      if card.isTreasure and card.coins > (this.coinLossMargin(state) + 1)
        value -= 10
      return value

  envoyValue: (state, card, my) ->
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

  # `foolsGoldTrashPriority` will trash a Fool's Gold for a real Gold if
  # it's nearing the endgame (5 gains or less), there is one FG in hand,
  # and losing it will not change its buy.
  foolsGoldTrashPriority: (state, my) ->
    if my.countInHand(state.cardInfo["Fool's Gold"]) == 1 and my.ai.coinLossMargin(state) >= 1
      [yes]
    else
      [no]  

  # Do you want to gain a copper from Ill-Gotten Gains? Yes, we want if that improves our buy
  gainCopperPriority: (state, my) ->
    if my.ai.coinGainMargin(state) <= my.countInHand("Ill-Gotten Gains")+1
      [yes]
    else
      [no]

  # The `herbalist` decision puts a treasure card back on the deck. It sounds
  # the same as `putOnDeck`, but it's for a different
  # situation -- the card is coming from in play, not from your hand. So
  # actually we use the `mintValue` by default.
  herbalistValue: (state, card, my) =>
    this.mintValue(state, card, my)


  huntingGroundsGainPriority: (state, my) -> [
    "Duchy"
    "Estates"
  ]
  

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

  librarySetAsideValue: (state, card, my) -> [
    if my.actions == 0 and card.isAction
      1
    else
      -1
  ]

  miningVillageTrashValue: (state, choice, my) ->
    if this.goingGreen(state) and this.coinGainMargin(state) <= 2
      1
    else
      -1

  minionDiscardValue: (state, choice, my) ->
    if choice == yes
      # Find out how valuable it would be to discard these cards and draw 4.
      value = this.discardHandValue(state, my.hand, my, 4)
      opponent = state.players[state.players.length - 1]

      # If the attack would decrease an opponent's hand size, it's more valuable.
      if opponent.hand.length > 4
        value += 2
      return value
    else
      return 0

  # Mint anything but Copper and Diadem. Otherwise, go mostly by the card's base cost.
  # There is only 1 Diadem, never any available to gain, so never Mint it.
  mintValue: (state, card, my) -> 
    return card.cost - 1
  
  # Choose whether we want these cards or two random cards.
  oracleDiscardValue: (state, cards, my) ->
    deck = my.discard.concat(my.draw)
    shuffle(deck)
    randomCards = deck[0...cards.length]

    return my.ai.compareByDiscarding(state, my.hand.concat(randomCards), my.hand.concat(cards))

  # Choose to attack or use available coins when playing Pirate Ship.
  # Current strategy is basically Geronimoo's attackUntil5Coins play strategy,
  # but only with Provinces--or technically, cards costing 8 or more.
  pirateShipPriority: (state, my) -> [
    'coins' if state.current.mats.pirateShip >= 5 and state.current.getAvailableMoney()+state.current.mats.pirateShip >= 8
    'attack'
  ]
  
  # might want to think about something more clever, but for first, just discard Coppers
  plazaDiscardPriority: (state, my) -> [
    "Copper"
    null
  ]       

  rogueGainValue: (state, card, my) ->
    [coins, potions] = card.getCost(state)
    return coins

  rogueTrashValue: (state, card, my) ->
    [coins, potions] = card.getCost(state)
    return coins

  salvagerTrashPriority: (state, card, my) -> [
    "Border Village"
    "Mandarin"
    "Ill-Gotten Gains" if this.coinLossMargin(state) > 0
    "Feodum"
    "Salvager"
  ]
  
  # To calculate the salvagerTrashValue, we simulate trashing each card, determine
  # the best card we would buy as a result, and evaluate it as if we were
  # upgrading the trashed card into the bought one.
  salvagerTrashValue: (state, card, my) ->
    [hypothesis, hypothetically_my] = state.hypothetical(this)
    hypothetically_my.hand.remove(card)
    [coins, potions] = card.getCost(hypothesis)
    hypothetically_my.coins += coins
    hypothetically_my.buys += 1
    buyState = this.fastForwardToBuy(hypothesis, hypothetically_my)
    gained = buyState.getSingleBuyDecision()

    return this.upgradeValue(state, [card, gained], my)

  # Scheme uses the same priority function as multiplied actions.  Good actions
  # to multiply this turn are typically good actions to have around next turn.
  schemeValue: (state, card, my) ->
    # Project a little of what the state will look like at the beginning of the
    # next turn.  This keeps multipliedActionPriority from evaluating a card
    # as though it will be used in the current (finished) turn.
    myNext = {}
    myNext[key] = value for key, value of my
    myNext.actions = 1
    myNext.buys = 1
    myNext.coins = 0
    return this.getChoiceValue('multiplied', state, card, myNext)

  # `scryingPoolDiscardValue` is like `discardValue`, except it strongly
  # prefers to discard non-actions.
  scryingPoolDiscardValue: (state, card, my) ->
    if not card.isAction
      2000
    else
      this.choiceToValue('discard', state, card)

  spiceMerchantTrashPriority: (state, my) -> [
    "Copper",
    "Potion",
    "Loan",
    "Ill-Gotten Gains",
    "Fool's Gold" if my.countInDeck("Fool's Gold") == 1,
    "Silver" if my.getTotalMoney() >= 8,
    null,
    "Silver",
    "Venture",
    "Cache",
    "Gold",
    "Harem",
    "Platinum"
  ]

  # Which treasure, if any, should be discarded to feed Stables? Defaults
  # to a list of generally crappy treasures. Doesn't include $1 Fool's Gold
  # because you presumably have another one you're trying to draw.
  stablesDiscardPriority: (state, my) -> [
    "Copper"
    "Potion" if my.countInPlay(state.cardInfo["Alchemist"]) == 0
    "Ill-Gotten Gains"
    "Silver"
    "Horn of Plenty"
    null
    "Potion"
    "Venture"
    "Cache"
    "Gold"
    "Platinum"
  ]
   
  # Do you want to discard a Province to win a Tournament? The answer is
  # *very* yes.
  tournamentDiscardPriority: (state, my) -> [yes]

  transmuteValue: (state, card, my) ->
    if card.isAction and this.goingGreen(state)
      return 10
    else if card.isAction and card.isVictory and card.cost <= 4
      return 1000
    else
      return this.choiceToValue('trash', state, card)
  
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
  
  #### Trash-for-benefit decisions

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
  
  # developValue measures the benefit of choices Develop,
  # where you exchange one card for two.
  # 
  # So here's a really basic thing that might work.
  developValue: (state, choice, my) ->
    [oldCard, [newCard1, newCard2]] = choice
    return my.ai.cardInDeckValue(state, newCard1, my) + \
           my.ai.cardInDeckValue(state, newCard2, my) - \
           my.ai.cardInDeckValue(state, oldCard, my)  

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
  
  # How much do we want to overpay for Masterpiece?
  # If we care to buy it probably as much as possible
  #
  chooseOverpayMasterpiece: (state, maxAmount) ->
    return maxAmount

  # How many Coin Tokens do we want to spend?
  # Try to buy the 'best' card you can afford, and spend as less as possible for this
  #
  spendCoinTokens: (state, my) ->
    cardsBoughtOld = []
    ct = my.coinTokens      
    loop
      [hypState, hypMy] = state.hypothetical(this)
      
      hypMy.coins += ct
      hypMy.coinTokensSpendThisTurn = ct
      cardsBought = []
      while hypMy.buys > 0
        cardBought = hypState.getSingleBuyDecision()
        if cardBought?
          [coinCost, potionCost] = cardBought.getCost(hypState)
          hypMy.coins -= coinCost
          hypMy.potions -= potionCost
          cardsBought.push cardBought
        hypMy.buys -= 1
      if ((ct < my.coinTokens) and not (arrayEqual(cardsBought, cardsBoughtOld)))
        ct += 1
        break
      if ct == 0
        break
      ct -= 1
      cardsBoughtOld = cardsBought
    return ct

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

  # `wantsToPlayRats` is like `wantsToTrash` except that the answer is no.
  #
  # Come on, it's a first-order approximation of good strategy. If you've got
  # a better idea, put it in a strategy file.
  wantsToPlayRats: (state) -> no
  
  # `wantsToDiscard` returns the number of cards in hand that we would
  # freely discard.
  wantsToDiscard: (state) ->
    my = this.myPlayer(state)
    discardableCards = 0
    for card in my.hand
      if this.chooseDiscard(state, [card, null]) is card
        discardableCards += 1
    return discardableCards
  
  multiplierChoices: (state) ->
    my = this.myPlayer(state)
    mults = (card for card in my.hand when card.isMultiplier)
    if mults.length > 0
      mult = mults[0]
      choices = (card for card in my.hand when card.isAction)
      choices.remove(mult)
      choices.push(null)
      return choices
    else
      return []

  okayToPlayMultiplier: (state) ->
    choices = this.multiplierChoices(state)
    if this.choose('multiplied', state, choices)?
      return true
    else
      return false

  wantsToPlayMultiplier: (state) ->
    my = this.myPlayer(state)
    choices = this.multiplierChoices(state)
    if choices.length > 1
      choice = this.choose('multiplied', state, choices)
      multipliedValue = this.getChoiceValue('multiplied', state, choice, my)
      if choice? and choice.isMultiplier
        # prevent infinite loops
        unmultipliedValue = 0
      else
        unmultipliedValue = this.getChoiceValue('play', state, choice, my)
      return (multipliedValue > unmultipliedValue)
    return false
  
  # play Spoils if it changes your buys this turn.  Or if in hypothetical state to solve recursion
  wantsToPlaySpoils: (state) ->
    if state.depth > 0
      return true
    else
      cardsGainedWithout = this.pessimisticCardsGained(state)
      [hypState, hypMy] = state.hypothetical(this)
      hypState.current.hand.remove(c["Spoils"])
      cardsGainedWith = this.pessimisticCardsGained(hypState)
      if arrayEqual(cardsGainedWithout, cardsGainedWith)
        return false
      else
        return true
      
  # wantsToRebuild and rebuildPriority: taken from the Rebuild strategy
  wantsToRebuild: (state, my) ->
    if my.countInHand("Rebuild") >= state.countInSupply("Province") \
       and my.ai.getScoreDifference(state, my) > 0
          answer = 1
    else if state.countInSupply("Province") == 1 \
            and my.ai.getScoreDifference(state, my) < -4
              answer = 0
    else if state.countInSupply("Duchy") == 0 \
            and my.ai.countNotInHand(my, "Duchy") == 0\
            and my.ai.getScoreDifference(state, my) < 0
              answer = 0
    else if my.getTreasureInHand() > 7 and state.countInSupply("Province") == 1
              answer = 0
    else
          answer = state.countInSupply("Province") > 0
    return answer

  rebuildPriority: (state, my) -> [
    "Province"
    "Duchy"
    "Estate"
  ]

  nameVPPriority: (state, my) -> [
    "Colony" if my.countInDeck("Colony") > 0
    "Province"
  ]

  # Assume we always want to play Journeyman
  wantsToJM: (state, my) ->
    true
  
  wantsToDiscardBeggar: (state) ->
    return true
  
  # `goingGreen`: determine when we're playing for victory points. By default,
  # it's if there are any Colonies, Provinces, or Duchies in the deck.
  #
  # The bigger the number, the greener the deck, but a true (greater than 0)
  # value is a good indication in itself that we want victory cards.
  goingGreen: (state) ->
    my = this.myPlayer(state)
    bigGreen = my.countInDeck("Colony") + my.countInDeck("Province") + my.countInDeck("Duchy")
    return bigGreen
  
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
    
    return this.fastForwardToBuy(hypothesis, hypothetically_my)

  fastForwardToBuy: (state, my) ->
    if state.depth == 0
      throw new Error("Can only fast-forward in a hypothetical state")
    #We need to save draw and discard before emptying and restore them before buyPhase, to be able to choose the right buys in actionPriority(state)
    oldDraws   = my.draw.slice(0)
    oldDiscard = my.discard.slice(0)
    my.draw = []
    my.discard = []
    
    while state.phase != 'buy'
      state.doPlay()
      
    my.draw = oldDraws
    my.discard = oldDiscard

    return state
  
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
    coins = newState.current.coins
    cardToBuy = newState.getSingleBuyDecision()
    return 0 if cardToBuy is null
    [coinsCost, potionsCost] = cardToBuy.getCost(newState)
    return coins - coinsCost
  
  # coinGainMargin determines how much treasure the player wants to gain,
  # in order to get a better card. Tries up to +$8, then returns Infinity
  # if nothing changes.
  coinGainMargin: (state) ->
    newState = this.pessimisticBuyPhase(state)
    coins = newState.current.coins
    baseCard = newState.getSingleBuyDecision()
    for increment in [1, 2, 3, 4, 5, 6, 7, 8]
      newState.current.coins = coins+increment
      cardToBuy = newState.getSingleBuyDecision()
      if cardToBuy != baseCard
        return increment
    return Infinity
  
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
  # in priority order, until one of them gets to 2 or fewer cards.
  #
  # Returns a -1 or 1 that can be used in sorting; it's
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
      if hand1.length <= 2 and hand2.length <= 2
        state.current.actions = savedActions
        return 0      
      if hand1.length <= 2
        state.current.actions = savedActions
        return -1
      if hand2.length <= 2
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

  # Some functions need to check the actionPriority a lot. This pair of
  # methods will save a cached value so you don't need to run such an expensive
  # function over and over.
  cachedActionPriority: (state, my) ->
    my.ai.cachedAP
    
  cacheActionPriority: (state, my) ->
    @cachedAP = my.ai.actionPriority(state, my)

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
  
# compare Arrays
arrayEqual = (a, b) ->
  a.length is b.length and a.every (elem, i) -> elem is b[i]
