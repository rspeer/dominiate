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

  doPlay: () ->
    # Do the appropriate next thing, based on the value of @phase:
    #   'duration': resolve duration effects, then go to action phase
    #   'action': play and resolve some number of actions, then go to
    #     treasure phase
    #   'treasure': play and resolve some number of treasures, then go to
    #     buy phase
    #   'buy': buy some number of cards, then go to cleanup phase
    #   'cleanup': resolve cleanup effects, discard everything, draw 5 cards
    switch @phase
      when 'duration'
        
    

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

