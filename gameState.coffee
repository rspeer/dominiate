# Many modules begin with this "indecisive import" pattern. It's messy
# but it gets the job done, and it's explained at the bottom of this
# documentation.
{c} = require './cards' if require?

# The PlayerState class
# ---------------------  
# A PlayerState stores the part of the game state
# that is specific to each player, plus what AI is making the decisions.
class PlayerState
  # At the start of the game, the State should
  # .initialize() each PlayerState, which assigns its AI and sets up its
  # starting state. Before then, it is an empty object.
  initialize: (ai, log) ->
    # These attributes of the PlayerState are okay for card effects and
    # AI strategies to refer to.
    # 
    # Often, you will want to find out something
    # about the player whose turn it is, who will appear as `state.current`.
    # For example, if you want to know how many actions the current player
    # has, you can look up `state.current.actions`.
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
    
    # For now, AIs shouldn't ask what's in a player's draw pile. This would
    # cause the AI to cheat, by accessing information it shouldn't have.
    #
    # When hidden information is implemented, however, `state.current.draw`
    # will contain a random guess about what's in the draw pile.
    @draw = []
    @inPlay = []
    @duration = []
    @setAside = []
    @moatProtected = false
    @turnsTaken = 0
    
    # Set the properties passed in from the State.
    @ai = ai
    @log = log

    # To start the game, the player starts with the 10 starting cards
    # in the discard pile, then shuffles them and draws 5.
    this.drawCards(5)
    this

  #### Informational methods
  # 
  # The methods here ask about general properties of a player's deck,
  # discard pile, and so on. A number of similar methods appear on the `State`
  # class defined below, which deal with information that is not so
  # player-specific, such as the cards in the supply.
  # 
  # As an example:
  # Most AI code will start with a reference to the State, called `state`.
  # If you want to check the number of cards in the current player's deck,
  # you would ask the *player object* `state.current`:
  #
  #    state.current.numCardsInDeck()
  #
  # If you want to check how many piles are currently empty, you would ask
  # the *state object* itself:
  #
  #    state.numEmptyPiles()
  
  # `getDeck()` returns all the cards in the player's deck, even those in
  # strange places such as the Island mat.
  getDeck: () ->
    @draw.concat @discard.concat @hand.concat @inPlay.concat @duration.concat @mats.nativeVillage.concat @mats.island
  
  # `countInDeck(card)` counts the number of copies of a card in the deck.
  # The card may be specified either by name or as a card object.
  countInDeck: (card) ->
    count = 0
    for card2 in this.getDeck()
      if card.toString() == card2.toString()
        count++
    count
  
  # `numCardsInDeck()` returns the size of the player's deck.
  numCardsInDeck: () -> this.getDeck().length
  
  # `getVP()` returns the number of VP the player would have if the game
  # ended now.
  getVP: (state) ->
    total = 0
    for card in this.getDeck()
      total += card.getVP(state)
    total
  
  # `getTotalMoney()` adds up the total money in the player's deck,
  # including *all* cards that provide a constant number of +$, not just
  # Treasure.
  getTotalMoney: () ->
    total = 0
    for card in this.getDeck()
      total += card.coins
    total
  
  # `countInHand(card)` counts the number of copies of a card in hand.
  countInHand: (card) ->
    countStr(@hand, card)

  # `countInHand(card)` counts the number of copies of a card in the discard
  # pile.
  countInDiscard: (card) ->
    countStr(@discard, card)

  # `countInPlay(card)`
  # counts the number of copies of a card in play. Don't use this
  # for evaluating effects that stack, because you may also need
  # to take Throne Rooms and King's Courts into account.
  countInPlay: (card) ->
    countStr(@inPlay, card)
  
  # `numActionCardsInDeck()` is the number of action cards in the player's
  # entire deck.
  numActionCardsInDeck: () ->
    count = 0
    for card in this.getDeck()
      if card.isAction
        count += 1
    count
  
  # `getActionDensity()` returns a fractional value, between 0.0 and 1.0,
  # representing the proportion of actions in the deck.
  getActionDensity: () ->
    this.numActionCardsInDeck() / this.getDeck().length
  
  # `menagerieDraws()` is the number of cards the player would draw upon
  # playing a Menagerie: either 1 or 3.
  menagerieDraws: () ->
    seen = {}
    cardsToDraw = 3
    for card in @hand
      if seen[card.name]?
        cardsToDraw = 1
        break
      seen[card.name] = true
    cardsToDraw

  # `shantyTownDraws()` is the number of cards the player would draw upon
  # playing a Shanty town: either 0 or 2.
  shantyTownDraws: () ->
    cardsToDraw = 2
    for card in @hand
      if card.isAction
        cardsToDraw = 0
        break
    cardsToDraw
  
  # `actionBalance()` is a complex method meant to be used by AIs in
  # deciding whether they want +actions or +cards, for example.
  #
  # If the actionBalance is
  # less than 0, you want +actions, because otherwise you will have dead
  # action cards in hand or risk drawing them dead. If it is greater than
  # 0, you want +cards, because you have a surplus of actions and need
  # action cards to spend them on.
  actionBalance: () ->
    balance = @actions
    for card in @hand
      if card.isAction
        balance += card.actions
        balance--

        # Estimate the risk of drawing an action card dead.
        #
        # *TODO*: do something better when there are variable card-drawers.
        if card.actions == 0
          balance -= card.cards * this.getActionDensity()
    balance

  drawCards: (nCards) ->
    if @draw.length < nCards
      diff = nCards - @draw.length
      if @draw.length > 0
        this.log("#{@ai} draws #{@draw.length} cards.")
      @hand = @hand.concat(@draw)
      @draw = []
      if @discard.length > 0
        this.shuffle()
        this.drawCards(diff)
        
    else
      this.log("#{@ai} draws #{nCards} cards.")
      @hand = @hand.concat(@draw[0...nCards])
      @draw = @draw[nCards...]

  doDiscard: (card) ->
    idx = @hand.indexOf(card)
    if idx == -1
      this.warn("#{@ai} has no #{card} to discard")
      return
    @hand.splice(idx, 1)
    @discard.push(card)
  
  doTrash: (card) ->
    idx = @hand.indexOf(card)
    if idx == -1
      this.warn("#{@ai} has no #{card} to trash")
      return
    @hand.splice(idx, 1)
  
  shuffle: () ->
    this.log("#{@ai} shuffles.")
    if @draw.length > 0
      throw new Error("Shuffling while there are cards left to draw")
    shuffle(@discard)
    @draw = @discard
    @discard = []
    # TODO: add an AI decision for Stashes

  # Most PlayerStates are created by copying an existing one.
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
    other.log = @log
    other.turnsTaken = @turnsTaken
    other

