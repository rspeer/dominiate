###
The compiled result of this CoffeeScript gets combined with dominion.js and
the rest of the extension. We export the function 'updateGolem', which is
passed relevant information about the game state.
###

updateGolem = (players, turnNum) ->
  myself = null
  opponent = null

  # Get my deck, and the deck belonging to the (relevant) opponent.
  for name, player of players
    if name == "You"
      myself = player
    else
      if opponent is null or player.score > opponent.score
        opponent = player
  mydata = {score: myself.score, card_counts: myself.card_counts}
  oppdata = {score: opponent.score, card_counts: opponent.card_counts}

  supply = getSupply()
  
  jQuery.ajax "http://localhost:8888/gain", {
    data: {
      myself: JSON.stringify(mydata)
      opponent: JSON.stringify(oppdata)
      supply: JSON.stringify(supply)
      turnNum: turnNum
      coins: 11      # show all possibilities for now
      buys: 1
    }
    dataType: 'json'
    success: (data) ->
      showBuyValues(data)
    error: (data) ->
      console.log("ajax error: "+JSON.stringify(data))
  }

showBuyValues = (data) ->
  baseline = 0
  for choice, score of data.choices
    if choice == []
      baseline = score
  for choice, score of data.choices
    score -= baseline
    if choice.length == 1
      cardName = choice[0]
      showCardValue(cardName, score)

getSupply = () ->
  supply = {}
  jQuery('div.supplycard').each (i) ->
    elt_vertical = this.getElementsByClassName("vertical")[0]
    elt_imprice = elt_vertical.getElementsByClassName("imprice")[0]
    elt_imavail = elt_vertical.getElementsByClassName("imavail")[0]
    cardname = this.getAttribute("cardname")
    price = parseInt(elt_imprice.textContent.substring(1))
    availText = elt_imprice.textContent
    avail = parseInt(availText.substring(1, availText.length-1))
    if avail > 0
      supply[cardname] = [avail, price]
  supply

showCardValue = (cardName, score) ->
  jQuery('div.supplycard').each (i) ->
    if this.getAttribute("cardname") == cardName
      elt_cardname = this.getElementsByClassName("cardname")[0]
      elt_cardname.innerHTML = cardName + '<br>' + score.toFixed(3)

window.updateGolem = updateGolem

