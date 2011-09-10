# SillyAI's strategy is to buy an arbitrary card with the highest available
# cost. It does a reasonable job of playing like a newbie, it occasionally
# gets lucky and pulls off nice combos, and it tests a lot of possible
# states of the game.
{
  name: 'SillyAI'

  gainPriority: (state) -> 
    cards = []
    for card, count of state.supply
      if state.cardInfo[card].cost > 0
        cards.push(card)
    effectiveCost = (card) ->
      [coins, potions] = state.cardInfo[card].getCost(state)
      coins + potions*2 + Math.random()
    cards.sort( (c1, c2) ->
      effectiveCost(c2) - effectiveCost(c1)
    )
    cards
}