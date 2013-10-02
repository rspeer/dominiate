{
  name: 'Beggar Gardens'
  author: 'ragingduckd'
  requires: ['Beggar', 'Gardens']
  gainPriority: (state, my) -> [
    "Province"
    "Duchy" if state.gainsToEndGame() <= 4
    "Estate" if state.gainsToEndGame() <= 2
    "Beggar" if my.countInDeck("Beggar") < 2
    "Gardens"
    "Duchy"
    "Beggar"
    "Estate"
    "Copper"
  ]
}
