{
  name: 'BigEnvoy'
  requires: ['Envoy']
  gainPriority: (state, my) -> [
    "Colony" if my.countInDeck("Platinum") > 0
    "Province" if state.countInSupply("Colony") <= 6 \
               or state.countInSupply("Province") <= 6
    
    "Duchy" if 0 < state.gainsToEndGame() <= 5
    "Estate" if 0 < state.gainsToEndGame() <= 2
    "Platinum"
    "Gold"
    "Envoy" if my.countInDeck("Envoy") < 1
    "Silver"
    "Copper" if state.gainsToEndGame() <= 3
  ]
}

