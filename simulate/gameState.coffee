shuffle = (v) ->
  i = v.length
  while i
    j = parseInt(Math.random() * i)
    i -= 1
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
  v

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

  doPlay: (ret) ->
    # Do the appropriate next thing, based on the value of @phase:
    #   'duration': resolve duration effects, then go to action phase
    #   'action': play and resolve some number of actions, then go to
    #     treasure phase
    #   'treasure': play and resolve some number of treasures, then go to
    #     buy phase
    #   'buy': buy some number of cards, then go to cleanup phase
    #   'cleanup': resolve cleanup effects, discard everything, draw 5 cards
    #
    # *Eventually* returns a state where the game is over.
    switch @phase
      when 'duration'
        this.resolveDurations @current.duration, (newState) ->
          newState.phase = 'action'
          newState.doPlay(ret)
      when 'action'
        this.resolveActions (newState) ->
          newState.phase = 'treasure'
          newState.doPlay(ret)
      when 'treasure'
        this.resolveTreasure (newState) ->
          newState.phase = 'buy'
          newState.doPlay(ret)
      when 'buy'
        this.resolveBuy (newState) ->
          newState.phase = 'cleanup'
          newState.doPlay(ret)
      when 'cleanup'
        this.resolveCleanup (newState) ->
          if newState2.gameIsOver()
            ret(newState2)
          else
            newState.drawCards 0, 5, (newState2) ->
              newState2.rotatePlayer().doPlay(ret)
  
  resolveDurations: (cards, ret) ->
    if cards.length == 0
      ret(this)
    else
      nextCard = cards[0]
      remainingCards = cards[1...]
      nextCard.onDuration this, (newState) ->
        newState.resolveDurations(remainingCards, ret)
  
  resolveActions: (cards, ret) ->
    ...

  resolveTreasure: (cards, ret) ->
    ...
  
  resolveBuy: (cards, ret) ->
    ...

  resolveCleanup: (cards, ret) ->
    # TODO: allow cleanup order to be selected? (not very important)
    if cards.length == 0
      ret(this)
    else
      nextCard = cards[0]
      remainingCards = cards[1...]
      nextCard.onCleanup this, (newState) ->
        newState.resolveCleanup(remainingCards, ret)
  
  drawCards: (playerNum, nCards, ret) ->
    # returns itself through a callback
    player = @players[playerNum]
    if player.draw.length < nCards
      diff = nCards - player.draw.length
      player.hand = player.hand.concat(player.draw)
      player.draw = []
      this.shuffle playerNum, (newState) ->
        newState.drawCards(playerNum, diff, ret)
        
    else
      player.hand = player.hand.concat(player.draw[0...nCards])
      player.draw = player.draw[nCards...]
      ret(this)
  
  shuffle: (playerNum, ret) ->
    # returns itself through a callback
    player = @players[playerNum]
    shuffle(player.discard)
    player.draw = player.discard
    player.discard = []

    # TODO: add a decision for Stashes
    ret(this)

class PlayerState
  # A PlayerState is a simple structure that stores the part of the game state
  # that is specific to each player, plus what AI is making the decisions.

  constructor: (@hand, @draw, @discard, @inPlay, @duration, @chips, @ai) ->
  
  copy: () ->
    new PlayerState(
      @hand.slice(0),
      @draw.slice(0),
      @discard.slice(0),
      @inPlay.slice(0),
      @duration.slice(0),
      @chips,
      @ai
    )

  getDeck: () ->
    @draw.concat @discard.concat @hand.concat @inPlay.concat @duration

class PlayerAI
  ...

###
A State still needs to support these methods:
  current
  current.chips
  current.hand
  current.draw
  current.discard
  current.inPlay
  current.drawCards(nCards, ret)
  current.getDeck()
  current.revealHand(ret)
  phase
  quarries
###

