# SillyAI's strategy is to buy an arbitrary card with the highest available
# cost. It does a reasonable job of playing like a newbie, it occasionally
# gets lucky and pulls off nice combos, and it tests a lot of possible
# states of the game.
{
  name: 'SillyAI'
  author: 'rspeer'
  requires: []
  gainPriority: (state, my) -> []
  gainValue: (state, card, my) ->
    if my.turnsTaken > 100 and card isnt null
      # oh god, just make it stop
      return 1
    if card.name is "Copper" or card.name is "Curse"
      return -1
    else
      [coins, potions] = card.getCost(state)
      return coins + potions*2 + Math.random()
}
