#strategy to test the Baker, NOT optimized
{
  name: 'Big Money-Baker'
  author: 'DStu'
  requires: ['Baker']
  gainPriority: (state, my) -> [
    "Province" if my.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Baker"
    "Silver"
  ]
}

