{
  name: 'DoubleGoons'
  requires: ['Goons']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Goons" if my.countInDeck("Goons") < 2
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 4 \
             and my.countInPlay("Goons") > 0
  ]
}
