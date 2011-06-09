###
The main file that answers requests for Golem to figure out what to play.

This code is written in Node CoffeeScript. If you're looking at "golem.js",
you're seeing machine-generated code. The real, understandable code is in
"golem.coffee".
###

assert = require("assert")
card_info = require("./card_info").card_info
deckdata = require("./deckdata")
util = require("./util")
vowpal = require("./vowpal")

COUNT = 0
COST = 1
buyChoices = (supply, coins, mincost, buys) ->
  choices = [[]]
  if buys != 0
    for card of supply
      if supply[card][COUNT] > 0
        cost = supply[card][COST]
        if cost <= coins and cost >= mincost
          supply[card][COUNT] -= 1
          for choice in buyChoices(supply, coins-cost, cost, buys-1)
            choices.push([card].concat(choice))
          supply[card][COUNT] += 1
  choices

makeModelName = (num) ->
  if num < 2 then "model2.vw"
  else if num > 25 then "model25.vw"  # fix when later models work
  else "model#{num}.vw"

chooseGain = (mydeck, oppdeck, supply, coins, buys, turnNum, responder) ->
  # Decide what to gain or buy.
  # Arguments:
  #   - mydeck: an object mapping card names to counts for my cards.
  #   - oppdeck: an object mapping card names to counts for my opponent's
  #     cards.
  #     - Note: Both 'mydeck' and 'oppdeck' should contain a fake card called
  #       'vp' with the counted number of victory points.
  #   - supply: maps card names to [number in supply, current cost].
  #   - coins: maximum number of coins to spend.
  #   - buys: maximum number of cards to gain.
  #   - turnNum: what turn number it is.
  #   - responder: an object that we will call .succeed or .fail on with
  #     the result.
  #
  # For each possibility:
  #   Add those cards to the current hand.
  #   Update VP, card count, etc. accordingly.
  #   Normalize to cards per hand.
  #   Convert to a VW string.
  #
  # Run the file through VW. Sort the results. Do the best thing.
  choices = buyChoices(supply, coins, 0, buys)
  myfeatures = deckdata.getDeckFeatures(mydeck)
  oppfeatures = deckdata.getDeckFeatures(oppdeck)
  
  vwLines = for choice in choices
    newfeats = deckdata.addToDeckFeatures(mydeck, myfeatures, choice)
    vwStruct = {
      cards: deckdata.normalizeFeats(newfeats)
      opponent: deckdata.normalizeFeats(oppfeatures)
    }
    vowpal.featureString(choice, vwStruct)
  
  vowpal.maximizePrediction(
    makeModelName(turnNum+1),
    vwLines.join('\n'),
    responder
  )

gainHandler = (request, responder, query) ->
  myself = JSON.parse(query.myself)     # Player object
  opponent = JSON.parse(query.opponent) # Player object
  supply = JSON.parse(query.supply)     # mapping from card -> [count, cost]
  # supply should only include cards that the game allows buying or gaining
  # now.

  coins = parseInt(query.coins)
  buys = parseInt(query.buys)
  turnNum = parseInt(query.turnNum)
  
  mydeck = myself.card_counts
  mydeck['vp'] = myself.score ? 3
  oppdeck = opponent.card_counts
  oppdeck['vp'] = opponent.score ? 3

  chooseGain(mydeck, oppdeck, supply, coins, buys, turnNum, responder)

trashHandler = (request, responder, query) ->
  responder.fail "Not implemented"

exports.buyChoices = buyChoices
exports.chooseGain = chooseGain
exports.gain = exports.gainHandler = gainHandler
exports.trash = exports.trashHandler = trashHandler
