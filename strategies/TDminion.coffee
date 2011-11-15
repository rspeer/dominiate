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
    {input: {"my:Province": 8}, output: {0: 1}}
    {input: {"opp:Province": 8}, output: {0: 0}}
    {input: {"my:vp": 48}, output: {0: 1}}
    {input: {"opp:vp": 48}, output: {0: 0}}
  ]

  constructor: ->
    @lambda = 0.9
    @timeHorizon = 20

    @net = new NeuralNetwork({
      hidden: [10],
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
    @net.train(@training, 1000)

    @cachedTurn = null
    @cachedVec = null
    @history = []
  
  stateToVector: (state) ->
    my = this.myPlayer(state)
    opp = this.anyOpponent(state)
    vec = {}
    
    for card, count of state.supply
      vec["supply:#{card}"] = count
    
    for card in state.prizes
      vec["supply:#{card}"] = 1

    for card in my.getDeck()
      vec["my:#{card}"] ?= 0
      vec["my:#{card}"]++

    for card in opp.getDeck()
      vec["opp:#{card}"] ?= 0
      vec["opp:#{card}"]++
    
    vec["my:vp"] = my.getVP()
    vec["my:totalMoney"] = my.getTotalMoney()
    vec["my:actionBalance"] = my.actionBalance()
    vec["my:actionDensity"] = my.actionDensity()
    vec["my:cardsInDeck"] = my.numCardsInDeck()

    vec["opp:vp"] = opp.getVP()
    vec["opp:totalMoney"] = opp.getTotalMoney()
    vec["opp:actionBalance"] = opp.actionBalance()
    vec["opp:actionDensity"] = opp.actionDensity()
    vec["opp:cardsInDeck"] = opp.numCardsInDeck()
    vec["numEmptyPiles"] = state.numEmptyPiles()
    vec["gainsToEndGame"] = state.gainsToEndGame()

    return vec
   
  updateVecForGain: (vec, state, card) ->
    newVec = {}
    for own key, value of vec
      newVec[key] = value
    my = this.myPlayer(state)
    newVec["my:vp"] += card.getVP(my)
    newVec["my:#{card}"] ?= 0
    newVec["my:#{card}"]++
    newVec["supply:#{card}"] ?= 0
    newVec["supply:#{card}"]--
    newVec["my:cardsInDeck"]++
    if state.supply[card] == 1
      newVec["numEmptyPiles"]++
      newVec["gainsToEndGame"]--
    return newVec

  updateTurn: (state, my) ->
    @cachedVec = this.stateToVector(state)
    @prediction = @net.run(@cachedVec)[0] ? 0
    if @prediction.toString() == 'NaN'
      throw new Error("got NaN")
    @cachedTurn = my.turnsTaken
    console.log("Prediction: #{@prediction}")

    @history.push(@cachedVec)
    if @history.length > @timeHorizon
      @history.shift()

    this.learnValue(@prediction)

  learnValue: (prediction) ->
    # revisit previous states and tell them to learn from this one
    @net.learningRate = 1.0
    if @history.length > 0
      for i in [(@history.length-1)..0]
        @net.trainItem(@history[i], {0: prediction})
        @net.learningRate *= @lambda
        if @net.inputLayer.nodes['supply:Copper'].error?.toString() == 'NaN'
          throw new Error("NaN at iteration #{i}")    
  
  atEndOfGame: (state, my) ->
    winners = state.getWinners()

    if this.name in winners
      winPoints = state.nPlayers
    else
      winPoints = 0
    
    # scale to [0, 1] and learn it as the final outcome
    winValue = (winPoints / state.nPlayers)
    console.warn("winValue: #{winValue}")
    this.learnValue(winValue)
    
    # reset for the next game if there is one
    @history = []
    @cachedTurn = null
  
  gainPriority: (state, my) -> []

  gainValue: (state, card, my) ->
    if state.depth == 0 and my.turnsTaken != @cachedTurn
      this.updateTurn(state, my)
    
    vec = this.updateVecForGain(@cachedVec, state, card)
    nextPrediction = @net.run(vec)[0] ? 0
    if nextPrediction.toString() == 'NaN'
      throw new Error("next is NaN")
    value = nextPrediction - @prediction
    console.log("  #{card}: #{value}")
    return value

new TDminion()