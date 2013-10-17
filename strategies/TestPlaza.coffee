{
  name: 'Plaza'
  author: 'DStu'
  requires: ["Plaza"]
  gainPriority: (state, my) -> [
    "Province" 
    "Duchy" if state.gainsToEndGame() <= 5
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Plaza" if my.countInDeck("Plaza") < 3
    "Silver"
  ]  
}
