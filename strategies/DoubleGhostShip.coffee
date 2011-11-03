{
  name: 'DoubleGhostShip'
  requires: ['Ghost Ship']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 and my.countInDeck("Gold") > 0
    "Ghost Ship" if my.countInDeck("Ghost Ship") < 2
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
  ]
}
