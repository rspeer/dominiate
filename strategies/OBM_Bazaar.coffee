# Optimized version of Big Money + Bazaar
{
  name: 'OBM Bazaar'
  author: 'WanderingWinder'
  requires: ['Bazaar']
  gainPriority: (state, my) -> [
    "Province" if my.countInDeck("Gold") > 0
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 5
    "Bazaar"
    "Silver"
  ]
}

