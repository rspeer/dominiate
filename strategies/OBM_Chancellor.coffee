{
  name: 'OBM Chancellor'
  author: 'rspeer'
  requires: ['Chancellor']
  gainPriority: (state, my) -> [
    "Province" if my.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 6
    "Chancellor" if my.countInDeck("Chancellor") < 1
    "Silver"
  ]
}

