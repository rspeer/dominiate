# Optimized version of Big Money + Bazaar
{
  name: 'OBM Bridge'
  author: 'WanderingWinder'
  gainPriority: (state) -> [
    "Province" if state.current.countInDeck("Gold") > 0
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 6
    "Bridge" if state.current.countInDeck("Bridge") <= state.current.countCardTypeInDeck("Treasure") / 10
    "Bridge" if state.current.countInDeck("Bridge") == 0
    "Bazaar"
    "Silver"
  ]
}

