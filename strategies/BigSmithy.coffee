{
  name: 'BigSmithy'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Smithy" if state.current.countInDeck("Smithy") < 2 \
             and state.current.numCardsInDeck() >= 16
    "Smithy" if state.current.countInDeck("Smithy") < 1
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}

