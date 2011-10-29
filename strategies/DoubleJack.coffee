# Buys two Jacks of All Trades and otherwise plays a version of Big Money.
#
# This has no Colony rules, because it would be a terrible strategy in
# Colony games.
{
  name: 'DoubleJack'
  author: 'rspeer'
  requires: ["Jack of All Trades"]
  gainPriority: (state, my) -> [
    "Province" if my.getTotalMoney() > 15
    "Duchy" if state.gainsToEndGame() <= 5
    "Estate" if state.gainsToEndGame() <= 2
    "Gold"
    "Jack of All Trades" if my.countInDeck("Jack of All Trades") < 2
    "Silver"
  ]
}
