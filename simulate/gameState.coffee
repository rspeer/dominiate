exports ?= window['gameState']

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
    this.drawCards(0, 5)
  
  drawCards: (playerNum, nCards) ->
    player = @players[playerNum]
    if player.draw.length < nCards
      diff = nCards - player.draw.length
      player.hand = player.hand.concat(player.draw)
      player.draw = []
      newState = this.shuffle(playerNum)
      return newState.drawCards(playerNum, diff)
        
    else
      player.hand = player.hand.concat(player.draw[0...nCards])
      player.draw = player.draw[nCards...]
      return this
  
  shuffle: (playerNum) ->
    # returns itself through a callback
    player = @players[playerNum]
    shuffle(player.discard)
    player.draw = player.discard
    player.discard = []

    # TODO: add a decision for Stashes
    return this
  
  revealHand: (playerNum) ->
    # nothing interesting happens
    return this

class PlayerState
  # A PlayerState is a simple structure that stores the part of the game state
  # that is specific to each player, plus what AI is making the decisions.

  constructor: (@actions, @buys, @coins, @chips, @hand, @draw, @discard, @inPlay, @duration, @chips, @ai) ->
  
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

class PlayerAI
  # TODO

exports.State = State
exports.PlayerAI = PlayerAI

