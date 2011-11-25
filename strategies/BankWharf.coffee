# Play Big Money including Banks, except buy Wharf with every $5 buy.
{
  name: 'BankWharf'
  author: 'Geronimoo' #tweaked by Jorbles
  requires: ['Bank', 'Wharf']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Platinum"
    "Bank"
    "Gold"
    "Wharf"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
