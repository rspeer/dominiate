# The main file that answers requests for Golem to figure out what to play.

exec = require("child_process").exec
card_list = require("../card_list").card_list
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

deckVP = (deck) ->
  undefined

chooseGain = (mydeck, oppdeck, supply, coins, buys) ->
  # For each possibility:
  #   Add those cards to the current hand.
  #   Update VP, card count, etc. accordingly.
  #   Normalize to cards per hand.
  #   Convert to a VW string.
  #
  # Run the file through VW. Sort the results. Do the best thing.
  choices = buyChoices(supply, coins, 0, buys)
  newdeck = util.clone(mydeck)

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
