{
  name: 'Rebuild' 
  author: 'ragingduckd', 'SheCantSayNo'
  requires: ['Rebuild']
  gainPriority: (state, my) -> [
    "Province"
    "Rebuild" if my.countInDeck("Rebuild") < 2
    "Rebuild" if my.countInDeck("Rebuild") < 3 and state.countInSupply("Rebuild") == 8
    "Duchy"
    "Estate" if state.gainsToEndGame() <= 1
    "Estate" if state.gainsToEndGame() == 2 and my.ai.getScore(state, my) > -8
    "Gold"
    "Estate" if state.gainsToEndGame() <= 2
    "Rebuild" if (my.countInDeck("Duchy") > 0 or my.ai.getScore(state, my) > 2)\
                and (state.countInSupply("Rebuild") > 2 or my.ai.getScore(state, my) > 3 \
                or (state.countInSupply("Rebuild") == 1 and my.ai.getScore(state, my) > 0))
    "Estate" if my.countInDeck("Duchy") == 0 \
                and my.countInDeck("Estate") == 0 \
                and state.countInSupply("Duchy") >= 4
    "Estate" if my.countInDeck("Duchy") == 0 \
                and state.countInSupply("Duchy") == 0
    "Silver"
  ]

  getScore: (state, my) -> 
    for status in state.getFinalStatus()
      [name, score, turns] = status
      if name == my.ai.toString()
        myScore = score
      else
        opponentScore = score
    return myScore - opponentScore

  countNotInHand: (my, card) ->
    return my.countInDeck(card) - my.countInHand(card)

  countInDraw: (my, card) ->
    return my.countInDeck(card) - my.countInHand(card) - my.countInDiscard(card)

  wantsToRebuild: (state, my) ->
    if my.countInHand("Rebuild") >= state.countInSupply("Province") \
       and my.ai.getScore(state, my) > 0
          answer = 1
    else if state.countInSupply("Province") == 1 \
            and my.ai.getScore(state, my) < -4
              answer = 0
    else if state.countInSupply("Duchy") == 0 \
            and my.ai.countNotInHand(my, "Duchy") == 0\
            and my.ai.getScore(state, my) < 0
              answer = 0
    else if my.getTreasureInHand() > 7 and state.countInSupply("Province") == 1
              answer = 0
    else
          answer = state.countInSupply("Province") > 0
    return answer

  rebuildPriority: (state, my) -> [
    "Province"
    "Duchy"
    "Estate"
  ]

  nameVPPriority: (state, my) -> [
    "Duchy" if  state.countInSupply("Duchy") > 0 \
            and my.ai.countNotInHand(my, "Estate") > 0 \
            and (my.ai.countNotInHand(my, "Province") == 0 \
                or  (my.ai.countInDraw(my, "Province") == 0 \
                    and my.ai.countInDraw(my, "Duchy") > 0 \
                    and my.ai.countInDraw(my, "Estate") > 0))
    "Province" if my.ai.countInDraw(my, "Estate") == 0 \
               and my.ai.countInDraw(my, "Duchy") > 0 \
               and my.ai.countInDraw(my, "Province") > 0
    "Province" if my.ai.countNotInHand(my, "Estate") == 0 \
               and my.ai.countNotInHand(my, "Duchy") > 0 \
               and my.ai.countNotInHand(my, "Province") > 0
    "Estate" if my.countInHand("Rebuild") + 1 >= state.countInSupply("Province") \
             and my.ai.getScore(state, my) > 0
    "Estate" if state.countInSupply("Duchy") == 0 \
             and my.ai.countInDraw(my, "Estate") > 0 \
             and my.ai.countInDraw(my, "Province") == 0
    "Province" if state.countInSupply("Duchy") == 0 \
               and my.ai.countInDraw(my, "Duchy") > 0 \
               and my.ai.countInDraw(my, "Province") > \
               my.ai.countInDraw(my, "Estate") 
    "Estate" if state.countInSupply("Duchy") == 0 \
             and my.ai.countInDraw(my, "Estate") > 0 \
             and my.ai.countInDraw(my, "Province") > 0 \
             and my.ai.getScore(state, my) > 2
    "Estate" if state.countInSupply("Duchy") == 0 \
             and my.ai.countNotInHand(my, "Estate") > 0 \
             and my.ai.countNotInHand(my, "Duchy") < 3 \
             and my.ai.countNotInHand(my, "Province") > 0 \
             and my.ai.getScore(state, my) > 4
    "Estate" if state.countInSupply("Duchy") == 0 \
             and my.countInDeck("Duchy") == 0 \
             and my.ai.getScore(state, my) > 0
    "Estate" if state.countInSupply("Duchy") == 0 \
             and my.ai.countNotInHand(my, "Duchy") == 0 \
             and my.ai.countNotInHand(my, "Province") > 0 \
             and my.ai.getScore(state, my) > 2
    "Province" if my.ai.countNotInHand(my, "Province") > 0
    "Estate"
  ]
} 