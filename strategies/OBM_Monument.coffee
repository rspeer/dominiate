# Optimized version of Big Money + Monument
{
  name: 'OBM Monument'
  author: 'tko'
  requires: ['Monument']
  gainPriority: (state, my) -> [
    "Province" if my.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 5
    "Monument" if my.countInDeck("Monument") < 3
    "Silver"
  ]
}

