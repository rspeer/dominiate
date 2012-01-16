# Dominion cards and their effects are defined in this file.  Each card is a
# singleton, immutable object.

# We begin by creating the `c` object, an exported object with which one can 
# look up any card by its name.
c = {}
this.c = c
c.allCards = []

# Defining cards
# --------------
# Many cards are defined in terms of other cards using a pattern similar to
# inheritance, except without the classes. There is no need for classes because
# there are no separate instances.
# Each Copper is a reference to the same single Copper object, for example.
#
# The `makeCard` function will define a new card and add it to the card list.
# `makeCard` works by copying an existing card object and applying a few new
# properties to it.
# 
# `name` is the name of the card, which will be the card's string
# representation and the key that you look it up in the card list `c` by.
# 
# To define a card independently of any existing card, let `origCard` be the
# abstract card called `basicCard`. To define a card in terms of another card,
# let `origCard` be that card object (probably a member of `c`, such as
# `c.Estate`).
# 
# `props` are the properties of the card that differ from its parent.
# 
# `fake` is true when this should be an abstract card, not a card in the
# supply. Fake cards are simply returned, not added to `c`.

makeCard = (name, origCard, props, fake) ->
  newCard = {}
  for key, value of origCard
    newCard[key] = value
  newCard.name = name
  for key, value of props
    newCard[key] = value
  newCard.parent = origCard.name   # for debugging
  if not fake
    c[name] = newCard
    c.allCards.push(name)
  newCard

#### The basicCard object
# `basicCard` contains all the things that are true by default
# about a card, plus many useful methods that will be available on all cards.
# All other cards should have `basicCard` as an ancestor. Many of the
# properties and methods of `basicCard` are meant to be overridden in
# real cards.
basicCard = {
  # This set of boolean values defines a card's types. Cards may have any
  # number of types.
  isAction: false
  isTreasure: false
  isVictory: false
  isAttack: false
  isReaction: false
  isDuration: false
  isPrize: false
  isMultiplier: false

  # The **base cost** of a card is defined here. To find out what a card
  # *actually* costs, use the getCost() method.
  cost: 0
  costPotion: 0

  # These methods may be overridden by cards whose costs vary on their own,
  # particularly Peddler.
  costInCoins: (state) -> this.cost
  costInPotions: (state) -> this.costPotion
  
  # Card costs can change according to things external to the card, such as
  # bridges and quarries in play. Therefore, any code that wants to know the
  # actual cost of a card in a state should call `card.getCost(state)`.
  #
  # This method returns a list of two elements, which are the cost in
  # coins and the cost in potions.
  getCost: (state) ->
    coins = this.costInCoins(state)
    coins -= state.bridges
    coins -= state.highways
    coins -= state.princesses * 2
    if this.isAction
      coins -= state.quarries * 2
    if coins < 0
      coins = 0
    return [coins, this.costInPotions(state)]
  
  # These properties define simple, non-variable effects of playing a card.
  # They may only have constant numeric values.
  actions: 0
  cards: 0
  coins: 0
  buys: 0
  vp: 0
  trash: 0        # if the card requires trashing for no further effect

  # If a card has simple effects that *vary* based on the state, define
  # them by overriding these methods, which do take the state as a parameter.
  # The constant properties above will be ignored in that case, but you could
  # fill them in with reasonable guesses for the benefit of AI methods that
  # don't want to examine the state.
  getActions: (state) -> this.actions
  getCards: (state) -> this.cards
  getCoins: (state) -> this.coins
  getBuys: (state) -> this.buys
  getTrash: (state) -> this.trash
  getVP: (player) -> this.vp
  
  # getPotion says whether the card provides a potion. There is only one
  # card for which this is true, which is Potion.
  getPotion: (state) -> 0

  # Some cards (Grand Market) may not be bought in certain situations.
  # Use `cards.mayBeBought(state)` to define when. By default, a card may be
  # bought whenever it is in the supply.
  mayBeBought: (state) -> true

  # `card.startingSupply(state)` is called once for each card in the supply
  # at the start of the game, to determine how many of them go into the supply.
  # This is 10 by default, but some types of cards override it.
  startingSupply: (state) -> 10

  #### Complex effects
  # More complex effects of a card can be defined using arbitrary functions
  # that modify the state. These functions are no-ops in `basicCard`, and
  # may be overridden by cards that need them:

  # - What happens when the card is bought?
  buyEffect: (state) ->
  # - What happens when the card is gained?
  gainEffect: (state) ->
  # - What happens (besides the simple effects defined above) when the card is
  #   played?
  playEffect: (state) ->
  # - What happens when this card is in play and another card is gained?
  gainInPlayEffect: (state, card) ->
  # - What happens when this card is in play and another card is specifically
  #   bought?
  buyInPlayEffect: (state, card) ->
  # - What happens when this card is cleaned up from play?
  cleanupEffect: (state) ->
  # - What happens when the card is in play as a Duration at the start of
  #   the turn?
  durationEffect: (state) ->
  # - What happens when the card is shuffled into the draw deck?
  shuffleEffect: (state) ->
  # - What happens when this card is in hand and an opponent plays an attack?
  reactToAttack: (state, player) ->
  # - What happens when this card is in hand and its owner gains a card?
  reactToGain: (state, player, card) ->
  # - What happens when this card is in hand and someone else gains a card?
  reactToOpponentGain: (state, player, opponent, card) ->
  # - What happens when this card is discarded?
  reactToDiscard: (state, player) ->
  
  # This defines everything that happens when a card is played, including
  # basic effects and complex effects defined in `playEffect`. Cards
  # should not override `onPlay`; they should override `playEffect` instead.
  onPlay: (state) ->
    state.current.actions += this.getActions(state)
    state.current.coins += this.getCoins(state)
    state.current.potions += this.getPotion(state)
    state.current.buys += this.getBuys(state)
    cardsToDraw = this.getCards(state)
    cardsToTrash = this.getTrash(state)
    if cardsToDraw > 0
      state.drawCards(state.current, cardsToDraw)
    if cardsToTrash > 0
      state.requireTrash(state.current, cardsToTrash)
    this.playEffect(state)
  
  # Similarly, these are other ways for the game state to interact
  # with the card. Cards should override the `Effect` methods, not these.
  onDuration: (state) ->
    this.durationEffect(state)
  
  onCleanup: (state) ->
    this.cleanupEffect(state)

  onBuy: (state) ->
    this.buyEffect(state)
  
  onGain: (state, player) ->
    this.gainEffect(state, player)
  
  # A card's string representation is its name.
  #
  # If you have a value called
  # `card` that may be a string or a card object, you can ensure that it is
  # a card object by looking up `c[card]`.
  toString: () -> this.name
}

# Base cards
# ----------
# These are the cards that are not Kingdom cards. Most of them appear in every
# game; Potion, Platinum, and Colony appear in only some games.

makeCard 'Curse', basicCard, {
  # Curse is the only card with no type.
  cost: 0
  vp: -1
  startingSupply: (state) ->
    switch state.nPlayers
      when 1, 2 then 10
      when 3 then 20
      when 4 then 30
      when 5 then 40
      else 50
}

# To define victory cards, we define Estate and then derive other cards from
# it.
makeCard 'Estate', basicCard, {
  cost: 2
  isVictory: true
  vp: 1
  startingSupply: (state) ->
    switch state.nPlayers
      when 1, 2 then 8
      else 12 
}

makeCard 'Duchy', c.Estate, {
  cost: 5, vp: 3,
  
  # If Duchess is in the game, the player has the option of gaining it.
  gainEffect: (state, player) ->
    if state.supply['Duchess']?
      state.gainOneOf(player, [c.Duchess, null])
}
makeCard 'Province', c.Estate, {
  cost: 8
  vp: 6
  startingSupply: (state) ->
    switch state.nPlayers
      when 1, 2 then 8
      when 3, 4 then 12
      when 5 then 15
      else 18
}
makeCard 'Colony', c.Estate, {cost: 11, vp: 10}

# Now we define the basic treasure cards. Our prototypical card here is
# Silver.

makeCard 'Silver', basicCard, {
  cost: 3
  isTreasure: true
  coins: 2
  startingSupply: (state) -> 40
}

# Copper is actually more complex than Silver: its value can vary when modified
# by Coppersmith.
makeCard 'Copper', c.Silver, {
  cost: 0
  coins: 1
  getCoins: (state) -> state.copperValue ? 1
  startingSupply: (state) -> 60
}

makeCard 'Gold', c.Silver, {
  cost: 6
  coins: 3
  startingSupply: (state) -> 30
}

makeCard 'Platinum', c.Silver, {
  cost: 9,
  coins: 5,
  startingSupply: (state) -> 12
}
makeCard 'Potion', c.Silver, {
  cost: 4
  coins: 0
  # Deleted playEffect. Potions where counted twice.
  # OnPlay() already increases @current.potions via getPotion(state)
  getPotion: (state) -> 1
  startingSupply: (state) -> 16
}

# Vanilla cards
# -------------
#
# These cards have effects that involve no decisions, and are expressed entirely
# in +actions, +cards, +coins, +buys, and VP.
#
# Action cards may derive from the virtual card called `action`.
action = makeCard 'action', basicCard, {isAction: true}, true

makeCard 'Village', action, {cost: 3, actions: 2, cards: 1}
makeCard "Worker's Village", action, {
  cost: 4
  actions: 2
  cards: 1
  buys: 1
}
makeCard 'Laboratory', action, {cost: 5, actions: 1, cards: 2}
makeCard 'Smithy', action, {cost: 4, cards: 3}
makeCard 'Festival', action, {cost: 5, actions: 2, coins: 2, buys: 1}
makeCard 'Woodcutter', action, {cost: 3, coins: 2, buys: 1}
makeCard 'Market', action, {
  cost: 5, actions: 1, cards: 1, coins: 1, buys: 1
}
makeCard 'Bazaar', action, {
  cost: 5, actions: 2, cards: 1, coins: 1
}

