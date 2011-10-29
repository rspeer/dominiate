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

  # This is the default Ambassador strategy, but it should likely be changed.
  ambassadorPriority: (state, my) ->
    [
      "Curse,2"
      "Curse,1"
      "Curse,0"
      "Estate,2"
      "Estate,1"
      # Make sure we have at least $5 in the deck, including if we buy a Silver.
      "Copper,2" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 5
      "Copper,2" if my.getTreasureInHand() >= 5
      "Copper,2" if my.getTreasureInHand() == 3 and my.getTotalMoney() >= 7
      "Copper,1" if my.getTreasureInHand() < 3 and my.getTotalMoney() >= 4
      "Copper,1" if my.getTreasureInHand() >= 4
      "Estate,0"
      "Copper,0"
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
