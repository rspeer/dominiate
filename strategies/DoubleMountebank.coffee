{
  name: 'DoubleMountebank'
  requires: ['Mountebank']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 and my.countInDeck("Gold") > 0
    "Duchy" if state.gainsToEndGame() <= 5
    "Mountebank" if my.countInDeck("Mountebank") < 2
    "Estate" if state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
  ]
}