# Kingdom Victory cards
# ---------------------
# These cards are all derived from Estate to insure their starting supply
# amount is correct. This goes for multi-type Victory cards too--deriving Great Hall
# from action instead of Estate results in 10 Great Halls in the supply instead of
# 8 for a 2-player game or 12 for more players.

makeCard 'Duke', c.Estate, {
  cost: 5
  getVP: (player) -> player.countInDeck('Duchy')
}

makeCard 'Fairgrounds', c.Estate, {
  cost: 6
  getVP: (player) ->
    unique = []
    deck = player.getDeck()
    for card in deck
      if card not in unique
        unique.push(card)
    2 * Math.floor(unique.length / 5)    
}

makeCard 'Farmland', c.Estate, {
  cost: 6
  vp: 2

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 == potions2) and (coins1 + 2 == coins2)

  buyEffect: (state) ->
    choices = upgradeChoices(state, state.current.hand, this.upgradeFilter)
    choice = state.current.ai.choose('upgrade', state, choices)
    if choice isnt null
      [oldCard, newCard] = choice
      state.doTrash(state.current, oldCard)
      state.gainCard(state.current, newCard)    
}


makeCard 'Gardens', c.Estate, {
  cost: 4
  getVP: (player) -> Math.floor(player.getDeck().length / 10)
}

makeCard 'Great Hall', c.Estate, {
  isAction: true
  cost: 3
  cards: +1
  actions: +1
}

makeCard 'Harem', c.Estate, {
  isTreasure: true
  cost: 6
  coins: 2
  vp: 2
}

makeCard 'Island', c.Estate, {
  isAction: true
  cost: 4
  vp: 2

  playEffect: (state) ->
    if state.current.hand.length == 0 # handle a weird edge case
      state.log("…setting aside the Island (no other cards in hand).")
    else
      card = state.current.ai.choose('island', state, state.current.hand)
      state.log("…setting aside the Island and a #{card}.")
      state.current.hand.remove(card)
      state.current.mats.island.push(card)

    # removing the Island from play is conditional so it won't break with 
    # Throne Room and King's Court
    if this in state.current.inPlay
      state.current.inPlay.remove(this)
      state.current.mats.island.push(this)
}

makeCard 'Nobles', c.Estate, {
  isAction: true
  cost: 6
  vp: 2

  # Nobles is an example of a card that allows a choice from multiple
  # simple effects. We implement this using the `choose('benefit')` AI method,
  # which is passed a list of benefit objects, one of which it will choose
  # to apply to the state.
  playEffect:
    (state) ->
      benefit = state.current.ai.choose('benefit', state, [
        {actions: 2},
        {cards: 3}
      ])
      applyBenefit(state, benefit)
}

makeCard 'Silk Road', c.Estate, {
  cost: 4
  getVP: (player) -> Math.floor(player.countCardTypeInDeck('Victory') / 4)
}

# Revealing Tunnel for Gold as it is discarded is automatic.
# TODO: make this into a decision.
makeCard 'Tunnel', c.Estate, {
  isReaction: true
  cost: 3
  vp: 2

  reactToDiscard: (state, player) ->
    if state.phase isnt 'cleanup'
      state.log("#{player.ai} gains a Gold for discarding the Tunnel.")
      state.gainCard(player, c.Gold)
    
}

makeCard 'Vineyard', c.Estate, {
  cost: 0
  costPotion: 1
  getVP: (player) -> Math.floor(player.numActionCardsInDeck() / 3)
}

# Kingdom Treasure cards
# ----------------------
# Kingdom cards that are also treasure cards derive from treasure, which
# derives from Silver, but with a changed startingSupply.

treasure = makeCard 'treasure', c.Silver, {startingSupply: (state) -> 10}, true

makeCard 'Bank', treasure, {
  cost: 7
  getCoins: (state) ->
    coins = 0
    for card in state.current.inPlay
      if card.isTreasure
        coins += 1
    coins
  playEffect: (state) ->
    state.log("...which is worth #{this.getCoins(state)}.")
}

makeCard 'Cache', treasure, {
  cost: 5
  coins: 3
  
  gainEffect: (state) ->
    state.gainCard(state.current, c.Copper)
    state.gainCard(state.current, c.Copper)
}

makeCard "Fool's Gold", treasure, {
  isReaction: true
  cost: 2
  coins: 1
  
  getCoins: (state) ->
    if state.current.foolsGoldInPlay
      4
    else
      1
  
  playEffect: (state) ->
    state.current.foolsGoldInPlay = true

  reactToOpponentGain: (state, player, opp, card) ->
    if card is c.Province
      if player.ai.choose('foolsGoldTrash', state, [yes, no])
        state.doTrash(player, this)
        state.gainCard(player, c.Gold, 'draw')
        state.log("...putting the Gold on top of the draw pile.")
}

makeCard "Hoard", treasure, {
  cost: 6
  buyInPlayEffect: (state, card) ->
    if card.isVictory
      state.gainCard(state.current, c.Gold, 'discard', true)
      state.log("...gaining a Gold.")
}

makeCard "Horn of Plenty", treasure, {
  cost: 5
  coins: 0
  playEffect: (state) -> 
    limit = state.current.numUniqueCardsInPlay()
    choices = []
    for cardName of state.supply
      card = c[cardName]
      [coins, potions] = card.getCost(state)
      if state.supply[cardName] > 0 and potions == 0 and coins <= limit
        choices.push(card)
    choice = state.gainOneOf(state.current, choices)
    if choice.isVictory
      transferCard(this, state.current.inPlay, state.trash)
      state.log("...#{state.current.ai} trashes the Horn of Plenty.")
}

makeCard 'Ill-Gotten Gains', treasure, {
  cost: 5
  coins: 1
  playEffect: (state) -> 
    if state.current.ai.choose('gainCopper', state, [yes, no])
      state.gainCard(state.current, c.Copper, 'hand')
  
  gainEffect: (state) ->
    # For each player but the current: gain a curse.
    for i in [1...state.nPlayers]
      state.gainCard(state.players[i], c.Curse)
}

makeCard 'Loan', treasure, {
  coins: 1
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isTreasure
    )    
    if drawn.length > 0
      treasure = drawn[0]
      trash = state.current.ai.choose('trash', state, [treasure, null])
      if trash?
        state.log("...trashing the #{treasure}.")
        transferCard(treasure, drawn, state.trash)
      else
        state.log("...discarding the #{treasure}.")
        state.current.discard.push(treasure)
        state.handleDiscards(state.current, [treasure])
}

makeCard "Philosopher's Stone", treasure, {
  cost: 3
  costPotion: 1
  getCoins: (state) ->
    Math.floor((state.current.draw.length + state.current.discard.length) / 5)
  playEffect: (state) ->
    state.log("...which is worth #{this.getCoins(state)}.")
}

makeCard 'Quarry', treasure, {
  cost: 4
  coins: 1
  playEffect: (state) -> state.quarries += 1
}

makeCard 'Royal Seal', treasure, {
  cost: 5
  gainInPlayEffect: (state, card) ->
    player = state.current
    return if player.gainLocation == 'trash'
    source = player[player.gainLocation]
    if player.ai.choose('gainOnDeck', state, [card, null])
      state.log("...putting the #{card} on top of the deck.")
      player.gainLocation = 'draw'
      transferCardToTop(card, source, player.draw)
}

makeCard 'Talisman', treasure, {
  cost: 4
  coins: 1
  buyInPlayEffect: (state, card) ->
    if card.getCost(state)[0] <= 4 and not card.isVictory
      state.gainCard(state.current, card, 'discard', true)
      state.log("...gaining a #{card}.")
}

makeCard 'Venture', treasure, {
  cost: 5
  coins: 1
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isTreasure
    )
    if drawn.length > 0
      treasure = drawn[0]
      state.log("...playing #{treasure}.")
      state.current.inPlay.push(treasure)
      treasure.onPlay(state)
}

# Duration cards
# --------------
# These cards have additional properties, such as `durationActions`, defining
# constant effects that happen when the card is resolved as a duration card.
# The virtual card `duration` specifies how to process these effects.
duration = makeCard 'duration', action, {
  durationActions: 0
  durationBuys: 0
  durationCoins: 0
  durationCards: 0
  isDuration: true

  durationEffect:
    (state) ->
      state.current.actions += this.durationActions
      state.current.buys += this.durationBuys
      state.current.coins += this.durationCoins
      if this.durationCards > 0
        state.drawCards(state.current, this.durationCards)
}, true

makeCard 'Haven', duration, {
  cost: 2
  cards: +1
  actions: +1
  
  playEffect: (state) ->
    cardInHaven = state.current.ai.choose('putOnDeck', state, state.current.hand)
    if cardInHaven?
      state.log("#{state.current.ai} sets aside a #{cardInHaven} with Haven.")
      transferCard(cardInHaven, state.current.hand, state.current.setAsideByHaven)
    else
      if state.current.hand.length==0
        state.log("#{state.current.ai} has no cards to set aside.")
      else
        state.warn("hand not empty but no card set aside")
  
  durationEffect: (state) ->
    cardFromHaven = state.current.setAsideByHaven.pop()
    if cardFromHaven?
      state.log("#{state.current.ai} picks up a #{cardFromHaven} from Haven.")
      state.current.hand.unshift(cardFromHaven)
}

makeCard 'Caravan', duration, {
  cost: 4
  cards: +1
  actions: +1
  durationCards: +1
}

makeCard 'Fishing Village', duration, {
  cost: 3
  coins: +1
  actions: +2
  durationActions: +1
  durationCoins: +1
}

makeCard 'Wharf', duration, {
  cost: 5
  cards: +2
  buys: +1
  durationCards: +2
  durationBuys: +1
}

makeCard 'Merchant Ship', duration, {
  cost: 5
  coins: +2
  durationCoins: +2
}

makeCard 'Lighthouse', duration, {
  cost: 2
  actions: +1
  coins: +1
  durationCoins: +1

  # The protecting effect is defined in gameState.
}

