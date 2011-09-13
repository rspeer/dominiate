{
  name: "TournamentPlayer"
  author: 'rspeer'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province"
    "Duchy" if 0 < state.gainsToEndGame() <= 2
    "Followers"
    "Trusty Steed"
    "Bag of Gold"
    "Princess"
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Diadem"
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Tournament"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
  
  discardPriority: (state) -> [
    "Colony"
    "Duchy"
    "Curse"
    "Estate"
    "Province" if state.current.countInHand("Tournament") == 0 \
               or state.current.countInHand("Province") > 1
    "Copper"
    null
    "Silver"
    "Gold"
  ]

}
