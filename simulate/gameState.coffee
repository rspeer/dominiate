# ambidextrous import
if require?
  c = require('./cards').c
else
  c = this.c

# general function to randomly shuffle a list
shuffle = (v) ->
  i = v.length
  while i
    j = parseInt(Math.random() * i)
    i -= 1
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
  v

# parameterize logging, so we can send it somewhere else when needed
log = (obj) ->
  console.log(obj)

warn = (obj) ->
  console.log("WARNING: ", obj)


class State
  # Stores the complete state of the game.
  # 
  # Many operations will mutate the state, for the sake of efficiency.
  # Any AI that evaluates different possible decisions must make a copy of
  # that state with less information in it, anyway.
  basicSupply: ['Curse', 'Copper', 'Silver', 'Gold',
                'Estate', 'Duchy', 'Province']

  initialize: (ais, kingdom) ->
    @players = (new PlayerState().initialize(ai) for ai in ais)
    @nPlayers = @players.length
    @current = @players[0]
    @supply = this.makeSupply(kingdom)

    @bridges = 0
    @quarries = 0
    @copperValue = 1
    @phase = 'start'
    return this
  
  makeSupply: (kingdom) ->
    allCards = this.basicSupply.concat(kingdom)
    supply = {}
    for card in allCards
      card = c[card] ? card
      supply[card] = card.startingSupply(this)
    supply

  copy: () ->
    newSupply = {}
    for key, value of @supply
      newSupply[key] = value
    newPlayers = []
    for player in @players
      newPlayers.push(player.copy())
    newState = new State()

    newState.players = newPlayers
    newState.current = newPlayers[0]
    newState.nPlayers = @nPlayers
    newState.bridges = @bridges
    newState.quarries = @quarries
    newState.copperValue = @copperValue
    newState.phase = @phase
    newState
    
  rotatePlayer: () ->
    players = @players[1...@nPlayers].concat [@players[0]]
    @phase = 'start'

  gameIsOver: () ->
    emptyPiles = []
    for key, value of @supply
      if value == 0
        emptyPiles.push(key)
    if emptyPiles.length >= 3\
        or 'Province' in emptyPiles\
        or 'Colony' in emptyPiles
      console.log("Empty piles: #{emptyPiles}")
      return true
    return false

  doPlay: () ->
    # Do the appropriate next thing, based on the value of @phase:
    #   'start': resolve duration effects, then go to action phase
    #   'action': play and resolve some number of actions, then go to
    #     treasure phase
    #   'treasure': play and resolve some number of treasures, then go to
    #     buy phase
    #   'buy': buy some number of cards, then go to cleanup phase
    #   'cleanup': resolve cleanup effects, discard everything, draw 5 cards
    
    switch @phase
      when 'start'
        @current.turnsTaken += 1
        log("\n== #{@current.ai}'s turn #{@current.turnsTaken} ==")
        log("Hand: #{@current.hand}")
        this.resolveDurations()
        @phase = 'action'
      when 'action'
        log("(action phase)")
        this.resolveActions()
        @phase = 'treasure'
      when 'treasure'
        log("(treasure phase)")
        this.resolveTreasure()
        @phase = 'buy'
      when 'buy'
        log("(buy phase)")
        this.resolveBuy()
        @phase = 'cleanup'
      when 'cleanup'
        log("(cleanup phase)")
        this.resolveCleanup()
        this.rotatePlayer()
  
  resolveDurations: () ->
    for card in @current.duration
      log("#{@current.ai} resolves the duration effect of #{card}.")
      card.onDuration(this)
  
  resolveActions: () ->
    while @current.actions > 0
      validActions = []
      for card in @current.hand
        if card.isAction and card not in validActions
          validActions.push(card)
      console.log("Actions: #{validActions}")
      action = @current.ai.chooseAction(this, validActions)
      return if action is null
      log("#{@current.ai} plays #{action}.")
      idx = @current.hand.indexOf(action)
      if idx == -1
        warn("#{@current.ai} chose an invalid action.")
        return
      @current.hand.splice(idx, 1)   # remove the action from the hand
      @current.inPlay.push(action)   # and put it in play
      action.onPlay(this)

  resolveTreasure: () ->
    loop
      validTreasures = []
      for card in @current.hand
        if card.isTreasure and card not in validTreasures
          validTreasures.push(card)
      
      treasure = @current.ai.chooseTreasure(this, validTreasures)
      return if treasure is null
      log("#{@current.ai} plays #{treasure}.")
      idx = @current.hand.indexOf(treasure)
      if idx == -1
        warn("#{@current.ai} chose an invalid treasure")
        return
      @current.hand.splice(idx, 1)   # remove the treasure from the hand
      @current.inPlay.push(treasure) # and put it in play
      treasure.onPlay(this)
  
  resolveBuy: () ->
    while @current.buys > 0
      buyable = []
      for cardname, count of @supply
        card = c[cardname]
        if card.mayBeBought(this) and count > 0
          [coinCost, potionCost] = card.getCost(this)
          if coinCost <= @current.coins and potionCost <= @current.potions
            buyable.push(card)
      log(@current.coins)
      choice = @current.ai.chooseBuy(this, buyable)
      return if choice is null
      log("#{@current.ai} buys #{choice}.")
      log(choice.name)
      @supply[choice] -= 1
      @current.discard.push(choice)
      [coinCost, potionCost] = choice.getCost(this)
      @current.coins -= coinCost
      @current.potionCost -= potionCost
      @current.buys -= 1
      choice.onBuy(this)
      this.resolveGain(choice)
  
  resolveGain: () ->
    # TODO: handle gain reactions

  resolveCleanup: () ->
    # Discard old duration cards
    @current.discard = @current.discard.concat @current.duration
    @current.duration = []

    # if any cards remain set aside, clean them up
    if @current.setAside.length > 0
      warn(["Cards were set aside at the end of turn", @current.setAside])
      @current.discard = @current.discard.concat @current.setAside
      @current.setAside = []

    # Clean up cards in play, where the default is to discard them
    # TODO: allow cleanup order to be selected? (not very important)
    while @current.inPlay.length > 0
      card = @current.inPlay[0]
      @current.inPlay = @current.inPlay[1...]
      if card.isDuration
        @current.duration.push(card)
      else
        @current.discard.push(card)
      card.onCleanup(this)

    # Discard remaining cards in hand
    @current.discard = @current.discard.concat(@current.hand)
    @current.hand = []

    @current.actions = 1
    @current.buys = 1
    @current.coins = 0
    @current.copperValue = 1
    @current.bridges = 0
    @current.drawCards(5)
  
  revealHand: (playerNum) ->
    # nothing interesting happens