makeCard 'Outpost', duration, {
  cost: 5
  #effect implemented by gameState
} 

makeCard 'Tactician', duration, {
  cost: 5
  durationActions: +1
  durationBuys: +1
  durationCards: +5

  playEffect: (state) ->
    cardsInHand = state.current.hand.length
    # If any cards can be discarded...
    if cardsInHand > 0
      # Discard the hand and activate the tactician.
      state.log("...discarding the whole hand.")
      state.current.tacticians++
      discards = state.current.hand
      state.current.discard = state.current.discard.concat(discards)
      state.current.hand = []
      state.handleDiscards(state.current, discards)
  
  # The cleanupEffect of a dead Tactician is to discard it instead of putting it in the
  # duration area. It's not a duration card in this case.
  cleanupEffect: (state) ->
    if state.current.tacticians > 0
      state.current.tacticians--
    else
      state.log("#{state.current.ai} discards an inactive Tactician.")
      transferCard(c.Tactician, state.current.duration, state.current.discard)
      state.handleDiscards(state.current, [c.Tactician])
}

# Trash-for-gain cards
# --------------------
# This section describes the actions where you trash one card to gain another.
# I refer to this in general as "upgrading", which is not meant to be specific
# to the card Upgrade.
# 
# The prototype on which we base these cards is Remodel. Most of the other
# cards are variants that simply change the filter for which upgrades are
# possible.
makeCard 'Remodel', action, {
  cost: 4

  exactCostUpgrade: false
  costFunction: (coins) -> coins + 2

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    if this.exactCostUpgrade
      return (potions1 >= potions2) and (this.costFunction(coins1) == coins2)
    else
      return (potions1 >= potions2) and (this.costFunction(coins1) >= coins2)

  playEffect: (state) ->
    choices = upgradeChoices(state, state.current.hand, this.upgradeFilter.bind(this))
    if this.exactCostUpgrade
      choices2 = nullUpgradeChoices(state, state.current.hand, this.costFunction.bind(this))
      choices = choices.concat(choices2)

    choice = state.current.ai.choose('upgrade', state, choices)
    if choice isnt null
      [oldCard, newCard] = choice
      state.doTrash(state.current, oldCard)
      if newCard isnt null
        state.gainCard(state.current, newCard)
}

makeCard 'Expand', c.Remodel, {
  cost: 7

  costFunction: (coins) -> coins + 3
}

makeCard 'Upgrade', c.Remodel, {
  cost: 5
  actions: +1
  cards: +1

  exactCostUpgrade: true
  costFunction: (coins) -> coins + 1
}

makeCard 'Remake', c.Remodel, {
  exactCostUpgrade: true
  costFunction: (coins) -> coins + 1

  playEffect: (state) ->
    for i in [1..2]
      choices = upgradeChoices(state, state.current.hand, this.upgradeFilter.bind(this))
      choices2 = nullUpgradeChoices(state, state.current.hand, this.costFunction.bind(this))
      choice = state.current.ai.choose('upgrade', state, choices.concat(choices2))
      if choice isnt null
        [oldCard, newCard] = choice
        state.doTrash(state.current, oldCard)
        if newCard isnt null
          state.gainCard(state.current, newCard)  
}

makeCard 'Mine', c.Remodel, {
  cost: 5

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 >= potions2) and (coins1 + 3 >= coins2) \
       and oldCard.isTreasure and newCard.isTreasure
  
  # Modify the Remodel playEffect so that it gains the card in hand.
  playEffect: (state) ->
    choices = upgradeChoices(state, state.current.hand, this.upgradeFilter.bind(this))
    choice = state.current.ai.choose('upgrade', state, choices)
    if choice isnt null
      [oldCard, newCard] = choice
      state.doTrash(state.current, oldCard)
      state.gainCard(state.current, newCard, 'hand')
}

# Prize cards
# -----------
# Because Prize cards can only be gained through Tournament, and all have
# cost = 0, startingSupply -> 0, and mayBeBought -> false it is useful to
# have a prototype prize. The prototype has isAction: true since 4 of the 5
# prizes are action cards.

prize = makeCard 'prize', basicCard, {
  cost: 0
  isPrize: true
  isAction: true
  mayBeBought: (state) -> false
  startingSupply: (state) -> 0
}, true

makeCard 'Bag of Gold', prize, {
  actions: +1 
  playEffect: (state) ->
    state.gainCard(state.current, c.Gold, 'draw')
    state.log("...putting the Gold on top of the deck.")
}

makeCard 'Diadem', prize, {
  isAction: false
  isTreasure: true 
  getCoins: (state) -> 2 + state.current.actions
}

makeCard 'Followers', prize, {
  cards: +2
  isAttack: true
  playEffect: (state) ->
    state.gainCard(state.current, c.Estate)
    state.attackOpponents (opp) ->
      state.gainCard(opp, c.Curse)
      if opp.hand.length > 3
        state.requireDiscard(opp, opp.hand.length - 3)
}

# Since there is only one Princess card, and Princess's cost
# reduction effect has the clause "while this is in play",
# state.princesses will never need to be greater than 1.
makeCard 'Princess', prize, {
  buys: 1
  playEffect:
    (state) ->
      state.princesses = 1
}

makeCard 'Trusty Steed', prize, {
  playEffect: (state) ->
    benefit = state.current.ai.choose('benefit', state, [
      {cards: 2, actions: 2},
      {cards: 2, coins: 2},
      {actions: 2, coins: 2},
      {cards: 2, horseEffect: yes},
      {actions: 2, horseEffect: yes},
      {coins: 2, horseEffect: yes}
    ])
    applyBenefit(state, benefit)
}

# Attack cards
# ------------
# Cards with the type Attack; their prototype is just used so
# isAttack: true doesn't need to be rewritten every time.

attack = makeCard 'attack', action, {isAttack: true}, true

makeCard 'Ambassador', attack, {
  cost: 3

  playEffect: (state) ->
    # Determine the cards and quantities that can be ambassadored
    counts = {}
    for card in state.current.hand
      counts[card] ?= 0
      counts[card] += 1
    choices = []
    for card, count of counts
      if count >= 2
        choices.push [card, 2]
      if count >= 1
        choices.push [card, 1]
      choices.push [card, 0]

    choice = state.current.ai.choose('ambassador', state, choices)

    if choice isnt null
      [cardName, quantity] = choice
      card = c[cardName]
      state.log("...choosing to return #{quantity} #{cardName}.")
      if state.supply[card]?
        for i in [0...quantity]
          state.current.hand.remove(card)
        # Return it to the supply, if it had a slot in the supply to begin with
        state.supply[card] += quantity
        state.attackOpponents (opp) ->
          state.gainCard(opp, card)
      else
        state.log("...but #{cardName} is not in the Supply.")
}

makeCard 'Bureaucrat', attack, {
  cost: 4
  playEffect: (state) ->
    state.gainCard(state.current, c.Silver, 'draw')
    state.attackOpponents (opp) ->
      victory = []
      if not opp.hand?
        state.log(opp)
        throw new Error("#{opp} has no hand attribute")
      for card in opp.hand
        if card.isVictory
          victory.push(card)
      if victory.length == 0
        state.revealHand(opp)
        state.log("#{opp.ai} reveals a hand with no Victory cards.")
      else
        choice = opp.ai.choose('putOnDeck', state, victory)
        transferCardToTop(choice, opp.hand, opp.draw)
        state.log("#{opp.ai} returns #{choice} to the top of the deck.")
}

makeCard 'Cutpurse', attack, {
  cost: 4
  coins: +2
  playEffect: (state) ->
      state.attackOpponents (opp) ->
        if c.Copper in opp.hand
          state.doDiscard(opp, c.Copper)
        else
          state.log("#{opp.ai} has no Copper in hand.")
          state.revealHand(opp)
}

makeCard 'Familiar', attack, {
  cost: 3
  costPotion: 1
  cards: +1
  actions: +1
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.gainCard(opp, c.Curse)
}

makeCard 'Fortune Teller', attack, {
  cost: 3
  coins: +2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      drawn = opp.dig(state,
        (state, card) -> card.isVictory or card is c.Curse
      )
      if drawn.length > 0
        card = drawn[0]
        transferCardToTop(card, drawn, opp.draw)
        state.log("...#{opp.ai} puts #{card} on top of the deck.")
}

makeCard 'Ghost Ship', attack, {
  cost: 5
  cards: +2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      while opp.hand.length > 3
        # Choosing cards one at a time does not necessarily lead to the
        # best decision. However, it leads to a reasonable, quick decision when
        # there could be a very large number of nearly-identical options
        # to evaluate, which is good for a simulator.
        choices = opp.hand
        putBack = opp.ai.choose('putOnDeck', state, choices)
        state.log("...#{opp.ai} puts #{putBack} on top of the deck.")
        transferCardToTop(putBack, opp.hand, opp.draw)
}

makeCard 'Jester', attack, {
  cost: 5
  coins: +2

  playEffect: (state) ->
    state.attackOpponents (opp) ->
      card = state.discardFromDeck(opp, 1)[0]
      if card?
        if card.isVictory
          state.gainCard(opp, c.Curse)
        else if state.current.ai.chooseGain(state, [card, null])
          state.gainCard(state.current, card)
        else
          state.gainCard(opp, card)
}

makeCard 'Margrave', attack, {
  cost: 5
  cards: +3
  buys: +1
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.drawCards(opp, 1)
      if opp.hand.length > 3
        state.requireDiscard(opp, opp.hand.length - 3)
}

makeCard "Militia", attack, {
  cost: 4
  coins: +2
  # Militia is a straightforward example of an attack card.
  #
  # All attack effects are wrapped in the `state.attackOpponents`
  # method, to give opponents a chance to play reaction cards.
  playEffect:
    (state) ->
      state.attackOpponents (opp) ->
        if opp.hand.length > 3
          state.requireDiscard(opp, opp.hand.length - 3)
}

