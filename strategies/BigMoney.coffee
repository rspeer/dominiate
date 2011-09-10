# This is an implementation of the pure Big Money strategy, derived from
# the one called "Big Money Ultimate" or "BMU" on the forums and in
# Geronimoo's simulator.
{
  name: 'BigMoney'
  gainPriority: (state) -> [
    # This strategy differs slightly from BMU in a couple of ways. For one
    # thing, there is no separate "BM with Colonies" strategy; it will include
    # Colonies and Platinums in its strategy if they are in the supply.
    "Colony" if state.current.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    # When deciding whether to go for Duchies and Estates:
    # Instead of counting the number of Colonies or Provinces to the end of
    # the game, we count the minimum number of gains (of any cards) that it
    # would take to end the game. This lets the BM strategy prepare correctly
    # for three-pile endings.
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
    # "null" represents a preference to buy nothing at this point.
    null
  ]
}
