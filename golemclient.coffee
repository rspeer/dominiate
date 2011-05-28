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
  console.log("received choices: #{JSON.stringify(data.choices)}")
  for [choice, score] in data.choices
    if choice.length == 0
      baseline = score
  for [choice, score] in data.choices
    score -= baseline
    if choice.length == 1
      cardName = choice[0]
      showCardValue(cardName, score)

getSupply = () ->
  supply = {}
  for elt in document.getElementsByClassName('supplycard')
    elt_imprice = elt.getElementsByClassName("imprice")[0]
    elt_imavail = elt.getElementsByClassName("imavail")[0]
    cardname = elt.getAttribute("cardname")
    price = parseInt(elt_imprice.textContent.substring(1))
    availText = elt_imavail.textContent
    avail = parseInt(availText.substring(1, availText.length-1))
    if avail > 0
      supply[cardname] = [avail, price]
  supply

showCardValue = (cardName, score) ->
  for elt in document.getElementsByClassName('supplycard')
    if elt.getAttribute("cardname") == cardName
      elt_cardname = elt.getElementsByClassName("cardname")[0]
      if not elt_cardname?
        elt_cardname = document.createElement('div')
        elt_cardname['class'] = "cardname"
        elt.appendChild(elt_cardname)
      try 
        elt_cardname.innerHTML = cardName + '<br>' + score.toFixed(3)
      catch exc
        null

window.updateGolem = updateGolem

