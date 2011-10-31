{
  name: 'Double Ambassador'
  author: 'rspeer'
  requires: ['Ambassador']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Ambassador" if my.countInDeck("Ambassador") < 2
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]

  discardPriority: (state, my) -> [
    "Colony"
    "Duchy"
    "Province"
    "Ambassador" if my.countInHand("Ambassador") > 1
    "Estate" if my.countInHand("Ambassador") == 0 \
             or state.gainsToEndGame <= 5
    "Curse" if my.countInHand("Ambassador") == 0 \
            or state.gainsToEndGame <= 5
    "Copper"
    "Estate"
    "Curse"
    null
    "Silver"
  ]
}