class PlayerState
  # A PlayerState stores the part of the game state
  # that is specific to each player, plus what AI is making the decisions.

  # We just use the default Object constructor, because new PlayerState objects
  # will almost always be created by copying. At the start of the game,
  # .initialize() each PlayerState, which assigns its AI and sets up its
  # starting state.

  initialize: (ai) ->
    @actions = 1
    @buys = 1
    @coins = 0
    @potions = 0
    @mats = {
      pirateShip: 0
      nativeVillage: []
      island: []
    }
    @chips = 0
    @hand = []
    @discard = [c.Copper, c.Copper, c.Copper, c.Copper, c.Copper,
                c.Copper, c.Copper, c.Estate, c.Estate, c.Estate]
    @draw = []
    @inPlay = []
    @duration = []
    @setAside = []
    @turnsTaken = 0
    @ai = ai
    this.drawCards(5)
    this

  copy: () ->
    other = new PlayerState()
    other.actions = @actions
    other.buys = @buys
    other.coins = @coins
    other.potions = @potions
    other.mats = @mats
    other.chips = @chips
    other.hand = @hand.slice(0)
    other.draw = @draw.slice(0)
    other.discard = @discard.slice(0)
    other.inPlay = @inPlay.slice(0)
    other.duration = @duration.slice(0)
    other.setAside = @setAside.slice(0)
    other.ai = @ai
    other.turnsTaken = @turnsTaken
    other

  getDeck: () ->
    @draw.concat @discard.concat @hand.concat @inPlay.concat @duration.concat @mats.nativeVillage.concat @mats.island

  countInDeck: (card) ->
    count = 0
    for card2 in this.getDeck()
      if card.toString() == card2.toString()
        count++
    count

  drawCards: (nCards) ->
    if @draw.length < nCards
      diff = nCards - @draw.length
      if @draw.length > 0
        log("#{@ai} draws #{@draw.length} cards.")
      @hand = @hand.concat(@draw)
      @draw = []
      if @discard.length > 0
        this.shuffle()
        this.drawCards(diff)
        
    else
      log("#{@ai} draws #{nCards} cards.")
      @hand = @hand.concat(@draw[0...nCards])
      @draw = @draw[nCards...]
  
  shuffle: () ->
    log("#{@ai} shuffles.")
    if @draw.length > 0
      throw new Error("Shuffling while there are cards left to draw")
    shuffle(@discard)
    @draw = @discard
    @discard = []
    # TODO: add an AI decision for Stashes

  getVP: (state) ->
    total = 0
    for card in this.getDeck()
      total += card.getVP(state)
    total

    

this.kingdoms = {
  moneyOnly: []
  allDefined: [
    'Platinum', 'Colony', 'Potion',
    'Bank', 'Bazaar', 'Bridge', 'Coppersmith', 'Duke', 'Festival',
    'Gardens', 'Grand Market', 'Great Hall', 'Harem', 'Laboratory', 'Market',
    'Menagerie', 'Monument', 'Peddler', "Philosopher's Stone", 'Quarry',
    'Shanty Town', 'Smithy', 'Village', 'Woodcutter', "Worker's Village",
  ]
}

this.State = State
this.PlayerState = PlayerState

