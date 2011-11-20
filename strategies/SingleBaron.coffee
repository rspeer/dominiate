{
  name: 'SingleBaron'
  requires: ['Baron']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if state.gainsToEndGame() <= 5
    "Estate" if state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Baron" if my.countInDeck("Baron") == 0
    "Silver"
    "Copper" if state.gainsToEndGame() <= 2
  ]
  
  discardPriority: (state, my) -> [
    "Colony"
    "Province"
    "Duchy"
    "Curse"
    "Estate" if my.countInHand("Baron") == 0 \
             or my.countInHand("Estate") > 1
    "Copper"
    "Baron" if my.countInHand("Estate") == 0
    null
    "Silver"
    "Estate"
    "Baron"
  ]

}
