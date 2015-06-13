# This "indecisive import" pattern is messy but it gets the job done, and it's
# explained at the bottom of this documentation.
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
    @coinTokens = 0
    @coinTokensSpendThisTurn = 0
    @multipliedDurations = []
    @chips = 0
    @hand = []
    @discard = [c.Copper, c.Copper, c.Copper, c.Copper, c.Copper,
                c.Copper, c.Copper, c.Estate, c.Estate, c.Estate]

    # A mat is a place where cards can store inter-turn state for a player.
    # It can correspond to a physical mat, like the Island or Pirate Ship
    # Mat or just a place to set things aside for cards like Haven.
    @mats = {}
    
    # If you want to ask what's in a player's draw pile, be sure to only do
    # it to a *hypothetical* PlayerState that you retrieve with
    # `state.hypothetical(ai)`. Then the draw pile will contain a random
    # guess, as opposed to the actual hidden information.
    @draw = []
    @inPlay = []
    @duration = []
    @setAside = []
    @gainedThisTurn = []
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
    result = [].concat(@draw, @discard, @hand, @inPlay, @duration, @setAside)

    for own name, contents of @mats when contents?
      # If contents is a card or an array containing cards, add it to the list
      if contents.hasOwnProperty('playEffect') || contents[0]?.hasOwnProperty('playEffect')
        result = result.concat(contents)
    result

  # `getCurrentAction()` returns the action being resolved that is on the
  # top of the stack.
  getCurrentAction: () ->
    @actionStack[@actionStack.length - 1]

  # `getMultiplier()` gets the value of the multipier that is currently being
  # played: 1 in most cases, 2 after playing Throne Room, 3 after playing
  # King's Court.
  getMultiplier: () ->
    action = this.getCurrentAction()
    if action?
      return action.getMultiplier()
    else
      return 1

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

  # Aliases for `numCardsInDeck` that you might use intuitively. 
  countCardsInDeck: this.numCardsInDeck
  cardsInDeck: this.numCardsInDeck
  
  # `countCardTypeInDeck(type)` counts the number of cards of a given type
  # in the deck. Curse is not a type for these purposes, it's a card.
  countCardTypeInDeck: (type) ->
    typeChecker = 'is'+type
    count = 0
    for card in this.getDeck()
      if card[typeChecker]
        count++
    count
  numCardTypeInDeck: this.countCardTypeInDeck

  # `getVP()` returns the number of VP the player would have if the game
  # ended now.
  getVP: (state) ->
    total = @chips
    for card in this.getDeck()
      total += card.getVP(this)
    total
  countVP: this.getVP
  
  # `getTotalMoney()` adds up the total money in the player's deck,
  # including both Treasure and +$x, +y Actions cards.
  getTotalMoney: () ->
    total = 0
    for card in this.getDeck()
      if card.isTreasure or card.actions >= 1
        total += card.coins
