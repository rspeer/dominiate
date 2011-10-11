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
  getVP: (state) -> this.vp
  
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
  attackReaction: (state, player) ->
  # - What happens when this card is in hand and its owner gains a card?
  gainReaction: (state, player, card, gainInHand) ->
  
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
  
  onGain: (state) ->
    this.gainEffect(state)
  
  reactToAttack: (state, player) ->
    this.attackReaction(state, player)
  
  reactToGain: (state, player, card) ->
    this.gainReaction(state, player, card)
  
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

makeCard 'Duchy', c.Estate, {cost: 5, vp: 3}
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
  getVP: (state) -> state.current.countInDeck('Duchy')
}

makeCard 'Fairgrounds', c.Estate, {
  cost: 6
  getVP: (state) ->
    unique = []
    deck = state.current.getDeck()
    for card in deck
      if card not in unique
        unique.push(card)
    2 * Math.floor(unique.length / 5)    
}

makeCard 'Gardens', c.Estate, {
  cost: 4
  getVP: (state) -> Math.floor(state.current.getDeck().length / 10)
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

makeCard 'Vineyard', c.Estate, {
  cost: 0
  costPotion: 1
  getVP: (state) -> Math.floor(state.current.numActionCardsInDeck() / 3)
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
      state.current.inPlay.remove(this)
      state.log("...#{state.current.ai} trashes the Horn of Plenty.")
}

makeCard 'Loan', treasure, {
  coins: 1
  playEffect: (state) ->
    drawn = state.current.dig(state,
      (state, card) -> card.isTreasure
    )    
    if drawn[0]?
      treasure = drawn[0]
      trash = state.current.ai.choose('trash', state, [treasure, null])
      if trash?
        state.log("...trashing the #{treasure}.")
        drawn.remove(treasure)
      else
        state.log("...discarding the #{treasure}.")
        state.current.discard.push(treasure)
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
    if drawn[0]?
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
      state.current.discard = state.current.discard.concat(state.current.hand)
      state.current.hand = []
  
  # The cleanupEffect of a dead Tactician is to discard it instead of putting it in the
  # duration area. It's not a duration card in this case.
  cleanupEffect: (state) ->
    if state.current.tacticians > 0
      state.current.tacticians--
    else
      state.log("#{state.current.ai} discards an inactive Tactician.")
      transferCard(c.Tactician, state.current.duration, state.current.discard)
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

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 >= potions2) and (coins1 + 2 >= coins2)

  playEffect: (state) ->
    choices = upgradeChoices(state, state.current.hand, this.upgradeFilter)
    choice = state.current.ai.choose('upgrade', state, choices)
    if choice isnt null
      [oldCard, newCard] = choice
      state.current.doTrash(oldCard)
      state.gainCard(state.current, newCard)
}

makeCard 'Expand', c.Remodel, {
  cost: 7

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 >= potions2) and (coins1 + 3 >= coins2)
}

makeCard 'Upgrade', c.Remodel, {
  cost: 5
  actions: +1
  cards: +1

  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 == potions2) and (coins1 + 1 == coins2)
}

makeCard 'Remake', c.Remodel, {
  upgradeFilter: (state, oldCard, newCard) ->
    [coins1, potions1] = oldCard.getCost(state)
    [coins2, potions2] = newCard.getCost(state)
    return (potions1 == potions2) and (coins1 + 1 == coins2)

  playEffect: (state) ->
    for i in [1..2]
      choices = upgradeChoices(state, state.current.hand, this.upgradeFilter)
      choice = state.current.ai.choose('upgrade', state, choices)
      if choice isnt null
        [oldCard, newCard] = choice
        state.current.doTrash(oldCard)
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
    choices = upgradeChoices(state, state.current.hand, this.upgradeFilter)
    choice = state.current.ai.choose('upgrade', state, choices)
    if choice isnt null
      [oldCard, newCard] = choice
      state.current.doTrash(oldCard)
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
      for i in [0...quantity]
        state.current.doTrash(card)
      # Return it to the supply, if it had a slot in the supply to begin with
      if state.supply[card]?
        state.supply[card] += quantity
      state.attackOpponents (opp) ->
        state.gainCard(opp, card)
}