makeCard "Goons", c.Militia, {
  cost: 6
  buys: +1

  buyInPlayEffect: (state, card) ->
    state.log("...getting +1 ▼.")
    state.current.chips += 1
}

makeCard "Minion", attack, {
  cost: 5
  actions: +1

  discardAndDraw4: (state, player) ->
    state.log("#{player.ai} discards the hand.")
    discarded = player.hand
    Array::push.apply(player.discard, discarded)
    player.hand = []
    state.handleDiscards(player, discarded)
    return state.drawCards(player, 4)

  playEffect: (state) ->
    player = state.current
    if player.ai.choose('minionDiscard', state, [yes, no])
      c['Minion'].discardAndDraw4(state, player)
      state.attackOpponents (opp) ->
        c['Minion'].discardAndDraw4(state, opp)
    else
      state.attackOpponents (opp) -> null
      player.coins += 2
}

makeCard "Mountebank", attack, {
  cost: 5
  coins: +2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      if c.Curse in opp.hand
        # Discarding a Curse against Mountebank is automatic.
        state.doDiscard(opp, c.Curse)
      else
        state.gainCard(opp, c.Copper)
        state.gainCard(opp, c.Curse)
}

# Because attacking on buy does not count as playing an Attack, Noble Brigand's
# buyEffect and playEffect cannot directly borrow from each other: the buyEffect
# should not be blockable by Moat, so it cannot just call the playEffect, and
# stat.attackOpponents needs an opp parameter, but buyEffect does not have an opp
# parameter. So a third method is defined which takes both the state and opp as
# parameters, and is accessed by both the buyEffect and the playEffect.
makeCard 'Noble Brigand', attack, {
  cost: 4
  coins: +1
  
  buyEffect: (state) ->
    for opp in state.players[1..]
      c['Noble Brigand'].robTheRich(state, opp)
    
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      c['Noble Brigand'].robTheRich(state, opp)
      
  robTheRich: (state, opp) ->
    drawn = opp.getCardsFromDeck(2)
    state.log("...#{opp.ai} reveals #{drawn}.")
    silversAndGolds = []
    gainCopper = true
    for card in drawn
      if card.isTreasure
        gainCopper = false
        if card is c.Gold or card is c.Silver
          silversAndGolds.push(card)
    treasureToTrash = state.current.ai.choose('trashOppTreasure', state, silversAndGolds)
    if treasureToTrash
      state.log("...#{state.current.ai} trashes #{opp.ai}'s #{treasureToTrash}.")
      transferCard(treasureToTrash, drawn, state.trash)
      transferCard(treasureToTrash, state.trash, state.current.discard)
      state.handleGainCard(state.current, treasureToTrash, 'discard')
      state.log("...#{state.current.ai} gains the trashed #{treasureToTrash}.")
    if gainCopper
      state.gainCard(opp, c.Copper)
    opp.discard = opp.discard.concat(drawn)
    state.handleDiscards(opp, [drawn])
    state.log("...#{opp.ai} discards #{drawn}.")     
}

makeCard 'Oracle', attack, {
  cost: 3

  playEffect: (state) ->
    player = state.current
    myCards = state.getCardsFromDeck(player, 2)
    if player.ai.oracleDiscardValue(state, myCards, player) > 0
      state.log("...discarding #{myCards}.")
      Array::push.apply(player.discard, myCards)
    else
      state.log("...keeping #{myCards} on top of the deck.")
      Array::unshift.apply(player.draw, myCards)
    
    state.attackOpponents (opp) ->
      cards = state.getCardsFromDeck(opp, 2)
      # Can't use oracleDiscardValue because it's a different situation, and
      # we don't know what's in the opponent's hand.

      value = 0
      for card in cards
        value += player.ai.choiceToValue('discardFromOpponentDeck', state, card)
      if value > 0
        state.log("#{player.ai} discards #{cards} from #{opp.ai}'s deck.")
        Array::push.apply(opp.discard, cards)
      else
        state.log("#{player.ai} leaves #{cards} on #{opp.ai}'s deck.")
        Array::unshift.apply(opp.draw, cards)

    state.drawCards(player, 2)
}

makeCard 'Pirate Ship', attack, {
  cost: 4

  playEffect: (state) ->
    choice = state.current.ai.choose('pirateShip', state, ['coins','attack'])
    if choice is 'coins'
      state.attackOpponents (opp) -> null
      state.current.coins += state.current.mats.pirateShip
      state.log("...getting +$#{state.current.mats.pirateShip}.")
    else if choice is 'attack'
      state.log("...attacking the other players.")
      attackSuccess = false

      state.attackOpponents (opp) ->
        drawn = opp.getCardsFromDeck(2)
        state.log("...#{opp.ai} reveals #{drawn}.")
        drawnTreasures = []
        for card in drawn
          if card.isTreasure
            drawnTreasures.push(card)
        treasureToTrash = state.current.ai.choose('trashOppTreasure', state, drawnTreasures)
        if treasureToTrash
          attackSuccess = true
          transferCard(treasureToTrash, drawn, state.trash)
          state.log("...#{state.current.ai} trashes #{opp.ai}'s #{treasureToTrash}.")
        opp.discard = opp.discard.concat(drawn)
        state.handleDiscards(opp, drawn)
        state.log("...#{opp.ai} discards #{drawn}.")
        
      if attackSuccess
        state.current.mats.pirateShip += 1
        state.log("...#{state.current.ai} takes a Coin token (#{state.current.mats.pirateShip} on the mat).")
}

makeCard 'Rabble', attack, {
  cost: 5
  cards: +3
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      drawn = opp.getCardsFromDeck(3)
      state.log("#{opp.ai} draws #{drawn}.")

      for card in drawn
        if card.isTreasure or card.isAction
          opp.discard.push(card)
          state.log("...discarding #{card}.")
          state.handleDiscards(opp, [card])
        else
          opp.setAside.push(card)
      
      if opp.setAside.length > 0
        order = opp.ai.chooseOrderOnDeck(state, opp.setAside, opp)
        state.log("...putting #{order} back on the deck.")
        opp.draw = order.concat(opp.draw)
        opp.setAside = []
}

makeCard 'Saboteur', attack, {
  cost: 5
  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 >= potions2) and (coins1-2 >= coins2)
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      drawn = opp.dig(state,
        (state, card) -> card.getCost(state)[0] >= 3                      
      )
      if drawn.length > 0
        cardToTrash = drawn[0]
        state.log("...#{state.current.ai} trashes #{opp.ai}'s #{cardToTrash}.")
        state.trash.push(drawn[0])
        choices = upgradeChoices(state, drawn, c.Saboteur.upgradeFilter)
        choices.push([cardToTrash,null])
        choice = opp.ai.choose('upgrade', state, choices)
        newCard = choice[1]
        if newCard?
          state.gainCard(opp, newCard, 'discard', true)
          state.log("...#{opp.ai} gains #{newCard}.")
        else
          state.log("...#{opp.ai} gains nothing.")
}

makeCard 'Scrying Pool', attack, {
  cost: 2
  costPotion: 1
  actions: +1

  playEffect: (state) ->
    spyDecision(state.current, state.current, state, 'scryingPoolDiscard')

    state.attackOpponents (opp) ->
      spyDecision(state.current, opp, state, 'discardFromOpponentDeck')
    
    loop
      drawn = state.drawCards(state.current, 1)[0]
      break if (not drawn?) or (not drawn.isAction)
}

makeCard 'Sea Hag', attack, {
  cost: 4
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.discardFromDeck(opp, 1)
      state.gainCard(opp, c.Curse, 'draw')
      state.log("...putting the Curse on top of the deck.")
}

makeCard 'Spy', attack, {
  cost: 4
  cards: +1
  actions: +1

  playEffect: (state) ->
    spyDecision(state.current, state.current, state, 'discard')

    state.attackOpponents (opp) ->
      spyDecision(state.current, opp, state, 'discardFromOpponentDeck')
}

makeCard 'Thief', attack, {
  cost: 4
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      drawn = opp.getCardsFromDeck(2)
      state.log("...#{opp.ai} reveals #{drawn}.")
      drawnTreasures = []
      for card in drawn
        if card.isTreasure
          drawnTreasures.push(card)
      treasureToTrash = state.current.ai.choose('trashOppTreasure', state, drawnTreasures)
      if treasureToTrash
        state.log("...#{state.current.ai} trashes #{opp.ai}'s #{treasureToTrash}.")
        transferCard(treasureToTrash, drawn, state.trash)

        cardToGain = state.current.ai.chooseGain(state, [treasureToTrash, null])
        if cardToGain
          transferCard(cardToGain, state.trash, state.current.discard)
          state.handleGainCard(state.current, cardToGain, 'discard')
          state.log("...#{state.current.ai} gains the trashed #{treasureToTrash}.")
      opp.discard = opp.discard.concat(drawn)
      state.handleDiscards(opp, [drawn])
      state.log("...#{opp.ai} discards #{drawn}.")
}

makeCard 'Torturer', attack, {
  cost: 5
  cards: +3
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      if opp.ai.choose('torturer', state, ['curse', 'discard']) == 'curse'
        state.gainCard(opp, c.Curse, 'hand')
      else
        state.requireDiscard(opp, 2)
}

makeCard 'Witch', attack, {
  cost: 5
  cards: +2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.gainCard(opp, c.Curse)
}

makeCard 'Young Witch', attack, {
  cost: 4
  cards: +2
  playEffect: (state) ->
    state.requireDiscard(state.current, 2)
    state.attackOpponents (opp) ->
      if state.bane in opp.hand
        state.log("#{opp.ai} is protected by the Bane card, #{state.bane}.")
      else
        state.gainCard(opp, c.Curse)
    
}

# Miscellaneous cards
# -------------------
# All of these cards have effects beyond what can be expressed with a
# simple formula, which are generally defined by overriding the complex
# methods such as `playEffect`.

makeCard 'Adventurer', action, {
  cost: 6
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isTreasure,
      2
    )
    if drawn.length > 0
      treasures = drawn
      state.current.hand = state.current.hand.concat(treasures)
      state.log("...#{state.current.ai} draws #{treasures}.")
}