#        total += card.coinTokens
    total
  totalMoney: this.getTotalMoney

  # `getAvailableMoney()` counts the money the player might have upon playing
  # all treasure in hand. Banks, Ventures, and such are counted inaccurately
  # so far.
  getAvailableMoney: () ->
    this.coins + this.getTreasureInHand()
  availableMoney: this.getAvailableMoney
  
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
  treasureInHand: this.getTreasureInHand
  
  countPlayableTerminals: (state) ->
    if (@actions>0)
      @actions + ( (Math.max (card.getActions(state) - 1), 0 for card in this.hand).reduce (s,t) -> s + t)
    else 0
  numPlayableTerminals: this.countPlayableTerminals    
  playableTerminals: this.countPlayableTerminals    
   
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
    this.countCardTypeInDeck('Action')
  
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

  # `deckActionBalance()` is a measure of action balance across the entire
  # deck.
  deckActionBalance: () ->
    balance = 0
    for card in this.getDeck()
      if card.isAction
        balance += card.actions
        balance--
    return balance / this.numCardsInDeck()

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
  countUniqueCardsInPlay: this.numUniqueCardsInPlay
  uniqueCardsInPlay: this.numUniqueCardsInPlay

  #### Methods that modify the PlayerState

  drawCards: (nCards) ->
    drawn = this.getCardsFromDeck(nCards)
    Array::push.apply @hand, drawn
    this.log("#{@ai} draws #{drawn.length} cards: #{drawn}.")
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
  
  # `dig` is a function to draw and reveal cards from the deck until
  # certain ones are found. The cards to be found are defined by digFunc,
  # which takes (state, card) and returns true if card is one that we're
  # trying find. For example, Venture's and Adventurer's would be
  # digFunc: (state, card) -> card.isTreasure
  #
  # nCards is the number of cards we're looking for; usually 1, but Golem
  # and Adventurer look for 2 cards.
  #
  # By default, discard the revealed and set aside cards, but Scrying Pool
  # digs for a card that is not an action, then draws up all the revealed
  # actions as well; discardSetAside allows a card calling dig to do
  # something with setAside other than discarding.
  dig: (state, digFunc, nCards=1, discardSetAside=true) ->
    foundCards = [] # These are the cards you're looking for
    revealedCards = [] # All the cards drawn and revealed from the deck
    while foundCards.length < nCards
      drawn = this.getCardsFromDeck(1)
      break if drawn.length == 0
      card = drawn[0]
      revealedCards.push(card)
      if digFunc(state, card)
        foundCards.push(card)
      else
        this.setAside.push(card)
    if revealedCards.length == 0
      this.log("...#{this.ai} has no cards to draw.")
    else
      this.log("...#{this.ai} reveals #{revealedCards}.")
    if discardSetAside
      if this.setAside.length > 0
        this.log("...#{this.ai} discards #{this.setAside}.")
      this.discard = this.discard.concat(this.setAside)
      state.handleDiscards(this, this.setAside)
      this.setAside = []
    foundCards
  
  discardFromDeck: (nCards) ->
    throw new Error("discardFromDeck is done by the state now")
  
  doDiscard: (card) ->
    throw new Error("doDiscard is done by the state now")
  
  doTrash: (card) ->
    throw new Error("doTrash is done by the state now")

  doPutOnDeck: (card) ->
    throw new Error("doPutOnDeck is done by the state now")
  
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
    other.coinTokens = @coinTokens
    other.multipliedDurations = @multipliedDurations.slice(0)

    # Clone mat contents, deep-copying arrays of cards
    other.mats = {}
    for own name, contents of @mats
      if contents instanceof Array
        contents = contents.concat()
      other.mats[name] = contents

    other.chips = @chips
    other.hand = @hand.slice(0)
    other.draw = @draw.slice(0)
    other.discard = @discard.slice(0)
    other.inPlay = @inPlay.slice(0)
    other.duration = @duration.slice(0)
    other.setAside = @setAside.slice(0)
    other.gainedThisTurn = @gainedThisTurn.slice(0)
    other.playLocation = @playLocation
    other.gainLocation = @gainLocation
    other.actionStack = @actionStack.slice(0)
    other.actionsPlayed = @actionsPlayed
    other.ai = @ai
    other.logFunc = @logFunc
    other.turnsTaken = @turnsTaken
    other.coinTokensSpendThisTurn = @coinTokensSpendThisTurn
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
# Almost all operations work by changing the game state. This means that if
# AI code wants to evaluate potential decisions, it should do them using a
# copy of the state (often one with hidden information in it).
class State
  basicSupply: [c.Curse, c.Copper, c.Silver, c.Gold,
                c.Estate, c.Duchy, c.Province]
  extraSupply: [c.Potion, c.Platinum, c.Colony]
  
  # AIs can get at the `c` object that stores information about cards
  # by looking up `state.cardInfo`.
  cardInfo: c
  
  # Set up the state at the start of the game. Takes these arguments:
  #
  # - `ais`: a list of AI objects that will make the decisions, one per player.
  #   This sets the number of players in the game.
  # - `tableau`: the list of non-basic cards in the supply. Colony, Platinum,
  #   and Potion have to be listed explicitly.
  initialize: (ais, tableau, logFunc) ->
    this.logFunc = logFunc
    @players = []
    playerNum = 0
    for ai in ais
      #playerNum += 1
      #if ai.name[2] == ':'
      #  ai.name = ai.name[3...]
      #ai.name = "P#{playerNum}:#{ai.name}"
      player = new PlayerState().initialize(ai, this.logFunc)
      @players.push(player)

    @nPlayers = @players.length
    @current = @players[0]
    @supply = this.makeSupply(tableau)
    # Cards like Tournament or Black Market may put cards in a special supply
    @specialSupply = {}
    @trash = []

    # A map of Card to state object that allows cards to define lasting state.
    @cardState = {}

    # A list of objects which have a "modify" method that takes a card and returns
    # a modification to its cost.  Objects must also have a "source" property that
    # specifies which card caused the cost modification.
    @costModifiers = []

    @copperValue = 1
    @phase = 'start'
    @extraturn = false
    
    @cache = {}
    
    # The `depth` indicates how deep into hypothetical situations we are. A depth of 0
    # indicates the state of the actual game.
    @depth = 0
    this.log("Tableau: #{tableau}")

    # Let cards in the tableau know the game is starting so they can perform
    # any necessary initialization
    for card in tableau
      card.startGameEffect(this)

    # `totalCards` tracks the total number of cards that are in the game. If it changes,
    # we screwed up.
    @totalCards = this.countTotalCards()

    return this
  
  # `setUpWithOptions` is the function I'd like to use as the primary way of setting up
  # a new game, doing the work of choosing a set of kingdom and extra cards (what I call
  # the tableau) with the cards they require plus random cards, and handling options.
  #
  # It takes two arguments, `ais` and `options`. `ais` is the list of AI objects, and
  # `options` is an object with these keys and values:
  #
  # - `randomizeOrder`: whether to shuffle the player order. Defaults to true.
  # - `colonies`: whether to add Colonies and Platinums to the tableau. Defaults
  #   to false-ish: it can be set to true by a strategy that requires Colony if
  #   left undefined.
  # - `log
  setUpWithOptions: (ais, options) ->
    if ais.length == 0
        throw new Error("There has to be at least one player.")
    tableau = []
    if options.require?
      for card in options.require
        tableau.push(c[card])
    for ai in ais
      if ai.requires?
        for card in ai.requires
          card = c[card]
          if card in [c.Colony, c.Platinum]
            if not options.colonies?
              options.colonies = true
            else if options.colonies is false
              throw new Error("This setup forbids Colonies, but #{ai} requires them")
          else if card not in tableau and card not in this.basicSupply\
               and card not in this.extraSupply and not card.isPrize
            tableau.push(card)

    if tableau.length > 10
      throw new Error("These strategies require too many different cards to play against each other.")
    
    index = 0
    moreCards = c.allCards.slice(0)
    shuffle(moreCards)
    while tableau.length < 10
      card = c[moreCards[index]]
      if not (card in tableau or card in this.basicSupply or card in this.extraSupply or card.isPrize)
        tableau.push(card)
      index++

    if options.colonies
      tableau.push(c.Colony)
      tableau.push(c.Platinum)
    
    for card in tableau
      if card.costPotion > 0
        if c.Potion not in tableau
          tableau.push(c.Potion)
    
    if options.randomizeOrder
      shuffle(ais)
    
    return this.initialize(ais, tableau, options.log ? console.log)

  # Given the tableau (the set of non-basic cards in play), construct the
  # appropriate supply for the number of players.
  makeSupply: (tableau) ->
    allCards = this.basicSupply.concat(tableau)
    supply = {}
    for card in allCards
      if c[card].startingSupply(this) > 0
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
  
  # `filledPiles()` determines which supply piles are not empty.
  filledPiles: () ->
    piles = []
    for key, value of @supply
      if value > 0
        piles.push(key)
    piles
  
  # `gameIsOver()` returns whether the game is over.
  gameIsOver: () ->
    # The game can only end after a player has taken a full turn. Check that
    # by making sure the phase is `'start'`.
    return false if @phase != 'start'

    # Check all the conditions in which empty piles can end the game.
    # Add a fake game-ending condition, too, which is a stalemate the SillyAI
    # sometimes ends up in.
    emptyPiles = this.emptyPiles()
    if emptyPiles.length >= this.totalPilesToEndGame() \
        or (@nPlayers < 5 and emptyPiles.length >= 3) \
        or 'Province' in emptyPiles \
        or 'Colony' in emptyPiles \
        or ('Curse' in emptyPiles and 'Copper' in emptyPiles and @current.turnsTaken >= 100)
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
  
  # `smugglerChoices` determines the set of cards that could be gained with a
  # Smuggler.
  smugglerChoices: () ->
    choices = [null]
    prevPlayer = @players[@nPlayers - 1]
    for card in prevPlayer.gainedThisTurn
      [coins, potions] = card.getCost(this)
      if potions == 0 and coins <= 6
        choices.push(card)
    choices
  
  # `countTotalCards` counts the number of cards that exist anywhere.
  countTotalCards: () ->
    total = 0
    for player in @players
      total += player.numCardsInDeck()
    for card, count of @supply
      total += count
    for card, count of @specialSupply
      total += count
    total += @trash.length
    total
    
  buyCausesToLose: (player, state, card) ->
    if not card? || @supply[card] > 1 || state.gainsToEndGame() > 1
      return false

    # Check to see if the player would be in the lead after buying this card
    maxOpponentScore = -Infinity
    for status in this.getFinalStatus()
      [name, score, turns] = status
      if name == player.ai.toString()
        myScore = score + card.getVP(player)
      else if score > maxOpponentScore
        maxOpponentScore = score

    if myScore > maxOpponentScore
      return false

    # One level of recursion is enough for first
    if (this.depth==0)
      [hypState, hypMy] = state.hypothetical(player.ai)
    else
      return false

    # try to buy this card
    # C&P from below
    #
    [coinCost, potionCost] = card.getCost(this)
    hypMy.coins -= coinCost
    hypMy.potions -= potionCost
    hypMy.buys -= 1

    hypState.gainCard(hypMy, card, 'discard', true)
    card.onBuy(hypState)
      

    for i in [hypMy.inPlay.length-1...-1]
        cardInPlay = hypMy.inPlay[i]
      if cardInPlay?
        cardInPlay.buyInPlayEffect(hypState, card)

      goonses = hypMy.countInPlay('Goons')
      if goonses > 0
        this.log("...gaining #{goonses} VP.")
        hypMy.chips += goonses
    #
    # C&P until here
    
    #finish buyPhase
    hypState.doBuyPhase()
    
    # find out if game ended and who if we have won it
    hypState.phase = 'start'
    if not hypState.gameIsOver() 
      return false
    if ( hypMy.ai.toString() in hypState.getWinners() )
      return false
    state.log("Buying #{card} will cause #{player.ai} to lose the game")
    return true
   

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
    # Clear out the list of cards gained. (We clear it here because this
    # information is actually used by Smugglers.)
    @current.gainedThisTurn = []

    # iterate backwards because cards might move
    for i in [@current.duration.length-1...-1]
      card = @current.duration[i]
      this.log("#{@current.ai} resolves the duration effect of #{card}.")
      card.onDuration(this)

    # `@current.multipliedDurations` contains virtual copies of cards, which
    # exist because a multiplier was played on a Duration card.
    for card in @current.multipliedDurations
      this.log("#{@current.ai} resolves the duration effect of #{card} again.")
      card.onDuration(this)
    
    @current.multipliedDurations = []
  
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
    @current.actionsPlayed += 1
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
      break if treasure is null
      this.log("#{@current.ai} plays #{treasure}.")

      # Remove the treasure from the hand and put it in the play area.
      if treasure not in @current.hand
        this.warn("#{@current.ai} chose an invalid treasure")
        break
      this.playTreasure(treasure)
    
    while (ctd = this.getCoinTokenDecision()) > 0
      @current.coins += ctd
      @current.coinTokens -= ctd
  
  getCoinTokenDecision: () ->
    ct = @current.ai.spendCoinTokens(this, @current)
    if (ct > @current.coinTokens)
      this.log("#{@current.ai} wants to spend more Coin Tokens as it possesses (#{ct}/#{@current.coinTokens})")
      ct = @current.coinTokens
    else
      if (ct > 0)
        this.log("#{@current.ai} spends #{ct} Coin Token#{if ct > 1 then "s" else ""}")
    @current.coinTokensSpendThisTurn = ct
    return ct
    
  
  playTreasure: (treasure) ->
    @current.hand.remove(treasure)
    @current.inPlay.push(treasure)
    @current.playLocation = 'inPlay'
    treasure.onPlay(this)

  # `getSingleBuyDecision` determines what single card (or none) the AI
  # wants to buy in the current state.
  getSingleBuyDecision: () ->
    buyable = [null]
    checkSuicide = (this.depth == 0 and this.gainsToEndGame() <= 2)
    for cardname, count of @supply
      # Because the supply must reference cards by their names, we use
      # `c[cardname]` to get the actual object for the card.
      card = c[cardname]

      # Determine whether each card can be bought in the current state.
      if card.mayBeBought(this) and count > 0
        [coinCost, potionCost] = card.getCost(this)
        if coinCost <= @current.coins and potionCost <= @current.potions
          buyable.push(card)

    # Don't allow cards that will lose us the game
    #
    # Note that this just cares for the buyPhase, gains by other means (Workshop) are not covered
    if checkSuicide
      buyable = (card for card in buyable when (not this.buyCausesToLose(@current, this, card)))
        
    # Ask the AI for its choice.
    this.log("Coins: #{@current.coins}, Potions: #{@current.potions}, Buys: #{@current.buys}")
    this.log("Coin Tokens left: #{@current.coinTokens}")
    choice = @current.ai.chooseGain(this, buyable)
    return choice

  # `doBuyPhase` steps through the buy phase, asking the AI to choose
  # a card to buy until it has no buys left or chooses to buy nothing.
  #
  # Setting `hypothetical` to true will skip gaining the cards and simply
  # return the card list.
  doBuyPhase: () ->
    while @current.buys > 0
      choice = this.getSingleBuyDecision()
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
        # If a Mandarin put cards back on the deck, this card may not be
        # there anymore. This showed up in a fascinating interaction among
        # Talisman, Quarry, Border Village, and Mandarin.
        if cardInPlay?
          cardInPlay.buyInPlayEffect(this, choice)
  
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
    
    # Check which multiplier cards ended up in `multipliedDurations`, which means
    # they should be cleaned up as if they were duration cards. Remove them once
    # they're dealt with. Disregard the other cards there for now.
    for i in [@current.multipliedDurations.length-1...-1]
      card = @current.multipliedDurations[i]
      if card.isMultiplier
        this.log("#{@current.ai} puts a #{card} in the duration area.")
        @current.inPlay.remove(card)
        @current.duration.push(card)
        @current.multipliedDurations.splice(i, 1)


    # Handle effects of cleaning up the card, which may involve moving it
    # somewhere else.  We do this before removing cards from play because
    # cards such as Scheme and Herbalist need to consider cards in play.
    cardsToCleanup = @current.inPlay.concat().reverse()
    for i in [cardsToCleanup.length-1...-1]
      card = cardsToCleanup[i]
      card.onCleanup(this)

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

    # Discard the remaining cards in hand.
    @current.discard = @current.discard.concat(@current.hand)
    @current.hand = []

    # Reset things for the next turn.
    @current.actions = 1
    @current.buys = 1
    @current.coins = 0
    @current.potions = 0
    @current.actionsPlayed = 0
    @copperValue = 1

    @costModifiers = []

    #Announce extra turn
    if @extraturn       
      this.log("#{@current.ai} takes an extra turn from Outpost.")
    
    # Finally, draw the next hand of three/five cards.
    if not (c.Outpost in @current.duration)
      @current.drawCards(5)
    else
      @current.drawCards(3)
    
    # Make sure we didn't drop cards on the floor.
    if this.countTotalCards() != @totalCards
      throw new Error("The game started with #{@totalCards} cards; now there are #{this.countTotalCards()}")

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
  gainCard: (player, card, gainLocation='discard', suppressMessage=false) ->
    if this.depth == 0
      delete @cache.gainsToEndGame
    if @supply[card] > 0 or @specialSupply[card] > 0
      for i in [player.hand.length-1...-1]
        reactCard = player.hand[i]
        if reactCard? and reactCard.isReaction and reactCard.reactReplacingGain?
          card = reactCard.reactReplacingGain(this, player, card)

      # Keep track of the card gained, for Smugglers.
      if player is @current
        player.gainedThisTurn.push(card)
      
      # `suppressMessage` is true when this happens as the direct result of a
      # buy. Nobody wants to read "X buys Y. X gains Y." all the time.
      if not suppressMessage
        this.log("#{player.ai} gains #{card}.")
      
      # Determine what list the card is being gained in, and add it to the
      # front of that list.
      location = player[gainLocation]
      location.unshift(card)

      # Remove the card from the supply
      if @supply[card] > 0
        @supply[card] -= 1
        gainSource = 'supply'
      else
        @specialSupply[card] -= 1
        gainSource = 'specialSupply'

      # Delegate to `handleGainCard` to deal with reactions.
      this.handleGainCard(player, card, gainLocation, gainSource)
    else
      this.log("There is no #{card} to gain.")
  
  # `handleGainCard` deals with the reactions that result from gaining a card.
  # A card effect such as Thief needs to call this explicitly after gaining a
  # card from someplace that is not the supply or the prize list.
  handleGainCard: (player, card, gainLocation='discard', gainSource='supply') ->
    # Remember where the card was gained, so that reactions can find it.
    player.gainLocation = gainLocation

    for own supplyCard, quantity of @supply
      c[supplyCard].globalGainEffect(this, player, card, gainSource)

    for own supplyCard, quantity of @specialSupply
      c[supplyCard].globalGainEffect(this, player, card, gainSource)
    
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
    
    for opp in this.players[1...]
      for i in [opp.hand.length-1...-1]
        reactCard = opp.hand[i]
        if reactCard.isReaction
          reactCard.reactToOpponentGain(this, opp, player, card)

    # Handle the card's own effects of being gained.
    card.onGain(this, player)      
  
  # Effects of an action could cause players to reveal their hand.
  # So far, nothing happens as a result, but in the future, AIs might
  # be able to take advantage of the information.
  revealHand: (player) ->
    this.log("#{player.ai} reveals the hand (#{player.hand}).")
  
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
  discardFromDeck: (player, nCards) ->
    drawn = player.getCardsFromDeck(nCards)
    player.discard = player.discard.concat(drawn)
    this.log("#{player.ai} draws and discards #{drawn.length} cards (#{drawn}).")
    this.handleDiscards(player, drawn)
    return drawn
  
  # `doDiscard` causes the player to discard a particular card.
  doDiscard: (player, card) ->
    if card not in player.hand
      this.warn("#{player.ai} has no #{card} to discard")
      return
    this.log("#{player.ai} discards #{card}.")
    player.hand.remove(card)
    player.discard.push(card)
    this.handleDiscards(player, [card])
  
  # `handleDiscards` looks through a list of cards and triggers their discard
  # reactions.
  handleDiscards: (player, cards) ->
    for card in cards
      if card.isReaction
        card.reactToDiscard(this, player)

  # `doTrash` causes the player to trash a particular card.
  doTrash: (player, card) ->
    if card not in player.hand
      this.warn("#{player.ai} has no #{card} to trash")
      return
    this.log("#{player.ai} trashes #{card}.")
    player.hand.remove(card)
    card.onTrash(this, player)
    @trash.push(card)
  
  # `doPutOnDeck` puts a particular card from the player's hand on top of
  # the player's draw pile.
  doPutOnDeck: (player, card) ->
    if card not in player.hand
      this.warn("#{player.ai} has no #{card} to put on deck.")
      return
    this.log("#{player.ai} puts #{card} on deck.")
    player.hand.remove(card)
    player.draw.unshift(card)
  
  # `getCardsFromDeck` is superficially similar to `drawCards`, but it does
  # not put the cards into the hand. Any code that calls it needs to determine
  # what happens to those cards (otherwise they'll be dropped on the floor!)
  #
  # This is useful
  # for effects that say "draw *n* cards, do something based on them, and
  # discard them".
  getCardsFromDeck: (player, num) ->
    player.getCardsFromDeck(num)

  # `allowDiscard` allows a player to discard 0 through `num` cards.
  # added typeFunc to only allow discards of certain type of cards.
  allowDiscard: (player, num, typeFunc = (card) -> true) ->
    discarded = []
    while discarded.length < num
      # In `allowDiscard`, valid discards are the entire hand, plus `null`
      # to stop discarding.
      validDiscards = ( card for card in player.hand when typeFunc(card?) ).slice(0)
      validDiscards.push(null)
      choice = player.ai.chooseDiscard(this, validDiscards)
      return discarded if choice is null
      discarded.push(choice)
      this.doDiscard(player, choice)
    return discarded
  
  # `requireDiscard` requires the player to discard exactly `num` cards,
  # except that it stops if the player has 0 cards in hand.
  requireDiscard: (player, num, typeFunc = (card) -> true) ->
    discarded = []
    while discarded.length < num
      validDiscards = ( card for card in player.hand when typeFunc(card) ).slice(0)
      return discarded if validDiscards.length == 0
      choice = player.ai.chooseDiscard(this, validDiscards)
      discarded.push(choice)
      this.doDiscard(player, choice)
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
      this.doTrash(player, choice)
    return trashed
  
  requireTrash: (player, num) ->
    trashed = []
    while trashed.length < num
      valid = player.hand.slice(0)
      return trashed if valid.length == 0
      choice = player.ai.chooseTrash(this, valid)
      trashed.push(choice)
      this.doTrash(player, choice)
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
    # attackEvent gets passed to each reactToAttack method.  Any card
    # may block the attack by setting attackEvent.blocked to true
    attackEvent = {}

    # Reaction cards in the hand can react to the attack
    reactionCards = (card for card in player.hand when card.isReaction)

    for card in reactionCards
      card.reactToAttack(this, player, attackEvent)
    
    for card in player.duration
      card.durationReactToAttack(this, player, attackEvent)
    
    # Apply the attack's effect unless it's been blocked by a card such as
    # Moat or Lighthouse
    effect(player) unless attackEvent.blocked
  
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
    
    newSpecialSupply = {}
    for key, value of @specialSupply
      newSpecialSupply[key] = value

    newState = new State()
    # If something overrode the log function, make sure that's preserved.
    newState.logFunc = @logFunc

    newPlayers = []
    for player in @players
      playerCopy = player.copy()
      playerCopy.logFunc = (obj) ->
      newPlayers.push(playerCopy)

    # Copy card-specific state
    newCardState = {}
    for card, state of @cardState
      # If the card state has a copy method, call it, otherwise just shallow
      # copy the state
      if state.copy?
        # Objects with a copy method
        newCardState[card] = state.copy?()
      else if typeof state == 'object'
        # Objects with no copy method
        newCardState[card] = copy = {}
        copy[k] = v for k, v of state
      else
        # Simple types
        newCardState[card] = state
    
    newState.players = newPlayers
    newState.supply = newSupply
    newState.specialSupply = newSpecialSupply
    newState.cardState = newCardState
    newState.trash = @trash.slice(0)
    newState.current = newPlayers[0]
    newState.nPlayers = @nPlayers
    newState.costModifiers = @costModifiers.concat()
    newState.copperValue = @copperValue
    newState.phase = @phase
    newState.cache = {}

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

    # Rotate through players until this AI is the current player.
    counter = 0
    while state.players[0].ai isnt ai
      counter++
      if counter > state.nPlayers
        throw new Error("Can't find this AI in the player list")
      state.players = state.players[1...].concat([state.players[0]])

    state.depth = this.depth + 1
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

    [state, my]
  
  # Functions for comparing, used for sorting
  #
  # Rob says: this is pretty AI-specific. It's also an unnecessarily complex operation,
  # even given caching. The choices are already in order in the actionPriority; they need
  # to be filtered, not sorted.
  compareByActionPriority: (state, my, x, y) ->
    my.ai.cacheActionPriority(state,my)
    my.ai.choiceToValue('cachedAction', state, x) - my.ai.choiceToValue('cachedAction', state, y)
    
  compareByCoinCost: (state, my, x, y) ->
    x.getCost(state)[0] - y.getCost(state)[0]
  
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
# This customized clone function will not make unnecessary copies of
# cards and AIs. However, it doesn't seem to work.
cloneDominionObject = (obj) ->
  if not obj? or typeof obj isnt 'object'
    return obj

  if (obj.gainPriority?) or (obj.costInCoins?)
    return obj
  newInstance = new obj.constructor()
  for own key, value of obj
    newInstance[key] = cloneDominionObject(value)
  newInstance

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

