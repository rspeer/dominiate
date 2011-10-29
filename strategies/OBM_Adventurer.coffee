# Optimized version of Big Money + Adventurer
{
  name: 'OBM Adventurer'
  author: 'WanderingWinder'
  requires: ['Adventurer']
  gainPriority: (state, my) -> [
    "Province" if my.countInDeck("Gold") > 0
    "Duchy" if state.countInSupply("Province") <= 4
    "Estate" if state.countInSupply("Province") <= 2
    "Adventurer" if state.countInSupply("Gold") > 0 \
                 and my.countInDeck("Adventurer") == 0
    "Gold"
    "Duchy" if state.countInSupply("Province") <= 5
    "Silver"
  ]
}
