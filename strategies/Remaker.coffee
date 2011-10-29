{
  name: 'Remaker'
  requires: ['Remake']
  gainPriority: (state, my) -> [
    "Province" if my.countInDeck("Gold") > 0
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Gold"
    "Remake" if my.countInDeck("Remake") == 0
    "Silver"

    # Some inoffensive $4, $5, and $7 cards, in case it needs them:
    "Expand"
    "Laboratory"
    "Caravan"
  ]
}
