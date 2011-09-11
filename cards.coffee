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

  # If a card has simple effects that *vary* based on the state, define
  # them by overriding these methods, which do take the state as a parameter.
  # The constant properties above will be ignored in that case, but you could
  # fill them in with reasonable guesses for the benefit of AI methods that
  # don't want to examine the state.
  getActions: (state) -> this.actions
  getCards: (state) -> this.cards
  getCoins: (state) -> this.coins
  getBuys: (state) -> this.buys
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
  # - What happens (besides the simple effects defined above) when the card is
  #   played?
  playEffect: (state) ->
  # - What happens when this card is in play and another card is gained?
  gainInPlayEffect: (state) ->
  # - What happens when this card is cleaned up from play?
  cleanupEffect: (state) ->
  # - What happens when the card is in play as a Duration at the start of
  #   the turn?
  durationEffect: (state) ->
  # - What happens when the card is shuffled into the draw deck?
  shuffleEffect: (state) ->
  # - What happens when this card is in hand and an opponent plays an attack?
  attackReaction: (state) ->
  # - What happens when this card is in hand and its owner gains a card?
  gainReaction: (state) ->
  
  # This defines everything that happens when a card is played, including
  # basic effects and complex effects defined in `playEffect`. Cards
  # should not override `onPlay`; they should override `playEffect` instead.
  onPlay: (state) ->
    state.current.actions += this.getActions(state)
    state.current.coins += this.getCoins(state)
    state.current.potions += this.getPotion(state)
    state.current.buys += this.getBuys(state)
    cardsToDraw = this.getCards(state)
    if cardsToDraw > 0
      state.drawCards(state.current, cardsToDraw)
    this.playEffect(state)
  
  # Similarly, these are other ways for the game state to interact
  # with the card. Cards should override the `Effect` methods, not these.
  onDuration: (state) ->
    this.durationEffect(state)
  
  onCleanup: (state) ->
    this.cleanupEffect(state)

  onBuy: (state) ->
    this.buyEffect(state)
  
  reactToAttack: (player) ->
    this.attackReaction(player)
  
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
      else 40      
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
      when 3, 4 then 12
      else 15
}

makeCard 'Duchy', c.Estate, {cost: 5, vp: 3}
makeCard 'Province', c.Estate, {cost: 8, vp: 6}
makeCard 'Colony', c.Estate, {cost: 11, vp: 10}

# Now we define the basic treasure cards. Our prototypical card here is
# Silver.

makeCard 'Silver', basicCard, {
  cost: 3
  isTreasure: true
  coins: 2
  startingSupply: (state) -> 30
}

# Copper is actually more complex than Silver: its value can vary when modified
# by Coppersmith.
makeCard 'Copper', c.Silver, {
  cost: 0
  coins: 1
  getCoins: (state) -> state.copperValue ? 1
}

makeCard 'Gold', c.Silver, {cost: 6, coins: 3}
makeCard 'Platinum', c.Silver, {
  cost: 9,
  coins: 5,
  startingSupply: (state) -> 12
}
makeCard 'Potion', c.Silver, {
  cost: 4
  coins: 0
  playEffect:
    (state) -> state.current.potions += 1
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
makeCard 'Great Hall', action, {
  cost: 3, actions: 1, cards: 1, vp: 1, isVictory: true
}
makeCard 'Market', action, {
  cost: 5, actions: 1, cards: 1, coins: 1, buys: 1
}
makeCard 'Bazaar', action, {
  cost: 5, actions: 2, cards: 1, coins: 1
}
makeCard 'Harem', c.Silver, {
  cost: 6
  isVictory: true
  vp: 2
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
  cards: 0
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
  cards: 0
  coins: +2
  durationCards: 0
  durationCoins: +2
}

# Miscellaneous cards
# -------------------
# All of these cards have effects beyond what can be expressed with a
# simple formula, which are generally defined by overriding the complex
# methods such as `playEffect`.

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

makeCard 'Bank', c.Silver, {
  cost: 7
  getCoins: (state) ->
    coins = 0
    for card in state.current.inPlay
      if card.isTreasure
        coins += 1
    coins
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
    state.allowDiscard(state.current, 1000)
    numDiscarded = startingCards - state.current.hand.length
    state.drawCards(state.current, numDiscarded)
}

makeCard 'Chapel', action, {
  cost: 2
  playEffect:
    (state) ->
      state.allowTrash(state.current, 4)
}

makeCard 'Coppersmith', action, {
  cost: 4
  playEffect:
    (state) ->
      state.copperValue += 1
}

makeCard 'Diadem', c.Silver, {
  cost: 0
  isPrize: true
  mayBeBought: (state) -> false
  getCoins: (state) -> 2 + state.current.actions
}

makeCard "Duke", c.Estate, {
  cost: 5
  getVP: (state) ->
    vp = 0
    for card in state.current.getDeck()
      if card is c.Duchy
        vp += 1
    vp
}

makeCard "Followers", action, {
  cost: 0
  isAttack: true
  isPrize: true
  mayBeBought: (state) -> false
  playEffect: (state) ->
    state.gainCard(state.current, c.Estate)
    state.attackOpponents (opp) ->
      state.gainCard(opp, c.Curse)
      if opp.hand.length > 3
        state.requireDiscard(opp, opp.hand.length - 3)
}

makeCard "Gardens", c.Estate, {
  cost: 4
  getVP: (state) -> Math.floor(state.current.getDeck().length / 10)
}

# Goons: *see Militia*
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
    state.log("...gaining $+#{unique.length}.")
}

