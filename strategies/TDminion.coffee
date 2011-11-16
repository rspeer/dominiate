# Import the brain.js framework for neural net learning, which we're
# going to build on to make a temporal difference learner.
{NeuralNetwork} = require 'brain' if exports?
{c} = require './cards' if exports?
{BasicAI} = require './BasicAI' if exports?

class TDminion extends BasicAI
  name: 'TDminion'
  requires: []
  author: 'rspeer'

  training: [
    {input: {"my:Province": 8, "my:vp": 48}, output: {win: 1, good: 1, bad: 0}}
    {input: {"opp:Province": 8, "opp:vp": 48}, output: {win: 0, good: 0, bad: 1}}
  ]

  constructor: ->
    @lambda = 0.99
    @timeHorizon = 30

    @net = new NeuralNetwork({
      hidden: [50],
      learningRate: 1.0
    })

    @net.train(@training, 1)

    @cachedTurn = null
    @cachedVec = {}
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
  
  invertVec: (vec) ->
    newVec = {}
    for key, value in newVec
      if key.substring(0,3) == 'my:'
        newKey = 'opp:' + key.substring(3)
      else if key.substring(0,4) == 'opp:'
        newKey = 'my:' + key.substring(4)
      else
        newKey = key
      newVec[newKey] = value
    newVec
   
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
    if @prediction.good.toString() == 'NaN'
      throw new Error("got NaN")
    @cachedTurn = my.turnsTaken
    state.log("Prediction: #{JSON.stringify(@prediction)}")
    state.log("vpdiff: #{@cachedVec['my:vp'] - @cachedVec['opp:vp']}")

    @history.push(@cachedVec)
    if @history.length > @timeHorizon
      @history.shift()

    this.learnValue(@prediction, 0.01)

  learnValue: (prediction, weight = 1) ->
    # revisit previous states and tell them to learn from this one
    total = prediction.good + prediction.bad
    prediction['good'] /= total
    prediction['bad'] /= total
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
    good = @net.outputLayer.nodes.good.sigmoid((my.getVP(state) - opp.getVP(state))/100 + winValue*2 - 1)
    bad = 1-good
    console.warn("winValue: #{winValue}, good: #{good}")
    @history.push(this.stateToVector(state))
    for i in [1..10]
      this.learnValue({win: winValue, good: good, bad: bad}, 1)
    
    # reset for the next game if there is one
    @history = []
    @cachedTurn = null
  
  gainPriority: (state, my) -> []

  gainValue: (state, card, my) ->
    if state.depth == 0 and my.turnsTaken != @cachedTurn
      this.updateTurn(state, my)
    prediction = @net.run(@cachedVec)
    total = prediction['good'] + prediction['bad']
    nowPrediction = prediction['good'] / total
    vec = this.updateVecForGain(@cachedVec, state, card)
    next = @net.run(vec)
    total = next['good'] + next['bad']
    nextPrediction = next['good'] / total
    if nextPrediction.toString() == 'NaN'
      throw new Error("next is NaN")

    value = nextPrediction - nowPrediction

    # possible hack: try not to fall into a trap of not buying things
    [coins, potions] = card.getCost(state)
    cost = coins + potions*2 + 1
    value += (cost * Math.exp(my.turnsTaken/5 - 20))
    console.log("  #{card}: #{value*1000}")
    return value

new TDminion()