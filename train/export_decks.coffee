mongodb = require('mongodb')
fs = require('fs')
card_info = require('../server/card_info')
deckdata = require('../server/deckdata')

server = new mongodb.Server("new-caledonia.media.mit.edu", 27017, {})

useCollection = (collection) ->
  # Given a collection, generate deck states from all the games in it.
  collection.find({}, {}).each (err, doc) ->
    throw err if err
    nPlayers = doc.players.length

    # Determine how many turns were played
    nTurns = 0
    for deck in doc.decks
      nTurns = Math.max(nTurns, deck.turns)
    
    if nTurns >= 5 and nPlayers >= 2
      # Don't learn about Possession and Outpost for now; they mess up turn
      # counting.
      if 'Possession' not in supply and 'Outpost' not in supply
        # Set up the initial supply and player decks
        decks = {}
        supply = {}
        for card in doc.supply
          supply[card] = card_info.numCopiesPerGame(card, nPlayers)
        for player in doc.players
          decks[player] = {'Copper': 7, 'Estate': 3}
        
        # Iterate by turn...
        for turnNum in [0...nTurns]
          # ... then by player
          for player in doc.players
            # TODO: do stuff with the player's deck and the best opponent's
            turn = deck[player].turns[turnNum]
            if turn?
              handleDeckChange(player, decks, supply, turn)

handleDeckChange = (player, decks, supply, change) ->
  if change.buys?
    for card in change.buys
      decks[player][card] += 1
      supply[card] -= 1
  if change.gains?
    for card in change.gains
      decks[player][card] += 1
      supply[card] -= 1
  if change.trashes?
    for card in change.trashes
      decks[player][card] -= 1
  if change.returns?
    for card in change.returns
      decks[player][card] -= 1
      supply[card] += 1
  if change.opp?
    for oppname, oppchange of change.opp
      handleDeckChange(oppname, decks, supply, oppchange)
  if change.vp_tokens?
    decks[player]['chips'] += change.vp_tokens
  return decks, supply
    
new mongodb.Db('test', server, {}).open (err, client) ->
  fs.readFile 'mongo_password.txt', (err, password) ->
    throw err if err
    client.authenticate 'mongo', password, (err, result) ->
      throw err if err
      collection = new mongodb.Collection(client, 'games')
      useCollection(collection)