makeCard "Horse Traders", action, {
  cost: 4
  buys: 1
  coins: 3
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
    (player) ->
      transferCard(c['Horse Traders'], player.hand, player.duration)
}

makeCard "Menagerie", action, {
  cost: 3
  actions: 1
  playEffect: (state) ->
    state.revealHand(state.current)
    state.drawCards(state.current, state.current.menagerieDraws())
}

makeCard "Militia", action, {
  cost: 4
  coins: 2
  isAttack: true
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
  coins: 2
  buys: 1

  # The effect of Goons that causes you to gain VP on each buy is 
  # defined in `State.doBuyPhase`. Other than that, Goons is a fancy
  # Militia.
}

makeCard "Moat", action, {
  cost: 2
  cards: +2
  isReaction: true
  # Revealing Moat sets a flag in the player's state, indicating
  # that the player is unaffected by the attack. In this code, Moat
  # is always revealed, without an AI decision.
  attackReaction:
    (player) -> player.moatProtected = true
}

makeCard "Monument", action, {
  cost: 4
  coins: 2
  playEffect:
    (state) ->
      state.current.chips += 1
}

makeCard 'Nobles', action, {
  cost: 6
  isVictory: true
  vp: 2

  # Nobles is an example of a card that allows a choice from multiple
  # simple effects. We implement this using the `chooseBenefit` AI method,
  # which is passed a list of benefit objects, one of which it will choose
  # to apply to the state.
  playEffect:
    (state) ->
      benefit = state.current.ai.chooseBenefit(state, [
        {actions: 2},
        {cards: 3}
      ])
      applyBenefit(state, benefit)
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

makeCard "Philosopher's Stone", c.Silver, {
  cost: 3
  costPotion: 1
  getCoins: (state) ->
    Math.floor((state.current.draw.length + state.current.discard.length) / 5)
}

makeCard 'Princess', action, {
  cost: 0
  buys: 1
  isPrize: true
  mayBeBought: (state) -> false
  playEffect:
    (state) ->
      state.bridges += 2
}

makeCard 'Quarry', c.Silver, {
  cost: 4
  coins: 1
  playEffect:
    (state) ->
      state.quarries += 1
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

makeCard 'Warehouse', action, {
  cost: 3
  playEffect: (state) ->
    state.drawCards(state.current, 3)
    state.requireDiscard(state.current, 3)
}

makeCard 'Witch', action, {
  cost: 5
  cards: 2
  playEffect: (state) ->
    state.attackOpponents (opp) ->
      state.gainCard(opp, c.Curse)
}

# Utility functions
# -----------------

# `transferCard` will move a card from one list to the end of another.
# 
# This sometimes happens when iterating over a list of cards, which is
# unfortunate. The current solution is to call cleanupList, defined in
# the state.
transferCard = (card, fromList, toList) ->
  idx = fromList.indexOf(card)
  if idx == -1
    throw new Error("#{fromList} does not contain #{card}")
  fromList[idx] = null
  toList.push(card)

# `transferCardToTop` will move a card from one list to the front of another.
# This is used to put a card on top of the deck, for example.
transferCardToTop = (card, fromList, toList) ->
  idx = fromList.indexOf(card)
  if idx == -1
    throw new Error("#{fromList} does not contain #{card}")
  fromList[idx] = null
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

