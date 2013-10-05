#simple version of Masterpiece/Feodum, not optimized but wins against BigMoney+X
{
  name: 'MasterpieceFeodum'
  author: 'DStu'
  requires: ['Masterpiece', 'Feodum']
  gainPriority: (state, my) -> [
    "Masterpiece" if my.coins >= 5
    "Feodum" if my.countInDeck("Silver") > 8
    "Estate" if state.countInSupply("Gardens") == 0
    "Silver"
    "Estate"
    "Copper"
  ]
}
  
