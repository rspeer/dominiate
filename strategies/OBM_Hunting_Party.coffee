{
  name: 'OBM Hunting Party'
  author: 'DG'
  requires: ['Hunting Party']
  gainPriority: (state, my) -> [
    "Province" if my.countInDeck("Gold") > 0
    "Duchy" if state.gainsToEndGame() <= 2
    "Estate" if state.gainsToEndGame() <= 2
    "Gold" if my.countInDeck("Gold") == 0
    "Hunting Party"
    "Gold"
    "Estate" if state.gainsToEndGame() <= 4
    "Silver"
  ]
}
