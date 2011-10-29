{
  name: 'BigSmithy'
  requires: ['Smithy']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Smithy" if my.countInDeck("Smithy") < 2 \
             and my.numCardsInDeck() >= 16
    "Smithy" if my.countInDeck("Smithy") < 1
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}

