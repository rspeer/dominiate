card_info = require("./card_info").card_info
numCopiesPerGame = require("./card_info").numCopiesPerGame
util = require("./util")

getDeckFeatures = (deck) ->
  features = {
    n: 0
    nUnique: 0
    nActions: 0
    vp: null
    cardvp: 0
    chips: null
    deck: {}
    unique: {}
  }
  for own card, count of deck
    # Decks that come straight from Isotropic will have a 'vp' entry, holding
    # the number of actual victory points the player has. We need to figure
    # out how many of them came from chips -- instead of cards -- and make
    # that into a feature.
    if card is 'vp'
      features.vp = count
    else if card is 'chips'
      features.chips = count
    else
      features.deck[card] = count
      features.unique[card] = 1
      features.nUnique += 1
      if not card_info[card]?
        console.log("no such card: #{card}")
      if card_info[card].isAction
        features.nActions += count
      features.n += count
  
  for own card, count of deck
    if card not in ['vp', 'chips']
      if card_info[card].isVictory or card is 'Curse'
        cardvp = 0
        switch card
          when 'Gardens'
            cardvp = Math.floor(features.n / 10)
          when 'Fairgrounds'
            cardvp = Math.floor(features.nUnique / 5) * 2
          when 'Duke'
            cardvp = features.deck['Duchy'] ? 0
          when 'Vineyard'
            cardvp = Math.floor(features.nActions / 3)
          else
            cardvp = card_info[card].vp
        # console.log(count+"x "+card+" is worth "+(cardvp*count))
        features.cardvp += cardvp * count
  if features.vp is null
    features.vp = features.cardvp
  if features.chips is null
    features.chips = features.vp - features.cardvp
  features

addToDeckFeatures = (deck, feats, newcards) ->
  # Takes in a deck and a 'deckFeatures' object that describes that deck,
  # plus a list of new cards. Returns the new deckFeatures object.
  newdeck = util.clone(deck)
  for card in newcards
    if newdeck[card]?
      newdeck[card] += 1
    else
      newdeck[card] = 1
  newfeats = getDeckFeatures(newdeck)
  
  # Take the known number of chips and use it to fix up the VP count.
  newfeats.chips = feats.chips
  newfeats.vp = newfeats.cardvp + newfeats.chips
  #assert.ok(newfeats.chips >= 0)
  newfeats

normalizeFeats = (feats) ->
  # Takes a deckFeatures object and squishes together the card counts and
  # a bunch of features into one object. The card counts will be normalized
  # into cards per hand to prepare for prediction by Vowpal.
  nHands = Math.max(feats.n, 5) / 5
  normalized = {
    actions: 0
    actionBalance: 0
    coinRatio: 0
    potionRatio: 0
  }
  for card, count of feats.deck
    normalized[card] = count / nHands
    if card_info[card].isAction
      normalized.actions += count / 10
      normalized.actionBalance += count*(card_info[card].actions - 1) / nHands
    if card_info[card].isTreasure
      normalized.coinRatio += count*(card_info[card].coins) / nHands
      normalized.potionRatio += count*(card_info[card].potion) / nHands
    # make features such as "Caravan>3"
    for level in [0...count]
      normalized[card+'>'+level] = 1
  
  normalized.unique = feats.nUnique
  normalized.n = feats.n / 10
  normalized.vp = feats.vp / 10
  normalized

normalizeDeck = (deck) ->
  normalizeFeats(getDeckFeatures(deck))

normalizeSupply = (supply) ->
  norm = {}
  for card, value of supply
    norm[card] = value / numCopiesPerGame(card, 2)
  norm

exports.getDeckFeatures = getDeckFeatures
exports.addToDeckFeatures = addToDeckFeatures
exports.normalizeFeats = normalizeFeats
exports.normalizeDeck = normalizeDeck
exports.normalizeSupply = normalizeSupply
