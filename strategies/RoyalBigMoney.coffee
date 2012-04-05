{
  name: 'Royal Big Money'
  requires: ['Royal Seal']
  gainPriority: (state, my) -> 
    if state.supply.Colony?
      [
        "Colony" if my.getTotalMoney() > 32
        "Province" if state.gainsToEndGame() <= 6
        "Duchy" if state.gainsToEndGame() <= 5
        "Estate" if state.gainsToEndGame() <= 2
        "Platinum"
        "Province" if state.countInSupply("Colony") <= 7
        "Gold"
        "Duchy" if state.gainsToEndGame() <= 6
        "Royal Seal"
        "Silver"
        "Copper" if state.gainsToEndGame() <= 2
      ]
    else
      [
        "Province" if my.getTotalMoney() > 18
        "Duchy" if state.gainsToEndGame() <= 4
        "Estate" if state.gainsToEndGame() <= 2
        "Gold"
        "Duchy" if state.gainsToEndGame() <= 6
        "Royal Seal"
        "Silver"
      ]
}

