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

countStr = (list, elt) ->
  count = 0
  for member in list
    if member.toString() == elt.toString()
      count++
  count

numericSort = (array) ->
  array.sort( (a, b) -> (a-b) )

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
  
  # make card information available to strategies
  cardInfo: c

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
    @players = @players[1...@nPlayers].concat [@players[0]]
    @current = @players[0]
    @phase = 'start'

  gameIsOver: () ->
    emptyPiles = []
    for key, value of @supply
      if value == 0
        emptyPiles.push(key)
    if emptyPiles.length >= 3\
        or 'Province' in emptyPiles\
        or 'Colony' in emptyPiles
      log("Empty piles: #{emptyPiles}")
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
        log("Draw: #{@current.draw}")
        log("Discard: #{@current.discard}")
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
      validActions = [null]
      for card in @current.hand
        if card.isAction and card not in validActions
          validActions.push(card)
      action = @current.ai.chooseAction(this, validActions)
      return if action is null
      log("#{@current.ai} plays #{action}.")
      idx = @current.hand.indexOf(action)
      if idx == -1
        warn("#{@current.ai} chose an invalid action.")
        return
      @current.hand.splice(idx, 1)   # remove the action from the hand
      @current.inPlay.push(action)   # and put it in play
      @current.actions -= 1
      action.onPlay(this)

  resolveTreasure: () ->
    loop
      validTreasures = [null]
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
      buyable = [null]
      for cardname, count of @supply
        card = c[cardname]
        if card.mayBeBought(this) and count > 0
          [coinCost, potionCost] = card.getCost(this)
          if coinCost <= @current.coins and potionCost <= @current.potions
            buyable.push(card)
      
      log("Coins: #{@current.coins}, Potions: #{@current.potions}, Buys: #{@current.buys}")
      choice = @current.ai.chooseBuy(this, buyable)
      return if choice is null
      
      log("#{@current.ai} buys #{choice}.")
      [coinCost, potionCost] = choice.getCost(this)
      @current.coins -= coinCost
      @current.potionCost -= potionCost
      @current.buys -= 1

      this.doGain(@current, choice)
      choice.onBuy(this)
  
  doGain: (player, card) ->
    if @supply[card] > 0
      player.discard.push(card)
      @supply[card] -= 1
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
    @current.potions = 0
    @copperValue = 1
    @bridges = 0
    @quarries = 0
    @current.drawCards(5)
  
  revealHand: (player) ->
    # nothing interesting happens
  
  drawCards: (player, num) ->
    player.drawCards(num)

  allowDiscard: (player, num) ->
    numDiscarded = 0
    while numDiscarded < num
      validDiscards = player.hand.slice(0)
      validDiscards.push(null)
      choice = player.ai.chooseDiscard(this, validDiscards)
      return if choice is null
      log("#{player.ai} discards #{choice}.")
      numDiscarded++
      player.doDiscard(choice)
  
  requireDiscard: (player, num) ->
    numDiscarded = 0
    while numDiscarded < num
      validDiscards = player.hand.slice(0)
      return if validDiscards.length == 0
      choice = player.ai.chooseDiscard(this, validDiscards)
      log("#{player.ai} discards #{choice}.")
      numDiscarded++
      player.doDiscard(choice)
  
  allowTrash: (player, num) ->
    numTrashed = 0
    while numTrashed < num
      valid = player.hand.slice(0)
      valid.push(null)
      choice = player.ai.chooseTrash(this, valid)
      return if choice is null
      log("#{player.ai} trashes #{choice}.")
      numTrashed++
      player.doTrash(choice)
  
  requireTrash: (player, num) ->
    numTrashed = 0
    while numTrashed < num
      valid = player.hand.slice(0)
      return if valid.length == 0
      choice = player.ai.chooseTrash(this, valid)
      log("#{player.ai} trashes #{choice}.")
      numTrashed++
      player.doTrash(choice)
  
  attackOpponents: (effect) ->
    for opp in @players[1...]
      this.attackPlayer(opp, effect)

  attackPlayer: (player, effect) ->
    player.moatProtected = false
    for card in player.hand
      if card.isReaction
        card.reactToAttack(player)
    if not player.moatProtected
      effect(player)
      
  countInSupply: (card) ->
    @supply[card] ? 0
  
  pilesToEndGame: () ->
    # How many piles have to be bought out to end the game?
    switch @nPlayers
      when 1, 2, 3, 4 then 3
      else 4

  gainsToEndGame: () ->
    # How many cards would have to be gained to end the game?
    counts = (count for card, count of @supply)
    numericSort(counts)
    piles = this.pilesToEndGame()
    minimum = 0
    for count in counts[...piles]
      minimum += count
    minimum = Math.min(minimum, @supply['Province'])
    if @supply['Colony']?
      minimum = Math.min(minimum, @supply['Colony'])
    minimum

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
    @moatProtected = false
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
    other.moatProtected = @moatProtected
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

  doDiscard: (card) ->
    idx = @hand.indexOf(card)
    if idx == -1
      warn("#{@ai} has no #{card} to discard")
      return
    @hand.splice(idx, 1)
    @discard.push(card)
  
  doTrash: (card) ->
    idx = @hand.indexOf(card)
    if idx == -1
      warn("#{@ai} has no #{card} to trash")
      return
    @hand.splice(idx, 1)
  
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
  
  getTotalMoney: () ->
    total = 0
    for card in this.getDeck()
      total += card.coins
    total

  # Helpful indicators
  countInHand: (card) ->
    countStr(@hand, card)

  countInDiscard: (card) ->
    countStr(@discard, card)

  countInPlay: (card) ->
    # Count the number of copies of a card in play. Don't use this
    # for evaluating effects that stack, because you may also need
    # to take Throne Rooms and King's Courts into account.
    countStr(@inPlay, card)

  countActionCardsInDeck: () ->
    count = 0
    for card in this.getDeck()
      if card.isAction
        count += 1
    count

  getActionDensity: () ->
    this.countActionCardsInDeck() / this.getDeck().length
  
  menagerieDraws: () ->
    seen = {}
    cardsToDraw = 3
    for card in @hand
      if seen[card.name]?
        cardsToDraw = 1
        break
      seen[card.name] = true
    cardsToDraw

  shantyTownDraws: () ->
    cardsToDraw = 2
    for card in @hand
      if card.isAction
        cardsToDraw = 0
        break
    cardsToDraw
  
  actionBalance: () ->
    balance = @actions
    for card in @hand
      if card.isAction
        balance += card.actions
        balance--

        # Estimate the risk of drawing an action dead.
        # TODO: do something better when there are variable card-drawers
        if card.actions == 0
          balance -= card.cards * this.getActionDensity()
    balance


this.kingdoms = {
  moneyOnly: []
  moneyOnlyColony: ['Platinum', 'Colony']
  allDefined: c.allCards
}
console.log(this.kingdoms.allDefined)

this.State = State
this.PlayerState = PlayerState