makeCard 'Alchemist', action, {
  cost: 3
  costPotion: 1
  actions: +1
  cards: +2

  cleanupEffect:
    (state) ->
      if c.Potion in state.current.inPlay
        transferCardToTop(c.Alchemist, state.current.discard, state.current.draw)
}

makeCard 'Apothecary', action, {
  cost: 2
  costPotion: 1
  cards: +1
  actions: +1

  playEffect: (state) ->
    drawn = state.getCardsFromDeck(state.current, 4)

    # Sort the cards into coppers and potions, which go to the hand,
    # and others, which go temporarily to the setAside pile.
    state.log("...drawing #{drawn}.")
    for card in drawn
      if card is c.Copper or card is c.Potion
        state.current.hand.push(card)
        state.log("...putting #{card} in the hand.")
      else
        state.current.setAside.push(card)
    
    if state.current.setAside.length > 0
      order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current)
      state.log("...putting #{order} back on the deck.")
      state.current.draw = order.concat(state.current.draw)
      state.current.setAside = []
}

makeCard 'Apprentice', action, {
  cost: 5
  actions: +1

  playEffect: (state) ->
    toTrash = state.current.ai.choose('apprenticeTrash', state, state.current.hand)
    if toTrash?
      [coins, potions] = toTrash.getCost(state)
      state.doTrash(state.current, toTrash)
      state.drawCards(state.current, coins+2*potions)
}

makeCard 'Baron', action, {
  cost: 4
  buys: +1
  playEffect: (state) ->
    discardEstate = no
    if c.Estate in state.current.hand
      discardEstate = state.current.ai.choose('baronDiscard', state, [yes, no])
    if discardEstate
      state.doDiscard(state.current, c.Estate)
      state.current.coins += 4
    else
      state.gainCard(state.current, c.Estate)
}

makeCard 'Bishop', action, {
  cost: 4
  coins: +1

  playEffect: (state) ->
    toTrash = state.current.ai.choose('bishopTrash', state, state.current.hand)
    state.current.chips += 1
    state.log("...gaining 1 VP.")
    if toTrash?
      state.doTrash(state.current, toTrash)
      [coins, potions] = toTrash.getCost(state)
      vp = Math.floor(coins/2)
      state.log("...gaining #{vp} VP.")
      state.current.chips += vp

    for opp in state.players[1...]
      state.allowTrash(opp, 1)
}

makeCard 'Border Village', c.Village, {
  cost: 6

  gainEffect: (state, player) ->
    choices = []
    [myCoins, myPotions] = c['Border Village'].getCost(state)
    for card of state.supply
      if state.supply[card] > 0
        [coins, potions] = c[card].getCost(state)
        if potions <= myPotions and coins < myCoins
          choices.push(c[card])
    state.gainOneOf(player, choices)
}

makeCard 'Bridge', action, {
  cost: 4
  coins: 1
  buys: 1
  playEffect:
    (state) ->
      state.bridges += 1
}

makeCard 'Cartographer', action, {
  cost: 5
  cards: +1
  actions: +1

  playEffect: (state) ->
    player = state.current
    revealed = player.getCardsFromDeck(4)
    kept = []
    state.log("#{player.ai} reveals #{revealed} from the deck.")
    while revealed.length
      card = revealed.pop()
      if player.ai.choose('discard', state, [card, null])
        state.log("#{player.ai} discards #{card}.")
        player.discard.push(card)
        state.handleDiscards(player, [card])
      else
        kept.push(card)
    order = player.ai.chooseOrderOnDeck(state, kept, player)
    state.log("#{player.ai} puts #{order} back on the deck.")
    player.draw = order.concat(player.draw)
}

makeCard 'Cellar', action, {
  cost: 2
  actions: 1
  playEffect: (state) ->
    startingCards = state.current.hand.length
    state.allowDiscard(state.current, Infinity)
    numDiscarded = startingCards - state.current.hand.length
    state.drawCards(state.current, numDiscarded)
}

makeCard 'Chancellor', action, {
  cost: 3
  coins: +2

  playEffect: (state) ->
    player = state.current
    # The AI has the option of reshuffling. Ask directly if it'll take it.
    if player.ai.choose('reshuffle', state, [yes, no])
      state.log("...putting the draw pile into the discard pile.")
      draw = player.draw.slice(0)
      player.draw = []
      player.discard = player.discard.concat(draw)
      state.handleDiscards(state.current, draw)
}

makeCard 'Chapel', action, {
  cost: 2
  playEffect:
    (state) ->
      state.allowTrash(state.current, 4)
}

makeCard 'City', action, {
  cost: 5
  actions: +2
  cards: +1
  
  getCards: (state) ->
    if state.numEmptyPiles() >= 1
      2
    else
      1
  
  getBuys: (state) ->
    if state.numEmptyPiles() >= 2
      1
    else
      0
  
  getCoins: (state) ->
    if state.numEmptyPiles() >= 2
      1
    else
      0
}

makeCard 'Conspirator', action, {
  cost: 4
  coins: 2
  # don't count Duration cards because they're not "played this turn"
  getActions: (state) ->
    if state.current.actionsPlayed >= 3
      1
    else
      0
  getCards: (state) ->
    if state.current.actionsPlayed >= 3
      1
    else
      0
}

makeCard 'Coppersmith', action, {
  cost: 4
  playEffect:
    (state) ->
      state.copperValue += 1
}

makeCard 'Council Room', action, {
  cost: 5
  cards: 4
  buys: 1
  playEffect: (state) ->
    for opp in state.players[1...]
      state.drawCards(opp, 1)
}

makeCard 'Counting House', action, {
  cost: 5
  playEffect: (state) ->
    coppersFromDiscard = (card for card in state.current.discard when card==c.Copper)
    state.current.discard = (card for card in state.current.discard when card!=c.Copper)
    Array::push.apply state.current.hand, coppersFromDiscard
    state.log("#{state.current.ai} puts " + coppersFromDiscard.length + " Coppers into his hand.")
}

makeCard 'Courtyard', action, {
  cost: 2
  cards: 3
  playEffect: (state) ->
    if state.current.hand.length > 0
      card = state.current.ai.choose('putOnDeck', state, state.current.hand)
      state.doPutOnDeck(state.current, card)
}

makeCard 'Crossroads', action, {
  cost: 2

  playEffect: (state) ->
    if not state.current.crossroadsPlayed
      state.current.crossroadsPlayed = true
      state.current.actions += 3

    # shortcut, because it doesn't particularly matter whether just the
    # victory cards are revealed
    state.revealHand(state.current)

    nVictory = (card for card in state.current.hand when card.isVictory).length
    state.drawCards(state.current, nVictory)
}

makeCard 'Duchess', action, {
  cost: 2
  coins: +2

  playEffect: (state) ->
    for pl in state.players
      drawn = state.getCardsFromDeck(pl, 1)[0]
      state.log("#{pl.ai} reveals #{drawn}.")
      if drawn?
        discarded = pl.ai.choose('discard', state, [drawn, null])
        if discarded?
          state.log("...choosing to discard it.")
          pl.discard.push(drawn)
        else
          state.log("...choosing to put it back.")
          pl.draw.unshift(drawn)
}

makeCard 'Embassy', action, {
  cost: 5
  cards: +5
  playEffect: (state) ->
    state.requireDiscard(state.current, 3)
    
  gainEffect: (state, player) ->
    for pl in state.players
      if pl isnt player
        state.gainCard(pl, c.Silver)
}

makeCard 'Envoy', action, {
  cost: 4

  playEffect: (state) ->
    drawn = state.current.getCardsFromDeck(5)
    state.log("#{state.current.ai} draws #{drawn}.")
    # Have the left-hand neighbor (or the AI itself in solitaire) choose a card
    # to discard.
    neighbor = state.players[1] ? state.players[0]
    choice = neighbor.ai.choose('envoy', state, drawn)
    if choice?
      state.log("#{neighbor.ai} chooses for #{state.current.ai} to discard #{choice}.")
      transferCard(choice, drawn, state.current.discard)
      Array::push.apply state.current.hand, drawn
}

makeCard 'Explorer', action, {
  cost: 5

  playEffect: (state) ->
    cardToGain = c.Silver

    if c.Province in state.current.hand
      state.log("…revealing a Province.")
      cardToGain = c.Gold

    if state.countInSupply(cardToGain) > 0
      state.gainCard(state.current, cardToGain, 'hand', true)
      state.log("…and gaining a #{cardToGain}, putting it in the hand.")
    else
      state.log("…but there are no #{cardToGain}s available to gain.")
}

makeCard 'Farming Village', action, {
  cost: 4
  actions: +2
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isAction or card.isTreasure
    )
    if drawn.length > 0
      card = drawn[0]
      state.log("...#{state.current.ai} draws #{card}.")
      state.current.hand.push(card)
}

makeCard "Feast", action, {
  cost: 4

  playEffect: (state) ->
    # Trash the Feast, unless it's already been trashed.
    if state.current.playLocation != 'trash'
      transferCard(c.Feast, state.current[state.current.playLocation], state.trash)
      state.current.playLocation = 'trash'
      state.log("...trashing the Feast.")
    
    # Gain a card costing up to $5.
    choices = []
    for cardName of state.supply
      card = c[cardName]
      [coins, potions] = card.getCost(state)
      if potions == 0 and coins <= 5
        choices.push(card)
    state.gainOneOf(state.current, choices)
}

makeCard 'Golem', action, {
  cost: 4
  costPotion: 1
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isAction and card.name isnt 'Golem',
      2
    )
    if drawn.length > 0
      firstAction = state.current.ai.choose('action', state, drawn)
      drawn.remove(firstAction)
      secondAction = drawn[0]
      actions = [firstAction, secondAction]
      for card in actions
        if card?
          state.log("...#{state.current.ai} plays #{card}.")
          state.current.inPlay.push(card)
          state.current.playLocation = 'inPlay'
          state.resolveAction(card)
}

