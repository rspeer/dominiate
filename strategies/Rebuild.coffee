{
  name: 'Rebuild'
  requires: ['Rebuild']
  gainPriority: (state, my) -> [
    "Province"
    "Rebuild" if my.countInDeck("Rebuild") < 2 or if state.countInSupply("Duchy") == 0
    "Duchy"
    "Silver"
    "Estate" if state.countInSupply("Duchy") == 0 and my.countInDeck("Estate") > 0
  ]
}
