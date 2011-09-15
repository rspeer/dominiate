# Gain one Chapel and one Witch, and otherwise play Big Money. One of the most
# powerful two-card strategies there is.
{
  name: 'ChapelWitch'
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Witch" if my.countInDeck("Witch") == 0
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    
    # If this bot somehow gets rid of its chapel later in the game,
    # it won't try to acquire another one.
    "Chapel" if my.coins <= 3 and my.countInDeck("Chapel") == 0 and my.turnsTaken <= 2
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
