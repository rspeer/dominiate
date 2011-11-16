# Import the brain.js framework for neural net learning, which we're
# going to build on to make a temporal difference learner.
{NeuralNetwork} = require 'brain' if exports?
{c} = require './cards' if exports?
{BasicAI} = require './BasicAI' if exports?

class TDmoney extends BasicAI
  name: 'TDmoney'
  requires: []
  author: 'rspeer'

  training: [
    {input: {"my:Province": 8, "my:vp": 48}, output: {win: 1, vpdiff: 1}}
    {input: {"opp:Province": 8, "opp:vp": 48}, output: {win: 0, vpdiff: 0}}
  ]

  constructor: ->
    @lambda = 0.9
    @timeHorizon = 10

    @net = new NeuralNetwork({
      hidden: [50],
      learningRate: 1.0
    })

    startVec = {}
    # TODO: simplify this
    for card in c.allCards
      startVec["supply:#{card}"] = 0
      startVec["my:#{card}"] = 0
      startVec["opp:#{card}"] = 0
    
    for extrafeat in ["my:vp", "my:totalMoney", "my:actionBalance", "my:actionDensity", "my:cardsInDeck", "opp:vp", "opp:totalMoney", "opp:actionBalance", "opp:actionDensity", "opp:cardsInDeck", "numEmptyPiles", "gainsToEndGame"]
      startVec[extrafeat] = 0
    @net.train(@training, 1)

    @cachedTurn = null
    @cachedVec = null
    @history = []
  
  stateToVector: (state) ->
    my = this.myPlayer(state)
    opp = this.anyOpponent(state)
    vec = {}
    
    vec["my:cardsInDeck"] = my.numCardsInDeck()
    vec["opp:cardsInDeck"] = opp.numCardsInDeck()

    myCards = Math.max(vec["my:cardsInDeck"], 5)
    oppCards = Math.max(vec["opp:cardsInDeck"], 5)

    for card, count of state.supply
      vec["supply:#{card}"] = count
    
    for card in state.prizes
      vec["supply:#{card}"] = 1

    for card in my.getDeck()
      vec["my:#{card}"] ?= 0
      vec["my:#{card}"]++
      vec["my:p:#{card}"] ?= 0
      vec["my:p:#{card}"] += 1 / myCards

    for card in opp.getDeck()
      vec["opp:#{card}"] ?= 0
      vec["opp:#{card}"]++
      vec["opp:p:#{card}"] ?= 0
      vec["opp:p:#{card}"] += 1 / oppCards
    
    vec["my:vp"] = my.getVP()
    vec["my:totalMoney"] = my.getTotalMoney()
    vec["my:actionBalance"] = my.actionBalance()
    vec["my:actionDensity"] = my.actionDensity()

    vec["opp:vp"] = opp.getVP()
    vec["opp:totalMoney"] = opp.getTotalMoney()
    vec["opp:actionBalance"] = opp.actionBalance()
    vec["opp:actionDensity"] = opp.actionDensity()
    vec["numEmptyPiles"] = state.numEmptyPiles()
    vec["gainsToEndGame"] = state.gainsToEndGame()

    return vec
   
  updateVecForGain: (vec, state, card) ->
    newVec = {}
    for own key, value of vec
      newVec[key] = value

    myCards = Math.max(vec["my:cardsInDeck"], 5)

    my = this.myPlayer(state)
    newVec["my:vp"] += card.getVP(my)
    newVec["my:totalMoney"] += card.coins
    newVec["my:#{card}"] ?= 0
    newVec["my:#{card}"]++
    newVec["supply:#{card}"] ?= 0
    newVec["supply:#{card}"]--
    newVec["my:cardsInDeck"]++
    newVec["my:p:#{card}"] ?= 0
    newVec["my:p:#{card}"] += 1/myCards
    if state.supply[card] == 1
      newVec["numEmptyPiles"]++
      newVec["gainsToEndGame"]--
    return newVec

  updateTurn: (state, my) ->
    @cachedVec = this.stateToVector(state)
    @prediction = @net.run(@cachedVec)
    if @prediction.vpdiff.toString() == 'NaN'
      throw new Error("got NaN")
    @cachedTurn = my.turnsTaken
    state.log("Prediction: #{JSON.stringify(@prediction)}")
    state.log("vpdiff: #{@cachedVec['my:vp'] - @cachedVec['opp:vp']}")

    @history.push(@cachedVec)
    if @history.length > @timeHorizon
      @history.shift()

    this.learnValue(@prediction, 0.1)

  learnValue: (prediction, weight = 1) ->
    # revisit previous states and tell them to learn from this one
    @net.learningRate = weight
    if @history.length > 0
      for i in [(@history.length-1)..0]
        @net.trainItem(@history[i], prediction)
        @net.learningRate *= @lambda
  
  atEndOfGame: (state, my) ->
    winners = state.getWinners()

    if this.name in winners
      winPoints = state.nPlayers / winners.length
    else
      winPoints = 0
    
    # scale to [0, 1] and learn it as the final outcome
    winValue = (winPoints / state.nPlayers)
    opp = this.anyOpponent(state)
    vpdiff = @net.outputLayer.nodes.vpdiff.sigmoid((my.getVP(state) - opp.getVP(state))/100 + winValue*2 - 1)
    state.log("winValue: #{winValue}, vpdiff: #{vpdiff}")
    @history.push(this.stateToVector(state))
    for i in [1..10]
      this.learnValue({win: winValue, vpdiff: vpdiff}, 1)

    # reset for the next game if there is one
    @history = []
    @cachedTurn = null
   
  gainPriority: (state, my) -> 
    if state.depth == 0 and my.turnsTaken != @cachedTurn
      this.updateTurn(state, my)
    if state.supply.Colony?
      [
        "Colony" if my.getTotalMoney() > 32
        "Province" if state.gainsToEndGame() <= 6
        "Duchy" if state.gainsToEndGame() <= 5
        "Estate" if state.gainsToEndGame() <= 2
        "Platinum"
        "Province" if state.countInSupply("Colony") <= 7
        "Gold"
        "Duchy" if state.gainsToEndGame() <= 6
        "Silver"
        "Copper" if state.gainsToEndGame() <= 2
      ]
    else
      [
        "Province" if my.getTotalMoney() > 18
        "Duchy" if state.gainsToEndGame() <= 4
        "Estate" if state.gainsToEndGame() <= 2
        "Gold"
        "Duchy" if state.gainsToEndGame() <= 6
        "Silver"
      ]

new TDmoney()