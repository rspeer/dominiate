card_info = require("./card_info").card_info
avg_deck = require("../average_deck").deck
deckdata = require("./deckdata")
golem = require("./golem")

rankCards = () ->
  deck = avg_deck['cards']
  supply = avg_deck['supply']
  
  choices = [[]]
  supply_info = {}

  for card, value of supply
    supply_info[card] = [10, 10]
    choices.push([card])

  responder = {
    succeed: (data) ->
      console.log(JSON.stringify(data))
  }
  golem.chooseGain(deck, deck, supply_info, choices, 6, responder)

rankCards()
