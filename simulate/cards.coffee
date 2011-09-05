# Create an exported object to store all card definitions
c = {}
this.c = c

# Cards here are built in an *almost* object-oriented way. Almost, because each
# card is a singleton value, not a class. There are no instances of cards,
# there are just cards.
#
# Therefore, they "inherit" from each other by copying their properties, using
# the cardFrom function. There isn't even a need for Javascript's prototype
# system here.

makeCard = (name, origCard, props) ->
  # Derive a card from an existing one.
  newCard = {}
  for key, value of origCard
    newCard[key] = value
  newCard.name = name
  for key, value of props
    newCard[key] = value
  newCard.parent = origCard.name   # for debugging
  c[name] = newCard
  newCard

basicCard = {
  isAction: false
  isTreasure: false
  isVictory: false
  isAttack: false
  isReaction: false
  isDuration: false
  isPrize: false
  
  # The _base cost_ of a card is defined here. To find out what a card
  # *actually* costs, use the getCost() method. In most cases, the cost can
  # be set directly through the "cost" attribute, but it should never be
  # accessed that way.
  cost: 0
  costPotion: 0
  costInCoins: (state) -> this.cost
  costInPotions: (state) -> this.costPotion
  
  getCost: (state) ->
    coins = this.costInCoins()
    coins -= state.bridges
    if this.isAction
      coins -= state.quarries * 2
    if coins < 0
      coins = 0
    return [coins, this.costInPotions()]

  # There are two kinds of methods of a card. Those that can be statically
  # evaluated based on a state take a single argument, the state.
  #
  # When evaluating different hypothetical decisions to make, remember:
  #   - The state should have unknown information (no cheating!)
  #   - Use a fresh copy of the state each time, because actions are allowed
  #     to mutate states for efficiency.
  #   - All AIs should be replaced by the AI making the decision -- AIs don't
  #     get to ask other AIs what they would do.
  
  actions: 0
  cards: 0
  coins: 0
  buys: 0
  vp: 0

  getActions: (state) -> this.actions
  getCards: (state) -> this.cards
  getCoins: (state) -> this.coins
  getBuys: (state) -> this.buys
  getVP: (state) -> this.vp
  mayBeBought: (state) -> true
  buyEffects: []
  playEffects: []
  gainInPlayEffects: []
  cleanupEffects: []

  durationEffects: []
  shuffleEffects: []
  attackReactions: []
  gainReactions: []
  
  doEffects: (effects, state) ->
    for effect in effects
      effect(state)

  onPlay: (state) ->
    state.current.actions += this.getActions(state)
    state.current.coins += this.getCoins(state)
    state.current.buys += this.getBuys(state)
    cardsToDraw = this.getCards(state)
    if cardsToDraw > 0
      state.current.drawCards(cardsToDraw)
    this.doEffects(this.playEffects, state)

  onDuration: (state) ->
    this.doEffects(this.durationEffects, state)
  
  onCleanup: (state) ->
    this.doEffects(this.cleanupEffects, state)

  onBuy: (state) ->
    this.doEffects(this.buyEffects, state)
  
  toString: () -> this.name
}

###
BASE CARDS

Estate and Silver are the prototypes that other Victory and Treasure cards
derive from, respectively. (Copper is actually more complex than Silver!)
###

makeCard 'Curse', basicCard, {
  cost: 0
  vp: -1
}

makeCard 'Estate', basicCard, {
  cost: 2
  isVictory: true
  vp: 1
}

makeCard 'Duchy', c.Estate, {cost: 5, vp: 3}
makeCard 'Province', c.Estate, {cost: 8, vp: 6}
makeCard 'Colony', c.Estate, {cost: 11, vp: 10}

makeCard 'Silver', basicCard, {
  cost: 3
  isTreasure: true
  coins: 2
}

makeCard 'Copper', c.Silver, {
  cost: 0
  coins: 1
  getCoins: (state) -> state.copperValue ? 1
}

makeCard 'Gold', c.Silver, {cost: 6, coins: 3}
makeCard 'Platinum', c.Silver, {cost: 9, coins: 5}
makeCard 'Potion', c.Silver, {
  cost: 4
  coins: 0
  getPotion: (state) -> 1
}

# And one that isn't a base card, but is easily described in terms of them:
makeCard 'Harem', c.Silver, {
  cost: 6
  isVictory: true
  getVP: (state) -> 2
}

###
VANILLA CARDS

These cards have effects that involve no decisions, and are expressed entirely
in +actions, +cards, +coins, +buys, and VP.
###

# make an action card to derive from
makeCard 'action', basicCard, {isAction: true}
action = c.action
delete c.action

makeCard 'Village', action, {actions: 2, cards: 1}
makeCard "Worker's Village", action, {
  cost: 4
  actions: 2
  cards: 1
  buys: 1
}
makeCard 'Laboratory', action, {cost: 5, actions: 1, cards: 2}
makeCard 'Smithy', action, {cost: 4, cards: 3}
makeCard 'Festival', action, {cost: 5, actions: 2, coins: 2}
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

###
Cards that involve no mid-card decisions.
###
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
  playEffects: [
    (state) ->
      state.bridges += 1
  ]
}

makeCard 'Coppersmith', action, {
  cost: 4
  playEffects: [
    (state) ->
      state.copperValue += 1
  ]
}

makeCard 'Diadem', c.Silver, {
  cost: 0
  isPrize: true
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

makeCard "Gardens", c.Estate, {
  cost: 4
  getVP: (state) -> Math.floor(state.current.getDeck().length / 10)
}

makeCard "Grand Market", c.Market, {
  cost: 6
  coins: 2
  mayBeBought: (state) ->
    not(c.Copper in state.current.inPlay)
}

makeCard "Menagerie", action, {
  cost: 3
  actions: 1
  playEffects: [
    (state) -> state.revealHand(0),
    (state) ->
      seen = {}
      cardsToDraw = 3
      for card in state.current.hand
        if seen[card.name]?
          cardsToDraw = 1
          break
        seen[card.name] = true
      state.current.drawCards(cardsToDraw)
  ]
}

makeCard "Monument", action, {
  cost: 4
  coins: 2
  playEffects: [
    (state) ->
      state.current.chips += 1
  ]
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
  playEffects: [
    (state) ->
      state.bridges += 2
  ]
}

makeCard 'Quarry', c.Silver, {
  cost: 4
  coins: 1
  playEffects: [
    (state) ->
      state.quarries += 1
  ]
}

makeCard 'Shanty Town', action, {
  cost: 3
  actions: +2
  playEffects: [
    (state) ->
      cardsToDraw = 2
      for card in state.current.inPlay
        if card.isAction
          cardsToDraw = 0
          break
      state.current.drawCards(cardsToDraw)
  ]
}
