{
  name: 'LordBottington'
  requires: ['Rats']
  gainPriority: (state, my) -> [
    "Province"
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Gold"
    "Rats" if my.countInDeck("Rats") < 2
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]

  wantsToPlayRats: (state, my) ->
    100 * Math.random() < 90
}