makeCard "Grand Market", c.Market, {
  cost: 6
  coins: 2
  actions: 1
  cards: 1
  buys: 1
  # Grand Market is the only card with a non-constant mayBeBought value.
  mayBeBought: (state) ->
    not(c.Copper in state.current.inPlay)
}

makeCard 'Haggler', action, {
  cost: 5
  coins: +2  
  buyInPlayEffect: (state, card1) ->
    [coins1, potions1] = card1.getCost(state)
    choices = []
    for cardName of state.supply
      card2 = c[cardName]
      [coins2, potions2] = card2.getCost(state)
      if (potions2 <= potions1) and (coins2 < coins1) and not card2.isVictory
        choices.push(card2)
      else if (potions2 < potions1) and (coins2 == coins1) and not card2.isVictory
        choices.push(card2)        
    state.gainOneOf(state.current, choices)
}

makeCard "Hamlet", action, {
  cost: 2
  cards: +1
  actions: +1

  playEffect: (state) ->
    player = state.current

    # We take a bit of a shortcut for now: we discard up to two cards, then if only
    # one was discarded, decide whether to use it for +action or +buy.
    discarded = state.allowDiscard(player, 2)
    if discarded.length == 2
      state.log("#{player.ai} gets +1 action and +1 buy.")
      player.actions++
      player.buys++
    else if discarded.length == 1
      benefit = player.ai.choose('benefit', state, [
        {actions: 1},
        {cards: 1}
      ])
      applyBenefit(state, benefit)
}

makeCard "Harvest", action, {
  cost: 5
  playEffect: (state) ->
    unique = []
    cards = state.discardFromDeck(state.current, 4)
    for card in cards
      if card not in unique
        unique.push(card)
    state.current.coins += unique.length
    state.log("...gaining +$#{unique.length}.")
}

makeCard "Herbalist", action, {
  cost: 2
  buys: +1
  coins: +1

  cleanupEffect: (state) ->
    choices = []
    for card in state.current.inPlay
      if card.isTreasure
        choices.push(card)
    choices.push(null)
    choice = state.current.ai.choose('herbalist', state, choices)
    if choice isnt null
      state.log("#{state.current.ai} uses Herbalist to put #{choice} back on the deck.")
      transferCardToTop(choice, state.current.inPlay, state.current.draw)
      
}

makeCard "Highway", action, {
  cost: 5
  cards: +1
  actions: +1
  
  playEffect: (state) ->
    highways = 0
    for card in state.current.inPlay
      if card.name is "Highway"
        highways++
    state.highways = highways
}

makeCard "Horse Traders", action, {
  cost: 4
  buys: +1
  coins: +3
  isReaction: true
  playEffect:
    (state) -> state.requireDiscard(state.current, 2)

  # Horse Traders is not actually a duration card, but it resolves like one
  # when it is set aside. There seems to be no harm in simplifying by
  # putting it in the duration area.
  durationEffect:
    (state) -> 
      # Pick up Horse Traders and draw another card.
      transferCard(c['Horse Traders'], state.current.duration, state.current.hand)
      state.drawCards(state.current, 1)
  
  reactToAttack:
    (state, player) ->
      transferCard(c['Horse Traders'], player.hand, player.duration)
}

# So far Hunting Party is the only card that digs for something 
# dependent on the game state.
makeCard 'Hunting Party', action, {
  cost: 5
  cards: +1
  actions: +1
  playEffect: (state) ->
    state.revealHand(state.current)    
    drawn = state.current.dig(state,
      (state, card) -> card not in state.current.hand
    )
    if drawn.length > 0
      card = drawn[0]
      state.log("...#{state.current.ai} draws #{card}.")
      state.current.hand.push(card)
}

makeCard 'Ironworks', action, {
  cost: 4
  playEffect: (state) ->
    choices = []
    for cardName of state.supply
      card = c[cardName]
      [coins, potions] = card.getCost(state)
      if potions == 0 and coins <= 4
        choices.push(card)
    gained = state.gainOneOf(state.current, choices)
    
    if gained.isAction
      state.current.actions += 1
    if gained.isTreasure
      state.current.coins += 1
    if gained.isVictory
      state.current.drawCards(1)
}

# Jack of All Trades is a complex card made up of steps that are simple
# to code:
makeCard 'Jack of All Trades', action, {
  cost: 4
  playEffect: (state) ->
    # Gain a silver.
    state.gainCard(state.current, c.Silver)

    # Look at the top card of your deck...
    card = state.current.getCardsFromDeck(1)[0]

    # discard it or put it back.
    if card?
      if state.current.ai.choose('discard', state, [card, null])
        state.log("#{state.current.ai} reveals and discards #{card}.")
        state.current.discard.push(card)
      else
        state.log("#{state.current.ai} reveals #{card} and puts it back.")
        state.current.draw.unshift(card)
    
    # Draw until you have 5 cards in hand.
    if state.current.hand.length < 5
      state.drawCards(state.current, 5 - state.current.hand.length)
    
    # You may trash a card from your hand that is not a Treasure.
    choices = (card for card in state.current.hand when not card.isTreasure)
    choices.push(null)
    choice = state.current.ai.choose('trash', state, choices)
    if choice?
      state.doTrash(state.current, choice)

}

makeCard "King's Court", action, {
  cost: 7
  isMultiplier: true
  multiplier: 3
  optional: true

  playEffect: (state) ->
    choices = (card for card in state.current.hand when card.isAction)
    if choices.length == 0
      state.log("...but has no action to play with the #{this}.")
    else
      choices.push(null) if @optional
      action = state.current.ai.choose('multipliedAction', state, choices)
      if action is null
        state.log("...choosing not to play an action.")
      else
        transferCard(action, state.current.hand, state.current.inPlay)

        for i in [0...@multiplier]
          return if action is null
          state.log("...playing #{action} (#{i+1} of #{@multiplier}).")
          state.resolveAction(action)
        
        # Determine whether this multiplier is going to go to the duration area
        # during the cleanup phase.

        putInDuration = false
        neverPutInDuration = false
        # If we've already marked a multiplier to be put in the Duration area,
        # don't mark this one. It's either already marked or it's not needed.
        md = state.current.multipliedDurations
        if md.length > 0 and md[md.length - 1].isMultiplier
          neverPutInDuration = true

        unless neverPutInDuration
          if action.isMultiplier
            # Mark the multiplier as if it were a multiplied Duration, which is
            # a flag to not clean it up (as if it were a Duration) later.
            if md.length > 0 and not (md[md.length - 1].isMultiplier)
              putInDuration = true
          if action.isDuration and action.name != 'Tactician'
            putInDuration = true
            # Store virtual copies of a multiplied duration card in `multipliedDurations`.
            for i in [0...@multiplier-1]
              md.push(action)
        
        if putInDuration
          # Mark it by putting it in multipliedDurations. This also signals that
          # all multiplied duration cards previous to it are accounted for.
          md.push(this)

  durationEffect: (state) ->
    # TR and KC don't actually have a duration effect. The multiplication of
    # of the Duration card has already happened, possibly more than once, and
    # the number of times it happens is not strictly related to the number of
    # multipliers in the duration area. It took a very long BGG thread to
    # figure this out.
}

makeCard 'Library', action, {
  cost: 5

  playEffect: (state) ->
    player = state.current
    while player.hand.length < 7
      drawn = player.getCardsFromDeck(1)

      # If nothing was drawn, the deck and discard pile are empty.
      if drawn.length == 0
        state.log("...stopping because there are no cards to draw.")
        break

      card = drawn[0]
      if card.isAction
        # Assume the times the AI wants to set the card aside are the times it
        # is on the discard priority list or has a positive discard value.
        if player.ai.choose('discard', state, [card, null])
          state.log("#{player.ai} sets aside a #{card}.")
          player.setAside.push(card)
        else
          state.log("#{player.ai} draws a #{card} and chooses to keep it.")
          player.hand.push(card)
      else
        state.log("#{player.ai} draws a #{card}.")
        player.hand.push(card)
    
    # Discard the set-aside cards.
    discards = player.setAside
    player.discard = player.discard.concat(discards)
    player.setAside = []
    state.handleDiscards(state.current, discards)

}

makeCard "Lookout", action, {
  cost: 3
  actions: +1

  playEffect: (state) ->
    drawn = state.getCardsFromDeck(state.current, 3)
    state.log("...drawing #{drawn}.")
    state.current.setAside = drawn
    trash = state.current.ai.choose('trash', state, drawn)
    if trash isnt null
      # Trash the card, with the side effect of removing it from the choice
      # list.
      state.log("...trashing #{trash}.")
      transferCard(trash, state.current.setAside, state.trash)
    
    discard = state.current.ai.choose('discard', state, drawn)
    if discard isnt null
      transferCard(discard, state.current.setAside, state.current.discard)
      state.log("...discarding #{discard}.")
      state.handleDiscards(state.current, [discard])
    
    # Put the remaining card back on the deck.
    state.log("...putting #{drawn} back on the deck.")
    state.current.draw = state.current.setAside.concat(state.current.draw)
    state.current.setAside = []
}

makeCard "Mandarin", action, {
  cost: 5
  coins: +3

  playEffect: (state) ->
    if state.current.hand.length > 0
      putBack = state.current.ai.choose('putOnDeck', state, state.current.hand)
      state.doPutOnDeck(state.current, putBack)
  
  gainEffect: (state, player) ->
    treasures = (card for card in player.inPlay when card.isTreasure)
    if treasures.length > 0
      for treasure in treasures
        player.inPlay.remove(treasure)
      order = player.ai.chooseOrderOnDeck(state, treasures, state.current)
      state.log("...putting #{order} back on the deck.")
      player.draw = order.concat(player.draw)
}

