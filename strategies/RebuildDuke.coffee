{
  name: 'RebuildDuke'
  author: 'ragingduckd', 'SheCantSayNo'
  requires: ['Rebuild', 'Duke']
  gainPriority: (state, my) -> [    
    "Rebuild" if my.countInDeck("Rebuild") < 2
    "Duchy"
    "Province"
    "Duke"    
    "Estate" if my.countInDeck("Estate") ==0 and my.countInDeck("Rebuild") >= 2
    "Estate" if state.countInSupply("Duchy") == 0
    "Rebuild"
    "Silver"
  ]

  wantsToRebuild: (state, my) ->
    answer = state.countInSupply("Province") > 0
    return answer

  rebuildPriority: (state, my) -> [
    "Duchy"
    "Province"
    "Duke"
    "Estate"
  ]

  nameVPPriority: (state, my) -> [
    "Duchy"
  ]
}