# When modifying built-in methods of core types, we need to play nice with
# other libraries.  For instance, our Array#toString method modifies the
# behavior in a way that breaks the CoffeeScript compiler.

# Modifies built-in methods of core Javascript types in a way that's reversible
modifyCoreTypes = ->
  # Make Array#toString output more readable
  Array::_originalToString ||= Array::toString
  Array::toString = ->
    '[' + this.join(', ') + ']'

# Reverses modifications to core Javascript types
restoreCoreTypes = ->
  Array::toString = Array::_originalToString if Array::_originalToString?
  delete Array::_originalToString

# useCoreTypeMods takes an object and the name of a method.  It then wraps
# that method so that it correctly uses and restores our core type
# modifications.  The modifications are visible within the method body and
# any child method calls, but they are cleaned up when leaving the method
useCoreTypeMods = (object, method) ->
  originalMethod = "_original_#{method}"
  unless object[originalMethod]?
    object[originalMethod] = object[method]
    object[method] = ->
      try
        modifyCoreTypes()
        this[originalMethod](arguments...)
      finally
        restoreCoreTypes()

# Use our core type modifications within the State object.  These three
# methods are the ones called by external functions to set up and play
# a game.
useCoreTypeMods(State::, 'setUpWithOptions')
useCoreTypeMods(State::, 'gameIsOver')
useCoreTypeMods(State::, 'doPlay')

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
