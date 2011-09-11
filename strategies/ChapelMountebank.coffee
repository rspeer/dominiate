# Gain one Chapel and one Mountebank, and otherwise play Big Money.
{
  name: 'ChapelMountebank'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6
    "Mountebank" if state.current.countInDeck("Mountebank") == 0
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    
    # If this bot somehow gets rid of its chapel later in the game,
    # it won't try to acquire another one.
    "Chapel" if state.current.coins <= 3 and state.current.countInDeck("Chapel") == 0 and state.current.turnsTaken <= 2
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
