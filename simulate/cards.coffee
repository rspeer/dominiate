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
  # Anything that might require making a decision -- such as the effect of
  # a card -- takes two arguments: the state, and "ret", a continuation
  # function that will be passed the return value.
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
  gainEffects: []
  playEffects: []
  gainInPlayEffects: []
  cleanupEffects: []
  durationEffects: []
  shuffleEffects: []
  attackReactions: []
  gainReactions: []

  onPlay: (state, ret) ->
    state.current.actions += this.getActions()
    state.current.coins += this.getCoins()
    state.current.buys += this.getBuys()
    cardsToDraw = this.getCards()
    if cardsToDraw > 0
      state.drawCards
        0,
        cardsToDraw,
        (newState) -> this.playEffectLoop(newState, ret)
    else
      this.playEffectLoop(state, ret)

  onDuration: (state, ret) ->
    this.playEffectLoopInner(state, this.durationEffects, ret)
  
  playEffectLoop: (state, ret) ->
    this.playEffectLoopInner(state, this.playEffects, ret)
  
  playEffectLoopInner: (state, effects, ret) ->
    if effects.length == 0
      ret(state)
    else
      nextEffect = effects[0]
      remainingEffects = effects[1...effects.length]
      nextEffect(
        state,
        (newState) -> playEffectLoopInner(newState, remainingEffects, ret)
      )
  
  toString: () -> this.name
}

###
BASE CARDS

Estate and Silver are the prototypes that other Victory and Treasure cards
derive from, respectively. (Copper is actually more complex than Silver!)
###

Curse = makeCard 'Curse', basicCard, {
  cost: 0
  vp: -1
}

Estate = makeCard 'Estate', basicCard, {
  cost: 2
  isVictory: true
  vp: 1
}

Duchy = makeCard 'Duchy', Estate, {cost: 5, vp: 3}
Province = makeCard 'Province', Estate, {cost: 8, vp: 6}
Colony = makeCard 'Colony', Estate, {cost: 11, vp: 10}

Silver = makeCard 'Silver', basicCard, {
  cost: 3
  isTreasure: true
  coins: 2
}

Copper = makeCard 'Copper', Silver, {
  cost: 0
  coins: 1
  getCoins: (state) -> state.copperValue ? 1
}

Gold = makeCard 'Gold', Silver, {cost: 6, coins: 3}
Platinum = makeCard 'Platinum', Silver, {cost: 9, coins: 5}
Potion = makeCard 'Potion', Silver, {
  cost: 4
  coins: 0
  getPotion: (state) -> 1
}

# And one that isn't a base card, but is easily described in terms of them:
Harem = makeCard 'Harem', Silver, {
  cost: 6
  isVictory: true
  getVP: (state) -> 2
}

###
VANILLA CARDS

These cards have effects that involve no decisions, and are expressed entirely
in +actions, +cards, +coins, +buys, and VP.
###

Village = makeCard 'Village', basicCard, {actions: 2, cards: 1}
WorkersVillage = makeCard "Worker's Village", basicCard, {
  cost: 4
  actions: 2
  cards: 1
  buys: 1
}
Laboratory = makeCard 'Laboratory', basicCard, {cost: 5, actions: 1, cards: 2}
Smithy = makeCard 'Smithy', basicCard, {cost: 4, cards: 3}
Festival = makeCard 'Festival', basicCard, {cost: 5, actions: 2, coins: 2}
Woodcutter = makeCard 'Woodcutter', basicCard, {cost: 3, coins: 2, buys: 1}
GreatHall = makeCard 'Great Hall', basicCard, {
  cost: 3, actions: 1, cards: 1, vp: 1, isVictory: true
}
Market = makeCard 'Market', basicCard, {
  cost: 5, actions: 1, cards: 1, coins: 1, buys: 1
}
Bazaar = makeCard 'Bazaar', basicCard, {
  cost: 5, actions: 2, cards: 1, coins: 1
}

###
Not-quite-vanilla cards that still involve no mid-card decisions.
###
Bank = makeCard 'Bank', Silver, {
  cost: 7
  getCoins: (state) ->
    coins = 0
    for card in state.current.inPlay
      if card.isTreasure
        coins += 1
    coins
}

Bridge = makeCard 'Bridge', basicCard, {
  cost: 4
  coins: 1
  buys: 1
  playEffects: [
    (state, ret) ->
      state.bridges += 1
      ret(state)
  ]
}

Coppersmith = makeCard 'Coppersmith', basicCard, {
  cost: 4
  playEffects: [
    (state, ret) ->
      state.copperValue += 1
      ret(state)
  ]
}

Diadem = makeCard 'Diadem', Silver, {
  cost: 0
  isPrize: True
  getCoins: (state) -> 2 + state.current.actions
}

Duke = makeCard "Duke", Estate, {
  cost: 5
  getVP: (state) ->
    vp = 0
    for card in state.current.getDeck()
      if card is Duchy
        vp += 1
    vp
}

Gardens = makeCard "Gardens", Estate, {
  cost: 4
  getVP: (state) -> Math.floor(state.current.getDeck().length / 10)
}

GrandMarket = makeCard "Grand Market", Market, {
  cost: 6
  coins: 2
  mayBeBought: (state) ->
    not(Copper in state.current.inPlay)
}

Menagerie = makeCard "Menagerie", basicCard, {
  cost: 3
  actions: 1
  playEffects: [
    (state, ret) -> state.revealHand(ret),
    (state, ret) ->
      seen = {}
      cardsToDraw = 3
      for card in state.current.hand
        if seen[card.name]?
          cardsToDraw = 1
          break
        seen[card.name] = True
      state.drawCards(0, cardsToDraw, ret)
}

Monument = makeCard "Monument", basicCard, {
  cost: 4
  coins: 2
  playEffects: [
    (state, ret) ->
      state.current.chips += 1
      ret(state)
  ]
}

Peddler = makeCard 'Peddler', basicCard, {
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

PhilosophersStone = makeCard "Philosopher's Stone", Silver, {
  cost: 3
  costPotion: 1
  getCoins: (state) ->
    Math.floor((state.current.draw.length + state.current.discard.length) / 5)
}

Princess = makeCard 'Princess', basicCard, {
  cost: 0
  buys: 1
  isPrize: true
  playEffects: [
    (state, ret) ->
      state.bridges += 2
      ret(state)
  ]
}

Quarry = makeCard 'Quarry', Silver, {
  cost: 4
  coins: 1
  playEffects: [
    (state, ret) ->
      state.quarries += 1
      ret(state)
  ]

ShantyTown = makeCard 'Shanty Town', basicCard, {
  cost: 3
  actions: +2
  playEffects: [
    (state, ret) ->
      cardsToDraw = 2
      for card in state.current.inPlay
        if card.isAction
          cardsToDraw = 0
          break
      state.drawCards(0, cardsToDraw, ret)
  ]
}
