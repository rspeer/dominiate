# This Bot does not win anything, but it demonstrates how to configure Develop...
# Feel free to write a Develop-bot that wins...
{
  name: 'Develop'
  author: 'DStu'
  requires: ["Develop", "Talisman", "Festival", "Watchtower", "Oasis"]
  gainPriority: (state, my) -> [
     "Province" if my.getTotalMoney() > 18
     "Talisman" if my.countInDeck("Talisman") < 2 and my.countInDeck("Develop") > 0
     "Festival" if my.countInDeck("Festival") < 1
     "Oasis" if my.countInDeck("Oasis") < 1
     "Develop" if my.countInDeck("Develop") < 1
     "Watchtower" if my.countInDeck("Watchtower") < 2
     "Festival"
     "Oasis"
    ]
    
  developPriority: (state, my) -> [
    ["Talisman", ["Festival", "Watchtower"]]
    ["Estate", ["Oasis", null]]
    ["Copper", [null, null]]
  ]
  
  actionPriority: (state, my) -> [
   "Festival"
   "Oasis"
   "Watchtower" if (my.actions > 1 and my.hand.length < 5)
   "Develop" if my.countInHand("Talisman") > 1
   "Develop" if my.countInHand("Estate") > 1
   "Develop" if my.countInHand("Copper") > 1
   "Watchtower"
  ]
    
  discardPriority: (state, my) -> [
    "Province"
    "Duchy"
    "Estate" 
    "Copper"
    "Develop" 
    "Talisman"  
    "Silver"
    "Watchtower"
    "Festival"
    "Gold"
  ]
}
