{
  name: 'OBM Courtyard'
  author: 'HiveMindEmulator'
  requires: ['Courtyard']
  gainPriority: (state, my) -> [
    "Province" if my.countInDeck("Gold") > 0
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 5
    "Silver" if my.countInDeck("Silver") == 0
    "Courtyard" if my.countInDeck("Courtyard") == 0
    "Courtyard" if my.countInDeck("Courtyard") < my.countCardTypeInDeck("treasure") / 8
    "Silver"
    "Courtyard" if my.countInDeck("Courtyard") <= 1
  ]
}