makeCard 'Bureaucrat', attack, {
  cost: 4
  playEffect: (state) ->
    state.gainCard(state.current, c.Silver, 'draw')
    state.attackOpponents (opp) ->
      victory = []
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
          opp.doDiscard(c.Copper)
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
      if drawn[0]?
        card = drawn[0]
        transferCardToTop(card, drawn, opp.draw)
        state.log("...#{opp.ai} puts #{card} on top of the deck.")
}

# Goons: *see Militia*
makeCard 'Jester', attack, {
  cost: 5
  coins: +2

  playEffect: (state) ->
    state.attackOpponents (opp) ->
      card = state.discardFromDeck(opp, 1)[0]
      if card.isVictory
        state.gainCard(opp, c.Curse)
      else if state.current.ai.chooseGain(state, [card, null])
        state.gainCard(state.current, card)
      else
        state.gainCard(opp, card)
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

  # The effect of Goons that causes you to gain VP on each buy is 
  # defined in `State.doBuyPhase`. Other than that, Goons is a fancy
  # Militia.
}

makeCard "Mountebank", attack, {
  cost: 5
  coins: +2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      if c.Curse in opp.hand
        # Discarding a Curse against Mountebank is automatic.
        opp.doDiscard(c.Curse)
      else
        state.gainCard(opp, c.Copper)
        state.gainCard(opp, c.Curse)
}

