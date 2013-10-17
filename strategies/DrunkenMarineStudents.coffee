{
  name: 'Drunk Marine Students'
  author: 'Geronimoo'
  requires: ['Potion', 'University', 'Vineyard', 'Wharf', 'Alchemist', 'Bazaar', 'Wharf']
  gainPriority: (state, my) -> [
    "Vineyard" if my.numActionCardsInDeck() > 11
    "Province"
    "Duchy" if state.countInSupply("Province") <= 2
    "Estate" if state.countInSupply("Province") <= 1
    "University" if my.countInDeck("University") < 3
    "Wharf" if my.countInDeck("University") + my.countInDeck("Bazaar") > my.countInDeck("Wharf")
    "Scrying Pool" if my.numActionCardsInDeck() > 3
    "Alchemist"
    "Bazaar"
    "Potion" if my.countInDeck("Potion") < 3
    "Silver"
  ]
}
