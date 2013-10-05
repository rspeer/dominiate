#simple version of Masterpiece/Feodum, not optimized but wins against BigMoney+X
{
  name: 'MasterpieceFeodum'
  author: 'DStu'
  requires: ['Masterpiece', 'Feodum']
  gainPriority: (state, my) -> [
    "Masterpiece" if my.coins >= 5
    "Feodum" if my.countInDeck("Silver") > 8
    "Duchy" if my.countInDeck("Feodum") > 0
    "Estate" if state.countInSupply("Feodum") == 0
    "Silver"
    "Estate"
    "Copper"
  ]
}
  
