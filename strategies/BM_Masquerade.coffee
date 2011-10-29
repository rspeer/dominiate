# ehunt described this strategy in words on the Dominion Strategy Forum,
# describing it as a "fun, if sobering, experiment" to play Masquerade
# completely algorithmically in a real game.
#
# "Do not try to tweak big money masquerade. Instead, let big money
# masquerade tweak you."
{
  name: 'BM Masquerade'
  requires: ['Masquerade']
  author: 'ehunt'
  gainPriority: (state, my) -> 
    [
      "Province"
      "Gold"
      "Duchy" if state.gainsToEndGame() <= 5
      "Masquerade" if my.countInDeck("Masquerade") == 0
      "Silver"
    ]
}