# The State class
# ---------------
# A State instance stores the complete state of the game at a point in time.
# 
# Many operations will mutate the state, for the sake of efficiency.
# Any AI that evaluates different possible decisions must make a copy of
# that state with less information in it, anyway.
class State
  basicSupply: ['Curse', 'Copper', 'Silver', 'Gold',
                'Estate', 'Duchy', 'Province']
  
  # AIs can get at the `c` object that stores information about cards
  # by looking up `state.c`.
  cardInfo: c
  
  # Set up the state at the start of the game. Takes these arguments:
  #
  # - `ais`: a list of AI objects that will make the decisions, one per player.
  #   This sets the number of players in the game.
  # - `tableau`: the list of non-basic cards in the supply. Colony, Platinum,
  #   and Potion have to be listed explicitly.
  initialize: (ais, tableau) ->
    @players = (new PlayerState().initialize(ai, this.log) for ai in ais)
    @nPlayers = @players.length
    @current = @players[0]
    @supply = this.makeSupply(tableau)

    @bridges = 0
    @quarries = 0
    @copperValue = 1
    @phase = 'start'
    return this
  
  # Given the tableau (the set of non-basic cards in play), construct the
  # appropriate supply for the number of players.
  makeSupply: (tableau) ->
    allCards = this.basicSupply.concat(tableau)
    supply = {}
    for card in allCards
      card = c[card] ? card
      supply[card] = card.startingSupply(this)
    supply

  #### Informational methods
  # These methods are referred to by some card effects, but can also be useful
  # in crafting a strategy.
  #
  # `emptyPiles()` determines which supply piles are empty.
  emptyPiles: () ->
    piles = []
    for key, value of @supply
      if value == 0
        piles.push(key)
    piles
  
  # `numEmptyPiles()` simply returns the number of empty piles.
  numEmptyPiles: () ->
    this.emptyPiles().length
  
  # `gameIsOver()` returns whether the game is over.
  gameIsOver: () ->
    # The game can only end after a player has taken a full turn. Check that
    # by making sure the phase is `'start'`.
    return false if @phase != 'start'

    # Check all the conditions in which empty piles can end the game.
    emptyPiles = this.emptyPiles()
    if emptyPiles.length >= this.totalPilesToEndGame() \
        or (@nPlayers < 5 and emptyPiles.length >= 3) \
        or 'Province' in emptyPiles \
        or 'Colony' in emptyPiles
      this.log("Empty piles: #{emptyPiles}")
      return true
    return false
  
  # `countInSupply()` returns the number of copies of a card that remain
  # in the supply. It can take in either a card object or card name.
  #
  # If the card has never been in the supply, it returns 0,
  # so it is safe to refer to `state.countInSupply('Colony')` even in
  # a non-Colony game. This does not count as an empty pile, of course.
  countInSupply: (card) ->
    @supply[card] ? 0
  
  # `totalPilesToEndGame()` returns the number of empty piles that triggers
  # the end of the game, which is almost always 3.
  totalPilesToEndGame: () ->
    switch @nPlayers
      when 1, 2, 3, 4 then 3
      else 4

  # As a useful heuristic, `gainsToEndGame()` returns the minimum number of
  # buys/gains that would have to be used by an opponent who is determined to
  # end the game. A low number means the game is probably ending soon.
  gainsToEndGame: () ->
    counts = (count for card, count of @supply)
    numericSort(counts)
    # First, add up the smallest 3 (or 4) piles.
    piles = this.totalPilesToEndGame()
    minimum = 0
    for count in counts[...piles]
      minimum += count
    # Then compare this to the number of Provinces or possibly Colonies
    # remaining, and see which one is smallest.
    minimum = Math.min(minimum, @supply['Province'])
    if @supply['Colony']?
      minimum = Math.min(minimum, @supply['Colony'])
    minimum
  
  #### Playing a turn
  #
  # `doPlay` performs the next step of the game, which is a particular phase
  # of a particular player's turn. If the phase is...
  #
  # - 'start': resolve duration effects, then go to action phase
  # - 'action': play and resolve some number of actions, then go to
  #     treasure phase
  # - 'treasure': play and resolve some number of treasures, then go to
  #     buy phase
  # - 'buy': buy some number of cards, then go to cleanup phase
  # - 'cleanup': resolve cleanup effects, discard everything, draw 5 cards,
  #     and go to the start phase of the next player's turn.
  # 
  # To play the entire game, iterate `doPlay()` until `gameIsOver()`. Putting
  # this in a single loop would be a bad idea because it would make Web
  # browsers freeze up. Browser-facing code should return control after each
  # call to `doPlay()`.
  doPlay: () ->  
    switch @phase
      when 'start'
        @current.turnsTaken += 1
        this.log("\n== #{@current.ai}'s turn #{@current.turnsTaken} ==")
        this.log("Hand: #{@current.hand}")
        this.log("Draw: #{@current.draw}")
        this.log("Discard: #{@current.discard}")
        this.doDurationPhase()
        @phase = 'action'
      when 'action'
        this.log("(action phase)")
        this.doActionPhase()
        @phase = 'treasure'
      when 'treasure'
        this.log("(treasure phase)")
        this.doTreasurePhase()
        @phase = 'buy'
      when 'buy'
        this.log("(buy phase)")
        this.doBuyPhase()
        @phase = 'cleanup'
      when 'cleanup'
        this.log("(cleanup phase)")
        this.doCleanupPhase()
        this.rotatePlayer()
  
  # `@current.duration` contains all cards that are in play with duration
  # effects. At the start of the turn, check all of these cards and run their
  # `onDuration` method.
  doDurationPhase: () ->
    for card in @current.duration
      this.log("#{@current.ai} resolves the duration effect of #{card}.")
      card.onDuration(this)
  
  # Perform the action phase. Ask the AI repeatedly which action to play,
  # until there are no more action cards to play or there are no
  # actions remaining to play them with, or the AI chooses `null`, indicating
  # that it doesn't want to play an action.
  doActionPhase: () ->
    while @current.actions > 0
      validActions = [null]

      # Determine the set of unique actions that may be played.
      for card in @current.hand
        if card.isAction and card not in validActions
          validActions.push(card)

      # Ask the AI for its choice.
      action = @current.ai.chooseAction(this, validActions)
      return if action is null
      this.log("#{@current.ai} plays #{action}.")

      # Remove the action from the hand and put it in the play area.
      idx = @current.hand.indexOf(action)
      if idx == -1
        this.warn("#{@current.ai} chose an invalid action.")
        return
      @current.hand.splice(idx, 1)
      @current.inPlay.push(action)

      # Subtract 1 from the action count, perform the action, and go back
      # to the start of the loop.
      @current.actions -= 1
      action.onPlay(this)
  
  # The "treasure phase" is a concept introduced in Prosperity. After playing
  # actions, you play any number of treasures in some order. This loop
  # repeats until the AI chooses `null`, either because there are no treasures
  # left to play or because it does not want to play any more treasures.
  doTreasurePhase: () ->
    loop
      validTreasures = [null]

      # Determine the set of unique treasures that may be played.
      for card in @current.hand
        if card.isTreasure and card not in validTreasures
          validTreasures.push(card)
      
      # Ask the AI for its choice.
      treasure = @current.ai.chooseTreasure(this, validTreasures)
      return if treasure is null
      this.log("#{@current.ai} plays #{treasure}.")

      # Remove the treasure from the hand and put it in the play area.
      idx = @current.hand.indexOf(treasure)
      if idx == -1
        this.warn("#{@current.ai} chose an invalid treasure")
        return
      @current.hand.splice(idx, 1)
      @current.inPlay.push(treasure)
      treasure.onPlay(this)
  
  # Ask the AI what to buy. Repeat until the player has no buys left or
  # the AI chooses to buy nothing.
  doBuyPhase: () ->
    while @current.buys > 0
      buyable = [null]
      for cardname, count of @supply
        # Because the supply must reference cards by their names, we use
        # `c[cardname]` to get the actual object for the card.
        card = c[cardname]

        # Determine whether each card can be bought in the current state.
        if card.mayBeBought(this) and count > 0
          [coinCost, potionCost] = card.getCost(this)
          if coinCost <= @current.coins and potionCost <= @current.potions
            buyable.push(card)
      
      # Ask the AI for its choice.
      this.log("Coins: #{@current.coins}, Potions: #{@current.potions}, Buys: #{@current.buys}")
      choice = @current.ai.chooseBuy(this, buyable)
      return if choice is null
      this.log("#{@current.ai} buys #{choice}.")

      # Update money and buys.
      [coinCost, potionCost] = choice.getCost(this)
      @current.coins -= coinCost
      @current.potionCost -= potionCost
      @current.buys -= 1

      # Gain the card and deal with the effects.
      this.gainCard(@current, choice)
      choice.onBuy(this)
  
  # Handle all the things that happen at the end of the turn.
  doCleanupPhase: () ->
    # Discard old duration cards.
    @current.discard = @current.discard.concat @current.duration
    @current.duration = []

    # If there are cards set aside at this point, it probably means something
    # went wrong in performing an action. But clean them up anyway.
    if @current.setAside.length > 0
      this.warn(["Cards were set aside at the end of turn", @current.setAside])
      @current.discard = @current.discard.concat @current.setAside
      @current.setAside = []

    # Clean up cards in play.
    while @current.inPlay.length > 0
      card = @current.inPlay[0]
      @current.inPlay = @current.inPlay[1...]
      # Put duration cards by default in the duration area, and other cards
      # in play in the discard pile.
      if card.isDuration
        @current.duration.push(card)
      else
        @current.discard.push(card)
      # Handle effects of cleaning up the card, which may involve moving it
      # somewhere else.
      card.onCleanup(this)

    # Discard the remaining cards in hand.
    @current.discard = @current.discard.concat(@current.hand)
    @current.hand = []

    # Reset things for the next turn.
    @current.actions = 1
    @current.buys = 1
    @current.coins = 0
    @current.potions = 0
    @copperValue = 1
    @bridges = 0
    @quarries = 0

    # Finally, draw the next hand of five cards.
    @current.drawCards(5)

  # The player list is implemented so that the current player is always first
  # in the list; the list rotates after every turn.
  #
  # For convenience, the attribute `@current` always points to the current
  # player.
  rotatePlayer: () ->
    @players = @players[1...@nPlayers].concat [@players[0]]
    @current = @players[0]
    @phase = 'start'
  
  #### Small-scale effects
  # `gainCard` performs the effects of a player gaining a card.
  #
  # This is one of many events that affects a particular player, and
  # also has some effect on the overall state (in that the supply is
  # decreased). In this function and others like it, the `player` argument
  # is the appropriate PlayerState object to affect. This must, of course,
  # be one of the objects in the `@players` array.
  gainCard: (player, card) ->
    if @supply[card] > 0
      player.discard.push(card)
      @supply[card] -= 1
    # TODO: handle gain reactions
  
  # Effects of an action could cause players to reveal their hand.
  # So far, nothing happens as a result, but in the future, AIs might
  # be able to take advantage of the information.
  revealHand: (player) ->
  
  # `drawCards` causes the player to draw `num` cards.
  #
  # This currently passes through directly to the PlayerState, without
  # passing any information from the global state.
  # An improved version would pass the state in case the player shuffles,
  # and has Stash in the deck, and wants to use information from the state
  # to decide where to put the Stash.
  drawCards: (player, num) ->
    player.drawCards(num)

  # `allowDiscard` allows a player to discard 0 through `num` cards.
  allowDiscard: (player, num) ->
    numDiscarded = 0
    while numDiscarded < num
      # In `allowDiscard`, valid discards are the entire hand, plus `null`
      # to stop discarding.
      validDiscards = player.hand.slice(0)
      validDiscards.push(null)
      choice = player.ai.chooseDiscard(this, validDiscards)
      return if choice is null
      this.log("#{player.ai} discards #{choice}.")
      numDiscarded++
      player.doDiscard(choice)
  
  # `requireDiscard` requires the player to discard exactly `num` cards,
  # except that it stops if the player has 0 cards in hand.
  requireDiscard: (player, num) ->
    numDiscarded = 0
    while numDiscarded < num
      validDiscards = player.hand.slice(0)
      return if validDiscards.length == 0
      choice = player.ai.chooseDiscard(this, validDiscards)
      this.log("#{player.ai} discards #{choice}.")
      numDiscarded++
      player.doDiscard(choice)
  
  # `allowTrash` and `requireTrash` are similar to `allowDiscard` and
  # `requireDiscard`.
  allowTrash: (player, num) ->
    numTrashed = 0
    while numTrashed < num
      valid = player.hand.slice(0)
      valid.push(null)
      choice = player.ai.chooseTrash(this, valid)
      return if choice is null
      this.log("#{player.ai} trashes #{choice}.")
      numTrashed++
      player.doTrash(choice)
  
  requireTrash: (player, num) ->
    numTrashed = 0
    while numTrashed < num
      valid = player.hand.slice(0)
      return if valid.length == 0
      choice = player.ai.chooseTrash(this, valid)
      this.log("#{player.ai} trashes #{choice}.")
      numTrashed++
      player.doTrash(choice)
  
  # `attackOpponents` takes in a function of one argument, and applies
  # it to all players except the one whose turn it is.
  #
  # The function should take in the PlayerState of the player to attack,
  # and alter it somehow. This function can also involve the global state:
  # it doesn't need to be passed in because it's already in scope in the place
  # where the action is defined. See `Militia` in `cards.coffee` for an
  # example.
  attackOpponents: (effect) ->
    for opp in @players[1...]
      this.attackPlayer(opp, effect)
  
  # `attackPlayer` does the work of attacking a particular player, including
  # handling their reactions to attacks.
  attackPlayer: (player, effect) ->
    # The most straightforward reaction is Moat, which cancels the attack.
    # Set a flag on the PlayerState that indicates that the player has not
    # yet revealed a Moat.
    player.moatProtected = false
    for card in player.hand
      if card.isReaction
        card.reactToAttack(player)

    # If the player has revealed a Moat, or has Lighthouse in the duration
    # area, the attack is averted. Otherwise, it happens.
    if not player.moatProtected and not c.Lighthouse in player.duration
      effect(player)
  
  #### Bookkeeping
  # `copy()` makes a copy of this state that can be safely mutated
  # without affecting the original state.
  #
  # Ideally, the AI would be passed a copy of the state, with unknown
  # information randomized, when it is asked to make a decision. This would
  # allow it to try simulating the effects of various plays without actually
  # breaking the game. But this isn't implemented yet, so make this a TODO.
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

    # If something overrode the log function, make sure that's preserved.
    newState.log = @log
    newState

  # Games can provide output using the `log` function. For now it just
  # prints to the console.
  log: (obj) ->
    if console?
      console.log(obj)

  # A warning has a similar effect to a log message, but indicates that
  # something has gone wrong with the gameplay.
  warn: (obj) ->
    if console?
      console.log("WARNING: ", obj)


