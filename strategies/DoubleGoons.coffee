{
  name: 'DoubleGoons'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Goons" if state.current.countInDeck("Goons") < 2
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 4 \
             and state.current.countInPlay("Goons") > 0
  ]
}
