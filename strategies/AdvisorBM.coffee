{
  name: 'AdvisorBM'
  requires: ['Advisor']
  gainPriority: (state, my) -> [
    "Province"
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Gold"
    "Advisor"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