# Define some possible tableaux to play the game with. None of these are
# actually legal tableaux, but that gives strategies more room to play.
this.tableaux = {
  moneyOnly: []
  moneyOnlyColony: ['Platinum', 'Colony']
  all: c.allCards
  noColony: (card for card in c.allCards if card != 'Platinum' and card != 'Colony')
}

# Utility functions
# -----------------
# General function to randomly shuffle a list.
shuffle = (v) ->
  i = v.length
  while i
    j = parseInt(Math.random() * i)
    i -= 1
    temp = v[i]
    v[i] = v[j]
    v[j] = temp
  v

# Count the number of times a value appears in a list, coercing everything
# to its string value.
countStr = (list, elt) ->
  count = 0
  for member in list
    if member.toString() == elt.toString()
      count++
  count

# Sort by numeric value. You'd think this would be in the standard library.
numericSort = (array) ->
  array.sort( (a, b) -> (a-b) )

# Exports
# -------
# Export the State and PlayerState classes for other modules to use.
this.State = State
this.PlayerState = PlayerState

# Indecisive imports
# ------------------
# Recall that this code begins with:
#
#     {c} = require './cards' if require?
#
# This means "get the variable named `c` from the module `./cards`. Unless
# you don't know how. In that case, don't."
#
# Here's why that is useful. When the code
# is running inside node.js, it will use node.js's import system. This
# uses the predefined function `require`, which doesn't exist in a 
# Web browser's JS environment.
#
# When running in a web browser, there is no sane way for one module to
# import another. Instead,
# the typical practice -- which we will use too -- is to just load a bunch of
# JavaScript files into the same global namespace.
#
# In that case, the variable `c` already exists without any additional effort
# from us. We're polluting the global namespace and defeating some of the
# point of modules, but that's how most JavaScript in the wild works anyway.
