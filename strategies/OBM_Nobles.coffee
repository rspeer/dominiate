{
  name: 'OBM Nobles'
  author: 'rspeer'
  requires: ['Nobles']
  gainPriority: (state, my) -> [
    "Province"  
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Nobles" if my.countInDeck("Nobles") < 1
    "Nobles" if state.gainsToEndGame() <= 6
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 2
  ]
}
