# Optimized version of Big Money + Monument
# based on TKO's but turned down to 1 monument
{
  name: 'OBM Monument'
  author: 'rspeer'
  gainPriority: (state) -> [
    "Province" if state.current.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 5
    "Monument" if state.current.countInDeck("Monument") < 1
    "Silver"
  ]
}

