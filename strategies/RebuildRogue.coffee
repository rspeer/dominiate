{
  name: 'RebuildRogue'
  author: 'ragingduckd', 'SheCantSayNo'
  requires: ['Rebuild', 'Rogue']
  gainPriority: (state, my) -> [
    "Province"    
    "Rebuild" if my.countInDeck("Rebuild") < 2
    "Rogue" if my.countInDeck("Rogue") == 0
    "Duchy"
    "Rogue" 
    "Rebuild"
    "Estate" if my.countInDeck("Duchy") == 0 \
             and my.countInDeck("Estate") == 0 \
             and my.countInDeck("Rebuild") == 2 \
             and state.countInSupply("Duchy") >= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Silver"
  ]

  rogueGainValue: (state, card, my) ->
    if state.gainsToEndGame() <= 4
      return card.getVP(my)
    else
      [coins, potions] = card.getCost(state)
      return coins

  rogueTrashValue: (state, card, my) ->
    if state.gainsToEndGame() <= 4
      return -card.getVP(my.getDeck())
    else
      [coins, potions] = card.getCost(state)
      return -coins

  wantsToRebuild: (state, my) ->
    return state.countInSupply("Province") > 0

  rebuildPriority: (state, my) -> [
    "Province"
    "Duchy"
    "Estate"
  ]

  nameVPPriority: (state, my) -> [
    "Duchy" if state.countInSupply("Duchy") > 0 \
            and my.countInDeck("Estate") - my.countInHand("Estate") > 0 \
            and my.countInDeck("Province") - my.countInHand("Province") < \
            (my.countInDeck("Estate") - my.countInHand("Estate"))
    "Province" if my.countInDeck("Duchy") - my.countInHand("Duchy") > 0 
    "Estate"
  ]
}
