# Optimized version of Big Money + Monument
{
  name: 'OBM Monument'
  author: 'tko'
  gainPriority: (state) -> [
    "Province" if state.current.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 5
    "Monument" if state.current.countInDeck("Monument") < 3
    "Silver"
  ]
}

