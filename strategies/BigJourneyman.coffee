{
  name: 'BigJourneyman'
  requires: ['Journeyman']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Journeyman" if my.countInDeck("Journeyman") < 2 \
                 and my.numCardsInDeck() >= 18
    "Journeyman" if my.countInDeck("Journeyman") < 1
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]

  wantsToJM: (state, my) -> 
    #my.draw.length >= 3
    true

  skipPriority: (state, my) -> [
    "Copper" if my.getTotalMoney() / my.numCardsInDeck() > 1
    "Province" if my.countInDeck("Province") > my.countInDeck("Duchy") \
               and my.countInDeck("Province") > my.countInDeck("Estate") 
    "Duchy" if my.countInDeck("Duchy") > my.countInDeck("Estate") 
    "Estate"
  ]
}

