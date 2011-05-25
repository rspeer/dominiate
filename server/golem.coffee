# The main file that answers requests for Golem to figure out what to play.
assert = require("assert")
exec = require("child_process").exec
card_info = require("../card_info").card_info
util = require("util")

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
exports.buyChoices = buyChoices

getDeckFeatures = (deck) ->
  features = {
    unique: 0
    actions: 0
    n: 0
    knownvp: 0
    cardvp: 0
    chips: 0
  }
  for card, count of deck
    # Decks that come straight from Isotropic will have a 'vp' entry, holding
    # the number of actual victory points the player has. We need to figure
    # out how many of them came from chips -- instead of cards -- and make
    # that into a feature.
    if card is 'vp'
      features.knownvp = count
    else
      if not features[card]
        features[card] = count
        features.unique += 1
      if card_info[card].isAction
        features.actions += count
      features.n += count
  
  for card, count of deck
    if card isnt 'vp'
      if card_info[card].isVictory or card is 'Curse'
        cardvp = card_info[card].vp # FIXME for variable cards
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

chooseGain = (mydeck, oppdeck, supply, coins, buys) ->
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
  for choice in choices
    newfeats = addToDeckFeatures(mydeck, myfeatures, choice)
  # not done yet

gainHandler = (request, responder, query) ->
  mydeck = JSON.parse(query.mydeck)   # mapping from card -> count
  oppdeck = JSON.parse(query.oppdeck) # mapping from card -> count
  supply = JSON.parse(query.supply)   # mapping from card -> [count, cost]
  # supply should only include cards that the game allows buying or gaining
  # now.

  coins = parseInt(query.coins)
  buys = parseInt(query.buys)
  chooseGain(mydeck, oppdeck, supply, coins, buys)
exports.gain = gainHandler

trashHandler = (request, responder, query) ->
  responder.fail "Not implemented"
exports.trash = trashHandler