makeCard "Masquerade", action, {
  cost: 3
  cards: +2

  playEffect: (state) ->
    # Get everyone's choice of cards to pass.
    passed = []
    for player in state.players
      cardToPass = player.ai.choose('trash', state, player.hand)
      passed.push(cardToPass)

    # Pass the cards.
    for i in [0...state.nPlayers]
      player = state.players[i]
      nextPlayer = state.players[(i + 1) % state.nPlayers]
      cardToPass = passed[i]
      state.log("#{player.ai} passes #{cardToPass}.")
      if cardToPass isnt null
        transferCard(cardToPass, player.hand, nextPlayer.hand)

    # Allow the Masquerade player to trash a card.
    state.allowTrash(state.current, 1)
}

makeCard "Menagerie", action, {
  cost: 3
  actions: +1
  playEffect: (state) ->
    state.revealHand(state.current)
    state.drawCards(state.current, state.current.menagerieDraws())
}

makeCard "Mining Village", c.Village, {
  cost: 4
  playEffect: (state) ->
    if state.current.ai.choose('miningVillageTrash', state, [yes, no])
      if state.current.playLocation != 'trash'
        transferCard(c['Mining Village'], state.current[state.current.playLocation], state.trash)
        state.current.playLocation = 'trash'
        state.log("...trashing the Mining Village for +$2.")
        state.current.coins += 2
}

makeCard "Mint", action, {
  cost: 5
  buyEffect: (state) ->
    state.quarries = 0
    state.potions = 0
    inPlay = state.current.inPlay
    for i in [inPlay.length-1...-1]
      if inPlay[i].isTreasure
        state.log("...trashing a #{inPlay[i]}.")
        state.trash.push(inPlay[i])
        inPlay.splice(i, 1)

  playEffect: (state) ->
    treasures = []
    for card in state.current.hand
      if card.isTreasure
        treasures.push(card)
    choice = state.current.ai.choose('mint', state, treasures)
    if choice isnt null
      state.gainCard(state.current, choice)
}

makeCard "Moat", action, {
  cost: 2
  cards: +2
  isReaction: true
  # Revealing Moat sets a flag in the player's state, indicating
  # that the player is unaffected by the attack. In this code, Moat
  # is always revealed, without an AI decision.
  reactToAttack:
    (state, player) -> player.moatProtected = true
}

makeCard 'Moneylender', action, {
  cost: 4

  playEffect: (state) ->
    if c.Copper in state.current.hand
      state.doTrash(state.current, c.Copper)
      state.current.coins += 3
}

makeCard "Monument", action, {
  cost: 4
  coins: 2
  playEffect:
    (state) ->
      state.current.chips += 1
}

makeCard 'Nomad Camp', c.Woodcutter, {
  cost: 4

  gainEffect: (state, player) ->
    if player.gainLocation != 'trash'
      transferCardToTop(c['Nomad Camp'], player[player.gainLocation], player.draw)
      player.gainLocation = 'draw'
      state.log("...putting the Nomad Camp on top of the deck.")
}

makeCard 'Navigator', action, {
  cost: 4
  coins: +2

  playEffect: (state) ->
    drawn = state.getCardsFromDeck(state.current, 5)
    if state.current.ai.choose('discardHand', state, [drawn, null]) is null
      state.log("...choosing to keep #{drawn}.")
      order = state.current.ai.chooseOrderOnDeck(state, drawn, state.current)
      state.log("...putting #{order} back on the deck.")
      state.current.draw = order.concat(state.current.draw)
    else
      state.log("...discarding #{drawn}.")
      Array::push.apply state.current.discard, drawn
      state.handleDiscards(state.current, drawn)
}

makeCard 'Oasis', action, {
  cost: 3
  cards: +1
  actions: +1
  coins: +1

  playEffect: (state) ->
    state.requireDiscard(state.current, 1)
}

makeCard 'Pawn', action, {
  cost: 2
  playEffect:
    (state) ->
      benefit = state.current.ai.choose('benefit', state, [
        {cards: 1, actions: 1},
        {cards: 1, buys: 1},
        {cards: 1, coins: 1},
        {actions: 1, buys: 1},
        {actions: 1, coins: 1},
        {buys: 1, coins: 1}
      ])
      applyBenefit(state, benefit)
}

makeCard 'Pearl Diver', action, {
  cost: 2
  cards: +1
  actions: +1
  playEffect: (state) ->
    player = state.current
    bottomCard = player.draw.pop()
    if bottomCard?
      doNotWant = player.ai.choose('discard', state, [bottomCard, null])
      if doNotWant
        state.log("...choosing to leave #{bottomCard} at the bottom of the deck.")
        player.draw.push(bottomCard)
      else
        state.log("...moving #{bottomCard} from the bottom to the top of the deck.")
        player.draw.unshift(bottomCard)
    else
      state.log("...but the draw pile is empty.")
}

makeCard 'Peddler', action, {
  cost: 8
  actions: 1
  cards: 1
  coins: 1
  costInCoins: (state) ->
    cost = 8
    if state.phase is 'buy'
      cost -= 2 * state.current.actionsPlayed
      if cost < 0
        cost = 0
    cost
}

makeCard 'Salvager', action, {
  cost: 4
  buys: +1

  playEffect: (state) ->
    toTrash = state.current.ai.choose('salvagerTrash', state, state.current.hand)
    if toTrash?
      [coins, potions] = toTrash.getCost(state)
      state.doTrash(state.current, toTrash)
      state.current.coins += coins
}

makeCard 'Scout', action, {
  cost: 4
  actions: +1

  playEffect: (state) ->
    drawn = state.getCardsFromDeck(state.current, 4)
    state.log("...drawing #{drawn}.")

    # Implemented approximately the same way as Apothecary.
    for card in drawn
      if card.isVictory
        state.current.hand.push(card)
        state.log("...putting #{card} in the hand.")
      else
        state.current.setAside.push(card)
    
    if state.current.setAside.length > 0
      order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current)
      state.log("...putting #{order} back on the deck.")
      state.current.draw = order.concat(state.current.draw)
      state.current.setAside = []
}

# Secret Chamber
# Initial code by Jorbles
# This is far from optimal, but I believe it does what the card
# is supposed to do without breaking any rules. I may have to come
# back to this when my coffee skills are stronger. And I have a 
# greater understanding of how discards are decided. Ideally, the 
# code for discards should be different depending on the type of 
# attack and the total money already in hand.

makeCard "Secret Chamber", action, {
  cost: 2
  isReaction: true

  playEffect: (state) ->
    discarded = state.allowDiscard(state.current, Infinity)
    state.log("...getting +$#{discarded.length} from the Secret Chamber.")
    state.current.coins += discarded.length

  reactToAttack: (state, player) ->
    state.log("#{player.ai.name} reveals a Secret Chamber.")
    state.drawCards(player, 2)
    card = player.ai.choose('putOnDeck', state, player.hand)
    if card isnt null
      state.doPutOnDeck(player, card)
    card = player.ai.choose('putOnDeck', state, player.hand)
    if card isnt null
      state.doPutOnDeck(player, card)
}

makeCard 'Shanty Town', action, {
  cost: 3
  actions: +2
  playEffect: (state) ->
    state.revealHand(state.current)
    state.drawCards(state.current, state.current.shantyTownDraws())
}

makeCard 'Smugglers', action, {
  cost: 3
  playEffect: (state) ->
    state.gainOneOf(state.current, state.smugglerChoices())
}

makeCard 'Spice Merchant', action, {
  cost: 4
  playEffect: (state) ->
    trashChoices = (card for card in state.current.hand when card.isTreasure)
    trashChoices.push(null)
    trashed = state.current.ai.choose('spiceMerchantTrash', state, trashChoices)
    if trashed?
      state.doTrash(state.current, trashed)
      benefit = state.current.ai.choose('benefit', state, [
        {cards: 2, actions: 1},
        {coins: 2, buys: 1}
      ])
      applyBenefit(state, benefit)
}

makeCard 'Stables', action, {
  cost: 5
  playEffect: (state) ->
    discardChoices = (card for card in state.current.hand when card.isTreasure)
    discardChoices.push(null)
    discarded = state.current.ai.choose('stablesDiscard', state, discardChoices)
    if discarded?
      state.doDiscard(state.current, discarded)
      state.drawCards(state.current, 3)
      state.current.actions += 1
}

makeCard 'Steward', action, {
  cost: 3
  playEffect:
    (state) ->
      benefit = state.current.ai.choose('benefit', state, [
        {cards: 2},
        {coins: 2},
        {trash: 2}
      ])
      applyBenefit(state, benefit)
}

makeCard 'Throne Room', c["King's Court"], {
  cost: 4
  multiplier: 2
  optional: false
}

makeCard 'Tournament', action, {
  cost: 4
  actions: +1
  playEffect:
    (state) ->
      # All Provinces are automatically revealed.
      opposingProvince = false
      for opp in state.players[1...]
        if c.Province in opp.hand
          state.log("#{opp.ai} reveals a Province.")
          opposingProvince = true
      if c.Province in state.current.hand
        discardProvince = state.current.ai.choose('tournamentDiscard', state, [yes, no])
        if discardProvince
          state.doDiscard(state.current, c.Province)
          choices = state.prizes.slice(0)
          if state.supply[c.Duchy] > 0
            choices.push(c.Duchy)
          choice = state.gainOneOf(state.current, choices, 'draw')
          if choice isnt null
            state.log("...putting the #{choice} on top of the deck.")
      if not opposingProvince
        state.current.coins += 1
        state.current.drawCards(1)
}

makeCard "Trade Route", action, {
  cost: 3
  buys: 1
  trash: 1
  getCoins: (state) ->
    state.tradeRouteValue
}

makeCard "Trader", action, {
  cost: 4
  playEffect: (state) ->
    trashed = state.requireTrash(state.current, 1)[0]
    if trashed?
      [coins, potions] = trashed.getCost(state)
      for i in [0...coins]
        state.gainCard(state.current, c.Silver)
  
  # `reactReplacingGain` triggers before `reactToGain`, and lets you replace
  # the card with a different one.
  reactReplacingGain: (state, player, card) ->
    card = player.ai.choose('gain', state, [c.Silver, card])
    return c[card]
}

