{
  name: 'SingleBaron'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Baron" if state.current.countInDeck("Baron") == 0
    "Silver"
    "Copper" if state.gainsToEndGame() <= 2
  ]
  
  discardPriority: (state) -> [
    "Colony"
    "Province"
    "Duchy"
    "Curse"
    "Estate" if state.current.countInHand("Baron") == 0 \
             or state.current.countInHand("Estate") > 1
    "Copper"
    "Baron" if state.current.countInHand("Estate") == 0
    null
    "Silver"
    "Estate"
    "Baron"
  ]

}
