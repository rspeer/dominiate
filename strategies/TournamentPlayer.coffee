{
  name: "TournamentPlayer"
  author: 'rspeer'
  requires: ['Tournament']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
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
  
  discardPriority: (state, my) -> [
    "Colony"
    "Duchy"
    "Curse"
    "Estate"
    "Province" if my.countInHand("Tournament") == 0 \
               or my.countInHand("Province") > 1
    "Copper"
    null
    "Silver"
    "Gold"
  ]

}