makeCard "Trading Post", action, {
  cost: 5
  playEffect: (state) ->
    state.requireTrash(state.current, 2)
    state.gainCard(state.current, c.Silver, 'hand')
    state.log("...gaining a Silver in hand.")    
}

makeCard "Transmute", action, {
  cost: 0
  costPotion: 1
  playEffect: (state) ->
    player = state.current
    trashed = player.ai.choose('transmute', state, player.hand)
    if trashed?
      state.doTrash(player, trashed)
      if trashed.isAction
        state.gainCard(state.current, c.Duchy)
      if trashed.isTreasure
        state.gainCard(state.current, c.Transmute)
      if trashed.isVictory
        state.gainCard(state.current, c.Gold)
}

makeCard 'Treasure Map', action, {
  cost: 4

  playEffect: (state) ->
    trashedMaps = 0

    if c['Treasure Map'] in state.current.inPlay
      state.log("...trashing the Treasure Map.")
      transferCard(c['Treasure Map'], state.current.inPlay, state.trash)
      trashedMaps += 1

    if c['Treasure Map'] in state.current.hand
      state.doTrash(state.current, c['Treasure Map'])
      state.log("...and trashing another Treasure Map.")
      trashedMaps += 1

    if trashedMaps == 2
      numGolds = 0
      for num in [1..4]
        if state.countInSupply(c.Gold) > 0
          state.gainCard(state.current, c.Gold, 'draw')
          numGolds += 1
      state.log("…gaining #{numGolds} Golds, putting them on top of the deck.")      
}

makeCard 'Treasury', c.Market, {
  buys: 0
  
  buyInPlayEffect: (state, card) ->
    if card.isVictory
      state.current.mayReturnTreasury = no
      
  cleanupEffect: (state) ->    
    if state.current.mayReturnTreasury
      transferCardToTop(c.Treasury, state.current.discard, state.current.draw)
      state.log("#{state.current.ai} returns a Treasury to the top of the deck.")    
}

makeCard 'Tribute', action, {
  cost: 5

  playEffect: (state) ->
    revealedCards = state.discardFromDeck(state.players[1], 2)

    unique = []
    for card in revealedCards
      if card not in unique
        unique.push(card)

    for card in unique
      if card.isAction
        state.current.actions += 2
      if card.isTreasure
        state.current.coins += 2
      if card.isVictory
        state.current.drawCards(2)
}

makeCard 'University', action, {
  cost: 2
  costPotion: 1
  actions: 2
  playEffect: (state) ->
    choices = []
    for cardName of state.supply
      card = c[cardName]
      [coins, potions] = card.getCost(state)
      if potions == 0 and coins <= 5 and card.isAction
        choices.push(card)
    state.gainOneOf(state.current, choices)
}

makeCard 'Vault', action, {
  cost: 5
  cards: +2

  playEffect: (state) ->
    discarded = state.allowDiscard(state.current, Infinity)
    state.log("...getting +$#{discarded.length} from the Vault.")
    state.current.coins += discarded.length

    for opp in state.players[1...]
      if opp.ai.wantsToDiscard(state) >= 2
        discarded = state.requireDiscard(opp, 2)
        if discarded.length == 2
          state.drawCards(opp, 1)
}

makeCard 'Walled Village', c.Village, {
  cost: 4
  
  #Clean up effect defined in `State.doCleanupPhase`
}

makeCard 'Warehouse', action, {
  cost: 3
  actions: +1
  playEffect: (state) ->
    state.drawCards(state.current, 3)
    state.requireDiscard(state.current, 3)
}

makeCard 'Watchtower', action, {
  cost: 3
  isReaction: true
  
  playEffect: (state) ->
    handLength = state.current.hand.length
    if handLength < 6
      state.drawCards(state.current, 6 - handLength)
  
  reactToGain: (state, player, card) ->
    return if player.gainLocation == 'trash'
    source = player[player.gainLocation]

    # Determine if the player wants to trash the card. If so, use the
    # Watchtower to do so.
    if player.ai.chooseTrash(state, [card, null]) is card
      # trash the card
      state.log("#{player.ai} reveals a Watchtower and trashes the #{card}.")
      transferCard(card, source, state.trash)
      # Note that the gained card now has no valid location; it's in the trash.
      player.gainLocation = 'trash'
    else if player.ai.choose('gainOnDeck', state, [card, null])
      state.log("#{player.ai} reveals a Watchtower and puts the #{card} on the deck.")
      player.gainLocation = 'draw'
      transferCardToTop(card, source, player.draw)
}

makeCard 'Wishing Well', action, {
  cost: 3
  cards: 1
  actions: 1
  playEffect: (state) ->
    choices = []
    for cardName in c.allCards
      choices.push(c[cardName])
      
    wish = state.current.ai.choose('wish', state, choices)
    state.log("...wishing for a #{wish}.")
    drawn = state.current.getCardsFromDeck(1)
    if drawn.length > 0
      card = drawn[0]
      if card is wish
        state.log("...revealing a #{card} and keeping it.")
        state.current.hand.push(card)
      else
        state.log("...revealing a #{card} and putting it back.")
        state.current.draw.unshift(card)
    else
      state.log("...drawing nothing.")
}

makeCard 'Workshop', action, {
  cost: 3
  playEffect: (state) ->
    choices = []
    for cardName of state.supply
      card = c[cardName]
      [coins, potions] = card.getCost(state)
      if potions == 0 and coins <= 4 and state.supply[cardName] > 0
        choices.push(card)
    state.gainOneOf(state.current, choices)
}

# Utility functions
# -----------------

# `transferCard` will move a card from one list to the end of another.
# 
# If you are doing something to each card in a list which might result in
# that card being moved somewhere else, you *must* iterate over the list
# backwards. Otherwise you'll run off the end of the list.
transferCard = (card, fromList, toList) ->
  if card not in fromList
    throw new Error("#{fromList} does not contain #{card}")
  fromList.remove(card)
  toList.push(card)

# `transferCardToTop` will move a card from one list to the front of another.
# This is used to put a card on top of the deck, for example.
transferCardToTop = (card, fromList, toList) ->
  if card not in fromList
    throw new Error("#{fromList} does not contain #{card}")
  fromList.remove(card)
  toList.unshift(card)

# Some cards give you a constant benefit, such as +cards or +actions,
# every time you play them; these benefits are defined directly on the card
# object. Other cards give you such a benefit only under certain conditions,
# and if the benefits are straightforward, we may use `applyBenefit` to make
# them happen. This takes in an object that describes the benefit, and
# applies it to the game state.
#
# The actions that can be performed through `applyBenefit` currently are:
#
# - `{cards: n}`: draw *n* cards
# - `{actions: n}`: get *+n* actions
# - `{buys: n}`: get *+n* buys
# - `{coins: n}`: get *+n* coins
# - `{trash: n}`: trash *n* cards
# - `{horseEffect: yes}`: gain 4 Silvers and discard your draw pile
#
# The AI has no rule in it that chooses `horseEffect`.
applyBenefit = (state, benefit) ->
  state.log("#{state.current.ai} gets #{JSON.stringify(benefit)}.")
  if benefit.cards?
    state.drawCards(state.current, benefit.cards)
  if benefit.actions?
    state.current.actions += benefit.actions
  if benefit.buys?
    state.current.buys += benefit.buys
  if benefit.coins?
    state.current.coins += benefit.coins
  if benefit.trash?
    state.requireTrash(state.current, benefit.trash)
  if benefit.horseEffect
    for i in [0...4]
      state.gainCard(state.current, c.Silver)
    discards = state.current.draw
    state.current.discard = state.current.discard.concat(discards)
    state.current.draw = []
    state.handleDiscards(state.current, discards)

# `upgradeChoices` is a helper function to get a list of choices for
# Remodel and similar "upgrading" cards. In addition to the game state, it
# takes in:
# 
# - `cards`: a list of cards that may be improved, which is usually the cards
#   in hand; duplicates are fine.
# - `filter`: a function of (oldCard, newCard) that describes whether the
#   improvement is allowed.
upgradeChoices = (state, cards, filter) ->
  used = []
  choices = []
  for card in cards
    if card not in used
      used.push(card)
      for cardname2 of state.supply
        card2 = c[cardname2]
        if filter(state, card, card2) and state.supply[card2] > 0
          choices.push([card, card2])          
  return choices

# Find options where you can upgrade a card into nothing, because you're
# required to gain a card at a cost where there isn't anything.
nullUpgradeChoices = (state, cards, costFunction) ->
  costs = []
  for cardname of state.supply
    if state.supply[cardname] > 0
      card = c[cardname]
      cost = ""+card.getCost(state)  # make it a string so it's searchable
      if cost not in costs
        costs.push(cost)

  used = []
  choices = []
  for card in cards
    if card not in used
      used.push(card)
      [coins, potions] = card.getCost(state)
      coins2 = costFunction(coins)
      costStr = ""+[coins2, potions]
      if costStr not in costs
        choices.push([card, null])
  return choices

# The `player` makes a single spying decision on `target`'s deck, using
# the decision named `decision` to decide whether to keep the card. For
# example, if the player is choosing to discard from its own deck, the
# decision name is `discard`; if it's an opponent's deck, the decision
# name is `discardFromOpponentDeck`.
spyDecision = (player, target, state, decision) ->
  drawn = state.getCardsFromDeck(target, 1)[0]
  if drawn?
    state.log("#{target.ai} reveals #{drawn}.")
    discarded = player.ai.choose(decision, state, [drawn, null])
    if discarded?
      state.log("#{player.ai} chooses to discard it.")
      target.discard.push(drawn)
    else
      state.log("#{player.ai} chooses to put it back on the draw pile.")
      target.draw.unshift(drawn)
  else
    state.log("#{target.ai} has no card to reveal.")

# Export functions that are needed elsewhere.
this.transferCard = transferCard
this.transferCardToTop = transferCardToTop
