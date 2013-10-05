{
  name: 'BeggarGardens'
  author: 'ragingduckd'
  requires: ['Beggar', 'Gardens']
  
  gainPriority: (state, my) ->  
    if state.supply["Rebuild"]?
      return this.gainPriorityRebuild(state, my)
    else
      return this.gainPriorityDefault(state, my)
  
  gainPriorityRebuild: (state, my) -> [
    "Province"
    "Duchy"
    "Estate" if state.gainsToEndGame() <= 2
    "Beggar" if my.countInDeck("Beggar") < 2
    "Gardens"
    "Duchy"
    "Beggar"
    "Estate"
    "Copper"
  ]
  
  gainPriorityDefault: (state, my) -> [
    "Gardens"
    "Duchy"
    "Estate" if state.gainsToEndGame() <= 4
    "Beggar"
    "Silver"
    "Estate"
    "Copper"
  ]
}
