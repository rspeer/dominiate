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
  #
  # All functions that might cause a player to have to make a decision are
  # written in continuation-passing style.

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
    new State(players, @supply, 'start').copy()

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
        newState = this.resolveDurations()
        newState.phase = 'action'
      when 'action'
        log("(action phase)")
        newState = this.resolveActions()
        newState.phase = 'treasure'
      when 'treasure'
        log("(treasure phase)")
        newState = this.resolveTreasures()
        newState.phase = 'buy'
      when 'buy'
        log("(buy phase)")
        newState = this.resolveBuy()
        newState.phase = 'cleanup'
      when 'cleanup'
        log("(cleanup phase)")
        newState = this.resolveCleanup()
        newState = newState.rotatePlayer()
  
  # All these functions are written defensively so that the card effects
  # may replace the state with a new object. This is a bit ugly, and I may
  # want to revisit the design when I know what happens to the objects.
  resolveDurations: () ->
    state = this
    for card in @current.duration
      log("#{@current.ai} resolves the duration effect of #{card}.")
      state = card.onDuration(state)
    return state
  
  resolveActions: () ->
    state = this
    loop
      validActions = []
      for card in state.current.hand
        if card.isAction and card not in validActions
          validActions.push(card)
      
      action = state.current.ai.chooseAction(validActions)
      return state if action is null
      log("#{state.current.ai} plays #{action}.")
      idx = state.current.hand.indexOf(action)
      if idx == -1
        warn("#{state.current.ai} chose an invalid action.")
        return state
      state.current.hand.splice(idx, 1)   # remove the action from the hand
      state.current.inPlay.push(action)   # and put it in play
      state = action.onPlay(state)

  resolveTreasure: () ->
    state = this
    loop
      validTreasures = []
      for card in state.current.hand
        if card.isTreasure and card not in validTreasures
          validTreasures.push(card)
      
      treasure = state.current.ai.chooseTreasure(validTreasures)
      return state if action is null
      log("#{state.current.ai} plays #{treasure}.")
      idx = state.current.hand.indexOf(treasure)
      if idx == -1
        warn("#{ai} chose an invalid treasure")
        return state
      state.current.hand.splice(idx, 1)   # remove the treasure from the hand
      state.current.inPlay.push(treasure) # and put it in play
      state = treasure.onPlay(state)
  
  resolveBuy: () ->
    buyable = []
    state = this
    while state.buys > 0
      for card, count of state.supply
        if card.mayBeBought(state) and count > 0
          buyable.push(card)
      choice = state.current.ai.chooseBuy(buyable)
      return state if choice is null
      log("#{state.current.ai} buys #{choice}.")
      state.supply[card] -= 1
      state.current.discard.push(card)
      state = card.onBuy(state)

      # TODO: handle gain reactions
    return state
    
  resolveCleanup: () ->
    # Discard old duration cards
    @current.discard = @current.discard + @current.duration
    @current.duration = []

    # Clean up cards in play, where the default is to discard them
    # TODO: allow cleanup order to be selected? (not very important)
    state = this
    while state.inPlay.length > 0
      card = state.inPlay[0]
      log("Cleaning up #{card}.")
      state.inPlay = state.inPlay[1...]
      state = card.onCleanup(state)

    # Discard remaining cards in hand
    state.current.discard = state.current.discard + state.current.hand
    state.current.hand = []

    state.current.actions = 1
    state.current.buys = 1
    state.drawCards(0, 5)
    return state
  
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

