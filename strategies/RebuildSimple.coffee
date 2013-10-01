{
  name: 'RebuildSimple'
  requires: ['Rebuild']
  gainPriority: (state, my) -> [
    "Province"
    "Rebuild" if my.countInDeck("Rebuild") < 2
    "Duchy"
    "Rebuild"
    "Estate" if my.countInDeck("Duchy") == 0 \
             and my.countInDeck("Estate") == 0 \
             and my.countInDeck("Rebuild") == 2
    "Estate" if state.gainsToEndGame() <= 4
    "Silver"
    "Estate" if state.gainsToEndGame() <= 6
  ]

  wantsToRebuild: (state, my) ->
    return state.countInSupply("Province") > 0

  rebuildPriority: (state, my) -> [
    "Province"
    "Duchy"
    "Estate"
  ]

  nameVPPriority: (state, my) -> [
    "Province" if state.gainsToEndGame() > 1
    "Estate"
  ]
}

