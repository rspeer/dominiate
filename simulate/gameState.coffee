# ambidextrous import/export
if exports?
  c = require('./cards')
else
  gameState = {}
  exports = gameState

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

  constructor: (@players, @supply, @phase) ->
    @nPlayers = @players.length
    @current = @players[0]

    @bridges = 0
    @quarries = 0
    @copperValue = 1

  copy: () ->
    newSupply = {}
    for key, value of @supply
      newSupply[key] = value
    newPlayers = []
    for player in @players
      newPlayers.push(player.copy())
    newState = new State(newPlayers, newSupply, @phase)

    newState.bridges = @bridges
    newState.quarries = @quarries
    newState.copperValue = @copperValue
    newState.phase = @phase
    newState
    
  rotatePlayer: () ->
    players = @players[1...@nPlayers].concat [@players[0]]
    @phase = start

  gameIsOver: () ->
    emptyPiles = 0
    for key, value of @supply
      if value == 0
        if key is cards.Province
          return true
        emptyPiles += 1
    return (emptyPiles >= 3)

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
        log("== #{@current.ai}'s turn #{@current.turnsTaken} ==")
        this.resolveDurations()
        @phase = 'action'
      when 'action'
        log("(action phase)")
        this.resolveActions()
        @phase = 'treasure'
      when 'treasure'
        log("(treasure phase)")
        this.resolveTreasures()
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
    loop
      validActions = []
      for card in @current.hand
        if card.isAction and card not in validActions
          validActions.push(card)
      
      action = @current.ai.chooseAction(validActions)
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
      
      treasure = @current.ai.chooseTreasure(validTreasures)
      return if action is null
      log("#{@current.ai} plays #{treasure}.")
      idx = @current.hand.indexOf(treasure)
      if idx == -1
        warn("#{ai} chose an invalid treasure")
        return
      @current.hand.splice(idx, 1)   # remove the treasure from the hand
      @current.inPlay.push(treasure) # and put it in play
      treasure.onPlay(this)
  
  resolveBuy: () ->
    buyable = []
    while @buys > 0
      for card, count of @supply
        if card.mayBeBought(this) and count > 0
          buyable.push(card)
      choice = @current.ai.chooseBuy(buyable)
      return if choice is null
      log("#{@current.ai} buys #{choice}.")
      @supply[card] -= 1
      @current.discard.push(card)
      card.onBuy(this)
      # TODO: handle gain reactions
    
  resolveCleanup: () ->
    # Discard old duration cards
    @current.discard = @current.discard.concat @current.duration
    @current.duration = []

    # Clean up cards in play, where the default is to discard them
    # TODO: allow cleanup order to be selected? (not very important)
    while @current.inPlay.length > 0
      card = @current.inPlay[0]
      log("Cleaning up #{card}.")
      @current.inPlay = @current.inPlay[1...]
      card.onCleanup(this)

    # Discard remaining cards in hand
    @current.discard = @current.discard.concat @current.hand
    @current.hand = []

    @current.actions = 1
    @current.buys = 1
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
                c.Copper, c.Copper, c.Copper, c.Estate, c.Estate]
    @inPlay = []
    @duration = []
    @turnsTaken = 0
    @ai = ai

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
    other.ai = @ai
    other.turnsTaken = @turnsTaken

  getDeck: () ->
    @draw.concat @discard.concat @hand.concat @inPlay.concat @duration
  
  drawCards: (nCards) ->
    if @draw.length < nCards
      diff = nCards - @draw.length
      @hand = @hand.concat(@draw)
      @draw = []
      if @discard.length > 0
        this.shuffle()
        this.drawCards(diff)
        
    else
      @hand = @hand.concat(@draw[0...nCards])
      @draw = @draw[nCards...]
  
  shuffle: () ->
    shuffle(@discard)
    @draw = @discard
    @discard = []
    # TODO: add an AI decision for Stashes

exports.State = State

