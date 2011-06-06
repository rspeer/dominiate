mongodb = require('../node-mongodb-native/lib/mongodb')
fs = require('fs')
card_info = require('../server/card_info')
deckdata = require('../server/deckdata')
vowpal = require('../server/vowpal')

server = new mongodb.Server("new-caledonia.media.mit.edu", 27017, {})

useCollection = (collection, output) ->
  console.log("finding")
  counter = 0
  # Given a collection, generate deck states from all the games in it.
  collection.find({}, {}).each (err, doc) ->
    throw err if err
    return if not doc?
    counter += 1
    console.log(counter) if (counter % 1000 == 0)
    nPlayers = doc.players.length
    playerdecks = {}

    # Determine how many turns were played
    nTurns = 0
    for playerdeck in doc.decks
      nTurns = Math.max(nTurns, playerdeck.turns.length)
      playerdecks[playerdeck.name] = playerdeck
    if nTurns >= 5 and nPlayers >= 2
      # Don't learn about Possession and Outpost for now; they mess up turn
      # counting.
      if 'Possession' not in supply and 'Outpost' not in supply
        # Set up the initial supply and player states
        states = {}
        supply = {}
        for card in doc.supply
          supply[card] = card_info.numCopiesPerGame(card, nPlayers)
        for card in card_info.everySetCards
          supply[card] = card_info.numCopiesPerGame(card, nPlayers)
        for player in doc.players
          states[player] = {'Copper': 7, 'Estate': 3}
          return if not playerdecks[player]?
        
        # Iterate by turn...
        for turnNum in [0...nTurns]
          # ... then by player
          for player in doc.players
            bestopp = null
            bestscore = -200
            for opponent in doc.players
              if opponent != player and playerdecks[opponent].points > bestscore
                bestopp = opponent
            # TODO: do stuff with the player's deck and the best opponent's
            win = 0
            return if not playerdecks[player]?
            if playerdecks[player].win_points > playerdecks[bestopp].win_points
              win = 1
            else if playerdecks[player].win_points < playerdecks[bestopp].win_points
              win = -1
            if win isnt 0
              outputFeatures(states[player], states[bestopp], supply,
                doc._id+'__'+turnNum, win, output)
              turn = playerdecks[player].turns[turnNum]
              if turn?
                handleDeckChange(player, states, supply, turn)

outputFeatures = (mydeck, oppdeck, supply, id, win, out) ->
  vwStruct = {
    cards: deckdata.normalizeDeck(mydeck)
    opponent: deckdata.normalizeDeck(oppdeck)
    supply: supply
  }
  try
    fs.write(out, vowpal.featureString(id, vwStruct, win)+'\n')
  catch err
    console.log(err)
    debug = {mydeck: mydeck, oppdeck: oppdeck, vwStruct: vwStruct}
    console.log(debug)
    throw "bad feature value"


handleDeckChange = (player, states, supply, change) ->
  # Change the states of players' decks based on a DB object that describes
  # that change.
  if change.buys?
    for card in change.buys
      states[player][card] ?= 0
      states[player][card] += 1
      supply[card] ?= 1
      supply[card] -= 1
  if change.gains?
    for card in change.gains
      states[player][card] ?= 0
      states[player][card] += 1
      supply[card] ?= 1
      supply[card] -= 1
  if change.trashes?
    for card in change.trashes
      states[player][card] ?= 0
      states[player][card] -= 1
  if change.returns?
    for card in change.returns
      states[player][card] ?= 0
      states[player][card] -= 1
      supply[card] ?= 1
      supply[card] += 1
  if change.opp?
    for oppname, oppchange of change.opp
      handleDeckChange(oppname, states, supply, oppchange)
  if change.vp_tokens?
    states[player]['chips'] ?= 0
    states[player]['chips'] += change.vp_tokens
  return [states, supply]

console.log("starting")
new mongodb.Db('test', server, {native_parser: true}).open (err, client) ->
  console.log("got db")
  fs.readFile 'mongo_password.txt', 'utf8', (err, password) ->
    throw err if err
    password = password.replace(/\s+$/,"")
    client.authenticate 'golem', password, (err, result) ->
      throw err if err
      console.log("authenticating")
      fs.open 'output/allTurns.txt', 'w', 0664, (err, output) ->
        throw err if err
        collection = new mongodb.Collection(client, 'games')
        useCollection(collection, output)

