{
  name: 'MasterpieceGardens'
  requires: ['Masterpiece', 'Gardens']
  gainPriority: (state, my) -> [
    "Masterpiece" if my.coins >= 5
    "Gardens"
    "Masterpiece" if my.coins == 4
    "Silver"
    "Estate"
    "Copper"
  ]
  
  #chooseOverpayMasterpiece: (state, maxAmount) ->
  #  return maxAmount
 }
  
