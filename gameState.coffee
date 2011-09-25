# Many modules begin with this "indecisive import" pattern. It's messy
# but it gets the job done, and it's explained at the bottom of this
# documentation.
{c,transferCard,transferCardToTop} = require './cards' if exports?

# The PlayerState class
# ---------------------  
# A PlayerState stores the part of the game state
# that is specific to each player, plus what AI is making the decisions.
class PlayerState
  # At the start of the game, the State should
  # .initialize() each PlayerState, which assigns its AI and sets up its
  # starting state. Before then, it is an empty object.
  initialize: (ai, logFunc) ->
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
    
    # If you want to ask what's in a player's draw pile, be sure to only do
    # it to a *hypothetical* PlayerState that you retrieve with
    # `state.hypothetical(ai)`. Then the draw pile will contain a random
    # guess, as opposed to the actual hidden information.
    @draw = []
    @inPlay = []
    @duration = []
    @setAside = []
    @moatProtected = false
    @tacticians = 0  # number of Tacticians that will go to the duration area
    @turnsTaken = 0

    # To stack various card effects, we'll have to keep track of the location
    # of the card we're playing and the card we're gaining. For example, if
    # you have two Feasts in hand and you Throne Room a Feast, you don't
    # trash *both* Feasts -- you trash one and then do nothing, based on the
    # fact that *that particular* Feast is already in the trash.
    @playLocation = 'inPlay'
    @gainLocation = 'discard'
    
    # The `actionStack` is not a physical location for cards to be in; it's
    # a computational list of what actions are in play but not yet resolved.
    # This becomes particularly important with King's Courts.
    @actionStack = []
    
    # Set the properties passed in from the State.
    @ai = ai
    @logFunc = logFunc

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
  
  # `getCurrentAction()` returns the action being resolved that is on the
  # top of the stack.
  getCurrentAction: () ->
    @actionStack[@actionStack.length - 1]

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
  
  # `countCardTypeInDeck(type)` counts the number of cards of a given type
  # in the deck. Curse is not a type for these purposes, it's a card.
  countCardTypeInDeck: (type) ->
    typeChecker = 'is'+type
    count = 0
    for card in this.getDeck()
      if card[typeChecker]
        count++
    count

  # `getVP()` returns the number of VP the player would have if the game
  # ended now.
  getVP: (state) ->
    total = @chips
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

  # `getAvailableMoney()` counts the money the player might have upon playing
  # all treasure in hand. Banks, Ventures, and such are counted inaccurately
  # so far.
  getAvailableMoney: () ->
    this.coins + this.getTreasureInHand()
  
  # `getTreasureInHand()` adds up the value of the treasure in the player's
  # hand. Banks and Ventures and such will be inaccurate.
  #
  # A `getMoneyInHand(state)` method that counted playable action cards would
  # be great, but I'm skipping it for now because it's difficult to get right.
  getTreasureInHand: () ->
    total = 0
    for card in this.hand
      if card.isTreasure
        total += card.coins
    total    
  
  # `countInHand(card)` counts the number of copies of a card in hand.
  countInHand: (card) ->
    countStr(@hand, card)

  # `countInDiscard(card)` counts the number of copies of a card in the discard
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
  # 
  # *TODO*: allow for a hypothetical version where it's okay to have another
  # Menagerie.
  menagerieDraws: () ->
    seen = {}
    cardsToDraw = 3
    for card in @hand
      if seen[card.name]?
        cardsToDraw = 1
        break
      seen[card.name] = true
    cardsToDraw

  # `shantyTownDraws()` is the number of cards the player draws upon
  # playing a Shanty town: either 0 or 2.
  #
  # Set `hypothetical` to `true` if deciding whether to play a Shanty Town
  # (because it won't be in your hand anymore when you do).
  shantyTownDraws: (hypothetical = false) ->
    cardsToDraw = 2
    skippedShanty = false
    for card in @hand
      if card.isAction
        if hypothetical and not skippedShanty
          skippedShanty = true
        else
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
  
  # What is the trashing power of this hand?
  trashingInHand: () ->
    trash = 0
    for card in this.hand
      # Count actions that simply trash a constant number of cards from hand.
      trash += card.trash
      # Add other trashers, including the trash-on-gain power of Watchtower.
      trash += 2 if card is c.Steward
      trash += 2 if card is c['Trading Post']
      trash += 4 if card is c.Chapel
      trash += 1 if card is c.Masquerade
      trash += 2 if card is c.Ambassador
      trash += 1 if card is c.Watchtower
    return trash
  
  numUniqueCardsInPlay: () ->
    unique = []
    cards = @inPlay.concat(@duration)
    for card in cards
      if card not in unique
        unique.push(card)
    return unique.length

  #### Methods that modify the PlayerState

  drawCards: (nCards) ->
    drawn = this.getCardsFromDeck(nCards)
    @hand = @hand.concat(drawn)
    this.log("#{@ai} draws #{drawn.length} cards (#{drawn}).")
    return drawn

  discardFromDeck: (nCards) ->
    drawn = this.getCardsFromDeck(nCards)
    @discard = @discard.concat(drawn)
    this.log("#{@ai} draws and discards #{drawn.length} cards (#{drawn}).")
    return drawn
  
  # `getCardsFromDeck` is a sub-method of many things that need to happen
  # with the game. It takes `nCards` cards off the deck, and then
  # *returns* them so you can do something with them.
  # 
  # Code that calls `getCardsFromDeck`
  # is responsible for making sure the cards aren't just "dropped on the
  # floor" after that, so to speak.
  getCardsFromDeck: (nCards) ->
    if @draw.length < nCards
      diff = nCards - @draw.length
      drawn = @draw.slice(0)
      @draw = []
      if @discard.length > 0
        this.shuffle()
        return drawn.concat(this.getCardsFromDeck(diff))
      else
        return drawn
        
    else
      drawn = @draw[0...nCards]
      @draw = @draw[nCards...]
      return drawn
  
  doDiscard: (card) ->
    if card not in @hand
      this.warn("#{@ai} has no #{card} to discard")
      return
    this.log("#{@ai} discards #{card}.")
    @hand.remove(card)
    @discard.push(card)
  
  doTrash: (card) ->
    if card not in @hand
      this.warn("#{@ai} has no #{card} to trash")
      return
    this.log("#{@ai} trashes #{card}.")
    @hand.remove(card)
  
  doPutOnDeck: (card) ->
    if card not in @hand
      this.warn("#{@ai} has no #{card} to put on deck.")
      return
    this.log("#{@ai} puts #{card} on deck.")
    @hand.remove(card)
    @draw.push(card)
  
  shuffle: () ->
    this.log("(#{@ai} shuffles.)")
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
    other.playLocation = @playLocation
    other.gainLocation = @gainLocation
    other.actionStack = @actionStack.slice(0)
    other.tacticians = @tacticians
    other.ai = @ai
    other.logFunc = @logFunc
    other.turnsTaken = @turnsTaken
    other
  
  # Games can provide output using the `log` function.
  log: (obj) ->
    if this.logFunc?
      this.logFunc(obj)
    else
      if console?
        console.log(obj)


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
  initialize: (ais, tableau, logFunc) ->
    this.logFunc = logFunc
    @players = (new PlayerState().initialize(ai, this.logFunc) for ai in ais)
    @nPlayers = @players.length
    @current = @players[0]
    @supply = this.makeSupply(tableau)
    @prizes = [c["Bag of Gold"], c.Diadem, c.Followers, c.Princess, c["Trusty Steed"]]
    @tradeRouteMat = []
    @tradeRouteValue = 0

    @bridges = 0
    @quarries = 0
    @copperValue = 1
    @phase = 'start'
    @cache = {}
    
    @extraturn = false
    
    # The `depth` indicates how deep into hypothetical situations we are. A depth of 0
    # indicates the state of the actual game.
    @depth = 0
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
      for [playerName, vp, turns] in this.getFinalStatus()
        this.log("#{playerName} took #{turns} turns and scored #{vp} points.")
      return true
    return false

  # `getFinalStatus()` is a useful thing to call when `gameIsOver()` is true.
  # It returns a list of triples of [player name, score, turns taken].
  getFinalStatus: () ->
    ([player.ai.toString(), player.getVP(this), player.turnsTaken] for player in @players)

  # `getWinners()` returns a list (usually of length 1) of the names of players
  # that won the game, or would win if it were over now.
  getWinners: () ->
    scores = this.getFinalStatus()
    best = []
    bestScore = -Infinity
    
    for [player, score, turns] in scores
      # Modify the score by subtracting a fraction of turnsTaken.
      modScore = score - turns/100

      if modScore == bestScore
        best.push(player)
      if modScore > bestScore
        best = [player]
        bestScore = modScore
    best
  
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
    if @cache.gainsToEndGame?
      return @cache.gainsToEndGame
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

    # Cache the result; apparently it's expensive to compute.
    @cache.gainsToEndGame = minimum
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
        if not @extraturn
          @current.turnsTaken += 1
          this.log("\n== #{@current.ai}'s turn #{@current.turnsTaken} ==")
          this.doDurationPhase()
          @phase = 'action'
        else
          this.log("\n== #{@current.ai}'s turn #{@current.turnsTaken}+ ==")
          this.doDurationPhase()
          @phase = 'action'
      when 'action'
        this.doActionPhase()
        @phase = 'treasure'
      when 'treasure'
        this.doTreasurePhase()
        @phase = 'buy'
      when 'buy'
        this.doBuyPhase()
        @phase = 'cleanup'
      when 'cleanup'
        this.doCleanupPhase()
        if not @extraturn
          this.rotatePlayer()
        else
          @phase = 'start'
  
  # `@current.duration` contains all cards that are in play with duration
  # effects. At the start of the turn, check all of these cards and run their
  # `onDuration` method.
  doDurationPhase: () ->
    # iterate backwards because cards might move
    for i in [@current.duration.length-1...-1]
      card = @current.duration[i]
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
      # Remove the action from the hand and put it in the play area.
      if action not in @current.hand
        this.warn("#{@current.ai} chose an invalid action.")
        return
      this.playAction(action)
  
  # The current player plays an action from the hand, and performs the effect
  # of the action.
  playAction: (action) ->
    this.log("#{@current.ai} plays #{action}.")

    # Subtract 1 from the action count and perform the action.
    @current.hand.remove(action)
    @current.inPlay.push(action)
    @current.playLocation = 'inPlay'
    @current.actions -= 1
    this.resolveAction(action)
    
  # Another event that causes actions to be played, such as Throne Room,
  # should skip straight to `resolveAction`.
  resolveAction: (action) ->
    @current.actionStack.push(action)
    action.onPlay(this)
    @current.actionStack.pop()
  
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
      if treasure not in @current.hand
        this.warn("#{@current.ai} chose an invalid treasure")
        return
      this.playTreasure(treasure)
  
  playTreasure: (treasure) ->
    @current.hand.remove(treasure)
    @current.inPlay.push(treasure)
    @current.playLocation = 'inPlay'
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
      choice = @current.ai.chooseGain(this, buyable)
      return if choice is null
      this.log("#{@current.ai} buys #{choice}.")

      # Update money and buys.
      [coinCost, potionCost] = choice.getCost(this)
      @current.coins -= coinCost
      @current.potions -= potionCost
      @current.buys -= 1

      # Gain the card and deal with the effects.
      this.gainCard(@current, choice, 'discard', true)
      choice.onBuy(this)
      
      # Handle cards such as Talisman that respond to cards being bought.
      for i in [@current.inPlay.length-1...-1]
        cardInPlay = @current.inPlay[i]
        cardInPlay.buyInPlayEffect(this, card)

      # Gain victory for each Goons in play.
      goonses = @current.countInPlay('Goons')
      if goonses > 0
        this.log("...gaining #{goonses} VP.")
        @current.chips += goonses
  
  # Handle all the things that happen at the end of the turn.
  doCleanupPhase: () ->
    # Clean up Walled Villages first
    actionCardsInPlay = 0
    for card in @current.inPlay
      if card.isAction
        actionCardsInPlay += 1

    if actionCardsInPlay <= 2  
      while c['Walled Village'] in @current.inPlay
        transferCardToTop(c['Walled Village'], @current.inPlay, @current.draw)
        this.log("#{@current.ai} returns a Walled Village to the top of the deck.")

    @extraturn = not @extraturn and (c['Outpost'] in @current.inPlay)
    
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
    @current.tacticians = 0
    @copperValue = 1
    @bridges = 0
    @quarries = 0

    #Announce extra turn
    if @extraturn       
      this.log("#{@current.ai} takes an extra turn from Outpost.")
    
    # Finally, draw the next hand of three/five cards.
    if not (c.Outpost in @current.duration)
      @current.drawCards(5)
    else
      @current.drawCards(3)


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
  #
  # `suppressMessage` is true when this happens as the direct result of a
  # buy. Nobody wants to read "X buys Y. X gains Y." all the time.
  gainCard: (player, card, gainLocation='discard', suppressMessage=false) ->
    delete @cache.gainsToEndGame
    if card in @prizes or @supply[card] > 0
      if not suppressMessage
        this.log("#{player.ai} gains #{card}.")
      player.gainLocation = gainLocation
      location = player[player.gainLocation]
      location.unshift(card)
      if card in @prizes
        @prizes.remove(card)
      else
        @supply[card] -= 1
      if @supply["Trade Route"]? and card.isVictory and card not in @tradeRouteMat
        @tradeRouteMat.push(card)
        @tradeRouteValue += 1
      
      # Handle cards such as Royal Seal that respond to gains while they are
      # in play.
      for i in [player.inPlay.length-1...-1]
        cardInPlay = player.inPlay[i]
        cardInPlay.gainInPlayEffect(this, card)
      
      # Handle cards such as Watchtower that react to gains as a Reaction card.
      for i in [player.hand.length-1...-1]
        reactCard = player.hand[i]
        if reactCard.isReaction
          reactCard.reactToGain(this, player, card)
    else
      this.log("There is no #{card} to gain.")
  
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
  # 
  # The drawn cards will be returned.
  drawCards: (player, num) ->
    player.drawCards(num)
  
  # `discardFromDeck` puts *num* cards from the top of the deck directly
  # in the discard pile. It returns the set of cards, for the benefit of
  # actions that do something based on which cards were discarded.
  discardFromDeck: (player, num) ->
    player.discardFromDeck(num)

  # `getCardsFromDeck` is superficially similar to `drawCards`, but it does
  # not put the cards into the hand. Any code that calls it needs to determine
  # what happens to those cards (otherwise they'll be trashed!) This is useful
  # for effects that say "draw *n* cards, do something based on them, and
  # discard them".
  getCardsFromDeck: (player, num) ->
    player.getCardsFromDeck(num)

  # `allowDiscard` allows a player to discard 0 through `num` cards.
  allowDiscard: (player, num) ->
    discarded = []
    while discarded.length < num
      # In `allowDiscard`, valid discards are the entire hand, plus `null`
      # to stop discarding.
      validDiscards = player.hand.slice(0)
      validDiscards.push(null)
      choice = player.ai.chooseDiscard(this, validDiscards)
      return discarded if choice is null
      discarded.push(choice)
      player.doDiscard(choice)
    return discarded
  
  # `requireDiscard` requires the player to discard exactly `num` cards,
  # except that it stops if the player has 0 cards in hand.
  requireDiscard: (player, num) ->
    discarded = []
    while discarded.length < num
      validDiscards = player.hand.slice(0)
      return discarded if validDiscards.length == 0
      choice = player.ai.chooseDiscard(this, validDiscards)
      discarded.push(choice)
      player.doDiscard(choice)
    return discarded
  
  # `allowTrash` and `requireTrash` are similar to `allowDiscard` and
  # `requireDiscard`.
  allowTrash: (player, num) ->
    trashed = []
    while trashed.length < num
      valid = player.hand.slice(0)
      valid.push(null)
      choice = player.ai.chooseTrash(this, valid)
      return trashed if choice is null
      trashed.push(choice)
      player.doTrash(choice)
    return trashed
  
  requireTrash: (player, num) ->
    trashed = []
    while trashed.length < num
      valid = player.hand.slice(0)
      return trashed if valid.length == 0
      choice = player.ai.chooseTrash(this, valid)
      trashed.push(choice)
      player.doTrash(choice)
    return trashed
  
  # `gainOneOf` gives the player a choice of cards to gain. Include
  # `null` if gaining nothing is an option.
  gainOneOf: (player, options, location='discard') ->
    choice = player.ai.chooseGain(this, options)
    return null if choice is null
    this.gainCard(player, choice, location)
    return choice
  
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
    
    # Iterate backwards because we might be removing things from the list
    for i in [player.hand.length-1...-1]
      card = player.hand[i]
      if card.isReaction
        card.reactToAttack(this, player)
    
    # If the player has revealed a Moat, or has Lighthouse in the duration
    # area, the attack is averted. Otherwise, it happens.
    if player.moatProtected
      this.log("#{player.ai} is protected by a Moat.")
    else if c.Lighthouse in player.duration
      this.log("#{player.ai} is protected by the Lighthouse.")
    else
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
    newState.tradeRouteMat = @tradeRouteMat
    newState.tradeRouteValue = @tradeRouteValue
    newState.bridges = @bridges
    newState.quarries = @quarries
    newState.copperValue = @copperValue
    newState.phase = @phase
    newState.cache = @cache

    # If something overrode the log function, make sure that's preserved.
    newState.logFunc = @logFunc
    newState

  # `hypothetical(ai)` returns a State and PlayerState that an AI can do
  # whatever it wants to without affecting the real state:
  #
  # - Modifying the state will not affect the game (it is a copy, after all).
  # - The hidden information in the state is randomized.
  # - All the other AIs will be replaced by copies of the given AI.
  #
  # An AI that wants to test a hypothesis should do this:
  #   [state, my] = state.hypothetical(this)
  hypothetical: (ai) ->
    state = this.copy()
    my = null
    for player in state.players
      if player.ai isnt ai
        player.ai = ai.copy()

        # We don't know what's in their hand or their deck, so shuffle them
        # together randomly, preserving the number of cards.
        handSize = player.hand.length
        combined = player.hand.concat(player.draw)
        shuffle(combined)
        player.hand = combined[...handSize]
        player.draw = combined[handSize...]
      else
        shuffle(player.draw)
        my = player

    state.depth = this.depth + 1
    [state, my]

  # Games can provide output using the `log` function.
  log: (obj) ->
    # Only log things that actually happen.
    if @depth == 0
      if this.logFunc?
        this.logFunc(obj)
      else 
        if console?
          console.log(obj)

  # A warning has a similar effect to a log message, but indicates that
  # something has gone wrong with the gameplay.
  warn: (obj) ->
    if console?
      console.warn("WARNING: ", obj)

# Define some possible tableaux to play the game with. None of these are
# actually legal tableaux, but that gives strategies more room to play.
this.tableaux = {
  moneyOnly: []
  moneyOnlyColony: ['Platinum', 'Colony']
  all: c.allCards
}

# How to remove something from a JavaScript array. Modifies the list and
# returns the 0 or 1 removed elements.
Array.prototype.remove = (elt) ->
  idx = this.lastIndexOf(elt)
  if idx != -1
    this.splice(idx, 1)
  else
    []

# Define the additional tableau of everything but Platinum/Colony.
# If there's a better way to remove items from a JS array, I'd like to know
# what it is.
noColony = this.tableaux.all.slice(0)
noColony.remove('Platinum')
noColony.remove('Colony')
this.tableaux.noColony = noColony

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
#     {c} = require './cards' if exports?
#
# This means "get the variable named `c` from the module `./cards`. Unless
# there's no module system. In that case, don't."
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
