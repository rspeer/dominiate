# This is an implementation of the pure Big Money strategy, derived from
# the one called "Big Money Ultimate" or "BMU" on the forums and in
# Geronimoo's simulator.
{
  name: 'BigMoney'
  gainPriority: (state) -> [
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}
