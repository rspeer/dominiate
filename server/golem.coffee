###
The main file that answers requests for Golem to figure out what to play.

This code is written in Node CoffeeScript. If you're looking at "golem.js",
you're seeing machine-generated code. The real, understandable code is in
"golem.coffee".
###

assert = require("assert")
card_info = require("./card_info").card_info
util = require("./util")

COUNT = 0
COST = 1
buyChoices = (supply, coins, mincost, buys) ->
  choices = [[]]
  if buys == 0
    [[]]
  else
    for card of supply
      if supply[card][COUNT] > 0
        cost = supply[card][COST]
        if cost <= coins and cost >= mincost
          supply[card][COUNT] -= 1
          for choice in buyChoices(supply, coins-cost, cost, buys-1)
            choices.push([card].concat(choice))
          supply[card][COUNT] += 1
  choices

getDeckFeatures = (deck) ->
  features = {
    n: 0
    nUnique: 0
    nActions: 0
    knownvp: 0
    cardvp: 0
    chips: 0
    deck: {}
    unique: {}
  }
  for card, count of deck
    # Decks that come straight from Isotropic will have a 'vp' entry, holding
    # the number of actual victory points the player has. We need to figure
    # out how many of them came from chips -- instead of cards -- and make
    # that into a feature.
    if card is 'vp'
      features.knownvp = count
    else
      features.deck[card] = count
      features.unique[card] = 1
      features.nUnique += 1
      if card_info[card].isAction
        features.nActions += count
      features.n += count
  
  for card, count of deck
    if card isnt 'vp'
      if card_info[card].isVictory or card is 'Curse'
        cardvp = 0
        switch card
          when 'Gardens'
            cardvp = Math.floor(features.n / 10)
          when 'Fairgrounds'
            cardvp = Math.floor(features.nUnique / 5) * 2
          when 'Duke'
            cardvp = features.deck['Duchy']
          when 'Vineyard'
            cardvp = Math.floor(features.nActions / 3)
          else
            cardvp = card_info[card].vp
        # console.log(count+"x "+card+" is worth "+(cardvp*count))
        features.cardvp += cardvp * count
  features.chips = features.knownvp - features.cardvp
  features

addToDeckFeatures = (deck, feats, newcards) ->
  # Takes in a deck and a 'deckFeatures' object that describes that deck,
  # plus a list of new cards. Returns the new deckFeatures object.
  newdeck = util.clone(deck)
  for card in newcards
    newdeck[card] += 1
  newfeats = getDeckFeatures(newdeck)
  
  # Take the known number of chips and use it to fix up the VP count.
  newfeats.chips = feats.chips
  newfeats.vp = newfeats.cardvp + newfeats.chips
  assert.ok(newfeats.chips >= 0)
  newfeats

normalizeDeck = (feats) ->
  # Takes a deckFeatures object and squishes together the card counts and
  # a bunch of features into one object. The card counts will be normalized
  # into cards per hand, and other quantities also reduced, to prepare for
  # prediction by Vowpal.
  nHands = Math.max(feats.n, 5) / 5
  normalized = {actions: 0}
  for card, count of feats.deck
    normalized[card] = count / nHands
    if card_info[card].isAction
      # This was a bug in our training! Unfortunately, we should test the
      # same way. We counted unique actions / 5 instead of total actions.
      normalized.actions += 0.2
  normalized.unique = feats.unique / 5
  normalized.n = feats.n / 10
  normalized.vp = feats.vp / 10
  normalized

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
  myfeatures = getDeckFeatures(mydeck)
  oppfeatures = getDeckFeatures(oppdeck)
  
  vwLines = for choice in choices
    newfeats = addToDeckFeatures(mydeck, myfeatures, choice)
    vwStruct = {
      cards: normalizeDeck(newfeats)
      opponent: normalizeDeck(oppfeatures)
      unique: newfeats.unique
      vsunique: oppfeatures.unique
    }
    name = choice.join('+')
    vowpal.featureString(name, vwStruct)
  
  vowpal.maximizePrediction(
    "model"+turnNum+".vw",
    vwLines.join('\n'),
    responder
  )

gainHandler = (request, responder, query) ->
  mydeck = JSON.parse(query.mydeck)   # mapping from card -> count
  oppdeck = JSON.parse(query.oppdeck) # mapping from card -> count
  supply = JSON.parse(query.supply)   # mapping from card -> [count, cost]
  # supply should only include cards that the game allows buying or gaining
  # now.

  coins = parseInt(query.coins)
  buys = parseInt(query.buys)
  turnNum = parseInt(query.turnNum)
  chooseGain(mydeck, oppdeck, supply, coins, buys, turnNum, responder)

trashHandler = (request, responder, query) ->
  responder.fail "Not implemented"

exports.buyChoices = buyChoices
exports.getDeckFeatures = getDeckFeatures
exports.gain = exports.gainHandler = gainHandler
exports.trash = exports.trashHandler = trashHandler
