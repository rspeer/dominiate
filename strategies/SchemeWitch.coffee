{
  name: 'SchemeWitch'
  requires: ['Witch', 'Scheme']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 and my.countInDeck("Gold") > 0
    "Witch" if my.countInDeck("Witch") == 0
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Scheme" if my.countInDeck('Scheme') < 2 and my.countInDeck('Silver') > 0
    "Silver"
  ]
}
