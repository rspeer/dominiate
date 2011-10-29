# Plays Coppersmith on 5/2 starts; plays Big Money otherwise.
{
  name: 'OBM Coppersmith'
  author: 'HiveMindEmulator'
  requires: ['Coppersmith']
  gainPriority: (state, my) -> [
    "Province" if my.getTotalMoney() > 18
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Duchy" if state.gainsToEndGame() <= 6
    "Coppersmith" if my.numCardsInDeck() == 10 and my.getAvailableMoney() == 5
    "Silver"
  ]
}

