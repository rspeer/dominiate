# Buy Wharf with every $5 and King's Court with every $7. Probably not
# optimized.
{
  name: 'KCWharf'
  author: 'rspeer'
  requires: ["King's Court", "Wharf"]
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "King's Court"
    "Gold"
    "Wharf"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