makeCard 'Pirate Ship', attack, {
  cost: 4

  playEffect: (state) ->
    choice = state.current.ai.choose('pirateShip', state, ['coins','attack'])
    if choice is 'coins'
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
          drawn.remove(treasureToTrash)
          state.log("...#{state.current.ai} trashes #{opp.ai}'s #{treasureToTrash}.")
        state.current.discard.concat (drawn)
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
          state.current.discard.push(card)
          state.log("...discarding #{card}.")
        else
          state.current.setAside.push(card)
      
      if state.current.setAside.length > 0
        order = state.current.ai.chooseOrderOnDeck(state, state.current.setAside, state.current)
        state.log("...putting #{order} back on the deck.")
        state.current.draw = order.concat(state.current.draw)
        state.current.setAside = []
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
      if drawn[0]?
        cardToTrash = drawn[0]
        state.log("...#{state.current.ai} trashes #{opp.ai}'s #{cardToTrash}.")
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

makeCard 'Sea Hag', attack, {
  cost: 4
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.discardFromDeck(opp, 1)
      state.gainCard(opp, c.Curse, 'draw', true)
      state.log("#{opp.ai} gains a Curse on top of the deck.")
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
        drawn.remove(treasureToTrash)
        state.log("...#{state.current.ai} trashes #{opp.ai}'s #{treasureToTrash}.")
        cardToGain =  state.current.ai.chooseGain(state, [treasureToTrash, null])
        if cardToGain
          state.gainCard(state.current, cardToGain, 'discard', true)
          state.log("...#{state.current.ai} gains the trashed #{treasureToTrash}.")
      state.current.discard.concat (drawn)
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

# Miscellaneous cards
# -------------------
# All of these cards have effects beyond what can be expressed with a
# simple formula, which are generally defined by overriding the complex
# methods such as `playEffect`.

makeCard 'Adventurer', action, {
  cost: 6

  playEffect: (state) ->
    treasuresDrawn = 0
    while treasuresDrawn < 2
      # Take cards one at a time, and either put them in hand or set them
      # aside depending on their type.
      drawn = state.current.getCardsFromDeck(1)
      if drawn.length == 0
        break
      card = drawn[0]
      if card.isTreasure
        treasuresDrawn += 1
        state.current.hand.push(card)
        state.log("...drawing a #{card}.")
      else
        state.current.setAside.push(card)
    state.current.discard = state.current.discard.concat(state.current.setAside)
    state.current.setAside = []
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

makeCard 'Baron', action, {
  cost: 4
  buys: 1
  playEffect: (state) ->
    discardEstate = no
    if c.Estate in state.current.hand
      discardEstate = state.current.ai.choose('baronDiscard', state, [yes, no])
    if discardEstate
      state.current.doDiscard(c.Estate)
      state.current.coins += 4
    else
      state.gainCard(state.current. c.Estate)
}

makeCard 'Bridge', action, {
  cost: 4
  coins: 1
  buys: 1
  playEffect:
    (state) ->
      state.bridges += 1
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
    if state.current.inPlay.length >= 3
      1
    else
      0
  getCards: (state) ->
    if state.current.inPlay.length >= 3
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
  actions: 2
  
  playEffect: (state) ->
    cardsDrawn = 0;
    while cardsDrawn < 1
      drawn = state.current.getCardsFromDeck(1)
      if drawn.length == 0
        break
      card = drawn[0]
      if card.isAction or card.isTreasure
        cardsDrawn += 1
        state.current.hand.push(card)
        state.log("...drawing a #{card}.")
      else
        state.current.setAside.push(card)
    state.current.discard = state.current.discard.concat(state.current.setAside)
    state.current.setAside = []
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
  
  attackReaction:
    (state, player) ->
      transferCard(c['Horse Traders'], player.hand, player.duration)
}

makeCard 'Hunting Party', action, {
  cost: 5
  actions: +1
  cards: +1

  playEffect: (state) ->
    state.revealHand(state.current)
    cardsDrawn = 0;
    while cardsDrawn < 1
      drawn = state.current.getCardsFromDeck(1)
      if drawn.length == 0
        break
      card = drawn[0]
      state.log("...revealing a #{card}")

      if card not in state.current.hand
        cardsDrawn += 1
        state.current.hand.push(card)
        state.log("...drawing a #{card}.")
      else
        state.current.setAside.push(card)
    state.current.discard = state.current.discard.concat(state.current.setAside)
    state.current.setAside = []
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

makeCard 'Library', action, {
  cost: 5

  playEffect: (state) ->
    player = state.current
    while player.hand.length < 7
      drawn = player.getCardsFromDeck(1)

      # If nothing was drawn, the deck and discard pile are empty.
      break if drawn.length == 0

      card = drawn[0]
      if card.isAction
        # Assume the times the AI wants to set the card aside are the times it
        # is on the discard priority list or has a positive discard value.
        if player.ai.choose('discard', state, [card, null])
          state.log("#{player.ai} sets aside a #{card}.")
          player.setAside.push(card)
        else
          state.log("#{player.ai} draws a #{card}.")
          player.hand.push(card)
    
    # Discard the set-aside cards.
    player.discard = player.discard.concat(player.setAside)
    player.setAside = []

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
      state.current.setAside.remove(trash)
    
    discard = state.current.ai.choose('discard', state, drawn)
    if discard isnt null
      transferCard(discard, state.current.setAside, state.current.discard)
      state.log("...discarding #{discard}.")
    
    # Put the remaining card back on the deck.
    state.log("...putting #{drawn} back on the deck.")
    state.current.draw = state.current.setAside.concat(state.current.draw)
    state.current.setAside = []
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

makeCard "Mint", action, {
  cost: 5
  buyEffect: (state) ->
    state.quarries = 0
    state.potions = 0
    inPlay = state.current.inPlay
    for i in [inPlay.length-1...-1]
      if inPlay[i].isTreasure
        state.log("...trashing a #{inPlay[i]}.")
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
  attackReaction:
    (state, player) -> player.moatProtected = true
}

makeCard 'Moneylender', action, {
  cost: 4

  playEffect: (state) ->
    if c.Copper in state.current.hand
      state.current.doTrash(c.Copper)
      state.current.coins += 3
}

makeCard "Monument", action, {
  cost: 4
  coins: 2
  playEffect:
    (state) ->
      state.current.chips += 1
}

makeCard 'Pawn', action, {
  cost: 2
  playEffect:
    (state) ->
      benefit = state.current.ai.chooseBenefit(state, [
        {cards: 1, actions: 1},
        {cards: 1, buys: 1},
        {cards: 1, coins: 1},
        {actions: 1, buys: 1},
        {actions: 1, coins: 1},
        {buys: 1, coins: 1}
      ])
      applyBenefit(state, benefit)
}

makeCard 'Peddler', action, {
  cost: 8
  actions: 1
  cards: 1
  coins: 1
  costInCoins: (state) ->
    cost = 8
    if state.phase is 'buy'
      for card in state.current.inPlay
        if card.isAction
          cost -= 2
          break if cost <= 0
    cost
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

makeCard 'Shanty Town', action, {
  cost: 3
  actions: +2
  playEffect: (state) ->
    state.revealHand(0)
    state.drawCards(state.current, state.current.shantyTownDraws())
}

makeCard 'Steward', action, {
  cost: 3
  playEffect:
    (state) ->
      benefit = state.current.ai.chooseBenefit(state, [
        {cards: 2},
        {coins: 2},
        {trash: 2}
      ])
      applyBenefit(state, benefit)
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
        state.log("#{state.current.ai} reveals a Province.")
        choices = state.prizes
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

makeCard "Trading Post", action, {
  cost: 5
  playEffect: (state) ->
    state.requireTrash(state.current, 2)
    state.gainCard(state.current, c.Silver, 'hand')
    state.log("...gaining a Silver in hand.")    
}

makeCard 'Treasure Map', action, {
  cost: 4

  playEffect: (state) ->
    trashedMaps = 0

    if c['Treasure Map'] in state.current.inPlay
      state.current.inPlay.remove(c['Treasure Map'])
      state.log("...trashing the Treasure Map.")
      trashedMaps += 1

    if c['Treasure Map'] in state.current.hand
      state.current.doTrash(c['Treasure Map'])
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
  
  canTopDeck: yes

  buyInPlayEffect: (state, card) ->
    if card.isVictory      
      c.Treasury.canTopDeck = no
      
  cleanupEffect: (state) ->    
    if c.Treasury.canTopDeck
      transferCardToTop(c.Treasury, state.current.discard, state.current.draw)
      state.log("#{state.current.ai} returns a Treasury to the top of the deck.")
    
    
    # canTopDeck must be reset with the last Treasury cleaned up so that the
    # effect of buying a Victory card does not carry on to future turns
    if c.Treasury not in state.current.inPlay
      c.Treasury.canTopDeck = yes
}

makeCard 'Tribute', action, {
  cost: 5

  playEffect: (state) ->
    revealedCards = state.players[1].discardFromDeck(2)

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
  
  gainReaction: (state, player, card) ->
    return if player.gainLocation == 'trash'
    source = player[player.gainLocation]

    # Determine if the player wants to trash the card. If so, use the
    # Watchtower to do so.
    if player.ai.chooseTrash(state, [card, null]) is card
      # trash the card
      state.log("#{player.ai} reveals a Watchtower and trashes the #{card}.")
      source.remove(card)
      # Note that the gained card now has no location; it's in the trash.
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
      if potions == 0 and coins <= 4
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
# The basic AI has no rule in it that chooses `horseEffect`.
applyBenefit = (state, benefit) ->
  state.log("#{state.current.ai} chooses #{JSON.stringify(benefit)}.")
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
    state.current.discard = state.current.discard.concat(state.current.draw)
    state.current.draw = []

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

# Export functions that are needed elsewhere.
this.transferCard = transferCard
this.transferCardToTop = transferCardToTop
